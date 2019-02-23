; ------------------------------------------------------------------
; MichalOS VESA mode checker
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	mov di, 800h			; 2kB after the program loads
	call os_vesa_scan

	mov bx, 4000h
	
	mov ax, [di + 2]		; Get the screen width...
	call os_int_to_string
	call copy_string
	call put_space
	
	mov ax, [di + 4]		; ...then the height...
	call os_int_to_string
	call copy_string
	call put_space
	
	mov ah, 0
	mov al, [di + 6]		; ...and finally the color depth
	call os_int_to_string
	call copy_string
	call put_space
	
	call put_comma
	
	ret
	
	.loadsgmt	dw 2000h

put_comma:
	mov byte [bx], ','
	inc bx
	ret
	
put_space:
	mov byte [bx], ' '
	inc bx
	ret
	
copy_string:				; AX/BX = source/destination
	pusha
	mov si, ax
	mov di, bx
	
.loop:
	lodsb
	cmp al, 0
	je .exit
	
	stosb					; Don't terminate the destination string with a 0!
	jmp .loop

.exit:
	mov [.tmp_word], di
	popa
	mov bx, [.tmp_word]
	ret

	.tmp_word		dw 0