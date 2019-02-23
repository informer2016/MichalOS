; ==================================================================
; MichalOS Software Video Renderer
; ==================================================================

; Initializes the services.
; IN: nothing
; OUT: nothing

os_start_svr:
	mov cx, 10h
	call os_get_int_handler		; Back up the previous INT 10h...
	
	mov cx, 30h
	call os_modify_int_handler	; ...into INT 30h
	
	mov cx, 10h					; Enable the services
	mov di, 1000h
	mov si, os_svr_services
	call os_modify_int_handler

	mov ax, 10h					; 640x350, 16 colors
	int 30h

	mov byte [current_video_mode], 3
	
	ret
	
os_svr_services:
	pusha

	cmp ah, 00h
	je int_00_set_video_mode

	cmp byte [current_video_mode], 3
	jne use_the_bios	; Incompatible video mode
	
	cmp ah, 02h
	je int_02_set_cursor_pos
	
	cmp ah, 03h
	je int_03_get_cursor_pos
	
	cmp ah, 05h
	je int_05_set_active_page
	
	cmp ax, 0600h
	je int_06_clear_screen
	
	cmp ah, 06h
	je int_06_scroll_window_up
	
	cmp ah, 09h
	je int_09_write_char_attrib
	
	cmp ah, 0Eh
	je int_0E_teletype
	
	cmp ah, 0Fh
	je int_0F_get_video_mode
	
	cmp ah, 4Fh			; VESA stuff
	je use_the_bios
	
	popa
	iret
	
use_the_bios:
	popa
	int 30h
	iret
	
int_00_set_video_mode:
	mov [current_video_mode], al
	
	cmp al, 3			; Is the system trying to init the default text mode?
	jne .no_text		; If not, it's OK
	
	mov al, 10h			; If it is, do 640x350 instead
	
.no_text:
	int 30h				; Set the video mode
	popa
	iret
	
int_02_set_cursor_pos:
	mov [cursor_pos_x], dl
	mov [cursor_pos_y], dh
	popa
	iret
	
int_03_get_cursor_pos:
	popa
	mov ch, [cursor_type_start]
	mov cl, [cursor_type_end]
	mov dh, [cursor_pos_y]
	mov dl, [cursor_pos_x]
	iret
	
int_05_set_active_page:
	mov [current_page], al
	popa
	iret

int_06_clear_screen:
	popa
	pushad
	mov ah, bh
	
	mov esi, 0A000h - 65536
	mov cx, 80 * 25
	
.loop:
	mov [esi], ax
	add esi, 2
	
	dec cx
	cmp cx, 0
	jne .loop
	
	mov dx, 3C4h			; Select an EGA color plane
	mov ax, 0F02h			; Select all the planes
	out dx, ax		
	
	mov edi, 0A0000h - 65536
	mov cx, (80 * 350) / 4
	
.draw_loop:
	mov dword [edi], 0		; Using DWORDs here, to speed things up
	
	add edi, 4
	dec cx
	cmp cx, 0
	jne .draw_loop

	popad
	iret
	
int_06_scroll_window_up:
	popa
	pushad
	mov ch, al
	mov dx, 0
	call calculate_vram
	push esi
	
	mov dx, 80
	call calculate_vram
	pop edi
	
.line_loop:
	mov cl, 80
	
.loop:
	mov ax, [esi]
	mov [edi], ax
	
	inc esi
	inc edi
	
	dec cl
	cmp cl, 0
	jne .loop
	
	dec ch
	cmp ch, 0
	jne .line_loop
	
	call draw_screen
	
	popad
	iret
	
int_09_write_char_attrib:
	popa
	pushad
	mov ah, bl
	mov dl, [cursor_pos_x]
	mov dh, [cursor_pos_y]
	call calculate_vram
	
.loop:
	mov [esi], ax
	add esi, 2
	dec cx
	push cx
	push dx
	movzx cx, dl
	movzx dx, dh
	call os_draw_char
	pop dx
	inc dl
	cmp dl, 80
	jne .no_change
	
	mov dl, 0
	inc dh

.no_change:
	pop cx
	cmp cx, 0
	jne .loop

	popad
	iret
	
int_0E_teletype:
	popa
	pushad
	mov dl, [cursor_pos_x]
	mov dh, [cursor_pos_y]
	call calculate_vram
	mov [esi], al
	
	cmp al, 10
	je .line_feed
	
	cmp al, 13
	je .carriage_return
	
	movzx cx, byte [cursor_pos_x]
	movzx dx, byte [cursor_pos_y]
	mov ah, [esi + 1]
	
	call os_draw_char
	
	inc byte [cursor_pos_x]	
	popad
	iret

.line_feed:
	cmp byte [cursor_pos_y], 24
	je .no_line_feed
	inc byte [cursor_pos_y]

.no_line_feed:
	popad
	iret
	
.carriage_return:
	mov byte [cursor_pos_x], 0
	popad
	iret
	
int_0F_get_video_mode:
	popa
	mov ah, 80
	mov al, 3
	mov bh, [current_page]
	iret

draw_screen:
	pushad
	mov esi, 0A000h - 65536
	mov cx, 0
	mov dx, 0
	
.loop:
	mov ax, [esi]
	call os_draw_char
	
	add esi, 2
	
	inc cx
	cmp cx, 80
	jne .loop
	
	mov cx, 0
	inc dx
	cmp dx, 25
	jne .loop
	
	popad
	ret
	
calculate_vram:
	push bx
	push ax
	push dx
	push dx			; Yes, twice!	
	movzx ax, dh
	mov bx, 80
	mul bx
	pop dx
	mov dh, 0
	add ax, dx
	shl ax, 1		; 1 character = 2 bytes
	movzx esi, ax
	add esi, 0A000h - 65536
	pop dx
	pop ax
	pop bx
	ret
	
	current_video_mode		db 0
	current_page			db 0
	cursor_pos_x			db 0
	cursor_pos_y			db 0
	cursor_type_start		db 0
	cursor_type_end			db 0
