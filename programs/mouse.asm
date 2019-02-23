; ------------------------------------------------------------------
; MichalOS Mouse Test
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	mov byte [0082h], 1
	
	call os_mouse_setup
	
	mov dh, 1
	mov dl, 1
	call os_mouse_scale
	
	mov ax, 0
	mov bx, 0
	mov cx, 1023
	mov dx, 767
	call os_mouse_range

	mov ax, 261
	mov bl, 1
	mov cx, 1024
	mov dx, 768
	call os_vesa_mode
	
.loop:
	call os_mouse_locate
	
	call os_mouse_leftclick
	jc .red
	
	call os_mouse_middleclick
	jc .green
	
	call os_mouse_rightclick
	jc .blue
	
	mov al, 63
	call os_vesa_pixel

.continue:
	call os_check_for_key
	cmp al, 27
	jne .loop
	
	mov ax, 3
	int 10h
	ret
	
.red:
	mov al, 110000b
	call os_vesa_pixel
	jmp .continue
	
.green:
	mov al, 001100b
	call os_vesa_pixel
	jmp .continue
	
.blue:
	mov al, 000011b
	call os_vesa_pixel
	jmp .continue
	
; ------------------------------------------------------------------