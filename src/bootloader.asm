;***********************************
;   The First Bootloader
;       - A simple Bootloader
;
;   Author: Nicolas Almeida Prado
;   Mentor: Mike from BrokenThorn, and much more resources
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
numberOfHeads:      resb 1 ;10000010 10001010
numberOfCylinders:  resb 2 ;
numberOfSectors:    resb 1 ; 10101100 00001000

;******************************
;   Important addresses
;******************************
FATSegmentES:           db 0x0000
rootDirectoryOffset:    db 0x0200

;******************************
; Functions
;******************************
Print:
    lodsb
    or al,al
    jz PrintDone
    mov ah, 0x0e
    int 10h
    jmp Print
PrintDone:
    ret

ResetDiskSystem:
    mov ah, 0
    mov dl, 80h
    int 13h

PopulateDiskParameters:
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

ClearRegisters:
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx

    xor si, si
    xor di, di

    ret

pointer_asciiAxPrologue db 'AX: ', 0
pointer_asciiAx db 20 dup(0)
dumpAxRegister:
    mov dx, pointer_asciiAx
    call populateAsciiDxPointer

    mov si, pointer_asciiAxPrologue
    call Print
    mov si, pointer_asciiAx
    call Print
    mov si, defaultBreakline
    call Print

    ret

populateAsciiDxPointer_pointer_tempArray db 16 dup(0)
populateAsciiDxPointer:
    xor cx, cx
    mov si, populateAsciiDxPointer_pointer_tempArray
    populateAsciiDxPointer_loop_binToAscii:
        mov bx, ax
        and bx, 0000000000000001b
        add bl, 00110000b
        mov [si], bl

        inc si
        inc cx
        shr ax, 1
        cmp cx, 16

        jne populateAsciiDxPointer_loop_binToAscii
    
    mov di, dx
    mov bx, 0
    populateAsciiDxPointer_loop_populateAsciiDxPointer:
        dec si
        dec cx

        mov al, [si]
        mov [di], al

        cmp cx, 0
        jz populateAsciiDxPointer_loopEnd_populateAsciiDxPointer

        inc di

        push ax
        push bx
        push cx
        push dx

        xor dx, dx
        mov ax, cx
        mov bx, 4
        div bx
        cmp dx, 0

        pop dx
        pop cx
        pop bx
        pop ax
        jne populateAsciiDxPointer_loop_populateAsciiDxPointer

        mov al, ' '
        mov [di], al

        inc di
        jmp populateAsciiDxPointer_loop_populateAsciiDxPointer
    populateAsciiDxPointer_loopEnd_populateAsciiDxPointer:

    inc di
    mov bl, 0
    mov [di], bl
    ret

;***********************************
;   Bootloader Entry Point
;***********************************

welcomeMessage     db      "EPK!!!", 0xA, 0xD, 0
defaultBreakline   db      0xA, 0xD, 0

loader:
    ; Preparing OS environment
    call ClearRegisters

    reset:
        call ResetDiskSystem
        jc reset

    ; Read disk parameters
    ; call PopulateDiskParameters

    xor ax, ax
    mov es, ax
    mov di, ax
    mov ah, 08h
    mov dl, 80h
    int 13h

    pusha
    mov ax, cx
    call dumpAxRegister
    popa
    
    pusha
    xor ax, ax
    mov al, dh
    call dumpAxRegister
    popa

    pusha
    xor ax, ax
    mov al, cl
    call dumpAxRegister
    popa

    cli
    hlt

times 446 - ($-$$) db 0

;***********************************
;   MBR: Partition entry nº1, will be populated
;   in the build of the system
;***********************************
peStatus:           resb 1
peFirstSectorCHS:   resb 3
peType:             resb 1
peLastSectorCHS:    resb 3
peFirstSectorLBA:   resb 4
peNumberOfSectors:  resb 4

;qemu-system-i386                                 \
;  -accel tcg,thread=single                       \
;  -cpu core2duo                                  \
;  -m 128                                         \
;  -no-reboot                                     \
;  -drive format=raw,media=cdrom,file=hashidaOS.iso    \
;  -serial stdio                                  \
;  -smp 1                                         \
;  -usb                                           \
;  -vga std