; ==================================================================
; MISCELLANEOUS ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_pause -- Delay execution for specified 110ms chunks
; IN: AX = 100 millisecond chunks to wait (max delay is 32767,
;     which multiplied by 55ms = 1802 seconds = 30 minutes)

os_pause:
	pusha
	cmp ax, 0
	je .time_up			; If delay = 0 then bail out

	mov cx, 0
	mov [.counter_var], cx		; Zero the counter variable

	mov bx, ax
	mov ax, 0
	mov al, 2			; 2 * 55ms = 110mS
	mul bx				; Multiply by number of 110ms chunks required 
	mov [.orig_req_delay], ax	; Save it

	mov ah, 0
	int 1Ah				; Get tick count	

	mov [.prev_tick_count], dx	; Save it for later comparison

.checkloop:
	mov ah,0
	int 1Ah				; Get tick count again

	cmp [.prev_tick_count], dx	; Compare with previous tick count

	jne .up_date			; If it's changed check it
	jmp .checkloop			; Otherwise wait some more

.time_up:
	popa
	ret

.up_date:
	mov ax, [.counter_var]		; Inc counter_var
	inc ax
	mov [.counter_var], ax

	cmp ax, [.orig_req_delay]	; Is counter_var = required delay?
	jge .time_up			; Yes, so bail out

	mov [.prev_tick_count], dx	; No, so update .prev_tick_count 

	jmp .checkloop			; And go wait some more


	.orig_req_delay		dw	0
	.counter_var		dw	0
	.prev_tick_count	dw	0

; ------------------------------------------------------------------
; os_clear_registers -- Clear all registers
; IN: Nothing; OUT: Clear registers

os_clear_registers:
	mov eax, 0
	mov ebx, 0
	mov ecx, 0
	mov edx, 0
	mov esi, 0
	mov edi, 0
	ret

os_illegal_call:
	mov ax, .msg
	jmp os_crash_application
	
	.msg db 'Attempt to call a non-existent system function', 0
	
os_update_clock:
	pusha
	mov al, [0082h]
	cmp al, 1
	je near .update_time_end
	
	mov ah, 02h			; Get the time
	int 1Ah
	mov ax, [.tmp_time]
	cmp ax, cx
	je near .update_time_end
	mov [.tmp_time], cx
	
	call os_get_cursor_pos
	push dx
	
	mov bx, .tmp_buffer
	call os_get_date_string
	
	mov dl, 69			; Display date
	mov dh, 0
	call os_move_cursor

	mov si, bx
	call os_print_string
	
	mov bx, .tmp_buffer
	call os_get_time_string

	mov dl, 63			; Display time
	mov dh, 0
	call os_move_cursor
	mov si, bx
	call os_print_string
	
	pop dx
	call os_move_cursor
	
.update_time_end:
	popa
	ret
	
	.tmp_buffer		times 12 db 0
	.tmp_time		dw 0
	.tmp_hours		db 0

; ------------------------------------------------------------------
; os_crash_application -- Crash the application (or the system)
; IN: AX = error message string location

os_crash_application:
	cmp byte [app_running], 0
	je os_fatal_error
	
	sti
	
	pusha
	mov ax, 1000h
	mov ds, ax
	mov es, ax
	mov ax, 3
	int 10h
	mov ax, 1003h						; Set text output with certain attributes
	mov bx, 0							; to be bright, and not blinking
	int 10h	
	mov ax, os_fatal_error.title_msg	; Steal stuff from the other routine
	mov bx, os_fatal_error.footer_msg
	mov cl, [57000]
	call os_draw_background
	call os_reset_font
	popa
	
	mov cx, ax
	mov ax, .msg0
	mov bx, .msg1
	mov dx, 0
	call os_dialog_box

	mov sp, [origstack]					; Crash the application
	sub sp, 2
	
	ret	
	
	.msg0	db 'Application has performed an illegal', 0
	.msg1	db 'operation, and it must be shut down.', 0
		
; ------------------------------------------------------------------
; os_fatal_error -- Display error message and halt execution
; IN: AX = error message string location

os_fatal_error:
	mov [.ax], ax			; Store string location for now, ...
	call os_clear_screen
	
.main_screen:
	mov ax, 1000h
	mov ds, ax
	mov es, ax

	mov ax, 3
	int 10h
	mov ax, 1003h				; Set text output with certain attributes
	mov bx, 0					; to be bright, and not blinking
	int 10h	

	call .background
	
	mov dh, 2
	mov dl, 35
	call os_move_cursor
	mov si, .msg0
	call os_print_string
	mov dh, 3
	mov dl, 35
	call os_move_cursor
	mov ah, 0Ah					; Write a 43-character long asterisk-type line
	mov al, '*'
	mov bh, 0
	mov cx, 43
	int 10h
	mov dh, 5
	mov dl, 35
	call os_move_cursor
	mov si, .msg3
	call os_print_string

	mov si, [.ax]
	call os_print_string

	mov dh, 2
	mov dl, 1
	call os_move_cursor
	mov si, bomblogo0
	call os_print_string
	
	call os_hide_cursor
	
.dead_loop:
	hlt
	jmp .dead_loop
	
.background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 01001111b
	call os_draw_background
	call os_reset_font
	ret
	
	.title_msg		db 'MichalOS Fatal Error', 13, 10, 0
	.footer_msg		db 0
	
	.msg0			db 'MichalOS has encountered a critical error.', 0
	.msg3			db 'Error: ', 0

	.ax			dw 0

; Gets the amount of system RAM.
; IN: nothing
; OUT: AX = conventional memory(kB), BX = high memory(kB)
os_get_memory:
	pusha
	mov cx, 0
	int 12h					; Get the conventional memory size...
	mov [.conv_mem], ax		; ...and store it
	
	mov ah, 88h				; Also get the high memory (>1MB)...
	int 15h
	mov [.high_mem], ax		; ...and store it too
	
	popa
	mov ax, [.conv_mem]
	mov bx, [.high_mem]
	ret

	.conv_mem	dw 0
	.high_mem	dw 0

; Calls a system function.
; IN: BP = System function number (8000h, 8003h...)
; OUT: nothing
os_far_call:
	call bp
	retf
	
; ==================================================================

