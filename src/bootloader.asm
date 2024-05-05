;***********************************
;   The First Bootloader
;       - A simple Bootloader
;
;   Author: Nicolas Almeida Prado
;   Mentor: Mike from BrokenThorn
;***********************************

bits 16

org 0x7c00

; BPB Data Structure
bpbStartingJump:        dw 0 nop
bpbOEMIdentifier:       dw 0 nop
bpbBytesPerSector:      dw 0 nop
bpbSectorsPerCluster:   dw 0 nop
bpbReservedSectors:     dw 0 nop
bpbNumberOfFATs:        dw 0 nop
bpbRootDirEntries:      dw 0 nop
bpbNumberOfSectors:     dw 0 nop
bpbMediaDescType:       dw 0 nop
bpbSectorsPerFAT:       dw 0 nop
bpbSectorsPerTrack:     dw 0 nop
bpbNumberOfHeads:       dw 0 nop
bpbHiddenSectors:       dw 0 nop
bpbNumberOfSectorsE:    dw 0 nop
ebpbDriveNumber:        dw 0 nop
ebpbReserved:           dw 0 nop
ebpbSignature:          dw 0 nop
ebpbVolumeID:           dw 0 nop
ebpbVolumeLabel:        dw 0 nop
ebpbSystemIdentifier:   dw 0 nop


start: jmp loader

;******************************
; Prints a string
;   DS[SI]: 0 terminated string
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

;***********************************
;   Bootloader Entry Point
;***********************************

msg     db      "EPK", 0

loader:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov si, msg
    call print

    cli
    hlt