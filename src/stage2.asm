bits 16

org 0x7c01

start: jmp code

;******************************
; Prints a string
;   DS[SI]: 0 terminated string
;******************************
print:
    mov al, [si]
    inc si
    or al,al
    jz printDone
    mov ah, 0x0e
    int 10h
    jmp print

printDone:
    ret

msg     db      "That is the second stage... EL PSY KONGROO!!!", 0

code:
    xor ax, ax
    mov dx, ax
    mov es, ax

    mov si, msg
    call print