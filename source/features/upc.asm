; ==================================================================
; MichalOS User Privilege Control
; ==================================================================

UPC:
	pusha

	cmp byte [0082h], 1
	je .cli_upc
	
	mov ax, .uac_name
	mov bx, .blank_string
	mov cx, [57000]
	call os_draw_background
	
	cmp byte [57002], 0
	je .no_password
	
.password:
	mov ax, .buffer
	mov bx, .msg_pass
	call os_password_dialog
	
	mov si, .buffer
	mov di, 57003
	call os_string_compare
	
	jc .success
	jnc .fail

.no_password:
	mov ax, 0
	mov bx, 9999
	call os_get_random
	
	mov ax, cx
	call os_int_to_string
	
	mov si, ax
	mov di, .randomcode
	call os_string_copy
	
	mov ax, .buffer
	mov bx, .msg_nopass
	call os_password_dialog
	
	mov si, .buffer
	mov di, .randomcode
	call os_string_compare
	
	jc .success
	
.fail:
	popa
	stc
	ret
	
.success:
	popa
	clc
	ret
	
.cli_upc:
	call os_print_newline
	mov si, .uac_name
	call os_print_string
	call os_print_newline
	
	cmp byte [57002], 0
	je .cli_no_password
	
.cli_password:
	mov si, .msg_pass
	call os_print_string
	call os_print_newline
	
	mov ax, .buffer
	mov bl, 7
	call os_input_password
	
	call os_print_newline
	call os_print_newline

	mov si, .buffer
	mov di, 57003
	call os_string_compare
	
	jc .success
	jnc .fail

.cli_no_password:
	mov ax, 0
	mov bx, 9999
	call os_get_random
	
	mov ax, cx
	call os_int_to_string
	
	mov si, ax
	mov di, .randomcode
	call os_string_copy
	
	mov si, .msg_nopass
	call os_print_string
	call os_print_newline
	
	mov ax, .buffer
	mov bl, 7
	call os_input_password
	
	call os_print_newline
	call os_print_newline

	mov si, .buffer
	mov di, .randomcode
	call os_string_compare
	
	jc .success
	jnc .fail
	
	
	.uac_name		db 'MichalOS User Privilege Control', 0
	.blank_string	db 0
	
	.msg_nopass		db 'Zadejte nasledujici kod: '
	.randomcode		times 8 db 0
	
	.msg_pass		db 'Zadejte uzivatelske heslo: ', 0
	
	.buffer			equ 65500