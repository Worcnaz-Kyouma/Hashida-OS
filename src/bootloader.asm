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
driveNumber:        db 0h
numberOfHeads:      resb 1
numberOfCylinders:  resb 2
numberOfSectors:    resb 1

;******************************
;   Important addresses
;******************************
FATSegmentES:           dw 0x0000
rootDirectoryOffset:    dw 0x0200

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
    mov dl, [driveNumber]
    int 13h

PopulateDiskParameters:
    xor ax, ax
    mov es, ax
    mov di, ax
    mov ah, 08h
    mov dl, [driveNumber]
    int 13h

    mov bl, cl
    and cl, 00111111b
    mov [numberOfSectors], cl

    mov cl, bl
    mov [numberOfCylinders], ch
    xor ch, ch
    and cl, 11000000b
    shl cx, 2
    inc cx
    or [numberOfCylinders], cx

    inc dh
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

ParseLBAtoCHS:
    mov cx, ax ;CX = LBA
    
    xor ax, ax
    mov al, [numberOfHeads]
    xor bx, bx
    mov bl, [numberOfSectors]
    mul bx
    mov bx, ax

    mov ax, cx
    xor dx, dx
    
    div bx
    push ax ; Cylinder

    mov ax, cx
    xor dx, dx

    xor bx, bx
    mov bl, [numberOfSectors]
    div bx

    xor dx, dx

    xor bx, bx
    mov bl, [numberOfHeads]
    div bx

    push dx ; Head

    mov ax, cx

    xor dx, dx
    xor bx, bx
    mov bl, [numberOfSectors]
    div bx 
    
    inc dx

    push dx ; Sector

    pop cx
    pop dx
    pop ax
    mov ch, al

    ret
;***********************************
;   Bootloader Entry Point
;***********************************

welcomeMessage     db      "Welcome to HashidaOS, my build from scratch operational system. El Psy Kongroo.", 0xA, 0xD, 0
defaultBreakline   db      0xA, 0xD, 0

loader:
    ; ds:welcomeMessage
    mov si, welcomeMessage
    call Print

    ; Preparing OS environment
    call ClearRegisters

    reset:
        call ResetDiskSystem
        jc reset

    ; Read disk parameters
    call PopulateDiskParameters

    mov dx, [bpbHiddenSectors]

    mov ax, [bpbSectorsPerFAT]
    mov bx, [bpbNumberOfFATs]
    mul bx

    add dx, ax

    mov ax, [bpbRootDirEntries]
    mov bx, 32
    mul bx
    mov bx, 512
    div bx
    inc ax

    mov bx, ax
    mov ax, dx ; Root LBA
    mov dx, bx ; Root size

    call ParseLBAtoCHS

    mov ah, 02h
    mov al, dl
    mov dl, [driveNumber]
    mov bx, 0x7c00
    mov es, bx
    mov bx, [rootDirectoryOffset]
    int 13h

    cli
    hlt

times 510 - ($-$$) db 0
dw 0xAA55