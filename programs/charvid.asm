; ------------------------------------------------------------------
; MichalOS Program
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	mov byte [0082h], 1

	mov ax, 10h
	int 10h
	
	mov cx, 0
	mov dx, 0
	mov si, buffer
	mov ah, 0
	
.loop:
	lodsb

	call os_draw_char
	
	inc ah
	
	inc cx
	cmp cx, 80
	jne .loop

	mov cx, 0
	inc dx
	cmp dx, 25
	jne .loop
	
	call os_wait_for_key
	ret
	
	buffer	db ' Hi! This is a test of the new EGA text rendering engine! It is soooooooooooooooooooo awesome!!!'