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
;   Includes
;*****************
%include "Utilities.inc"
%include "Stdio16.inc"

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
;   Utility variables
;*****************
    driveNumber:        db 0h
    numberOfHeads:      resb 1
    numberOfCylinders:  resb 2
    numberOfSectors:    resb 1

    dirEndByte:             db 0h
    fileEntryNotFoundMsg:   db 'File entry not found ;~;', 0x0A, 0xD, 0
    fileEntryFoundMsg:      db 'File entry found! :D', 0x0A, 0xD, 0

    loadClustersSucessMsg:      db 'File successfully loaded! :D', 0x0A, 0xD, 0
    loadClustersErrorMsg:       db 'File NOT successfully loaded... we got an error :C', 0x0A, 0xD, 0
    dataRegionStartLBA:         resb 2
    segmentInvalidErrorMsg:    db 'Damn bro, your file is too large for us to handle, passed the 0x9000 segment, sorry :C', 0x0A, 0xD, 0

;*****************
;   Macros
;*****************
%macro copy_bpb_param 3
    mov di, %1      ; source BPB param offset
    add di, 0x7c00

    mov si, %2      ; destination BPB param offset
    mov cx, %3      ; size

    call copyBPBParam
%endmacro

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

    movzx bx, byte [numberOfSectors]
    div_simple ax, bx

    inc dx
    push dx ; Sector
    
    movzx bx, byte [numberOfHeads]
    div_simple ax, bx

    push dx ; Head
    
    ; Cylinder calculation
    mul_simple_8 byte [numberOfHeads], byte [numberOfSectors]
    mov bx, ax

    div_simple cx, bx

    pop dx ; Head
    shl dx, 8
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

    call populateDiskParameters

    push word [bp + 10]   ; FATSegment
    push word [bp + 8]    ; FATOffset 
    call loadFAT

    push word [bp + 6]    ; RootDirSegment
    push word [bp + 4]    ; RootDirOffset 
    call loadRootDirectory

    mov sp, bp
    pop bp
    ret

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

loadFAT:
    push bp
    mov bp, sp

    ; FAT Start
    mov ax, [bpbReservedSectors]

    push ax
    call parseLBAtoCHS
    
    mov ah, 02h
    mov al, [bpbSectorsPerFAT]
    mov dl, [driveNumber]
    mov es, [bp + 6]
    mov bx, [bp + 4]
    int 13h

    mov sp, bp
    pop bp
    ret

loadRootDirectory:
    push bp
    mov bp, sp

    ; RootEntriesCount * 32
    mul_simple [bpbRootDirEntries], 32

    ; (RootEntriesCount * 32) / BytesPerSector
    div_simple ax, [bpbBytesPerSector]
    inc ax

    push ax
    
    ; NumberOfFATs * SectorsPerFAT
    movzx ax, byte [bpbNumberOfFATs]
    mul_simple ax, [bpbSectorsPerFAT]

    ; FAT Start
    add ax, [bpbReservedSectors]

    push ax
    call parseLBAtoCHS

    pop ax

    pop ax                  ; AX -> AL = (RootEntriesCount * 32) / BytesPerSector
    mov ah, 02h
    mov dl, [driveNumber]
    mov es, [bp + 6]
    mov bx, [bp + 4]
    int 13h

    mov sp, bp
    pop bp
    ret

getFileEntry:
    push bp
    mov bp, sp

    ; [bp + 4] -> kernelName
    ; [bp + 6] -> rootDirOffset
    ; [bp + 8] -> rootDirSegment

    mov es, [bp + 8]
    mov di, [bp + 6]
    .loop_NameCompare:
        ; Store di to get it back later, summing 32 to the next entry in the end
        push di

        ; Verify if is the end of dir, decrement di to starting value
        mov si, dirEndByte
        cmpsb
        je .dirEnd
        dec di

        ; Get filename address
        mov si, [bp + 4]
        
        ; Compare names
        mov cx, 11
        rep cmpsb
        je .fileFound

        ; Go to next file entry = (initial di + 32)
        pop di
        add di, 32
        jmp .loop_NameCompare
    
    .dirEnd:
        pop di

        stc
        mov si, fileEntryNotFoundMsg
        call print

        mov sp, bp
        pop bp
        ret
    .fileFound:
        mov si, fileEntryFoundMsg
        call print

        pop di
        mov sp, bp
        pop bp
        ret
loadClusters:
    push bp
    mov bp, sp

    ; [bp + 4]  -> First cluster
    ; [bp + 6]  -> destinationOffset
    ; [bp + 8]  -> destinationSegment
    ; [bp + 10] -> FATOffset
    ; [bp + 12] -> FATSegment

    ; Data Region calculation
    ; RootDir Start
    movzx ax, byte [bpbNumberOfFATs]
    mul_simple ax, [bpbSectorsPerFAT]
    add ax, [bpbReservedSectors]
    push ax

    ; Data Region Start
    mul_simple [bpbRootDirEntries], 32
    div_simple ax, [bpbBytesPerSector]
    pop dx
    add ax, dx
    mov [dataRegionStartLBA], ax

    ; First cluster
    mov dx, [bp + 4]

    ; Starting destination segment and offset into stack
    push word [bp + 6]
    push word [bp + 8]

    .loop_loadingClusters:
        ; Get destination segment and offset from stack
        pop es
        pop di

        ; Test end of file
        cmp dx, 0xFF8
        jae .loopEnd_loadedClusters

        ; Test cluster error
        cmp dx, 0x002
        jbe .loopEnd_clusterError
        cmp dx, 0xFF7
        je .loopEnd_clusterError
    
        ; Load current cluster
        push dx             ; cluster
        push di             ; destinationOffset
        push es             ; destinationSegment
        call loadCluster    ; Returns the next values in ES, DI and output the current cluster into dx

        ; Next destination segment and offset into stack
        push di
        push es

        push dx             ; cluster
        push word [bp + 10] ; FATOffset
        push word [bp + 12] ; FATSegment
        call getNextCluster ; Returns the next cluster into dx
        add sp, 6

        jmp .loop_loadingClusters

    .loopEnd_loadedClusters
    mov si, loadClustersSucessMsg
    call print

    mov sp, bp
    pop bp
    ret

    .loopEnd_clusterError
    stc
    mov si, loadClustersErrorMsg
    call print

    mov sp, bp
    pop bp
    ret

loadCluster:
    push bp
    mov bp, sp

    ; [bp + 4]  -> destinationSegment
    ; [bp + 6]  -> destinationOffset
    ; [bp + 8]  -> cluster

    ; Verify if is valid segment
    mov bx, [bp + 4]
    cmp bx, 0xA000
    jae .segmentInvalidError
    cmp bx, 0x2000
    jbe .segmentInvalidError

    ; Cluster to first sector LBA
    mov ax, [bp + 8]
    sub ax, 2
    movzx dx, byte [bpbSectorsPerCluster]
    mul_simple ax, dx
    add ax, [dataRegionStartLBA]

    push ax
    call parseLBAtoCHS

    ; Load cluster
    mov ah, 02h
    mov al, [bpbSectorsPerCluster]
    mov dl, [driveNumber]
    mov es, [bp + 4]
    mov bx, [bp + 6]
    int 13h

    ; Calculate next address
    mul_simple [bpbSectorsPerCluster], [bpbBytesPerSector]
    add bx, ax
    mov di, bx
    jc .segmentEnd

    mov dx, [bp + 8]   ; Current cluster

    mov sp, bp
    pop bp
    ret

    ; End of current loading segment, get next segment summing 0x1000
    .segmentEnd:
    mov bx, es
    add bx, 0x1000
    mov es, bx
    xor di, di

    mov dx, [bp + 8]   ; Current cluster

    mov sp, bp
    pop bp
    ret

    ; Invalid segment, throw error
    .segmentInvalidError:
    stc
    mov si, segmentInvalidErrorMsg
    call print

    mov sp, bp
    pop bp
    ret

getNextCluster:
    push bp
    mov bp, sp

    ; [bp + 4] -> FATSegment
    ; [bp + 6] -> FATOffset
    ; [bp + 8] -> cluster

    ; Load FAT Segment
    mov es, [bp + 4]

    ; Get FAT offset of next cluster into di
    mul_simple [bp + 8], 3
    div_simple ax, 2
    mov di, ax

    ; Get FAT index parity
    div_simple [bp + 8], 2
    cmp dx, 0
    je .evenFATIndex

    ; Parse next FAT cluster using index parity

    ; Odd index
    mov ax, es:[di]
    shr ax, 4
    mov dx, ax

    mov sp, bp
    pop bp
    ret

    ; Even index
    .evenFATIndex
    mov ax, es:[di]
    and ax, 0x0FFF
    mov dx, ax

    mov sp, bp
    pop bp
    ret

;*****************

%endif ;__FAT12_INC_3444_INCLUDED__