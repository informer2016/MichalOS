	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

	disk_buffer	equ	16384

start:
	call os_wait_for_key

	mov al, [0]
	mov [.drive], al

	mov ax, 0
	
.loop:
	call .sectorselect
	inc ax
	cmp ax, 2880
	jl .loop
	
	mov ax, [.bad_sectors]
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov si, .badmsg0
	call os_print_string
	
	call os_wait_for_key
	ret
	
.sectorselect:
	pusha
	mov si, .sectormsg
	call os_print_string
	
	call os_int_to_string
	mov si, ax
	call os_print_string
	popa
	
	pusha
	call os_disk_l2hts		; Entered number -> HTS
	mov bx, disk_buffer		; Read the sector
	mov ah, 2
	mov al, 1
	mov dl, [.drive]
	stc
	int 13h
	jc .error
	
	mov si, .pass_msg
	call os_print_string
	popa
	ret
	
.error:
	mov si, .err_msg
	call os_print_string
	inc word [.bad_sectors]
	popa
	ret

	.drive				db 0
	.bad_sectors		dw 0
	
	.sectormsg			db 'Sector ', 0
	.pass_msg			db ' - Passed', 13, 10, 0
	.err_msg			db ' - Failed', 13, 10, 0
	.badmsg0			db ' bad sectors found.', 0
	
; ------------------------------------------------------------------

