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

; Esta no resto da MBR
;times 510 - ($-$$) db 0
;dw 0xAA55