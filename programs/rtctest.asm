BITS 16
ORG 100h
%INCLUDE "michalos.inc"

start:
	call .draw_background

	mov ax, .exit_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	call os_clear_screen	
.test:
	call os_check_for_key
	cmp al, "Q"
	je near .exit

	mov ax, 0
	int 1Ah
	
	mov ax, cx
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov si, .space
	call os_print_string
	mov ax, dx
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov si, .space
	call os_print_string
	
	mov ax, cx
	rol eax, 16
	mov ax, dx
	push eax
	call os_32int_to_string
	mov si, ax
	call os_print_string
	pop eax
	mov si, .space
	call os_print_string

	call os_print_8hex
	
	call os_print_newline
	jmp .test
	
.draw_background:	
	mov ax, .title
	mov bx, .blank
	mov cx, [57000]
	call os_draw_background
	ret

.exit:
	ret
	
	.title			db 'MichalOS RTC Diagnostic Tool', 0
	.blank			db 0
	
	.space			db ' ', 0
	.exit_msg		db 'Press Shift+Q to quit.', 0