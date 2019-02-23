; ------------------------------------------------------------------
; MichalOS Configuration
; ------------------------------------------------------------------

; SYSTEM.CFG map:
; 0 = Desktop background color (BYTE)
; 1 = Window background color (BYTE)
; 2 = Password enabled (BYTE)
; 3 - 35 = Password data (STRING)
; 36 - 68 = Username (STRING)
; 69 - Sound enabled on startup (BYTE)
; 70 - Free space
; 71 - Menu screen dimming enabled (BYTE)
; 72 - Menu color (BYTE)
; 73 - "DOS" font enabled (BYTE)
; 74 - Minutes to wait for screensaver (WORD)
; 76 - Graphics mode enabled (BYTE)

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	call .draw_background

	mov ax, .command_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc near .exit					; User pressed Esc?

	cmp ax, 1
	je near .look

	cmp ax, 2
	je near .sound
	
	cmp ax, 3
	je near .password
		
.look:
	call .draw_background

	mov ax, .look_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc near start					; User pressed Esc?

	cmp ax, 1
	je near .bg_change
	
	cmp ax, 2
	je near .window_change
	
	cmp ax, 3
	je near .menu_change
	
	cmp ax, 4
	je near .screensaver_settings
	
	cmp ax, 5
	je near .font_change

	cmp ax, 6
	je near .enable_graphics
	
	cmp ax, 7
	je near .enable_text_mode
	
	cmp ax, 8
	je near .enable_dimming
	
	cmp ax, 9
	je near .disable_dimming
	
.enable_dimming:
	mov byte [57071], 1
	call .update_config
	jmp .look
	
.disable_dimming:
	mov byte [57071], 0
	call .update_config
	jmp .look

.enable_graphics:
	mov byte [57076], 1
	call .update_config
	jmp .look
	
.enable_text_mode:
	mov byte [57076], 0
	call .update_config
	jmp .look
	
.screensaver_settings:
	call .draw_background
	
	mov ax, .screensaver_list
	mov bx, .help_msg1
	mov cx, .help_msg2
	
	call os_list_dialog
	
	jc .look
	
	cmp ax, 1
	je near .disable_screensaver
	
	cmp ax, 2
	je near .screensaver_change_time
	
.disable_screensaver:
	mov word [57074], 0
	call .update_config
	jmp .screensaver_settings

.screensaver_change_time:
	call .draw_background
	
	mov ax, buffer
	mov bx, .screensaver_msg
	call os_input_dialog
	
	mov si, buffer
	call os_string_to_int
	
	mov [57074], ax
	
	call .update_config
	jmp .screensaver_settings
	
.font_change:
	call .draw_background

	mov ax, .font_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc near .look					; User pressed Esc?
	
	cmp ax, 1
	je near .michalos_font
	
	cmp ax, 2
	je near .bios_font
	
.michalos_font:
	mov byte [57073], 0
	call .update_config
	call os_reset_font
	jmp .look
	
.bios_font:
	mov byte [57073], 1
	call .update_config
	mov ax, 3
	int 10h
	mov ax, 1003h			; Set text output with certain attributes
	mov bx, 0				; to be bright, and not blinking
	int 10h
	jmp .look
	
.menu_change:
	call os_color_selector
	jc .look
	cmp al, 14
	jg .menu_confirm
	add al, 0F0h
.menu_confirm:
	rol al, 4
	mov [57072], al
	call .update_config
	jmp .look
	
.bg_change:
	call os_color_selector
	jc .look
	cmp al, 14
	jg .bg_confirm
	add al, 0F0h
.bg_confirm:
	rol al, 4
	mov [57000], al
	call .update_config
	jmp .look

.window_change:
	call os_color_selector
	jc .look
	cmp al, 14
	jge .window_confirm
	add al, 240
.window_confirm:
	rol al, 4
	mov [57001], al
	call .update_config
	jmp .look

.sound:
	call .draw_background

	mov ax, .sound_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc near start					; User pressed Esc?

	cmp ax, 1
	je near .enable_sound
	
	cmp ax, 2
	je near .disable_sound

.enable_sound:
	mov byte [57069], 1
	call .update_config
	jmp .sound
	
.disable_sound:
	mov byte [57069], 0
	call .update_config
	jmp .sound
	
.password:
	mov ax, .password_list
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog
	
	jc start
	
	cmp ax, 1
	je near .change_name
	
	cmp ax, 2
	je near .disable_password
	
	cmp ax, 3
	je near .set_password
	
.change_name:
	call .reset_name
	mov ax, 57036
	mov bx, .name_msg
	call os_input_dialog
	call .update_config
	jmp .password
	
.disable_password:
	mov al, 0
	mov [57002], al
	call .update_config
	jmp .password
	
.set_password:
	mov al, 1
	mov [57002], al
	call .reset_password
	mov ax, 57003
	mov bx, .password_msg
	call os_password_dialog
	call .update_config
	jmp .password
	
.exit:
	call os_clear_screen
	ret

;------------------------------------------

.reset_password:
	mov di, 57003	
	mov al, 0
.reset_password_loop:
	stosb
	cmp di, 57036
	jl .reset_password_loop
	ret

.reset_name:
	mov di, 57036	
	mov al, 0
.reset_name_loop:
	stosb
	cmp di, 57069
	jl .reset_name_loop
	ret

.draw_background:
	pusha
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, [57000]
	call os_draw_background
	popa
	ret

.update_config:
	mov ax, .config_name	; Replace the SYSTEM.CFG file with the new configuration...
	call os_remove_file
	mov ax, .config_name
	mov bx, 57000
	mov cx, 77				; SYSTEM.CFG file size
	call os_write_file
	jc .write_error
	mov ax, .changedone
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	ret
	
.write_error:
	mov ax, .errmsg1
	mov bx, .errmsg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	ret

	.command_list		db 'Look and feel,Sound,User information', 0
	.password_list		db 'Change the name,Disable the password,Set the password', 0
	.look_list			db 'Background color,Window color,Main menu color,Screensaver settings,Font,Set experimental EGA renderer on startup,Set default text mode on startup,Enable background dimming when in menu,Disable background dimming when in menu', 0
	.font_list			db 'MichalOS System Font,BIOS Default Font', 0
	.screensaver_list	db 'Disable the screensaver,Set the screensaver', 0
	.sound_list			db 'Enable sound at startup,Disable sound at startup', 0
	
	.password_msg		db 'Enter a new password (32 chars max.):', 0
	.name_msg			db 'Enter a new name (32 chars max.):', 0
	
	.screensaver_msg	db 'Enter the amount of minutes:', 0
	
	.changedone			db 'Changes have been saved.', 0
	
	.help_msg1			db 'Choose an option...', 0
	.help_msg2			db '', 0
	
	.title_msg			db 'MichalOS Settings', 0
	.footer_msg			db '', 0

	.config_name		db 'SYSTEM.CFG', 0
	
	.errmsg1			db 'Error writing to the disk!', 0
	.errmsg2			db 'Make sure it is not read only!', 0

buffer:
	
; ------------------------------------------------------------------

