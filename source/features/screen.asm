; ==================================================================
; SCREEN HANDLING SYSTEM CALLS
; ==================================================================

; ------------------------------------------------------------------
; os_print_string -- Displays text
; IN: SI = message location (zero-terminated string)
; OUT: Nothing (registers preserved)

os_print_string:
	pusha

	mov ah, 0Eh			; int 10h teletype function

.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string

	int 10h				; Otherwise, print it
	jmp .repeat			; And move on to next char

.done:
	popa
	ret

; ------------------------------------------------------------------
; os_format_string -- Displays colored text
; IN: BL/SI = text color/message location (zero-terminated string)
; OUT: Nothing (registers preserved)

os_format_string:
	pusha

	mov ah, 09h			; int 09h
	mov bh, 0
	mov cx, 1
	call os_get_cursor_pos
	
.repeat:
	lodsb				; Get char from string
	cmp al, 13
	je .cr
	cmp al, 10
	je .lf
	cmp al, 0
	je .done			; If char is zero, end of string

	int 10h				; Otherwise, print it

	inc dl
	call os_move_cursor
	
	jmp .repeat			; And move on to next char
	
.cr:
	mov dl, 0
	call os_move_cursor
	jmp .repeat

.lf:
	inc dh
	call os_move_cursor
	jmp .repeat
	
.done:
	popa
	ret


; ------------------------------------------------------------------
; os_clear_screen -- Clears the screen to background
; IN/OUT: Nothing (registers preserved)

os_clear_screen:
	pusha

	mov dx, 0			; Position cursor at top-left
	call os_move_cursor

	mov ah, 6			; Scroll full-screen
	mov al, 0			; Normal white on black
	mov bh, 7			;
	mov cx, 0			; Top-left
	mov dh, 24			; Bottom-right
	mov dl, 79
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

os_move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor

	popa
	ret


; ------------------------------------------------------------------
; os_get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column

os_get_cursor_pos:
	pusha

	mov bh, 0
	mov ah, 3
	int 10h				; BIOS interrupt to get cursor position

	mov [.tmp], dx
	popa
	mov dx, [.tmp]
	ret


	.tmp dw 0


; ------------------------------------------------------------------
; os_print_horiz_line -- Draw a horizontal line on the screen
; IN: AX = line type (1 for double (-), otherwise single (=))
; OUT: Nothing (registers preserved)

os_print_horiz_line:
	pusha

	mov cx, ax			; Store line type param
	mov al, 196			; Default is single-line code

	cmp cx, 1			; Was double-line specified in AX?
	jne .ready
	mov al, 205			; If so, here's the code

.ready:
	mov cx, 0			; Counter
	mov ah, 0Eh			; BIOS output char routine

.restart:
	int 10h
	inc cx
	cmp cx, 80			; Drawn 80 chars yet?
	je .done
	jmp .restart

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_show_cursor -- Turns on cursor in text mode
; IN/OUT: Nothing

os_show_cursor:
	pusha

	mov ch, 6
	mov cl, 7
	mov ah, 1
	mov al, 3
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_hide_cursor -- Turns off cursor in text mode
; IN/OUT: Nothing

os_hide_cursor:
	pusha

	mov ch, 32
	mov ah, 1
	mov al, 3			; Must be video mode for buggy BIOSes!
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos

os_draw_block:
	pusha

.more:
	call os_move_cursor		; Move to block starting position

	mov ah, 09h			; Draw colour section
	mov bh, 0
	mov cx, si
	mov al, ' '
	int 10h

	inc dh				; Get ready for next line

	movzx ax, dh		; Get current Y position into DL
	cmp ax, di			; Reached finishing point (DI)?
	jne .more			; If not, keep drawing

	popa
	ret


; ------------------------------------------------------------------
; os_file_selector -- Show a file selection dialog
; IN: Nothing; OUT: AX = location of filename string (or carry set if Esc pressed)

os_file_selector:
	pusha

	mov word [.filename], 0		; Terminate string in case user leaves without choosing

	mov ax, 64000			; Get comma-separated list of filenames
	call os_get_file_list

	call os_drive_letter
	mov bx, ax
	mov ax, 64000			; Show those filenames in a list dialog box
	mov cx, .help_msg2
	call os_list_dialog

	jc .esc_pressed

	dec ax				; Result from os_list_dialog starts from 1, but
					; for our file list offset we want to start from 0

	mov cx, ax
	mov bx, 0

	mov si, 64000			; Get our filename from the list
.loop1:
	cmp bx, cx
	je .got_our_filename
	lodsb
	cmp al, ','
	je .comma_found
	jmp .loop1

.comma_found:
	inc bx
	jmp .loop1


.got_our_filename:			; Now copy the filename string
	mov di, .filename
.loop2:
	lodsb
	cmp al, ','
	je .finished_copying
	cmp al, 0
	je .finished_copying
	stosb
	jmp .loop2

.finished_copying:
	mov byte [di], 0		; Zero terminate the filename string

	popa

	mov ax, .filename

	clc
	ret


.esc_pressed:				; Set carry flag if Escape was pressed
	popa
	stc
	ret

	.help_msg2	db '', 0

	.filename	times 13 db 0


; ------------------------------------------------------------------
; os_list_dialog -- Show a dialog with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated),
;     BX = first help string, CX = second help string
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog:
	pusha

	push ax				; Store string list for now

	push cx				; And help strings
	push bx

	call os_hide_cursor


	mov cl, 0			; Count the number of entries in the list
	mov si, ax
.count_loop:
	mov al, [es:si]
	inc si
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


	mov bl, [57001]		; Color from RAM
	mov dl, 2			; Start X position
	mov dh, 2			; Start Y position
	mov si, 76			; Width
	mov di, 23			; Finish Y position
	call os_draw_block		; Draw option selector window

	mov dl, 3			; Show first line of help text...
	mov dh, 3
	call os_move_cursor

	pop si				; Get back first string
	call os_print_string

	inc dh
	call os_move_cursor

	pop si				; ...and the second
	call os_print_string


	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov dl, 25			; Set up starting position for selector
	mov dh, 6

	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110000b		; Black on white for option list box
	mov dl, 3
	mov dh, 5
	mov si, 74
	mov di, 22
	call os_draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
 	call .draw_list

.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	jmp .more_select	; If not, wait for another key

.go_up:
	cmp dh, 6			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .more_select


.go_down:				; Already at bottom of list?
	cmp dh, 20
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 6
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select


.hit_top:
	mov byte cl, [.skip_num]	; Any lines to scroll up?
	cmp cl, 0
	je .another_key			; If not, wait for another key

	dec byte [.skip_num]		; If so, decrement lines to skip
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	mov cx, 0
	mov byte cl, dh

	sub cl, 6
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	inc byte [.skip_num]		; If so, increment lines to skip
	jmp .more_select



.option_selected:
	call os_show_cursor

	sub dh, 6

	mov ax, 0
	mov al, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	clc				; Clear carry as Esc wasn't pressed
	ret



.esc_pressed:
	call os_show_cursor
	popa
	stc				; Set carry for Esc
	ret



.draw_list:
	pusha

	mov dl, 5			; Get into position for option list text
	mov dh, 6
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	mov al, [es:si]
	inc si
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	mov al, [es:si]		; Get next character in file name, increment pointer
	inc si
	
	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 5			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc bx				; Update the number-of-options counter
	cmp bx, 15			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 4
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 72
	mov bl, 00001111b		; White text on black background
	mov al, ' '
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 4
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 72
	mov bl, 11110000b		; Black text on white background
	mov al, ' '
	int 10h

	popa
	ret


	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0


; ------------------------------------------------------------------
; os_draw_background -- Clear screen with white top and bottom bars
; containing text, and a coloured middle section.
; IN: AX/BX = top/bottom string locations, CX = colour

os_draw_background:
	pusha
	
	push ax				; Store params to pop out later
	push bx
	push cx

	mov dl, 0
	mov dh, 0
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 80
	mov bl, 01110000b
	mov al, ' '
	int 10h

	mov dh, 1
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Draw colour section
	mov cx, 1840
	pop bx				; Get colour param (originally in CX)
	mov bh, 0
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Draw white bar at bottom
	mov bh, 0
	mov cx, 80
	mov bl, 01110000b
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 1
	call os_move_cursor
	pop si				; Get bottom string param
	call os_print_string

	mov dh, 0
	mov dl, 1
	call os_move_cursor
	pop si				; Get top string param
	call os_print_string

	mov bx, tmp_string
	call os_get_date_string
	
	mov dl, 69			; Display date
	mov dh, 0
	call os_move_cursor
	mov si, bx
	call os_print_string
	
	mov bx, tmp_string
	call os_get_time_string

	mov dl, 63			; Display time
	mov dh, 0
	call os_move_cursor
	mov si, bx
	call os_print_string
	
	
	
	mov dh, 1			; Ready for app text
	mov dl, 0
	call os_move_cursor

	popa
	ret

	tmp_string			times 15 db 0


; ------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line
; IN/OUT: Nothing (registers preserved)

os_print_newline:
	pusha

	mov ah, 0Eh			; BIOS output char code

	mov al, 13
	int 10h
	mov al, 10
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_dump_registers -- Displays register contents in hex on the screen
; IN/OUT: AX/BX/CX/DX = registers to show

os_dump_registers:
	pushad

	push edi
	push esi
	push edx
	push ecx
	push ebx

	mov si, .ax_string
	call os_print_string
	call os_print_8hex

	pop eax
	mov si, .bx_string
	call os_print_string
	call os_print_8hex

	pop eax
	mov si, .cx_string
	call os_print_string
	call os_print_8hex

	pop eax
	mov si, .dx_string
	call os_print_string
	call os_print_8hex

	pop eax
	mov si, .si_string
	call os_print_string
	call os_print_8hex

	pop eax
	mov si, .di_string
	call os_print_string
	call os_print_8hex

	call os_print_newline

	popad
	ret


	.ax_string		db 'EAX:', 0
	.bx_string		db ' EBX:', 0
	.cx_string		db ' ECX:', 0
	.dx_string		db ' EDX:', 0
	.si_string		db ' ESI:', 0
	.di_string		db ' EDI:', 0


; ------------------------------------------------------------------
; os_input_dialog -- Get text string from user via a dialog box
; IN: AX = string location, BX = message to show; OUT: AX = string location

os_input_dialog:
	pusha

	push ax				; Save string location
	push bx				; Save message to show


	mov dh, 10			; First, draw red background box
	mov dl, 12

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 55
	mov bl, [57001]		; Color from RAM
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	mov dl, 14
	mov dh, 14
	call os_move_cursor
	mov ah, 09h
	mov al, ' '
	mov bh, 0
	mov bl, 240
	mov cx, 51
	int 10h
	
	mov dl, 14
	mov dh, 11
	call os_move_cursor
	

	pop bx				; Get message back and display it
	mov si, bx
	call os_print_string

	mov dl, 14
	mov dh, 14
	call os_move_cursor


	pop ax				; Get input string back
	call os_input_string

	popa
	ret

; ------------------------------------------------------------------
; os_password_dialog -- Get a password from user via a dialog box
; IN: AX = string location, BX = message to show; OUT: AX = string location

os_password_dialog:
	pusha

	push ax				; Save string location
	push bx				; Save message to show


	mov dh, 10			; First, draw red background box
	mov dl, 12

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 55
	mov bl, [57001]		; Color from RAM
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	mov dl, 14
	mov dh, 14
	call os_move_cursor
	mov ah, 09h
	mov al, ' '
	mov bh, 0
	mov bl, 240
	mov cx, 51
	int 10h
	
	mov dl, 14
	mov dh, 11
	call os_move_cursor
	

	pop bx				; Get message back and display it
	mov si, bx
	call os_print_string

	mov dl, 14
	mov dh, 14
	call os_move_cursor


	pop ax				; Get input string back
	mov bl, 240
	call os_input_password

	popa
	ret


; ------------------------------------------------------------------
; os_dialog_box -- Print dialog box in middle of screen, with button(s)
; IN: AX, BX, CX = string locations (set registers to 0 for no display)
; IN: DX = 0 for single 'OK' dialog, 1 for two-button 'OK' and 'Cancel'
; OUT: If two-button mode, AX = 0 for OK and 1 for cancel
; NOTE: Each string is limited to 40 characters

os_dialog_box:
	pusha

	mov [.tmp], dx

	call os_hide_cursor

	mov dh, 9			; First, draw red background box
	mov dl, 19

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 42
	mov bl, [57001]		; Color from RAM
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	cmp ax, 0			; Skip string params if zero
	je .no_first_string
	mov dl, 20
	mov dh, 10
	call os_move_cursor

	mov si, ax			; First string
	call os_print_string

.no_first_string:
	cmp bx, 0
	je .no_second_string
	mov dl, 20
	mov dh, 11
	call os_move_cursor

	mov si, bx			; Second string
	call os_print_string

.no_second_string:
	cmp cx, 0
	je .no_third_string
	mov dl, 20
	mov dh, 12
	call os_move_cursor

	mov si, cx			; Third string
	call os_print_string

.no_third_string:
	mov dx, [.tmp]
	cmp dx, 0
	je .one_button
	cmp dx, 1
	je .two_button


.one_button:
	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 35
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 38			; OK button, centred at bottom of box
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	jmp .one_button_wait


.two_button:
	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 0			; Default button = 0
	jmp .two_button_wait



.one_button_wait:
	call os_wait_for_key
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .one_button_wait

	call os_show_cursor

	popa
	ret


.two_button_wait:
	call os_wait_for_key

	cmp ah, 75			; Left cursor key pressed?
	jne .noleft

	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov bl, 01001111b		; White on red for cancel button
	mov dh, 14
	mov dl, 42
	mov si, 9
	mov di, 15
	call os_draw_block

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 0			; And update result we'll return
	jmp .two_button_wait


.noleft:
	cmp ah, 77			; Right cursor key pressed?
	jne .noright


	mov bl, 01001111b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov bl, 11110000b		; White on red for cancel button
	mov dh, 14
	mov dl, 43
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 1			; And update result we'll return
	jmp .two_button_wait


.noright:
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .two_button_wait

	call os_show_cursor

	mov [.tmp], cx			; Keep result after restoring all regs
	popa
	mov ax, [.tmp]

	ret


	.ok_button_string	db 'OK', 0
	.cancel_button_string	db 'Cancel', 0

	.tmp dw 0

; ------------------------------------------------------------------
; os_print_space -- Print a space to the screen
; IN/OUT: Nothing

os_print_space:
	pusha

	mov ah, 0Eh			; BIOS teletype function
	mov al, 20h			; Space is character 20h
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_print_digit -- Displays contents of AX as a single digit
; Works up to base 37, ie digits 0-Z
; IN: AX = "digit" to format and print

os_print_digit:
	pusha

	cmp ax, 9			; There is a break in ASCII table between 9 and A
	jle .digit_format

	add ax, 'A'-'9'-1		; Correct for the skipped punctuation

.digit_format:
	add ax, '0'			; 0 will display as '0', etc.	

	mov ah, 0Eh			; May modify other registers
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_print_1hex -- Displays low nibble of AL in hex format
; IN: AL = number to format and print

os_print_1hex:
	pusha

	and ax, 0Fh			; Mask off data to display
	call os_print_digit

	popa
	ret


; ------------------------------------------------------------------
; os_print_2hex -- Displays AL in hex format
; IN: AL = number to format and print

os_print_2hex:
	pusha

	push ax				; Output high nibble
	shr ax, 4
	call os_print_1hex

	pop ax				; Output low nibble
	call os_print_1hex

	popa
	ret


; ------------------------------------------------------------------
; os_print_4hex -- Displays AX in hex format
; IN: AX = number to format and print

os_print_4hex:
	pusha

	push ax				; Output high byte
	mov al, ah
	call os_print_2hex

	pop ax				; Output low byte
	call os_print_2hex

	popa
	ret


; ------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
; IN/OUT: AX = location of string, other regs preserved
; (Location will contain up to 50 characters, zero-terminated)

os_input_string:
	pusha

	call os_show_cursor
	
	mov di, ax			; DI is where we'll store input (buffer)
	mov cx, 0			; Character received counter for backspace


.more:					; Now onto string getting
	call os_wait_for_key

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace			; If not, skip following checks

	cmp al, ' '			; In ASCII range (32 - 127)?
	jl .more			; Ignore most non-printing characters

	jmp .nobackspace


.backspace:
	cmp cx, 0			; Backspace at start of string?
	je .more			; Ignore it if so

	call os_get_cursor_pos		; Backspace at start of screen line?
	cmp dl, 0
	je .backspace_linestart

	pusha
	mov ah, 0Eh			; If not, write space and move cursor back
	mov al, 8
	int 10h				; Backspace twice, to clear space
	mov al, 32
	int 10h
	mov al, 8
	int 10h
	popa

	dec di				; Character position will be overwritten by new
						; character or terminator at end

	dec cx				; Step back counter

	jmp .more


.backspace_linestart:
	dec dh				; Jump back to end of previous line
	mov dl, 79
	call os_move_cursor

	mov al, ' '			; Print space there
	mov ah, 0Eh
	int 10h

	mov dl, 79			; And jump back before the space
	call os_move_cursor

	dec di				; Step back position in string
	dec cx				; Step back counter

	jmp .more


.nobackspace:
	cmp cx, 49			; Make sure we don't exhaust buffer
	jge near .more

	pusha
	mov ah, 0Eh			; Output entered, printable character
	int 10h
	popa

	stosb				; Store character in designated buffer
	inc cx				; Characters processed += 1
	
	jmp near .more			; Still room for more

.done:
	mov ax, 0
	stosb

	popa
	ret

; Input password(displays it as *s)
; IN: AX = location of string, other regs preserved, BL = color
; OUT: nothing
; (Location will contain up to 255 characters, zero-terminated)

os_input_password:
	pusha

	call os_get_cursor_pos	; Store the cursor position
	mov [.cursor], dx
	
	mov di, ax			; DI is where we'll store input (buffer)
	mov cx, 0			; Character received counter for backspace

.more:					; Now onto string getting
	call os_wait_for_key

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace			; If not, skip following checks

	cmp al, ' '			; In ASCII range (32 - 126)?
	jge .nobackspace	; Ignore most non-printing characters
	
	cmp al, 0
	jl .nobackspace
	
	jmp .more


.backspace:
	cmp cx, 0			; Backspace at start of string?
	je .more			; Ignore it if so

	dec di				; Character position will be overwritten by new
						; character or terminator at end

	dec cx				; Step back counter

	pusha
	mov dx, [.cursor]
	call os_move_cursor
	mov ah, 09h			; Clear the line
	mov bh, 0
	mov al, 32
	mov cx, 32
	int 10h
	popa

	pusha
	mov dx, [.cursor]
	call os_move_cursor
	mov ah, 09h			; Print *s(amount in CX)
	mov bh, 0
	mov al, 42
	int 10h
	add dl, cl
	call os_move_cursor
	popa

	jmp .more


.nobackspace:
	stosb				; Store character in designated buffer
	inc cx				; Characters processed += 1
	cmp cx, 254			; Make sure we don't exhaust buffer
	jae near .done

	pusha
	mov dx, [.cursor]
	call os_move_cursor
	mov ah, 09h			; Clear the line
	mov bh, 0
	mov al, 32
	mov cx, 32
	int 10h
	popa

	pusha
	mov dx, [.cursor]
	call os_move_cursor
	mov ah, 09h			; Print *s(amount in CX)
	mov bh, 0
	mov al, 42
	int 10h
	add dl, cl
	call os_move_cursor
	popa

	jmp near .more		; Still room for more

.done:
	mov ax, 0
	stosb

	popa
	clc
	ret

	.cursor			dw 0
	
; Opens up os_list_dialog with color.
; IN: nothing
; OUT: color number(0-15)

os_color_selector:
	pusha
	mov ax, .colorlist			; Call os_list_dialog with colors
	mov bx, .colormsg0
	mov cx, .colormsg1
	call os_list_dialog
	
	dec ax						; Output from os_list_dialog starts with 1, so decrement it
	mov [.tmp_word], ax
	popa
	mov al, [.tmp_word]
	ret
	
	.colorlist	db 'Black,Blue,Green,Cyan,Red,Magenta,Brown,Light Gray,Dark Gray,Light Blue,Light Green,Light Cyan,Light Red,Pink,Yellow,White', 0
	.colormsg0	db 'Choose a color...', 0
	.colormsg1	db 0
	.tmp_word	dw 0
	
; Displays EAX in hex format
; IN: EAX = unsigned integer
; OUT: nothing
os_print_8hex:
	pusha
	rol eax, 16
	call os_print_4hex
	rol eax, 16
	call os_print_4hex
	popa
	ret
	
; Displays a dialog similar to os_dialog_box, but without the buttons.
; IN: SI/AX/BX/CX/DX = string locations(or 0 for no display)
; OUT: nothing
os_temp_box:
	pusha

	mov [.string1], si
	mov [.string2], ax
	mov [.string3], bx
	mov [.string4], cx
	mov [.string5], dx
	
	call os_hide_cursor

	mov dh, 9			; First, draw red background box
	mov dl, 19

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 42
	mov bl, [57001]		; Color from RAM
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	mov si, [.string1]
	cmp si, 0			; Skip string params if zero
	je .no_first_string
	mov dl, 20
	mov dh, 10
	call os_move_cursor

	call os_print_string

.no_first_string:
	mov si, [.string2]
	cmp si, 0
	je .no_second_string
	mov dl, 20
	mov dh, 11
	call os_move_cursor

	call os_print_string

.no_second_string:
	mov si, [.string3]
	cmp si, 0
	je .no_third_string
	mov dl, 20
	mov dh, 12
	call os_move_cursor

	call os_print_string

.no_third_string:
	mov si, [.string4]
	cmp si, 0
	je .no_fourth_string
	mov dl, 20
	mov dh, 13
	call os_move_cursor
	
	call os_print_string

.no_fourth_string:
	mov si, [.string5]
	cmp si, 0
	je .no_fifth_string
	mov dl, 20
	mov dh, 14
	call os_move_cursor

	call os_print_string

.no_fifth_string:
	popa
	ret

	.string1	dw 0
	.string2	dw 0
	.string3	dw 0
	.string4	dw 0
	.string5	dw 0

; Prints a message on the footer.
; IN: SI = Message location(if 0, then it restores the previous message)
; OUT: nothing
os_print_footer:
	pusha
	mov al, [0082h]
	cmp al, 1
	je near .exit
	
	call os_get_cursor_pos
	push dx
	
	mov di, 1
	cmp si, 0
	je near .restore
	mov dl, 0
	mov dh, 24
	
.loop:
	call os_move_cursor
	mov ah, 08h
	mov bh, 0
	int 10h
	stosb
	inc dl
	cmp di, 81
	jnge near .loop
	
	mov byte [80], 0
	
	mov dl, 0
	mov dh, 24
	call os_move_cursor
	
	mov ah, 09h
	mov al, ' '
	mov bl, 70h
	mov bh, 0
	mov cx, 80
	int 10h
	
	mov dl, 0
	mov dh, 24
	call os_move_cursor
	
	call os_print_string
	
	pop dx
	call os_move_cursor

.exit:	
	popa
	ret
	
.restore:
	mov dl, 0
	mov dh, 24
	call os_move_cursor
	mov si, 1
	call os_print_string
	
	pop dx
	call os_move_cursor
	
	popa
	ret
	
; Resets the font to the selected default.
; IN = nothing
; OUT = nothing
os_reset_font:
	pusha
	cmp byte [57073], 1
	je near .bios
	
	pusha
	push es
	mov ax, 1100h
	mov bx, 1000h
	mov cx, 0100h
	mov dx, 0000h
	mov es, [driversgmt]
	mov bp, 8000h
	int 10h
	pop es
	popa	
	popa
	ret
	
.bios:
	popa
	ret
	
; Draws the MichalOS logo.
; IN: nothing
; OUT: a very beautiful logo :-)
os_draw_logo:
	pusha
	mov dh, 2
	mov dl, 0
	call os_move_cursor
	mov ah, 09h
	mov al, ' '
	mov bh, 0
	mov bl, 00000100b
	mov cx, 560
	int 10h
	mov si, logo0
	call os_print_string
	popa
	ret

; ------------------------------------------------------------------
; os_option_menu -- Show a menu with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated), BX = menu width
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc, left or right pressed

os_option_menu:
	pusha

	cmp byte [57071], 0
	je .skip
	
	mov dl, 0
	mov dh, 1

	call os_move_cursor
	
	mov ah, 08h
	mov bh, 0
	int 10h				; Get the character's attribute (X = 0, Y = 1)
	
	and ah, 0F0h		; Keep only the background, set foreground to 0
	mov bl, ah
	mov ah, 09h
	mov al, 0B1h
	mov bh, 0
	mov cx, 1840
	int 10h
	
	popa
	pusha

.skip:
	mov [.width], bx

	push ax				; Store string list for now

	call os_hide_cursor

	mov cl, 0			; Count the number of entries in the list
	mov si, ax
.count_loop:
	lodsb
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov dl, 25			; Set up starting position for selector
	mov dh, 2

	call os_move_cursor

.more_select:
	pusha
	mov bl, [57072]		; Black on white for option list box
	mov dl, 1
	mov dh, 1
	mov si, [.width]
	movzx di, [.num_of_entries]
	add di, 3
	call os_draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list

.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	cmp ah, 75			; Left pressed?
	je .left_pressed
	cmp ah, 77			; Right pressed?
	je .right_pressed
	jmp .another_key		; If not, wait for another key


.go_up:
	cmp dh, 2			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .more_select


.go_down:				; Already at bottom of list?
	mov bl, [.num_of_entries]
	inc bl
	cmp dh, bl
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 6
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select


.hit_top:
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	jmp .more_select



.option_selected:
	call os_show_cursor

	sub dh, 2

	mov ax, 0
	mov al, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	clc				; Clear carry as Esc wasn't pressed
	ret



.esc_pressed:
	call os_show_cursor
	popa
	mov ax, 0
	stc
	ret

.left_pressed:
	call os_show_cursor
	popa
	mov ax, 1
	stc
	ret

.right_pressed:
	call os_show_cursor
	popa
	mov ax, 2
	stc
	ret

.draw_list:
	pusha

	mov dl, 3			; Get into position for option list text
	mov dh, 2
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	lodsb
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	lodsb				; Get next character in file name, increment pointer

	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 3			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc bx				; Update the number-of-options counter
	movzx di, [.num_of_entries]	; Low 8 bits of DI = [.items], high 8 bits = 0
	cmp bx, di			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 2
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, [.width]
	sub cx, 2
	mov bl, 00001111b		; White text on black background
	mov al, ' '
	int 10h

	popa
	ret

.draw_white_bar:
	pusha

	mov dl, 2
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, [.width]
	sub cx, 2
	mov bl, [57072]	; Black text on white background
	mov al, ' '
	int 10h

	popa
	ret

	.tmp					dw 0
	.num_of_entries			db 0
	.skip_num				db 0
	.list_string			dw 0
	.width					dw 0
	
; ==================================================================
