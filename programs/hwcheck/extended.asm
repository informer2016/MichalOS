extendedcpu:
	mov si, name
	call os_print_string
	mov eax, [extendedid]
	cmp eax, 80000004h
	jge cpuname
	mov si, noimp
	call os_print_string
	jmp corecount
	
cpuname:
	mov eax, 80000002h
	cpuid
	mov [p1], eax
	mov [p2], ebx
	mov [p3], ecx
	mov [p4], edx
	
	mov eax, 80000003h
	cpuid
	mov [p5], eax
	mov [p6], ebx
	mov [p7], ecx
	mov [p8], edx
	
	mov eax, 80000004h
	cpuid
	mov [p9], eax
	mov [p10], ebx
	mov [p11], ecx
	mov [p12], edx
	
	mov si, p1
	call os_print_string
	call os_print_newline
	
	mov eax, [basicid]
	cmp eax, 04h
	jge corecount
	mov si, cores
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	mov si, threads
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	jmp freqcount
	
	
corecount:
	mov eax, [basicid]
	cmp eax, 04h
	jge near .start
	mov si, cores
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	mov si, threads
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	jmp freqcount
.start:
	mov eax, 04h
	cpuid
	and eax, 0FC000000h
	ror eax, 26
	inc eax
	push eax
	
	mov si, cores
	call os_print_string
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	
	mov eax, 01h
	cpuid
	mov ebx, edx
	and ebx, 10000000h
	ror ebx, 28
	inc ebx
	mov edx, 0
	pop eax
	mul ebx
	
	mov si, threads
	call os_print_string
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	
freqcount:
	mov eax, [basicid]
	cmp eax, 16h
	jge near .start
	mov si, coreclock
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	mov si, maxclock
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	jmp cpuidcheck
	
.start:
	mov eax, 16h
	cpuid
	call os_32int_to_string
	mov si, coreclock
	call os_print_string
	mov si, ax
	call os_print_string
	mov si, unit_mhz
	call os_print_string
	call os_print_newline

	mov eax, ebx
	call os_32int_to_string
	mov si, maxclock
	call os_print_string
	mov si, ax
	call os_print_string
	mov si, unit_mhz
	call os_print_string
	call os_print_newline

cpuidcheck:	
	mov si, cpuidbas
	call os_print_string
	mov eax, [basicid]
	call os_print_8hex
	mov si, unit_hex
	call os_print_string
	call os_print_newline
	
	mov si, cpuidext
	call os_print_string
	mov eax, [extendedid]
	call os_print_8hex
	mov si, unit_hex
	call os_print_string
	call os_print_newline
	
	
	
extendedcpuend:
	call os_wait_for_key
	jmp main_loop
	
	name		db 'Name            ', 0
	cores		db 'Core count:     ', 0
	threads		db 'Thread count:   ', 0
	cpuidbas	db 'Basic CPUID:    ', 0
	cpuidext	db 'Ext. CPUID:     ', 0
	coreclock	db 'Frequency:      ', 0
	maxclock	db 'Max. frequency: ', 0
