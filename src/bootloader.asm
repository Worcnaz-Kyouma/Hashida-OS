;***********************************
;   The First Bootloader
;       - A simple Bootloader
;
;   Author: Nicolas Almeida Prado
;   Mentor: Mike from BrokenThorn
;***********************************

bits 16

org 0x7c00

start: jmp loader

;***********************************
;   OEM Parameter Block
;***********************************
;; bpbOEM                  db "Hashida "

;; bpbBytesPerSector:      DW 512
;; bpbSectorsPerCluster:   DB 1
;; bpbReservedSectors:     DW 1
;; bpbNumberOfFATs:        DB 2
;; bpbRootEntries:         DW 224
;; bpbTotalSectors:        DW 2880
;; bpbMedia:               DB 0xF0
;; bpbSectorsPerFAT:       DW 9
;; bpbSectorsPerTrack:     DW 18
;; bpbHeadsPerCylinder:    DW 2
;; bpbHiddenSectors:       DD 0
;; bpbTotalSectorsBig:     DD 0
;; bsDriveNumber:          DB 0
;; bsUnused:               DB 0
;; bsExtBootSignature:     DB 0x29
;; bsSerialNumber:         DD 0xa0a1a2a3
;; bsVolumeLabel:          DB "MOS FLOPPY "
;; bsFileSystem:           DB "FAT12   "

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

msg     db      "Welcome to Hashida OS!", 0


loader:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov si, msg
    call print

    cli
    hlt

times 510 - ($-$$) db 0
dw 0xAA55