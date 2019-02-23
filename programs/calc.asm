; ------------------------------------------------------------------
; MichalOS Calculator (32-bit)
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	call .draw_background

	mov ax, .options
	mov bx, .options_name
	mov cx, .footer_msg
	call os_list_dialog
	
	jc .exit
	
	cmp ax, 1
	je .plus
	
	cmp ax, 2
	je .minus
	
	cmp ax, 3
	je .multiply
	
	cmp ax, 4
	je .divide
	
	cmp ax, 5
	je .power
	
	cmp ax, 6
	je .square_root
	
	cmp ax, 7
	je .cube_root
	
.plus:
	call .draw_background
	call .get_numbers
	mov edx, 0
	add eax, ebx
	call .result
	jmp start
	
.minus:
	call .draw_background
	call .get_numbers
	mov edx, 0
	sub eax, ebx
	call .result
	jmp start
	
.multiply:
	call .draw_background
	call .get_numbers
	mov edx, 0
	mul ebx
	call .result
	jmp start
	
.divide:
	call .draw_background
	call .get_numbers
	cmp ebx, 0
	je near .divide_error
	mov edx, 0
	div ebx
	call .result
	jmp start
	
.power:
	call .draw_background
	call .get_numbers
	call os_math_power
	call .result
	jmp start
	
.square_root:
	call .draw_background
	call .get_number
	mov ebx, 2
	call os_math_root
	cmp edx, 0
	jne .root_result
	call .result
	jmp start
	
.cube_root:
	call .draw_background
	call .get_number
	mov ebx, 3
	call os_math_root
	cmp edx, 0
	jne .root_result
	call .result
	jmp start
	
.get_number:
	mov ax, .firstnumberstring
	mov bx, .number_msg
	call os_input_dialog
	mov si, ax
	call os_string_to_32int
	ret
	
.get_numbers:
	mov ax, .firstnumberstring
	mov bx, .firstnumber_msg
	call os_input_dialog
	mov si, ax
	call os_string_to_32int
	push eax

	mov ax, .secondnumberstring
	mov bx, .secondnumber_msg
	call os_input_dialog
	mov si, ax
	call os_string_to_32int
	
	mov ebx, eax
	pop eax
	
	ret

.root_result:
	call os_32int_to_string		; We already have the result in EAX
	mov si, ax
	mov di, .resultmsg
	call os_string_copy
	mov bx, .resultmsg
	mov ax, .root_msg1
	call os_string_join

	mov ax, cx
	mov bx, .root_msg2
	call os_string_join
	mov eax, edx
	call os_32int_to_string
	mov bx, ax
	mov ax, cx
	call os_string_join
	
	mov ax, cx
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp start

.result:
	call os_32int_to_string		; We already have the result in EAX
	mov si, ax
	mov di, .resultmsg
	call os_string_copy
	mov bx, .resultmsg
	mov ax, .result_msg
	call os_string_join
	
	cmp edx, 0
	je near .skipremainder
	
	mov ax, cx
	mov bx, .remainder_msg
	call os_string_join
	mov eax, edx
	call os_32int_to_string
	mov bx, ax
	mov ax, cx
	call os_string_join
	mov ax, cx
	mov bx, .msg_end
	call os_string_join
	
.skipremainder:	
	mov ax, cx
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	ret
	
.divide_error:	
	mov ax, .divide_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp start
	
.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, [57000]
	call os_draw_background
	ret
	
.exit:
	ret
	
	.title_msg			db 'MichalOS Calculator', 0
	.footer_msg			db 0

	.options_name		db 'Choose an operation...', 0
	.options			db '+ (Add),- (Subtract),* (Multiply),/ (Divide),^ (Power),', 0EAh, ' (Square root),', 0E3h, 0EAh, ' (Cube root)', 0
	; 251 = root symbol

	.result_msg			db 'Answer: ', 0
	.remainder_msg		db ' (remainder: ', 0
	.msg_end			db ')', 0
	
	.root_msg1			db 'Answer: between ', 0
	.root_msg2			db ' a ', 0
	
	.divide_msg			db 'Cannot divide by zero!', 0
	
	.number_msg			db 'Enter a number:', 0
	.firstnumber_msg	db 'Enter the first number:', 0
	.secondnumber_msg	db 'Enter the second number:', 0
	
	.resultint			dd 2048 + 0
	.remainderint		dd 2048 + 4
	.firstnumber		dd 2048 + 8
	.secondnumber		dd 2048 + 12
	
	.firstnumberstring	equ 4096
	.secondnumberstring	equ 6144
	.resultmsg			equ 8192
	
	
; ------------------------------------------------------------------
