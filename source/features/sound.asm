; ==================================================================
; PC SPEAKER SOUND ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_speaker_tone -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note frequency; OUT: Nothing (registers preserved)

os_speaker_tone:
	pusha
	mov al, [0083h]
	cmp al, 0
	je near .exit
	popa
	
	pusha
	cmp ax, 0
	je near .exit
	mov cx, ax			; Store note value for now

	mov al, 10110110b
	out 43h, al
	mov dx, 12h			; Set up frequency
	mov ax, 34DCh
	div cx
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h			; Switch PC speaker on
	or al, 03h
	out 61h, al

.exit:
	popa
	ret


; ------------------------------------------------------------------
; os_speaker_off -- Turn off PC speaker
; IN/OUT: Nothing (registers preserved)

os_speaker_off:
	pusha

	in al, 61h
	and al, 0FCh
	out 61h, al

	popa
	ret


; ==================================================================

