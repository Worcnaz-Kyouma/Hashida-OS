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
;   Important values
;******************************
; FATSegmentES:           dw 0x4434
; rootDirectoryOffset:    dw 0x0500
rootDirStart:           resb 2
stage2Name              db "STAGE2  BIN"
; stage2Offset:           dw 0x1000

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

ParseLBAtoCHS:
    ; Cylinder is 10 bits, could be a good choice to improve the procedure with that logic, making Sector 6 bits, cause we didnt know that when implemented this.

    ; CX = LBA
    
    ; Sector + Head calculation
    mov ax, cx

    xor dx, dx
    movzx bx, byte [numberOfSectors]
    div bx

    inc dx
    push dx ; Sector
    
    xor dx,dx
    movzx bx, byte [numberOfHeads]
    div bx

    push dx ; Head
    
    ; Cylinder calculation
    mov al, [numberOfHeads]
    mov bl, [numberOfSectors]
    mul bl
    mov bx, ax

    mov ax, cx
    xor dx, dx
    div bx

    pop dx ; Head
    pop cx ; Sector(CL)
    mov ch, al ; Cylinder

    ret

ReadRootDirectory:
    
    mov ax, [bpbRootDirEntries]
    mov bx, 32
    mul bx
    mov bx, 512
    div bx
    inc ax
    push ax ; Root size

    mov cx, [bpbReservedSectors]
    mov al, [bpbNumberOfFATs]
    mov bx, [bpbSectorsPerFAT]
    mul bx

    add cx, ax

    mov [rootDirStart], cx
    call ParseLBAtoCHS

    pop bx

    mov ah, 02h
    mov al, bl
    mov dl, [driveNumber]
    xor bx, bx
    mov es, bx
    mov bx, 0x0500
    int 13h

    ret
FindSecondStage:
    mov cx, [bpbRootDirEntries]

    mov di, 0x0500

    FindSecondStage_loop_findFileSi:
        lea si, stage2Name
        push cx
        push di

        mov cx, 11 ; 11 Repeats
        rep cmpsb

        pop di
        pop cx
        je FindSecondStageDone

        add di, 32

        loop FindSecondStage_loop_findFileSi
        jmp error
FindSecondStageDone:
    ret

LoadFat:
    mov ah, 02h
    mov al, 127
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [driveNumber]
    mov bx, 0x4434
    mov es, bx
    xor bx, bx
    int 13h
    ret

LoadFile:
    call LoadFat
    mov ax, [di + 26] ; First cluster number

    movzx ax, byte [bpbMediaDescType]
    call DumpAxRegister
    
    mov bx, 0x4434
    mov es, bx

    mov ax, es:[0x0]
    call DumpAxRegister
    mov ax, es:[0x2]
    call DumpAxRegister
    mov ax, es:[0x4]
    call DumpAxRegister
    mov ax, es:[0x6]
    call DumpAxRegister
    mov ax, es:[0x8]
    call DumpAxRegister
    mov ax, es:[0x10]
    call DumpAxRegister
    ; LoadFile_loop_ReadFile:
    ;     xor bx, bx
    ;     mov es, bx
        
    ;     cmp ax, 0xFFF8
    ;     jae LoadFile_loopEnd_ReadFile

    ;     cmp ax, 0x0002
    ;     jbe error
    ;     cmp ax, 0xFFF7
    ;     je error

    ;     ; Read sectors of cluster in memory
    ;     mov ax, [bpbRootDirEntries]
    ;     mov bx, 32
    ;     mul ax
    ;     mov bx, [bpbBytesPerSector]
    ;     div bx
    ;     inc ax

    ;     mov cx, [rootDirStart]
    ;     add cx, ax

    ;     mov dx, ax
    ;     sub ax, 2
    ;     xor bx, bx
    ;     mov bl, [bpbSectorsPerCluster]
    ;     mul bx

    ;     add cx, ax

    ;     call ParseLBAtoCHS

    ;     mov ah, 02h
    ;     mov al, [bpbSectorsPerCluster]
    ;     mov dl, [driveNumber]
    ;     xor bx, bx
    ;     mov es, bx
    ;     mov bx, 0x1000
    ;     int 13h

    ;     ; Read the next cluster and save into si
    ;     mov bx, 0x4434
    ;     mov es, bx

    ;     mov si, ax
    ;     mov ax, [si]

    ;     jmp LoadFile_loop_ReadFile
LoadFile_loopEnd_ReadFile:
    ret

pointer_asciiAx db 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0xA, 0xD, 0
DumpAxRegister:
    lea si, pointer_asciiAx
    add si, 18
    mov cx, 19
    PopulateAsciiPointer_loop_PopulateAsciiPointer:
        mov bl, [si]
        cmp bl, 0x20
        je PopulateAsciiPointer_loop_PopulateAsciiPointerEnd

        mov bx, ax
        and bx, 0000000000000001b
        add bl, 00110000b
        mov [si], bl

        shr ax, 1
        PopulateAsciiPointer_loop_PopulateAsciiPointerEnd:
        dec si
        loop PopulateAsciiPointer_loop_PopulateAsciiPointer

    mov si, pointer_asciiAx
    call Print

    ret
;***********************************
;   Bootloader Entry Point
;***********************************

errorMessage   db      "Err", 0

error:
    mov si, errorMessage
    call Print

    cli 
    hlt

loader:

    ; Preparing OS environment
    xor ax, ax
    mov dx, ax
    mov es, ax

    reset:
        call ResetDiskSystem
        jc reset

    ; Read disk parameters
    call PopulateDiskParameters
    jc error

    ; Read root directory in rootDirectoryOffset
    call ReadRootDirectory
    jc error

    ; Return in DI the offset of stage 2 entry
    call FindSecondStage

    ; Read file into stage2Offset
    call LoadFile

    ; Jump to that code
    ; jmp 0x1000

times 510 - ($-$$) db 0
dw 0xAA55