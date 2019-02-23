; ------------------------------------------------------------------
; MichalOS VESA mode checker
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	mov di, 16384
	mov cx, 100h
	
.loop:
	mov ax, 4F01h
	int 10h
	
	cmp ah, 00h
	jne .not_good
	
	mov ax, cx
	call os_print_4hex
	
	call os_print_space
	
	mov ax, [di + 12h]
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	call os_print_space
	
	mov ax, [di + 14h]
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	call os_print_space
	
	mov ah, 0
	mov al, [di + 19h]
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	call os_print_newline
	
.not_good:
	inc cx
	cmp cx, 400h
	jne .loop

	call os_wait_for_key
	
	ret