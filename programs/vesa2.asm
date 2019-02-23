; ------------------------------------------------------------------
; MichalOS VESA tester no.2
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	mov byte [0082h], 1

	mov ax, 280					; 1024x768, 24-bit color
	mov cx, 1024 * 3				; 1 pixel = 3 bytes
	mov dx, 768
	call os_vesa_mode

	mov cx, 0
	mov dx, 0
	mov bl, 0					; Red channel
	mov bh, 0					; Green channel
	
.loop:
	inc cx
	mov al, bh
	call os_vesa_pixel
	inc cx
	mov al, bl
	call os_vesa_pixel
	inc cx
	
	inc bl
	
	cmp cx, 256 * 3
	jne .loop
	
	mov cx, 0
	inc bh
	inc dx
	cmp dx, 256
	jne .loop
	
	call os_wait_for_key
	
	ret
