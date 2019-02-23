; ------------------------------------------------------------------
; MichalOS Music Player
; ------------------------------------------------------------------


	BITS 16
	%INCLUDE "michalos.inc"
	%INCLUDE "notelist.txt"
	ORG 100h

start:
	call os_speaker_off
	call .draw_background
	mov byte [0082h], 0

	mov ax, .choice
	mov bx, .choice_msg1
	mov cx, .choice_msg2
	call os_list_dialog
	
	jc .exit
	
	cmp ax, 1
	je near .piano
	
	cmp ax, 2
	je near .play_file
	
	cmp ax, 3
	je near .exit
	
.play_file:
	call os_file_selector
	jc start
	call .draw_background
	mov cx, buffer
	call os_load_file
	call os_clear_screen
	mov si, .msgstart
	call os_print_string
	call os_wait_for_key
	cmp al, 27
	je start
	call os_print_newline
	mov byte [0082h], 1
	call startb
	jmp start
	
.piano:
	call .draw_background
	
	mov dl, 1
	mov dh, 9
	call os_move_cursor
	mov si, .piano0
	call os_print_string
	call os_hide_cursor
	
.pianoloop:
	call os_wait_for_key

	cmp al, ' '
	je .execstop
	cmp al, 27
	je start
	
	mov si, .keydata1
	mov di, .notedata1
	
.decodeloop:
	mov bh, [si]
	inc si
	add di, 2
	
	cmp ah, bh
	jne .decodeloop
	
	sub di, 2				; We've overflowed a bit
	mov ax, [di]
	call os_speaker_tone
	
	jmp .pianoloop
	
.execstop:
	call os_speaker_off
	jmp .pianoloop
	
.draw_background:
	pusha
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, [57000]
	call os_draw_background
	popa
	ret

.exit:
	call os_clear_screen
	ret
	
	.choice_msg1		db 'Choose an option...', 0
	.choice_msg2		db 0
	.choice				db 'Virtual piano,Play a file,Quit', 0

	.msgstart			db 'Press any key to play...', 0
	
	.title_msg			db 'MichalOS Music Player', 0
	.footer_msg			db 0

	.keydata1			db 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h, 34h, 35h
	.keydata2			db 1Fh, 20h, 22h, 23h, 24h, 26h, 27h
	.keydata3			db 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 1Ah, 1Bh
	.keydata4			db 03h, 04h, 06h, 07h, 08h, 0Ah, 0Bh, 0Dh, 00h
	
	.notedata1			dw C3, D3, E3, F3, G3, A3, B3, C4, D4, E4
	.notedata2			dw CS3, DS3, FS3, GS3, AS3, CS4, DS4
	.notedata3			dw C4, D4, E4, F4, G4, A4, B4, C5, D5, E5, F5, G5
	.notedata4			dw CS4, DS4, FS4, GS4, AS4, CS5, DS5, FS5
	
	.piano0 db 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 179, 13, 10
	.piano1 db 32, 179, 32, 32, 32, 83, 32, 32, 32, 68, 32, 32, 32, 179, 32, 32, 32, 71, 32, 32, 32, 72, 32, 32, 32, 74, 32, 32, 32, 179, 32, 32, 32, 50, 32, 32, 32, 51, 32, 32, 32, 179, 32, 32, 32, 53, 32, 32, 32, 54, 32, 32, 32, 55, 32, 32, 32, 179, 32, 32, 32, 57, 32, 32, 32, 48, 32, 32, 32, 179, 32, 32, 32, 61, 32, 32, 32, 179, 13, 10
	.piano2 db 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 179, 13, 10
	.piano3 db 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 179, 13, 10
	.piano4 db 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 13, 10
	.piano5 db 32, 179, 32, 90, 32, 179, 32, 88, 32, 179, 32, 67, 32, 179, 32, 86, 32, 179, 32, 66, 32, 179, 32, 78, 32, 179, 32, 77, 32, 179, 32, 81, 32, 179, 32, 87, 32, 179, 32, 69, 32, 179, 32, 82, 32, 179, 32, 84, 32, 179, 32, 89, 32, 179, 32, 85, 32, 179, 32, 73, 32, 179, 32, 79, 32, 179, 32, 80, 32, 179, 32, 91, 32, 179, 32, 93, 32, 179, 13, 10
	.piano6 db 32, 192, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 217, 0

startb:
	call .int_handler
	call os_check_for_key
	cmp al, 27
	je .exit
	mov ax, 1
	call os_pause
	cmp word [.pointer], .track0
	jne startb
	cmp byte [.delay], 0
	jne startb

.exit:
	mov word [.pointer], .track0	; Reset the values when we press Esc
	mov word [.previous], 0
	ret
	
.int_handler:
	pusha
	inc byte [.delay]
	mov al, [.song_delay]
	cmp byte [.delay], al
	jl .skip_play
	
	mov byte [.delay], 0
	
	mov si, [.pointer]
	lodsw
	mov [.pointer], si
	
	cmp ax, [.previous]
	je .noprint
	
	cmp ax, 0
	je .altprint
	
	pusha
	mov si, .msg0
	call os_print_string
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov si, .msg1
	call os_print_string
	jmp .continueprint
	
.altprint:
	pusha
	mov si, .msg0alt
	call os_print_string
	
.continueprint:
	mov si, .msg2
	call os_print_string
	mov ax, [.pointer]
	call os_print_4hex
	
	mov si, .msg3
	call os_print_string
	popa
	pusha
	call os_print_4hex
	
	call os_print_newline
	popa
	
.noprint:
	mov [.previous], ax

	cmp ax, 0
	je near .notone
	
	cmp ax, 1
	je near .end
	
	call os_speaker_tone
	
.skip_play:
	popa
	ret
	
.notone:
	call os_speaker_off
	popa
	ret
	
.end:
	call os_speaker_off
	mov word [.pointer], .track0
	popa
	ret

	.previous	dw 0
	.pointer	dw .track0
	.delay		db 0
	.song_delay	equ buffer
	.track0		equ buffer + 1
	.msg0		db 'Playing a note (frequency ', 0
	.msg1		db ') ', 0
	.msg0alt	db 'Pausing', 0
	.msg2		db ', offset 0x', 0
	.msg3		db ', data 0x', 0
	
buffer:
	
; ------------------------------------------------------------------

