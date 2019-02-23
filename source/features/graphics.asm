; ==================================================================
; MichalOS Graphics functions
; ==================================================================

; Draws a character in EGA.
; IN: AL/AH: Character/Attribute, CX: Column, DX: Row
; OUT: nothing
os_draw_char:
	pushad
	mov dh, dl
	mov dl, cl
	call calculate_vram		; From "SOFTVID.ASM"
	mov bx, [esi]
	mov ax, bx
	je .exit
	popad
	pushad
	
	mov [.character], ax
	
	push dx
	mov dx, 3C4h			; Select an EGA color plane
	mov ax, 0F02h			; Select all the planes
	out dx, ax	
	pop dx
	
	mov edi, 0A0000h - 65536
	movzx ecx, cx			; AND ECX, 0000FFFFh
	add edi, ecx
	movzx eax, dx
	mov ebx, 1120			; 640 / 8 * 14 lines
	mul ebx
	add edi, eax
	
	; EDI = correct VRAM location

	push edi
	mov cx, 0
	mov al, 0				; Clear the character first
	
.clear_loop:
	mov [edi], al
	add edi, 80
	
	inc cx
	cmp cx, 14
	jne .clear_loop

	pop edi
	
	mov ax, [.character]
	mov ah, 0
	shl ax, 4				; Multiply by 16
	movzx eax, ax
	mov esi, 8000h - 65536 + 2	; Crop the 2 highest pixel rows
	add esi, eax
	
	; ESI = character font, EDI = correct VRAM location
	
	mov cx, 0				; Counter

.char_loop:
	mov bl, 1				; Bit plane
	
.bitplane_loop:
	mov byte [.result], 0
	
	mov ah, bl
	mov dx, 3C4h			; Select an EGA color plane
	mov al, 02h				; The color is already in AH
	out dx, ax		

	mov ax, [.character]
	shr ah, 4				; Background value
	and ah, bl
	cmp ah, bl
	jne .no_bg
		
	mov al, [esi]
	not al					; Invert it, it's background
	add [.result], al
	
.no_bg:
	mov ax, [.character]
	and ah, bl
	cmp ah, bl
	jne .no_char			; Do we have to draw the character on the current plane?

	mov al, [esi]
	add [.result], al	
	
.no_char:
	mov al, [.result]
	mov [edi], al
	
	shl bl, 1
	cmp bl, 16
	jne .bitplane_loop

	inc esi
	add edi, 80
	
	inc cx
	cmp cx, 14
	jne .char_loop

.exit:
	popad
	ret
	
	.result			db 0
	.character		dw 0

; Scans for available VESA video modes.
; IN: ES:DI = pointer to a buffer (6kB max.)
; OUT: information about available modes in 8-byte long chunks:
;	00h (word) = mode number
;	02h (word) = screen width
;	04h (word) = screen height
;	06h (byte) = bits per pixel
;	07h (byte) = unused
;      AX = number of video modes found
os_vesa_scan:
	pusha
	mov [.pointer], di
	mov cx, 100h - 1				; 1st accessible VESA mode (don't mind the "- 1", it will be incremented later)
	
.loop:
	inc cx							; Increment the mode number

	push es
	mov ax, 4F01h					; Get information about a specific video mode
	mov es, [.default]
	mov di, disk_buffer				; Yeah, throw it in the disk buffer, whatever
	int 10h
	pop es
		
	cmp al, 01h						; Does this mode actually exist?
	je .loop						; If not, loop (the mode has already been incremented for us)

	inc word [.counter]				; Increment the counter of modes
	
	mov di, [.pointer]				; Load DI with the current pointer
	mov [es:di + 0], cx				; Store the mode number first, ...
	
	mov ax, [disk_buffer + 12h]		; Screen width
	mov [es:di + 2], ax				; ...the the width, ...
	
	mov ax, [disk_buffer + 14h]		; Screen height
	mov [es:di + 4], ax				; ...the the height...
	
	mov al, [disk_buffer + 19h]		; Bits per pixel
	mov [es:di + 6], al				; ...and finally the color depth
	
	add word [.pointer], 8			; Update the pointer
	
	cmp cx, 3FFh					; Are we done?
	jne .loop						; If not, loop!
	
	popa
	mov cx, [.counter]				; Return the number of found video modes
	ret
	
	.default	dw 1000h			; Default segment (hate 'em!)
	.pointer	dw 0
	.counter	dw 0				; Count the number of video modes
	
; Sets a VESA video mode.
; IN: AX = Mode number; CX = X res; DX = Y res
; OUT: nothing
os_vesa_mode:
	pusha
	mov [vesa_x], cx
	mov [vesa_y], dx
	mov bx, ax
	mov ax, 4F02h
	int 10h
	push es
	mov ax, 4F09h
	mov bl, 0
	mov cx, 256
	mov dx, 0
	mov es, [driversgmt]
	mov di, 7000h
	int 10h
	pop es
	popa
	ret
	
	vesa_x		dw 0
	vesa_y		dw 0
	vesa_window	dw 0
	
; Puts a pixel on the screen in VESA mode.
; IN: AL = Color; CX = X position; DX = Y position
; OUT: nothing
os_vesa_pixel:
	mov [.color], al
	pushad
	mov eax, 0
	mov ebx, 0
	and ecx, 0000FFFFh
	and edx, 0000FFFFh
	mov ax, dx
	mov bx, [vesa_x]
	mov dx, 0
	mul ebx
	add eax, ecx
	mov [.tmp_addr], ax
	rol eax, 16
	
	cmp ax, [vesa_window]
	je .no_change
	mov [.tmp_sgmt], ax
	mov ax, 4F05h
	mov bx, 0
	mov dx, [.tmp_sgmt]
	mov [vesa_window], dx
	int 10h
	
.no_change:
	mov edi, 090000h	;(0A0000 - load segment)	
	mov di, [.tmp_addr]
	mov al, [.color]
	mov [edi], al
	popad
	ret
	
	.color			db 0
	.tmp_addr		dw 0
	.tmp_sgmt		dw 0
	.video_sgmt		dw 0A000h

; Puts a pixel on the screen.
; IN: AL = Color; BH = Page; CX = X position; DX = Y position
; OUT: nothing
os_put_pixel:
	pusha
	mov ah, 0Ch
	int 10h
	popa
	ret
	
; Gets a pixel from the screen.
; IN: BH = Page; CX = X position; DX = Y position
; OUT: AL = Color
os_get_pixel:
	pusha
	mov ah, 0Dh
	int 10h
	mov [.tmp_byte], al
	popa
	mov al, [.tmp_byte]
	ret
	
	.tmp_byte	db 0
	
; Draws a box on the screen.
; IN: CX/DX/SI/DI = X1/Y1/X2/Y2, AL = color
; OUT: nothing
os_draw_box:
	pusha
	cmp cx, si		; Is X1 smaller than X2?
	jl .x_good
	xchg cx, si		; If not, exchange them
.x_good:
	cmp dx, di		; Is Y1 smaller than Y2
	jl .y_good
	xchg dx, di		; If not, exchange them
.y_good:
	mov [.x1], cx
	mov bh, 0
.x_loop:
	call os_put_pixel
	inc cx
	
	cmp cx, si
	jl .x_loop
	
	inc dx
	mov cx, [.x1]
	
	cmp dx, di
	jl .x_loop
	
	popa
	ret
	
	.x1		dw 0
