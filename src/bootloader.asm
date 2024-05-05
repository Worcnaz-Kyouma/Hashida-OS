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
bpbStartingJump:        db 3 dup (0)    ;3
bpbOEMIdentifier:       dq 0            ;8
bpbBytesPerSector:      dw 0            ;2
bpbSectorsPerCluster:   db 0            ;1
bpbReservedSectors:     dw 0            ;2
bpbNumberOfFATs:        db 0            ;1
bpbRootDirEntries:      dw 0            ;2
bpbNumberOfSectors:     dw 0            ;2
bpbMediaDescType:       db 0            ;1
bpbSectorsPerFAT:       dw 0            ;2
bpbSectorsPerTrack:     dw 0            ;2
bpbNumberOfHeads:       dw 0            ;2
bpbHiddenSectors:       dd 0            ;4
bpbNumberOfSectorsE:    dd 0            ;4
ebpbDriveNumber:        db 0            ;1
ebpbReserved:           db 0            ;1
ebpbSignature:          db 0            ;1
ebpbVolumeID:           dd 0            ;4
ebpbVolumeLabel:        db 11 dup (0)   ;11
ebpbSystemIdentifier:   dq 0            ;8

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