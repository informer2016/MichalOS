; ------------------------------------------------------------------
; MichalOS Clock
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	call .draw_background
	call os_hide_cursor
	
.timeloop:
	clc
	mov ah, 02h			; Get the time
	int 1Ah

	mov [.seconds], dh
	mov [.minutes], cl
	mov [.hours], ch
	
	mov al, [.hours]	; Draw the hours value
	mov dh, 9
	mov dl, 1
	rol al, 4
	call .draw_numbers
	add dl, 12
	rol al, 4
	call .draw_numbers
	add dl, 12

	call .draw_colon
	add dl, 4
	
	mov al, [.minutes]	; Draw the minutes value
	mov dh, 9
	rol al, 4
	call .draw_numbers
	add dl, 12
	rol al, 4
	call .draw_numbers
	add dl, 12
	
	call .draw_colon
	add dl, 4
	
	mov al, [.seconds]	; Draw the seconds value
	mov dh, 9
	rol al, 4
	call .draw_numbers
	add dl, 12
	rol al, 4
	call .draw_numbers
	add dl, 12
	
	mov ah, 04h			; Get the date
	int 1Ah
	
	mov [.day], dl
	mov [.month], dh
	mov [.year], cl
	mov [.century], ch
	
	mov dh, 17
	mov dl, 1
	call os_move_cursor
	
	mov al, [.day]
	call os_bcd_to_int
	mov ah, 0
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov al, [.month]
	call os_bcd_to_int
	dec al
	mov ah, 0
	mov bx, 10
	push dx
	mul bx
	pop dx
	add ax, .m1
	mov si, ax
	call os_print_string
	
	call os_print_space
	
	mov al, [.day]
	call os_bcd_to_int
	mov ah, 0
	call os_int_to_string
	mov si, ax
	call os_print_string

	mov si, .spacer2
	call os_print_string
	
	mov al, [.century]
	call os_bcd_to_int
	mov ah, 0
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov al, [.year]
	call os_bcd_to_int
	mov ah, 0
	call os_int_to_string
	mov si, ax
	call os_print_string	
	
	mov si, .spacer
	call os_print_string
	
	hlt
	call os_check_for_key
	cmp al, 27
	je near .exit
	
	jmp .timeloop
	
.draw_numbers:	; IN: low 4 bits of AL; DH/DL = cursor position
	pusha
	and al, 0Fh
	mov bl, al
	mov ax, 77
	mul bl
	add ax, .n00
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	popa
	ret
	
.draw_colon:		; IN: DH/DL = cursor position
	pusha
	mov ax, .na0
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	popa
	ret
	
.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, [57000]
	call os_draw_background
	ret
	
.exit:
	call os_show_cursor
	ret
	
	.spacer				db '        ', 0
	.spacer2			db ', ', 0
	
	.title_msg			db 'MichalOS Clock', 0
	.footer_msg			db 0

	.hours				db 0
	.minutes			db 0
	.seconds			db 0
	.day				db 0
	.month				db 0
	.year				db 0
	.century			db 0
		
	.n00				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n01				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n02				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n03				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n04				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n05				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n06				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.n10				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n11				db 32,  32,  219, 219, 219, 219, 32,  32,  32,  32,  0
	.n12				db 219, 219, 32,  32,  219, 219, 32,  32,  32,  32,  0
	.n13				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n14				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n15				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n16				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0

	.n20				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n21				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n22				db 32,  32,  32,  32,  32,  32,  219, 219, 32,  32,  0
	.n23				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n24				db 32,  32,  219, 219, 32,  32,  32,  32,  32,  32,  0
	.n25				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n26				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0

	.n30				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n31				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n32				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n33				db 32,  32,  32,  32,  219, 219, 219, 219, 32,  32,  0
	.n34				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n35				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n36				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	
	.n40				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n41				db 219, 219, 32,  32,  219, 219, 32,  32,  32,  32,  0
	.n42				db 219, 219, 32,  32,  219, 219, 32,  32,  32,  32,  0
	.n43				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0
	.n44				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n45				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n46				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0

	.n50				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0
	.n51				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n52				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n53				db 219, 219, 219, 219, 219, 219, 219, 219, 32,  32,  0
	.n54				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n55				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n56				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.n60				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n61				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n62				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n63				db 219, 219, 219, 219, 219, 219, 219, 219, 32,  32,  0
	.n64				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n65				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n66				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.n70				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0
	.n71				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n72				db 32,  32,  32,  32,  32,  32,  219, 219, 32,  32,  0
	.n73				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n74				db 32,  32,  219, 219, 32,  32,  32,  32,  32,  32,  0
	.n75				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n76				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0

	.n80				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n81				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n82				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n83				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n84				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n85				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n86				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.n90				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n91				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n92				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n93				db 32,  32,  219, 219, 219, 219, 219, 219, 219, 219, 0
	.n94				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n95				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n96				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.na0				db 32,  32,  0
	.na1				db 219, 219, 0
	.na2				db 32,  32,  0
	.na3				db 32,  32,  0
	.na4				db 32,  32,  0
	.na5				db 219, 219, 0
	.na6				db 32,  32,  0

	.m1					db 'January', 0, 0, 0
	.m2					db 'February', 0, 0
	.m3					db 'March', 0, 0, 0, 0, 0
	.m4					db 'April', 0, 0, 0, 0, 0
	.m5					db 'May', 0, 0, 0, 0, 0, 0, 0
	.m6					db 'June', 0, 0, 0, 0, 0, 0
	.m7					db 'July', 0, 0, 0, 0, 0, 0
	.m8					db 'August', 0, 0, 0, 0
	.m9					db 'September', 0
	.m10				db 'October', 0, 0, 0
	.m11				db 'November', 0, 0
	.m12				db 'December', 0, 0
	
	
; ------------------------------------------------------------------
