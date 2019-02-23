; -----------------------------------------------------------------
; os_modify_int_handler -- Change location of interrupt handler
; IN: CL = int number, DI:SI = handler location

os_modify_int_handler:
	pusha

	cli

	push es
	
	mov es, [driversgmt]
	
	mov al, cl			; Move supplied int into AL

	mov bl, 4			; Multiply by four to get position
	mul bl				; (Interrupt table = 4 byte sections)
	mov bx, ax

	mov [es:bx], si		; First store offset

	add bx, 2
	
	mov [es:bx], di		; Then segment of our handler

	pop es
	
	sti

	popa
	ret

; -----------------------------------------------------------------
; os_get_int_handler -- Change location of interrupt handler
; IN: CL = int number; OUT: DI:SI = handler location

os_get_int_handler:
	pusha

	push ds
	
	mov ds, [driversgmt]
	
	mov al, cl			; Move supplied int into AL

	mov bl, 4			; Multiply by four to get position
	mul bl				; (Interrupt table = 4 byte sections)
	mov bx, ax

	mov si, [ds:bx]		; First store offset
	add bx, 2

	mov di, [ds:bx]		; Then segment of our handler

	pop ds

	mov [.tmp_word], si
	mov [.tmp_sgmt], di
	popa
	mov si, [.tmp_word]
	mov di, [.tmp_sgmt]
	ret

	.tmp_word	dw 0
	.tmp_sgmt	dw 0
	
; -----------------------------------------------------------------
; Interrupt call parsers

os_compat_int00:				; Division by 0 error handler
	mov ax, .msg
	call os_crash_application

	.msg db 'CPU: Division by zero error', 0

os_compat_int04:				; INTO instruction error handler
	mov ax, .msg
	call os_crash_application

	.msg db 'CPU: INTO detected overflow', 0

os_compat_int05:				; BOUND instruction error handler
	mov ax, .msg
	call os_crash_application

	.msg db 'CPU: BOUND range exceeded', 0

os_compat_int06:				; Invalid opcode handler
	mov ax, .msg
	call os_crash_application

	.msg db 'CPU: Invalid opcode', 0

os_compat_int07:				; Processor extension error handler
	mov ax, .msg
	call os_crash_application

	.msg db 'CPU: Processor extension error', 0

os_compat_int1C:				; System timer handler (8253/8254)
	pushad
	push ds
	push es
	mov ax, 1000h
	mov ds, ax
	mov es, ax
	call os_update_clock
	pop es
	pop ds
	popad
	iret