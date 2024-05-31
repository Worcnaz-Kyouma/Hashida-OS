;******************
;   All logic to communicate with the disk in FAT 12 file system, through the BIOS services, precisely the int 13h
;   Functions:
;       - prepareFAT12Params: Prepare extern and intern params necessary to disk communication
;       - parseLBAtoCHS: Parse LBA value to CHS values, already in good registers for int 13h interface (CX[7:6][15:8] = cylinder, CL[5:0] = sector, dh = head)
;       - resetDiskSystem: Reset the disk system... what more you expected?
;       - populateDiskParameters: Populate important params of FAT12 code, like numberOfHeads, numberOfCylinders and numberOfSectors
;******************

%ifndef __FAT12_INC_3444_INCLUDED__
%define __FAT12_INC_3444_INCLUDED__

bits 16

;*****************
;   BPB Copy
;*****************
    bpbOEMIdentifier:       resb 8
    bpbBytesPerSector:      resb 2
    bpbSectorsPerCluster:   resb 1
    bpbReservedSectors:     resb 2
    bpbNumberOfFATs:        resb 1
    bpbRootDirEntries:      resb 2
    bpbNumberOfSectors:     resb 2
    bpbSectorsPerFAT:       resb 2
    bpbHiddenSectors:       resb 4
    bpbNumberOfSectorsE:    resb 4
    ebpbVolumeID:           resb 4
    ebpbVolumeLabel:        resb 11
    ebpbSystemIdentifier:   resb 8
;*****************

;*****************
;   Utility variables
;*****************
    driveNumber:        db 0h
    numberOfHeads:      resb 1
    numberOfCylinders:  resb 2
    numberOfSectors:    resb 1


;*****************

;*****************
;   Functions
;*****************

resetDiskSystem:
    mov ah, 0
    mov dl, [driveNumber]
    int 13h

populateDiskParameters:
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

parseLBAtoCHS:
    ; Function prologue
    push bp
    mov bp, sp
    
    mov cx, [bp + 4] ; CX = LBA

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

    ; Get two high bits of cylinder
    and ax, 0000001100000000b
    shr ax, 2
    or cl, al

    ; Function epilogue
    mov sp, bp
    pop bp

    ret

prepareFAT12Params:
    push bp
    mov bp, sp

    call copyBPB

    mov ax, [bpbNumberOfFATs]
    call dump16Registers

    ; populateDiskParameters

    mov sp, bp
    pop bp
    ret

%macro copy_bpb_param 3
    mov di, %1      ; source BPB param offset
    add di, 0x7c00

    mov si, %2      ; destination BPB param offset
    mov cx, %3      ; size

    call copyBPBParam
%endmacro

copyBPBParam:
    .loop_copyBPBParam:
        mov al, es:[di]
        mov [si], al

        inc di
        inc si
        loop .loop_copyBPBParam
    ret

copyBPB:
    xor bx, bx
    mov es, bx

    copy_bpb_param 0x03, bpbOEMIdentifier,      8
    copy_bpb_param 0x0B, bpbBytesPerSector,     2
    copy_bpb_param 0x0D, bpbSectorsPerCluster,  1
    copy_bpb_param 0x0E, bpbReservedSectors,    2
    copy_bpb_param 0x10, bpbNumberOfFATs,       1
    copy_bpb_param 0x11, bpbRootDirEntries,     2
    copy_bpb_param 0x13, bpbNumberOfSectors,    2
    copy_bpb_param 0x16, bpbSectorsPerFAT,      2
    copy_bpb_param 0x1C, bpbHiddenSectors,      4
    copy_bpb_param 0x20, bpbNumberOfSectorsE,   4
    copy_bpb_param 0x27, ebpbVolumeID,          4
    copy_bpb_param 0x2B, ebpbVolumeLabel,       11
    copy_bpb_param 0x36, ebpbSystemIdentifier,  8

    ret

; loadFAT:

; loadRootDirectory:

; getFileEntry:

; loadClusters:

;*****************

%endif ;__FAT12_INC_3444_INCLUDED__