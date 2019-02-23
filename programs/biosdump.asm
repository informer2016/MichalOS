; ------------------------------------------------------------------
; MichalOS BIOS Dumper
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	mov ax, 0F000h
	mov es, ax
	mov ax, .filename
	mov bx, 0
	mov cx, 65535
	call os_write_file	
	ret

	.filename	db 'BIOS.DAT', 0