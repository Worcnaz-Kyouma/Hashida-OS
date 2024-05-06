;***********************************
;   The First Bootloader
;       - A simple Bootloader
;
;   Author: Nicolas Almeida Prado
;   Mentor: Mike from BrokenThorn
;***********************************

bits 16

org 0x7c00

;***********************************
;   BIOS Parameter Block(BPB), will be populated
;   in the build of the system
;***********************************
bpbStartingJump:        resb 3         ; Reserve 3 bytes
bpbOEMIdentifier:       resb 8         ; Reserve 8 bytes
bpbBytesPerSector:      resb 2         ; Reserve 2 bytes (1 word)
bpbSectorsPerCluster:   resb 1         ; Reserve 1 byte
bpbReservedSectors:     resb 2         ; Reserve 2 bytes (1 word)
bpbNumberOfFATs:        resb 1         ; Reserve 1 byte
bpbRootDirEntries:      resb 2         ; Reserve 2 bytes (1 word)
bpbNumberOfSectors:     resb 2         ; Reserve 2 bytes (1 word)
bpbMediaDescType:       resb 1         ; Reserve 1 byte
bpbSectorsPerFAT:       resb 2         ; Reserve 2 bytes (1 word)
bpbSectorsPerTrack:     resb 2         ; Reserve 2 bytes (1 word)
bpbNumberOfHeads:       resb 2         ; Reserve 2 bytes (1 word)
bpbHiddenSectors:       resb 4         ; Reserve 4 bytes (1 dword)
bpbNumberOfSectorsE:    resb 4         ; Reserve 4 bytes (1 dword)
ebpbDriveNumber:        resb 1         ; Reserve 1 byte
ebpbReserved:           resb 1         ; Reserve 1 byte
ebpbSignature:          resb 1         ; Reserve 1 byte
ebpbVolumeID:           resb 4         ; Reserve 4 bytes (1 dword)
ebpbVolumeLabel:        resb 11        ; Reserve 11 bytes
ebpbSystemIdentifier:   resb 8         ; Reserve 8 bytes

start: jmp loader

;******************************
;   Disk parameters(int 13h, AH=08h)
;******************************
numberOfHeads:      resb 1
numberOfCylinders:  resb 2
numberOfSectors:    resb 1

;******************************
; Functions
;******************************
print:
    lodsb
    or al,al
    jz printDone
    mov ah, 0x0e
    int 10h
    jmp print
printDone:
    ret

populateDiskParameters:
    xor ax, ax
    mov es, ax
    mov di, ax
    mov ah, 08h
    mov dl, 80h
    int 13h

    mov bl, cl
    and cl, 00111111b
    mov [numberOfSectors], cl

    mov cl, bl
    mov [numberOfCylinders], ch
    xor ch, ch
    and cl, 11000000b
    shl cx, 2
    or [numberOfCylinders], cx

    mov [numberOfHeads], dh

    ret

clearRegisters:
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx

    xor si, si
    xor di, di

    ret

pointer_asciiAxPrologue db 'AX: ', 0
pointer_asciiAx db 20 dup(0)

pointer_asciiBxPrologue db 'BX: ', 0
pointer_asciiBx db 20 dup(0)

pointer_asciiCxPrologue db 'CX: ', 0
pointer_asciiCx db 20 dup(0)

pointer_asciiDxPrologue db 'DX: ', 0
pointer_asciiDx db 20 dup(0)
dumpGeneralRegisters:
    call populateAsciiAx
    call populateAsciiBx
    call populateAsciiCx
    call populateAsciiDx

    mov si, pointer_asciiAxPrologue
    call print
    mov si, pointer_asciiAx
    call print
    mov si, defaultBreakline
    call print

    mov si, pointer_asciiBxPrologue
    call print
    mov si, pointer_asciiBx
    call print
    mov si, defaultBreakline
    call print

    mov si, pointer_asciiCxPrologue
    call print
    mov si, pointer_asciiCx
    call print
    mov si, defaultBreakline
    call print

    mov si, pointer_asciiDxPrologue
    call print
    mov si, pointer_asciiDx
    call print
    mov si, defaultBreakline
    call print

populateAsciiAx_pointer_tempArray db 16 dup(0)
populateAsciiAx:
    xor cx, cx
    mov si, populateAsciiAx_pointer_tempArray
    populateAsciiAx_loop_binToAscii:
        shr ax, cx
        mov bx, ax
        and bx, 0000000000000001b
        add bl, 00110000b
        mov [si], bl

        inc si
        inc cx
        cmp cx, 16
        jne populateAsciiAx_loop_binToAscii
    
    mov dx, pointer_asciiAx
    mov bx, 0
    populateAsciiAx_loop_populateAsciiAx:
        dec si
        dec cx
        js populateAsciiAx_loopEnd_populateAsciiAx

        mov al, [si]
        mov [dx], al

        cmp cx, 0
        jz populateAsciiAx_loopEnd_populateAsciiAx

        inc dx

        push ax
        push bx
        push cx
        push dx
        xor dx, dx
        mov ax, cx
        mov bx, 4
        div bx
        cmp dx, 0
        pop ax
        pop bx
        pop cx
        pop dx
        jne populateAsciiAx_loop_populateAsciiAx

        mov al, ' '
        mov [dx], al

        inc dx
        jmp populateAsciiAx_loop_populateAsciiAx
    populateAsciiAx_loopEnd_populateAsciiAx:
    mov bx, 0
    mov [dx], bx
    ret

;***********************************
;   Bootloader Entry Point
;***********************************

welcomeMessage     db      "EPK!!!", 0
defaultBreakline   db      "\n", 0

loader:
    ; Preparing OS environment
    call clearRegisters

    ; Read disk parameters
    call populateDiskParameters

    ; Test
    call dumpGeneralRegisters

    mov si, msg
    call print

    cli
    hlt

; Test populateAsciiAx
global _start

section .data
populateAsciiAx_pointer_tempArray times 32 db 0
pointer_asciiAxPrologue db 'AX: ', 0
pointer_asciiAx times 40 db 0
teste db 'teste', 0

section .text

populateAsciiAx:
    xor ecx, ecx
    mov esi, populateAsciiAx_pointer_tempArray
    
    populateAsciiAx_loop_binToAscii:
        mov ebx, eax
        and ebx, 00000000000000000000000000000001b
        add bl, 00110000b
        mov [esi], bl

        inc esi
        inc cl
        shr eax, 1
        cmp cl, 32
    	
        jne populateAsciiAx_loop_binToAscii
        
    mov edx, pointer_asciiAx
    mov ebx, 0
    populateAsciiAx_loop_populateAsciiAx:
        dec esi
        dec ecx

        mov al, [esi]
        mov [edx], al

        cmp ecx, 0
        je populateAsciiAx_loopEnd_populateAsciiAx
		
        inc edx
        
        push eax
        push ebx
        push ecx
        push edx
        
        xor edx, edx
        mov eax, ecx
        mov ebx, 4
        div ebx
        cmp edx, 0
        
        pop edx
        pop ecx
        pop ebx
        pop eax
        jne populateAsciiAx_loop_populateAsciiAx

        mov al, ' '
        mov [edx], al

        inc edx
        jmp populateAsciiAx_loop_populateAsciiAx
    populateAsciiAx_loopEnd_populateAsciiAx:
	
	inc edx
    mov bl, 0
    mov [edx], bl
    
    ret

_start:
	mov eax, 10111010001110011011101000111001b
	call populateAsciiAx
	
	pusha
    mov eax, 4
    mov ebx, 1
    mov ecx, pointer_asciiAx
    mov edx, 40
    int 0x80
    popa  

exit:
	mov		eax, 01h		; exit()
	xor		ebx, ebx		; errno
	int		80h