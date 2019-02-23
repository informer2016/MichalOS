; ------------------------------------------------------------------
; MichalOS VESA Test
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	mov byte [0082h], 1

	mov ax, 257
	mov bl, 1
	mov cx, 640
	mov dx, 480
	call os_vesa_mode
	
	mov ax, [.default_color]
	mov dx, 0
	mov cx, 0
.loop:
	call os_vesa_pixel
	inc cx
	cmp cx, 640
	jne .loop
	
	mov cx, 0
	inc dx
	inc ax
	cmp ax, 64
	jl .no_color
	mov ax, 0
.no_color:
	cmp dx, 480
	jl .loop
	
	call os_check_for_key
	cmp al, 27
	je .exit
	
	mov dx, 0
	inc word [.default_color]
	cmp word [.default_color], 64
	jne .no_change
	
	mov word [.default_color], 0
	
.no_change:
	mov ax, [.default_color]
	jmp .loop
	
.exit:
	mov ax, 3
	int 10h
	ret
	
	.default_color	dw 0
	
; ------------------------------------------------------------------