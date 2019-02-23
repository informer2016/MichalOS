; ------------------------------------------------------------------
; MichalOS File Manager
; ------------------------------------------------------------------

	BITS 16
	%INCLUDE "michalos.inc"
	ORG 100h

start:
	call .draw_background

	mov byte [32767], 0
	
	call os_file_selector
	jc near .exit

	mov bx, ax
	mov cx, .screenstring
	call os_drive_letter
	call os_string_join
	mov ax, bx
	
	push ax

	mov bx, cx
	
.commands:
	mov ax, .command_list			; Draw list of disk operations
	mov cx, .helpmsg
	call os_list_dialog

	jc near .clearstack				; User pressed Esc?

	cmp ax, 1						; Otherwise respond to choice
	je near .launch_file
	
	cmp ax, 2
	je near .file_operations
	
	cmp ax, 3
	je near .disk_operations
	
.file_operations:
	mov ax, .file_cmd_list
	mov cx, .helpmsg
	call os_list_dialog
	
	jc .commands
	
	cmp ax, 1
	je near .create_file
	
	cmp ax, 2
	je near .delete_file
	
	cmp ax, 3
	je near .rename_file

	cmp ax, 4
	je near .copy_file
	
	cmp ax, 5
	je near .copy_to_disk
	
	cmp ax, 6
	je near .file_size

.disk_operations:
	mov ax, .disk_cmd_list
	mov cx, .helpmsg
	call os_list_dialog
	
	jc .commands
	
	cmp ax, 1
	je near .change_disk

	cmp ax, 2
	je near .format_disk
	
	cmp ax, 3
	je near .disk_info

.clearstack:
	pop ax
	jmp start
	
.format_disk:
	pop ax
	
	mov ax, .disk_list
	mov bx, .disk_msg
	mov cx, .helpmsg
	call os_list_dialog
	
	jc start
	
	dec al
	
	cmp al, 1
	jle near .format_done
	
	sub al, 2
	add al, 80h
	cmp al, 81h
	jle near .format_done
	
	mov al, 0E0h
	
.format_done:
	call os_change_disk

	mov ax, .delete_confirm_msg
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box
	
	cmp ax, 1
	je start
	
	mov bx, .bootloader
	mov si, blank
	call os_format_disk
	
	jc .disk_error

	jmp start
	
.change_disk:
	pop ax
	
	mov ax, .disk_list
	mov bx, .disk_msg
	mov cx, .helpmsg
	call os_list_dialog
	
	jc start
	
	dec al
	
	cmp al, 1
	jle near .change_done
	
	sub al, 2
	add al, 80h
	cmp al, 81h
	jle near .change_done
	
	mov al, 0E0h
	
.change_done:
	call os_change_disk
	
	mov cx, 1				; Load first disk sector into RAM
	mov dl, [0]
	mov dh, 0
	mov bx, .disk_buffer
	mov ah, 2
	mov al, 1
	stc
	int 13h					; BIOS load sector call

	jc .disk_error

	mov si, .disk_buffer + 36h		; Filesystem string starts here

	mov di, .tmp_string2
	mov cx, 8				; Copy 8 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov si, .tmp_string2
	mov di, .default_fs
	call os_string_compare
	
	jnc .file_error
	
	jmp start
	
.copy_to_disk:	
	call .draw_background

	pop ax
	push ax
	
	call os_get_file_size
	cmp ebx, 28672
	jl .no_copy_disk_change
	
	mov word [.load_segment], 2000h
	mov word [.load_offset], 0000h
	
.no_copy_disk_change:
	push es
	mov es, [.load_segment]
	mov bx, [.load_offset]
	call os_load_file
	pop es
	
	pusha

	mov ax, .disk_list
	mov bx, .disk_msg
	mov cx, .helpmsg
	call os_list_dialog
	
	dec al
	
	cmp al, 1
	jle near .copy
	
	sub al, 2
	add al, 80h
	cmp al, 81h
	jle near .copy
	
	mov al, 0E0h
	
.copy:
	call os_change_disk

	popa
	
	pop ax
	
	push es
	mov es, [.load_segment]
	mov cx, bx
	mov bx, [.load_offset]
	call os_write_file
	pop es

	jnc near .copy_ok
	
	mov word [.load_segment], 1000h
	mov word [.load_offset], 1000h

	call .draw_background
	mov ax, .error_msg
	mov bx, .error_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
.copy_ok:
	mov word [.load_segment], 1000h
	mov word [.load_offset], 1000h

	mov al, [0084h]
	call os_change_disk
	
	jmp start
	
.launch_file:
	mov al, 1
	mov [32767], al
	pop ax
	ret

.create_file:
	pop ax

	call .draw_background

	mov bx, .filename_msg			; Get a filename
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax				; And store it
	mov di, .filename_tmp1
	call os_string_copy

	mov cx, 0				; Create an empty file
	mov bx, 4096
	mov ax, .filename_tmp1
	call os_write_file

	jc near .writing_error

	jmp start

	

.delete_file:
	call .draw_background

	mov ax, .delete_confirm_msg		; Confirm delete operation
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box

	cmp ax, 0
	je .ok_to_delete

	pop ax
	jmp start

.ok_to_delete:
	pop ax
	call os_remove_file
	jc near .writing_error
	jmp start

.rename_file:
	call .draw_background

	pop ax
	
	mov si, ax				; And store it
	mov di, .filename_tmp1
	call os_string_copy

.retry_rename:
	call .draw_background

	mov bx, .filename_msg			; Get second filename
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax				; Store it for later
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, di				; Does the second filename already exist?
	call os_file_exists
	jnc .rename_fail			; Quit out if so

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	call os_rename_file
	jc near .writing_error

	jmp start


.rename_fail:
	mov ax, .err_file_exists
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .retry_rename


.copy_file:
	call .draw_background

	pop ax
	
	mov si, ax				; And store it
	mov di, .filename_tmp1
	call os_string_copy

	call .draw_background

	mov bx, .filename_msg			; Get second filename
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	call os_get_file_size
	cmp ebx, 28672
	jl .no_copy_change
	
	mov word [.load_segment], 2000h
	mov word [.load_offset], 0000h
	
.no_copy_change:
	push es
	mov es, [.load_segment]
	mov cx, [.load_offset]
	call os_load_file
	
	mov cx, bx
	mov bx, [.load_offset]
	mov ax, .filename_tmp2
	call os_write_file
	pop es
	
	jc near .writing_error

	mov word [.load_segment], 1000h
	mov word [.load_offset], 1000h

	jmp start

.no_copy_file_selected:
	jmp start

.file_size:
	call .draw_background

	pop ax
	
	call os_get_file_size

	mov eax, ebx				; Move size into AX for conversion
	call os_32int_to_string
	mov bx, ax				; Size into second line of dialog box...

	mov ax, .size_msg
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp start


.disk_info:
	pop ax
	
	mov cx, 1				; Load first disk sector into RAM
	mov dl, [0]
	mov dh, 0
	mov bx, .disk_buffer

	mov ah, 2
	mov al, 1
	stc
	int 13h					; BIOS load sector call

	jc .disk_error
	
	mov si, .disk_buffer + 2Bh		; Disk label starts here

	mov di, .tmp_string1
	mov cx, 11				; Copy 11 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov si, .disk_buffer + 36h		; Filesystem string starts here

	mov di, .tmp_string2
	mov cx, 8				; Copy 8 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov al, [0]
	
	cmp al, 00h
	je near .detect_floppy
	cmp al, 01h
	je near .detect_floppy
	cmp al, 80h
	je near .detect_hdd
	cmp al, 81h
	je near .detect_hdd
	cmp al, 0E0h
	je near .detect_cddvd
	
	mov bx, .disk_unknown
	
.detect_done:
	mov ax, .disk_type
	mov cx, .dstype_string_full
	call os_string_join

	mov ax, .label_string_text		; Add results to info strings
	mov bx, .tmp_string1
	mov cx, .label_string_full
	call os_string_join

	mov ax, .fstype_string_text
	mov bx, .tmp_string2
	mov cx, .fstype_string_full
	call os_string_join

	mov ax, .fstype_string_full
	call os_string_chomp
	
	mov ax, .fstype_string_full
	mov bx, .fstype_string_start
	call os_string_add
	
	call os_report_free_space
	shr ax, 1						; Divide by 2
	call os_int_to_string
	mov bx, ax
	mov ax, .fstype_string_full
	call os_string_add
	
	mov ax, .fstype_string_full
	mov bx, .fstype_string_ending
	call os_string_add
	
	call .draw_background

	mov ax, .label_string_full		; Show the info
	mov bx, .fstype_string_full
	mov cx, .dstype_string_full
	mov dx, 0
	call os_dialog_box

	jmp start


.writing_error:
	mov word [.load_segment], 1000h
	mov word [.load_offset], 1000h

	call .draw_background
	mov ax, .error_msg
	mov bx, .error_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp start


.exit:
	pusha
	mov al, [0084h]
	call os_change_disk
	popa
	call os_clear_screen
	ret


.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, [57000]
	call os_draw_background
	ret

.detect_floppy:
	mov bx, .disk_floppy
	jmp .detect_done
	
.detect_hdd:
	mov bx, .disk_hdd
	jmp .detect_done
	
.detect_cddvd:
	mov bx, .disk_cdrom
	jmp .detect_done
	
.file_error:
	mov ax, .fs_error
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	mov al, [0084h]
	call os_change_disk
	
	jmp start
	
.disk_error:
	mov ax, .dk_error
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	mov al, [0084h]
	call os_change_disk
	
	jmp start
	
	.command_list			db 'Run application,File operations,Disk operations', 0
	.file_cmd_list			db 'Create file,Delete file,Rename,Copy file,Copy file onto another disk,File information', 0
	.disk_cmd_list			db 'Change disk,Format disk (1.44 MB),Show disk information', 0
	.disk_list				db 'A:\,B:\,C:\,D:\,E:\', 0

	.disk_msg				db 'Choose a disk...', 0
	.helpmsg				db '', 0
	
	.title_msg				db 'MichalOS File Manager', 0
	.footer_msg				db '', 0

	.label_string_text		db 'Disk name: ', 0
	.label_string_full		times 40 db 0
	
	.fstype_string_text		db 'File system: ', 0
	.fstype_string_start	db ' (', 0
	.fstype_string_ending	db ' kB free)', 0
	.fstype_string_full		times 40 db 0
	
	.delete_confirm_msg		db 'Are you sure?', 0

	.filename_msg			db 'Enter a new filename:', 0
	.filename_input			times 15 db 0
	.filename_tmp1			times 15 db 0
	.filename_tmp2			times 15 db 0

	.size_msg				db 'Velikost souboru (v bajtech):', 0

	.error_msg				db 'Error writing to the disk!', 0
	.error_msg2				db '(Disk is read-only/file already exists)?', 0

	.err_file_exists		db 'File with this name already exists!', 0

	.disk_type				db 'Disk type: ', 0
	.disk_floppy			db 'floppy disk', 0
	.disk_hdd				db 'hard drive', 0
	.disk_cdrom				db 'CD/DVD', 0
	.disk_unknown			db 'unknown', 0

	.fs_error				db 'Disk contains an invalid file system!', 0
	
	.dk_error				db 'Disk error!', 0
	
	.default_fs				db 'FAT12   ', 0
	
	.dstype_string_full		times 40 db 0
	
	.tmp_string1			times 15 db 0
	.tmp_string2			times 15 db 0

	.load_segment			dw 2000h
	.load_offset			dw 0000h
	
	.disk_buffer			equ	16384

	.screenstring			times 24 db 0
	
.bootloader:
	Padding				times 3 db 0
	OEMLabel			db "MICHALOS"		; Disk label
	BytesPerSector		dw 512				; Bytes per sector
	SectorsPerCluster	db 1				; Sectors per cluster
	ReservedForBoot		dw 1				; Reserved sectors for boot record
	NumberOfFats		db 2				; Number of copies of the FAT
	RootDirEntries		dw 224				; Number of entries in root dir
											; (224 * 32 = 7168 = 14 sectors to read)
	LogicalSectors		dw 2880				; Number of logical sectors
	MediumByte			db 0F0h				; Medium descriptor byte
	SectorsPerFat		dw 9				; Sectors per FAT
	SectorsPerTrack		dw 18				; Sectors per track (36/cylinder)
	Sides				dw 2				; Number of sides/heads
	HiddenSectors		dd 0				; Number of hidden sectors
	LargeSectors		dd 0				; Number of LBA sectors
	DriveNo				dw 0				; Drive No: 0
	Signature			db 41				; Drive signature: 41 for floppy
	VolumeID			dd 00000000h		; Volume ID: any number
	VolumeLabel			db "MICHALOS   "	; Volume Label: any 11 chars
	FileSystem			db "FAT12   "		; File system type: don't change!

blank:
	
; ------------------------------------------------------------------