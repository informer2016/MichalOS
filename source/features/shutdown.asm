shutdownmenu:
	mov byte [0082h], 1
	call os_hide_cursor
	call .drawbackground
	call .drawwindow
	call .selector
	cmp al, 1
	je near .shutdown
	cmp al, 2
	je near .hardreset
	cmp al, 3
	je near checkformenu
	
.selector:
	mov dh, 11
	mov dl, 28
	call os_move_cursor
.selectorloop:
	call .drawcontents
	call .invert
	call os_wait_for_key
	cmp ah, 80
	je .selectdown
	cmp ah, 72
	je .selectup
	cmp al, 13
	je .select
	cmp al, 27
	je .return
	jmp .selectorloop
.return:
	mov al, 3
	mov byte [0082h], 1
	ret
.selectdown:
	cmp dh, 13
	je near .selectorloop
	inc dh
	jmp .selectorloop
.selectup:
	cmp dh, 11
	je near .selectorloop
	dec dh
	jmp .selectorloop
.select:
	mov al, dh
	sub al, 10
	ret
	
.invert:
	mov dl, 28
.invertloop:
	call os_move_cursor
	mov ah, 08h
	mov bh, 0
	int 10h
	mov bl, 240			; Black on white
	mov ah, 09h
	mov bh, 0
	mov cx, 1
	int 10h
	inc dl
	cmp dl, 60
	je near .invertend
	jmp .invertloop
	
.invertend:
	mov dl, 28
	ret
	
.drawwindow:
	mov dh, 9			; First, draw white background box
	mov dl, 19
	mov bl, [57001]
	mov si, 42
	mov di, 15
	call os_draw_block
.drawcontents:
	pusha
	mov bl, [57001]
	mov dh, 10
	mov dl, 20
	call os_move_cursor
	mov si, .dialogmsg1
	call os_format_string
	mov si, 57036
	call os_format_string
	mov si, .dialogmsg2
	call os_format_string
	mov dh, 11
	mov dl, 20
	call os_move_cursor
	mov si, .logo0
	call os_format_string
	mov dh, 12
	mov dl, 20
	call os_move_cursor
	mov si, .logo1
	call os_format_string
	mov dh, 13
	mov dl, 20
	call os_move_cursor
	mov si, .logo2
	call os_format_string
	mov dh, 14
	mov dl, 20
	call os_move_cursor
	mov si, .logo3
	call os_format_string
	popa
	ret

.drawbackground:
	call os_clear_screen
	mov dl, 0
	mov dh, 0
	call os_move_cursor
	mov al, 32
	mov ah, 09h
	mov bh, 0
	mov bl, 112			; Black on gray
	mov cx, 80
	int 10h
	mov dl, 0
	mov dh, 1
	call os_move_cursor
	mov bl, [57000]		; Color from RAM
	and bl, 11110000b
	mov cx, 1840
	mov al, 177
	int 10h
	mov dl, 0
	mov dh, 24
	call os_move_cursor
	mov bl, 112			; Black on gray
	mov cx, 80
	mov al, 32
	int 10h
	ret
	
.hardreset:
	mov ax, 0
	int 19h				; Reboot the system
	
.shutdown:
	mov ax, 5300h 		; check for existance of APM
	mov bx, 0
	int 15h 			; returns version in AL and AH
	jc .APM_missing

	
	mov ax, 5301h
	mov bx, 0
	mov cx, 0
	int 15h				; open an interface with APM
	jc .APM_interface

	mov ax, 5307h
	mov bx, 1
	mov cx, 3
	int 15h				; do a power off
	
.APM_error:
	mov ax, .errormsg1
	mov bx, .errormsg4
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	jmp .APM_error
	
.APM_missing:
	mov ax, .errormsg2
	mov bx, .errormsg4
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	jmp .APM_missing
	
.APM_interface:
	mov ax, .errormsg3
	mov bx, .errormsg4
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	jmp .APM_interface
	
	.dialogmsg1	db 'Goodbye, ', 0
	.dialogmsg2	db '.', 0
	.errormsg1	db 'Error shutting down the computer.', 0
	.errormsg2	db 'This computer does not support APM.', 0
	.errormsg3	db 'Error communicating with APM.', 0
	.errormsg4	db 'Please turn off the computer manually.', 0
	.logo0		db 218, 196, 196, 179, 196, 196, 191, '  Shut down the computer         ', 0
	.logo1		db 179, 32, 32, 179, 32, 32, 179,     '  Reboot the computer            ', 0
	.logo2		db 179, 32, 32, 32, 32, 32, 179,      '  Go back                        ', 0
	.logo3		db 192, 196, 196, 196, 196, 196, 217, 0
