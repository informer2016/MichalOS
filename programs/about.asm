; ------------------------------------------------------------------
; About MichalOS
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	call draw_background

	call os_draw_logo
	
	mov dh, 10
	mov dl, 2
	call os_move_cursor
	mov si, osname
	call os_print_string
	
	mov dh, 12
	mov dl, 0
	call os_move_cursor
	mov si, .text2
	call os_print_string
	
	call os_hide_cursor
	
	call os_wait_for_key
	
	call os_clear_screen
	ret

	.text2				db '  MichalOS: Copyright (C) Michal Prochazka, 2017-2018', 13, 10
	.text3				db '  MichalOS Font & logo: Copyright (C) Krystof Kubin, 2017-2018', 13, 10, 13, 10
	.text4				db '  Please report any bugs or glitches on prochazka2003@gmail.com', 0

	%INCLUDE "../source/features/name.asm"
	
draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 7
	call os_draw_background
	ret
	
	.title_msg			db 'About MichalOS', 0
	.footer_msg			db 0

; ------------------------------------------------------------------