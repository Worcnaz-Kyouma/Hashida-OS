;***********************************
;   The First Bootloader
;       - A simple Bootloader
;
;   Author: Nicolas Almeida Prado
;   Mentor: Mike from BrokenThorn, and much more resources
;***********************************

;***********************************
;   Sucess logs
;       - 18/05/2024: First JMP to the second stage
;***********************************

bits 16

org 0x7c00 ; 0x0:0x7c00

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
rootDirStart:   resb 2
dataReg:        resb 2
stage2Name      db "STAGE2  BIN"

; FATSegment:             dw 0x4434
; rootDirectoryOffset:    dw 0x0500

; stage2Offset:           dw 0x0
; stage2Segment:          dw 0x8000


;******************************
; Functions
;******************************
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

        mov cx, 11
        rep cmpsb

        pop di
        pop cx
        je FindSecondStageDone

        add di, 32

        loop FindSecondStage_loop_findFileSi
        jmp error
FindSecondStageDone:
    ret

LoadFile:
    ; Load fat
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

    ; Read sectors of cluster in memory
    mov ax, [bpbRootDirEntries]
    mov bx, 32
    xor dx, dx
    mul bx
    mov bx, [bpbBytesPerSector]
    xor dx, dx
    div bx

    mov dx, [rootDirStart]
    add dx, ax
    mov [dataReg], dx

    mov dx, [di + 26] ; First cluster number

    xor cx, cx
    LoadFile_loop_ReadFile: 
        cmp dx, 0xFF8
        jae LoadFile_loopEnd_ReadFile

        cmp dx, 0x002
        jbe error
        cmp dx, 0xFF7
        je error

        push dx
        push cx

        mov ax, dx

        sub ax, 2

        movzx bx, byte [bpbSectorsPerCluster]
        xor dx, dx
        mul bx
        mov cx, ax

        add cx, [dataReg]
        mov ax, cx

        call ParseLBAtoCHS

        mov ah, 02h
        mov al, [bpbSectorsPerCluster]
        mov dl, [driveNumber]
        mov bx, 0x8000
        mov es, bx
        pop bx ; That limit the second stage just to 65536 bytes (128 sectors, cause 0x0 point to the first one, more than that result in overflow here and load didnt work anymore)
        int 13h
        jc error

        mov cx, bx

        mov ax, [bpbSectorsPerCluster]
        mov bx, [bpbBytesPerSector]
        mul bx

        add cx, ax

        pop ax
        push cx
        push ax

        mov bx, 0x4434
        mov es, bx

        mov bx, 3
        xor dx, dx
        mul bx
        mov bx, 2
        xor dx, dx
        div bx
        mov di, ax

        pop ax
        mov bx, 2
        xor dx, dx
        div bx

        pop cx
        mov ax, es:[di]
        cmp dx, 0
        je evenFATIndex

        shr ax, 4
        mov dx, ax
        jmp LoadFile_loop_ReadFile

        evenFATIndex:
        and ax, 0x0fff
        mov dx, ax
        jmp LoadFile_loop_ReadFile
LoadFile_loopEnd_ReadFile:
    ret

;***********************************
;   Bootloader Entry Point
;***********************************

errorMessage   db      "Er", 0

error:
    mov si, errorMessage

    Print:
        lodsb
        or al,al
        jz PrintDone
        mov ah, 0x0e
        int 10h
        jmp Print
    PrintDone:

    cli 
    hlt

loader:
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

    jmp 0x8000:0

times 510 - ($-$$) db 0
dw 0x55AA