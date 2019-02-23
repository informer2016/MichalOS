os_enable_debugger:
	pusha
	pushf						; Set the trap flag (for debugging)
	mov bp, sp
	or word [ss:bp + 0], 0100h
	mov byte [debugger_running], 1
	popf
	popa
	ret
	
os_disable_debugger:
	pusha
	pushf						; Clear the trap flag (for debugging)
	mov bp, sp
	and word [ss:bp + 0], 0FEFFh
	popf
	popa
	mov byte [debugger_running], 0
	ret
	
	debugger_running	db 0
	
; -----------------------------------------------------------------
; MichalOS Debugger

debugger:
	pusha
	push ds
	push es

	; Do your debugging here

.exit:
	mov bp, sp				; Restore the trap flag
	add bp, 10
	mov bp, [ss:bp]
	add bp, 4
	or word [ss:bp], 0100h

	pop es
	pop ds
	popa
	iret