
	BITS 16
	
	org 4000h
	
	disk_buffer	equ	57344
	
start:
	cli						; Clear interrupts
	mov ax, 0
	mov ss, ax				; Set stack segment and pointer
	mov sp, 0FFFEh
	sti						; Restore interrupts

	cld						; The default direction for string operations
							; will be 'up' - incrementing address in RAM							
	mov ax, 0000h			; Set all segments to match where kernel is loaded
	mov ds, ax			
	mov es, ax
	
	cmp byte [.already_booted], 0
	jne .catastrophic_failure
	
	mov byte [.already_booted], 1
	
	mov [bootdev], dl
	
	call os_clear_screen
	
	mov si, .load_msg1
	call os_print_string
	
	mov si, .load_msg2
	call os_print_string

	mov cx, 0
	int 12h
	
	cmp ax, 128
	jl .not_enough_memory
	
	push es
	mov ax, .system_name
	mov es, [.load_sgmt]
	mov cx, 8000h
	call os_load_file
	jc .catastrophic_failure
	pop es
	
	mov si, .load_msg4
	call os_print_string
	mov ax, .vesa_name
	mov cx, 7000h
	call os_load_file
	jc .catastrophic_failure

	mov si, .load_msg5
	call os_print_string
	mov ax, .font_name
	mov cx, 8000h
	call os_load_file
	jc .catastrophic_failure

	mov si, .load_msg6
	call os_print_string
	mov ax, .fileman_name
	mov cx, 9000h
	call os_load_file
	jc .catastrophic_failure

	; Enable Unreal Mode
	
	mov si, .unreal_msg1
	call os_print_string
	
	cli				; no interrupts
	push ds			; save real mode
 
	mov si, .unreal_msg2
	call os_print_string
	
	lgdt [.gdtinfo]	; load gdt register

	mov eax, cr0	; switch to pmode by
	or al,1			; set pmode bit

	mov si, .unreal_msg3
	call os_print_string

	mov cr0, eax

	jmp .good		; tell 386/486 to not crash

.good:
	mov bx, 0x08	; select descriptor 1
	mov ds, bx		; 8h = 1000b

	and al,	0xFE		; back to realmode

	mov cr0, eax	; by toggling bit again

	pop ds			; get back old segment
	sti

	mov si, .unreal_msg4
	call os_print_string

	mov ax, 0
	mov ah, 88h				; Also get the high memory(>1MB)...
	int 15h
	cmp ax, 0				; If the computer doesn't have any high memory, skip the A20
	je .A20_on
		
	mov si, .a20_try1
	call os_print_string	
	call A20_check
	jnc .A20_on
	
	mov si, .a20_try2
	call os_print_string	
	call enable_A20_1
	call A20_check
	jnc .A20_on
	
	mov si, .a20_try3
	call os_print_string	
	call enable_A20_2
	call A20_check
	jnc .A20_on
	
	mov si, .a20_try4
	call os_print_string	
	call enable_A20_3
	call A20_check
	jnc .A20_on
	
	mov si, .a20_try5
	call os_print_string	
	call enable_A20_4
	call A20_check
	jnc .A20_on
	
	mov si, .err_msg
	call os_print_string

.error_loop:
	hlt
	jmp .error_loop
	
.A20_on:
	mov si, .boot_msg1
	call os_print_string

	mov dl, [bootdev]
	
	jmp long 1000h:8000h
	
.catastrophic_failure:
	mov ax, 3
	int 10h

	call os_clear_screen
	mov si, .cf_msg
	call os_print_string
	jmp $
 
.not_enough_memory:
	mov si, .mem_msg
	call os_print_string
	jmp $
 
.gdtinfo:
	dw .gdt_end - .gdt - 1		;last byte in table
	dd .gdt						;start of table

	.gdt					dd 0,0		; entry 0 is always unused
	.flatdesc				db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
	.gdt_end:
	
	.system_name			db 'MICHALOS.SYS', 0
	.load_sgmt				dw 1000h
	
	.load_msg1				db 'MichalOS/2 is now booting up...', 13, 10, 10, 0
	.load_msg2				db 'Loading MichalOS/2...', 13, 10, 0
	.load_msg4				db 'Loading VESA color palette...', 13, 10, 0
	.load_msg5				db 'Loading MichalOS System Font...', 13, 10, 0
	.load_msg6				db 'Loading MichalOS File Manager...', 13, 10, 0
	
	.mem_msg				db 'Not enough memory to start MichalOS/2!', 13, 10
	.mem_msg2				db '128K of RAM is required!', 0
	
	.a20_try1				db 'Checking if the A20 line is already enabled...', 0
	.a20_try2				db 'Attempting to enable the A20 line via the keyboard controller...', 0
	.a20_try3				db 'Attempting to enable the A20 line via the fast A20 gate...', 0
	.a20_try4				db 'Attempting to enable the A20 line via the BIOS...', 0
	.a20_try5				db 'Attempting to enable the A20 line via the 0xEE port...', 0
	
	.unreal_msg1			db 'Preparing for switching to protected mode...', 13, 10, 0
	.unreal_msg2			db 'Loading the GDT register...', 13, 10, 0
	.unreal_msg3			db 'Switching to protected mode...', 13, 10, 0
	.unreal_msg4			db 'We', 39, 're in unreal mode!', 13, 10, 0
	
	.boot_msg1				db 'Preparing for jumping to MICHALOS.SYS...', 13, 10, 0
	
	.fail_msg1				db ' fail.', 13, 10, 0
	.fail_msg2				db 'Expected ', 0
	.fail_msg3				db ', but received ', 0
	
	.succ_msg1				db ' success!', 13, 10, 0
	.succ_msg2				db 'Expected ', 0
	.succ_msg3				db ', received ', 0
	
	.err_msg				db 'Error enabling the A20 line!', 0
	
	.fileman_name			db 'FILEMAN.APP', 0
	.font_name				db 'FONT.SYS', 0
	.vesa_name				db 'VESA.SYS', 0

	.cf_msg					db 'Something went terribly wrong, and MichalOS/2 was shut down.', 0
	
	.already_booted			db 0
	
enable_A20_1:
	cli
 
	call .a20wait
	mov al, 0xAD
	out 0x64, al
 
	call .a20wait
	mov al, 0xD0
	out 0x64, al
 
	call .a20wait2
	in al, 0x60
	push eax
 
	call .a20wait
	mov al, 0xD1
	out 0x64, al
 
	call .a20wait
	pop eax
	or al, 2
	out 0x60, al

	call .a20wait
	mov al, 0xAE
	out 0x64, al
 
	call .a20wait
	sti
	
	ret
 
.a20wait:
	in al, 0x64
	test al, 2
	jnz .a20wait
	ret
	
.a20wait2:
	in al, 0x64
	test al, 1
	jz .a20wait2
	ret
	
enable_A20_2:
	in al, 0x92
	or al, 2
	out 0x92, al
	ret
	
enable_A20_3:
	mov ax, 2403h                ;--- A20-Gate Support ---
	int 15h
	jb .exit                  ;INT 15h is not supported
	cmp ah, 0
	jnz .exit                  ;INT 15h is not supported
	
	mov ax, 2402h                ;--- A20-Gate Status ---
	int 15h
	jb .exit              ;couldn't get status
	cmp ah, 0
	jnz .exit              ;couldn't get status
	
	cmp al, 1
	jz .exit           ;A20 is already activated
	
	mov ax, 2401h                ;--- A20-Gate Activate ---
	int 15h
	jb .exit              ;couldn't activate the gate
	cmp ah, 0
	jnz .exit              ;couldn't activate the gate

.exit:
	ret
	
enable_A20_4:
	in al, 0xee
	ret
	
A20_check:
	mov esi, 0x000000
	mov edi, 0x100000
	mov byte al, [esi]
	mov byte bl, [edi]
	cmp byte al, bl
	jne .A20_on

	push esi
	mov si, start.fail_msg1
	call os_print_string
	mov si, start.fail_msg2
	call os_print_string
	
	mov al, 0xFF
	call os_print_2hex
	
	mov si, start.fail_msg3
	call os_print_string
	
	pop esi
	mov al, [esi]
	call os_print_2hex
	
	call os_print_newline
	
	stc
	ret
	
.A20_on:
	push esi
	mov si, start.succ_msg1
	call os_print_string
	mov si, start.succ_msg2
	call os_print_string
	
	mov al, 0xFF
	call os_print_2hex
	
	mov si, start.succ_msg3
	call os_print_string
	
	pop esi
	mov al, [esi]
	call os_print_2hex
	
	call os_print_newline

	clc
	ret

; ------------------------------------------------------------------
; os_load_file -- Load file into RAM
; IN: AX = location of filename, CX = location in RAM to load file
; OUT: BX = file size (in bytes), carry set if file not found

os_load_file:
	mov [.old_segment], es
	mov es, [.default_segment]

	call os_string_uppercase

	call int_filename_convert

	mov [.filename_loc], ax		; Store filename location
	mov [.load_position], cx	; And where to load the file!

	mov eax, 0			; Needed for some older BIOSes

	call disk_reset_floppy		; In case floppy has been changed
	jnc .floppy_ok			; Did the floppy reset OK?

	jmp $

.floppy_ok:				; Ready to read first block of data
	mov ax, 19			; Root dir starts at logical sector 19
	call disk_convert_l2hts

	mov si, disk_buffer		; ES:BX should point to our buffer
	mov bx, si

	mov ah, 2			; Params for int 13h: read floppy sectors
	mov al, 14			; 14 root directory sectors

	pusha				; Prepare to enter loop


.read_root_dir:
	popa
	pusha

	stc				; A few BIOSes clear, but don't set properly
	int 13h				; Read sectors
	jnc .search_root_dir		; No errors = continue

	call disk_reset_floppy		; Problem = reset controller and try again
	jnc .read_root_dir

	popa
	jmp .root_problem		; Double error = exit

.search_root_dir:
	popa

	mov cx, word 224		; Search all entries in root dir
	mov bx, -32			; Begin searching at offset 0 in root dir

.next_root_entry:
	add bx, 32			; Bump searched entries by 1 (offset + 32 bytes)
	mov di, disk_buffer		; Point root dir at next entry
	add di, bx

	mov al, [di]			; First character of name

	cmp al, 0			; Last file name already checked?
	je .root_problem

	cmp al, 229			; Was this file deleted?
	je .next_root_entry		; If yes, skip it

	mov al, [di+11]			; Get the attribute byte

	cmp al, 0Fh			; Is this a special Windows entry?
	je .next_root_entry

	test al, 18h			; Is this a directory entry or volume label?
	jnz .next_root_entry

	mov byte [di+11], 0		; Add a terminator to directory name entry

	mov ax, di			; Convert root buffer name to upper case
	call os_string_uppercase

	mov si, [.filename_loc]		; DS:SI = location of filename to load

	call os_string_compare		; Current entry same as requested?
	jc .found_file_to_load

	loop .next_root_entry

.root_problem:
	mov bx, 0			; If file not found or major disk error,
	stc				; return with size = 0 and carry set
	ret


.found_file_to_load:			; Now fetch cluster and load FAT into RAM
	mov ax, [di+28]			; Store file size to return to calling routine
	mov word [.file_size], ax

	cmp ax, 0			; If the file size is zero, don't bother trying
	je .end				; to read more clusters

	mov ax, [di+26]			; Now fetch cluster and load FAT into RAM
	mov word [.cluster], ax

	mov ax, 1			; Sector 1 = first sector of first FAT
	call disk_convert_l2hts

	mov di, disk_buffer		; ES:BX points to our buffer
	mov bx, di

	mov ah, 2			; int 13h params: read sectors
	mov al, 9			; And read 9 of them

	pusha

.read_fat:
	popa				; In case registers altered by int 13h
	pusha

	stc
	int 13h
	jnc .read_fat_ok

	call disk_reset_floppy
	jnc .read_fat

	popa
	jmp .root_problem


.read_fat_ok:
	popa


.load_file_sector:
	mov ax, word [.cluster]		; Convert sector to logical
	add ax, 31

	call disk_convert_l2hts		; Make appropriate params for int 13h

	mov bx, [.load_position]
	mov es, [.old_segment]

	mov ah, 02			; AH = read sectors, AL = just read 1
	mov al, 01

	stc
	int 13h
	mov es, [.default_segment]
	
	jnc .calculate_next_cluster	; If there's no error...

	call disk_reset_floppy		; Otherwise, reset floppy and retry
	jnc .load_file_sector

	jmp $

.calculate_next_cluster:
	mov ax, [.cluster]
	mov bx, 3
	mul bx
	mov bx, 2
	div bx				; DX = [CLUSTER] mod 2
	mov si, disk_buffer		; AX = word in FAT for the 12 bits
	add si, ax
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0 [CLUSTER] = even, if DX = 1 then odd

	jz .even			; If [CLUSTER] = even, drop last 4 bits of word
					; with next cluster; if odd, drop first 4 bits

.odd:
	shr ax, 4			; Shift out first 4 bits (belong to another entry)
	jmp .calculate_cluster_cont	; Onto next sector!

.even:
	and ax, 0FFFh			; Mask out top (last) 4 bits

.calculate_cluster_cont:
	mov word [.cluster], ax		; Store cluster

	cmp ax, 0FF8h
	jae .end

	add word [.load_position], 512
	jmp .load_file_sector		; Onto next sector!


.end:
	mov bx, [.file_size]		; Get file size to pass back in BX
	clc				; Carry clear = good load
	mov es, [.old_segment]
	ret


	.bootd					db 0 		; Boot device number
	.cluster				dw 0 		; Cluster of the file we want to load
	.pointer				dw 0 		; Pointer into disk_buffer, for loading 'file2load'

	.filename_loc			dw 0		; Temporary store of filename location
	.load_position			dw 0		; Where we'll load the file
	.file_size				dw 0		; Size of the file

	.string_buff			times 12 db 0	; For size (integer) printing

	.old_segment			dw 0
	.default_segment		dw 0

; --------------------------------------------------------------------------
; Reset floppy disk

disk_reset_floppy:
	push ax
	push dx
	mov ax, 0
; ******************************************************************
	mov dl, [bootdev]
; ******************************************************************
	stc
	int 13h
	pop dx
	pop ax
	ret

; --------------------------------------------------------------------------
; disk_convert_l2hts -- Calculate head, track and sector for int 13h
; IN: logical sector in AX; OUT: correct registers for int 13h

disk_convert_l2hts:
	push bx
	push ax

	mov bx, ax			; Save logical sector

	mov dx, 0			; First the sector
	div word [SecsPerTrack]		; Sectors per track
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	mov dx, 0			; Now calculate the head
	div word [SecsPerTrack]		; Sectors per track
	mov dx, 0
	div word [Sides]		; Floppy sides
	mov dh, dl			; Head/side
	mov ch, al			; Track
	
	pop ax
	pop bx

; ******************************************************************
	mov dl, [bootdev]		; Set correct device
; ******************************************************************

	ret


	Sides dw 2
	SecsPerTrack dw 18
; ******************************************************************
	bootdev db 0			; Boot device number
; ******************************************************************

; ------------------------------------------------------------------
; int_filename_convert -- Change 'TEST.BIN' into 'TEST    BIN' as per FAT12
; IN: AX = filename string
; OUT: AX = location of converted string (carry set if invalid)

int_filename_convert:
	pusha

	mov si, ax

	call os_string_length
	cmp ax, 14			; Filename too long?
	jg .failure			; Fail if so

	cmp ax, 0
	je .failure			; Similarly, fail if zero-char string

	mov dx, ax			; Store string length for now

	mov di, .dest_string

	mov cx, 0
.copy_loop:
	lodsb
	cmp al, '.'
	je .extension_found
	stosb
	inc cx
	cmp cx, dx
	jg .failure			; No extension found = wrong
	jmp .copy_loop

.extension_found:
	cmp cx, 0
	je .failure			; Fail if extension dot is first char

	cmp cx, 8
	je .do_extension		; Skip spaces if first bit is 8 chars

	; Now it's time to pad out the rest of the first part of the filename
	; with spaces, if necessary

.add_spaces:
	mov byte [di], ' '
	inc di
	inc cx
	cmp cx, 8
	jl .add_spaces

	; Finally, copy over the extension
.do_extension:
	lodsb				; 3 characters
	cmp al, 0
	je .failure
	stosb
	lodsb
	cmp al, 0
	je .failure
	stosb
	lodsb
	cmp al, 0
	je .failure
	stosb

	mov byte [di], 0		; Zero-terminate filename

	popa
	mov ax, .dest_string
	clc				; Clear carry for success
	ret


.failure:
	popa
	stc				; Set carry for failure
	ret


	.dest_string	times 13 db 0

; ------------------------------------------------------------------
; os_string_length -- Return length of a string
; IN: AX = string location
; OUT AX = length (other regs preserved)

os_string_length:
	pusha

	mov bx, ax			; Move location of string to BX

	mov cx, 0			; Counter

.more:
	cmp byte [bx], 0		; Zero (end of string) yet?
	je .done
	inc bx				; If not, keep adding
	inc cx
	jmp .more


.done:
	mov word [.tmp_counter], cx	; Store count before restoring other registers
	popa

	mov ax, [.tmp_counter]		; Put count back into AX before returning
	ret


	.tmp_counter	dw 0

; ------------------------------------------------------------------
; os_string_uppercase -- Convert zero-terminated string to upper case
; IN/OUT: AX = string location

os_string_uppercase:
	pusha

	mov si, ax			; Use SI to access string

.more:
	cmp byte [si], 0		; Zero-termination of string?
	je .done			; If so, quit

	cmp byte [si], 'a'		; In the lower case A to Z range?
	jb .noatoz
	cmp byte [si], 'z'
	ja .noatoz

	sub byte [si], 20h		; If so, convert input char to upper case

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret

; ------------------------------------------------------------------
; os_string_compare -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different

os_string_compare:
	pusha

.more:
	mov al, [si]			; Retrieve string contents
	mov bl, [di]

	cmp al, bl			; Compare characters at current location
	jne .not_same

	cmp al, 0			; End of first string? Must also be end of second
	je .terminated

	inc si
	inc di
	jmp .more


.not_same:				; If unequal lengths with same beginning, the byte
	popa				; comparison fails at shortest string terminator
	clc				; Clear carry flag
	ret


.terminated:				; Both strings terminated at the same position
	popa
	stc				; Set carry flag
	ret

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
