; ------------------------------------------------------------------
; MichalOS Box Test
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	mov byte [0082h], 1

	mov ax, 13h
	int 10h
	
.loop:
	mov ax, 0
	mov bx, 15
	call os_get_random
	mov [.color], cl
	
	mov bx, 199
	call os_get_random
	mov di, cx
	call os_get_random
	mov dx, cx
	
	mov bx, 319
	call os_get_random
	mov si, cx
	call os_get_random
	
	mov al, [.color]
	call os_draw_box
	
	call os_check_for_key
	cmp al, 27
	jne .loop
	
	mov ax, 3
	int 10h
	ret
	
	.color	db 0
	
	
; ------------------------------------------------------------------