; ------------------------------------------------------------------
; MichalOS File Viewer
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	call .draw_background

	call os_file_selector		; Get filename

	jc .exit
	
	mov bx, ax			; Save filename for now

	mov di, ax

	call os_string_length
	add di, ax			; DI now points to last char in filename

	dec di
	dec di
	dec di				; ...and now to first char of extension!

	pusha
	
	mov si, pcx_extension
	mov cx, 3
	rep cmpsb			; Does the extension contain 'PCX'?
	je .valid_pcx_extension		; Skip ahead if so

	popa
	
	mov si, bmp_extension
	mov cx, 3
	rep cmpsb
	je .valid_bmp_extension
	
	
					; Otherwise show error dialog
	mov dx, 0			; One button for dialog box
	mov ax, err_string
	mov bx, err_string2
	mov cx, 0
	call os_dialog_box

	jmp start			; And retry

.valid_pcx_extension:
	call os_get_memory
	cmp ax, 192				; Do we have enough RAM?
	jl .not_enough_ram
	popa
	
	mov byte [0082h], 1
	
	push ds
	push es
	mov ax, 2000h
	mov es, ax
	mov ax, bx
	mov cx, 0			; Load PCX at 2000:0000h
	call os_load_file

	mov ah, 0			; Switch to graphics mode
	mov al, 13h
	int 10h

	mov ax, 0A000h		; ES = video memory
	mov es, ax

	mov ax, 2000h		; DS = source file
	mov ds, ax
	
	mov si, 80h			; Move source to start of image data (First 80h bytes is header)
	mov di, 0			; Start our loop at top of video RAM

.decode:
	mov cx, 1
	lodsb
	cmp al, 192			; Single pixel or string?
	jb .single
	and al, 63			; String, so 'mod 64' it
	mov cl, al			; Result in CL for following 'rep'
	lodsb				; Get byte to put on screen
.single:
	rep stosb			; And show it (or all of them)
	cmp di, 64001
	jb .decode


	mov dx, 3c8h		; Palette index register
	mov al, 0			; Start at colour 0
	out dx, al			; Tell VGA controller that...
	inc dx				; ...3c9h = palette data register

	mov cx, 768			; 256 colours, 3 bytes each
.setpal:
	lodsb				; Grab the next byte.
	shr al, 2			; Palettes divided by 4, so undo
	out dx, al			; Send to VGA controller
	loop .setpal

	pop es
	pop ds

	call os_wait_for_key

	mov byte [0082h], 0
	
	mov ax, 3			; Back to text mode
	mov bx, 0
	int 10h
	mov ax, 1003h		; No blinking text!
	int 10h

	call os_reset_font
	
	call os_clear_screen
	jmp start


.valid_bmp_extension:
	pusha
	call os_get_memory
	cmp bx, 1024
	jl .not_enough_ram
	popa
	
	mov ax, bx					; Get the filename back
	mov ecx, 100000h
	call os_32_load_file
	
	mov byte [0082h], 1

	call os_clear_screen
	
	mov si, .msg0
	call os_print_string
	
	call os_wait_for_key
	cmp al, 13
	jne .no_flag
	
	mov byte [.32bitflag], 1
	jmp .flag
	
.no_flag:
	mov byte [.32bitflag], 0
	mov ax, 274					; 1024x768, 24-bit color
	mov cx, 640 * 3				; 1 pixel = 3 bytes
	mov dx, 480
	call os_vesa_mode
	jmp .end_flag
	
.flag:
	mov ax, 274					; 1024x768, 24-bit color
	mov cx, 640 * 4				; 1 pixel = 3 bytes
	mov dx, 480
	call os_vesa_mode

.end_flag:
	mov esi, 100036h - 65536
	mov ecx, 0					; X position
	mov edx, 479				; Y position

	mov eax, 0					; os_vesa_pixel req's the high 24 bits of EAX to be 0
	mov ebx, 0					; ...and EBX as well
	
.draw_loop:
	mov al, [esi + 0]
	call os_vesa_pixel
	inc ecx
	mov al, [esi + 1]
	call os_vesa_pixel
	inc ecx
	mov al, [esi + 2]
	call os_vesa_pixel
	inc ecx
	
	cmp byte [.32bitflag], 1
	jne .no_extra_inc
	
	inc ecx

.no_extra_inc:	
	call os_check_for_key
	cmp al, 27
	je .exit
	
	add esi, 3

	mov edi, 640 * 3
	cmp byte [.32bitflag], 1
	jne .no_add
	
	add edi, 640
	
.no_add:
	cmp ecx, edi
	jl .draw_loop
	
	mov ecx, 0					; Reset the X position
	
	dec edx
	cmp edx, 0
	jne .draw_loop
	
	call os_wait_for_key
	
	mov byte [0082h], 0
	
	mov ax, 3			; Back to text mode
	mov bx, 0
	int 10h
	mov ax, 1003h		; No blinking text!
	int 10h

	call os_reset_font
	
	call os_clear_screen
	jmp start	
	
	.32bitflag		db 0
	.msg0			db 'Some modern computers do not work propertly with 24-bit video modes.', 13, 10
	.msg1			db 'Press Enter to display the image in 32-bit mode, otherwise press anything else.', 0
	
.draw_background:
	mov ax, title_msg		; Set up screen
	mov bx, footer_msg
	mov cl, [57000]
	call os_draw_background
	ret

.not_enough_ram:
	popa
	mov ax, no_ram
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	jmp start
	
.exit:
	ret
	
	pcx_extension	db 'PCX', 0
	bmp_extension	db 'BMP', 0
	
	no_ram		db 'Not enough RAM!', 0
	
	err_string	db 'Invalid file type!', 0
	err_string2	db '320x200x8 PCX/640x480x24 BMP only!', 0
	
	title_msg	db 'MichalOS Image Viewer', 0
	footer_msg	db '', 0

; ------------------------------------------------------------------

