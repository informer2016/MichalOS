; ------------------------------------------------------------------
; MichalOS Spreadsheet editor
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	call .clear_buffer
	call .draw_background
	
.loop:
	call .clear_screen
	call os_wait_for_key
	
	cmp ah, 72
	je near .go_up
	
	cmp ah, 75
	je near .go_left
	
	cmp ah, 77
	je near .go_right
	
	cmp ah, 80
	je near .go_down

	cmp ah, 83
	je near .delete
	
	cmp al, 13
	je near .enter
	
	cmp ah, 59
	je near .file_menu
	
	cmp ah, 60
	je near .delete_row
	
	cmp ah, 61
	je near .insert_row
	
	cmp ah, 24
	je near .open_file
	
	cmp ah, 31
	je near .save_file
	
	cmp ah, 49
	je near .new_file
	
	cmp ax, 1F00h		; Ctrl + Alt + S
	je near .save_file_as
	
	cmp ah, 16
	je near .exit
	
	cmp al, 27
	je near .exit
	
	jmp .loop
	
.delete_row:
	mov ah, 0
	mov al, [.cursor_y]
	add al, [.offset]
	mov bx, 72
	mul bx
	add ax, buffer
	mov di, ax
	add ax, 72
	mov si, ax
	mov cx, 14400
	rep movsb
	jmp .loop
	
.insert_row:
	mov ah, 0
	mov al, [.cursor_y]
	add al, [.offset]
	mov bx, 72
	mul bx
	add ax, buffer
	mov si, buffer + 14400
	mov di, buffer + 14400 + 72
.insert_loop:
	mov al, [si]
	mov [di], al
	dec si
	dec di
	cmp si, ax
	jg .insert_loop
	mov di, ax
	mov al, 0
	mov cx, 72
	rep stosb
	jmp .loop
	
.delete:
	mov ah, 0
	mov al, [.cursor_x]
	mov bx, 8
	mul bx
	push ax
	
	mov ah, 0
	mov al, [.cursor_y]
	add al, [.offset]
	mov bx, 72
	mul bx
	pop bx
	add ax, bx
	add ax, buffer
	mov di, ax

	mov al, 0
	stosb
	jmp .loop
	
.enter:
	mov ah, 0
	mov al, [.cursor_x]
	mov bx, 8
	mul bx
	push ax
	
	mov ah, 0
	mov al, [.cursor_y]
	add al, [.offset]
	mov bx, 72
	mul bx
	pop bx
	add ax, bx
	add ax, buffer
	
	call os_input_string
	jmp .loop
	
.go_up:
	cmp byte [.cursor_y], 0
	je .decrease_offset
	dec byte [.cursor_y]
	jmp .loop
	
.go_left:
	cmp byte [.cursor_x], 0
	je .loop
	dec byte [.cursor_x]
	jmp .loop
	
.go_right:
	cmp byte [.cursor_x], 8
	je .loop
	inc byte [.cursor_x]
	jmp .loop
	
.go_down:
	cmp byte [.cursor_y], 19
	je .increase_offset
	inc byte [.cursor_y]
	jmp .loop

.increase_offset:
	cmp byte [.offset], 180
	je .loop
	inc byte [.offset]
	jmp .loop
	
.decrease_offset:
	cmp byte [.offset], 0
	je .loop
	dec byte [.offset]
	jmp .loop
	
.clear_screen:
	call os_hide_cursor
	mov dh, 3
	mov dl, 8
.clear_screen_loop:
	call os_move_cursor
	mov cx, 72
	mov ah, 0Ah
	mov bh, 0
	mov al, 32
	int 10h
	inc dh
	cmp dh, 23
	jl .clear_screen_loop
	mov ah, 0
	mov al, [.offset]
	mov bx, 72
	mul bx
	mov dh, 3
	mov dl, 8
	mov si, buffer
	add si, ax
.render_screen:
	call os_move_cursor
	call os_print_string
	add si, 8
	add dl, 8
	cmp dl, 80
	jl .render_screen
	mov dl, 8
	inc dh
	cmp dh, 23
	jl .render_screen
	
	mov dh, 3
	mov dl, 0
.enter_clean_loop:
	call os_move_cursor
	mov cx, 8
	mov ah, 0Ah
	mov bh, 0
	mov al, 32
	int 10h
	inc dh
	cmp dh, 23
	jl .enter_clean_loop
	mov dh, 3
	mov dl, 2
	mov ah, 0
	mov al, [.offset]
	inc al
	call .draw_background_loop

	mov dl, 0
	mov dh, [.cursor_y]
	add dh, 3
	call os_move_cursor
	mov si, .pointer
	call os_print_string
	
	mov ax, [.cursor_x]			; Set the cursor position
	mov bx, 8
	mul bx
	add ax, 8
	push ax
	
	mov ax, [.cursor_y]
	add ax, 3
	
	pop dx
	mov dh, al
	
	call os_move_cursor
	call os_show_cursor
	
	ret
	
.draw_background:
	mov ax, .title_msg			; Set up the screen with info at top and bottom
	mov bx, .footer_msg
	mov cx, BLACK_ON_WHITE
	call os_draw_background
	mov dl, 0
	mov dh, 1
	call os_move_cursor
	mov ah, 09h
	mov al, 32
	mov bh, 0
	mov bl, 10001111b
	mov cx, 160
	int 10h
	mov dl, 0
	mov dh, 3
	mov cx, 8
.draw_gray_loop:
	call os_move_cursor
	int 10h
	inc dh
	cmp dh, 24
	jl .draw_gray_loop
	mov dh, 2
	mov dl, 8
	call os_move_cursor
	mov si, .column_text
	call os_print_string
	mov dh, 3
	mov dl, 2
	mov ah, 0
	mov al, [.offset]
	inc al
.draw_background_loop:
	call os_move_cursor
	push ax
	call os_int_to_string
	mov si, ax
	call os_print_string
	inc dh
	pop ax
	inc ax
	cmp dh, 23
	jl .draw_background_loop
	ret
	
.clear_buffer:
	pusha
	mov di, buffer
	mov al, 0
	mov cx, 14400
	rep stosb
	popa
	ret
	
.file_menu:
	mov ax, .chooselist
	mov bx, 18
	call os_option_menu
	
	cmp ax, 1
	je near .new_file
	
	cmp ax, 2
	je near .open_file
	
	cmp ax, 3
	je near .save_file
	
	cmp ax, 4
	je near .save_file_as
	
	cmp ax, 5
	je near .exit
	
	call .draw_background
	jmp .loop
	
.new_file:
	mov ax, .confirm_msg
	mov bx, .confirm_msg1
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	cmp ax, 1
	je near .end
	
	mov ax, .filename
	mov bx, .new_file_msg
	call os_input_dialog
	
.end:
	call .draw_background
	jmp .loop

.open_file:
	call os_file_selector

	jc .end
	
	push ax
	mov di, ax
	call os_string_length
	add di, ax

	sub di, 3
	
	mov si, .sps_extension
	mov cx, 3
	rep cmpsb
	jne .invalid_extension

	pop si
	mov di, .filename
	call os_string_copy
	
	mov si, .filename
	call os_print_string
	call os_wait_for_key
	mov ax, si
	mov cx, buffer
	call os_load_file
	
	call .draw_background
	jmp .loop

.save_file:
	cmp byte [.filename], 0
	je .save_file_as
	
	mov ax, .filename
	call os_remove_file
	
	jc .write_error
	
	mov ax, .filename
	mov cx, 14400
	mov bx, buffer
	call os_write_file
	
	jc .write_error

	mov ax, .save_succeed
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	call .draw_background
	jmp .loop

.save_file_as:
	mov ax, .filename
	mov bx, .new_file_msg
	call os_input_dialog
	
	mov cx, 14400
	mov bx, buffer
	call os_write_file
	
	jc .write_error
	
	call .draw_background
	jmp .loop
	
.write_error:
	mov ax, .save_fail_msg1
	mov bx, .save_fail_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	call .draw_background
	jmp .loop
	
.exit:
	ret
	
.invalid_extension:
	mov ax, .wrong_ext_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box	
	call .draw_background
	jmp .loop

	.pointer			db '#', 0
	.wrong_ext_msg		db 'Invalid file type (SPS only)!', 0
	.sps_extension		db 'SPS', 0
	.save_fail_msg1		db 'Error saving the file!', 0
	.save_fail_msg2		db '(Invalid filename/disk is read-only?)', 0
	.save_succeed		db 'File saved.', 0	
	.chooselist			db 'New,Open...,Save,Save as...,Exit', 0
	.confirm_msg			db 'Are you sure? All unsaved changes will', 0
	.confirm_msg1		db 'be lost!', 0
	.new_file_msg		db 'Choose a new filename (DOCUMENT.SPS):', 0
	.cursor_x			db 0
	.cursor_y			db 0
	.offset				db 0
	.title_msg			db 'MichalOS Spreadsheet Editor', 0
	.footer_msg			db '[F1] File [F2/F3] Delete/Insert a row', 0
	.blank_string		db 0
	.column_text		db '   A       B       C       D       E       F       G       H       I', 0
	.filename			times 32 db 0
	
buffer: