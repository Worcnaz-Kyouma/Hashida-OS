;***********************************
;   The First Bootloader
;       - A simple Bootloader
;
;   Author: Nicolas Almeida Prado
;   Mentor: Mike from BrokenThorn
;***********************************

bits 16

org 0x7c00

; 60 bits BPB Data, more 2 to align boot code
; INTERESTING! The fact the IP increase before the execution of the next code, i need to make more 2 offset to align the code
times 62 db 20h
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