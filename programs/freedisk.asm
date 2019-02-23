; ------------------------------------------------------------------
; MichalOS Free Space Checker
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	call os_report_free_space
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_wait_for_key
	ret
