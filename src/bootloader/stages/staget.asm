bits 16

org 0x0 ; 0x3000:0x0

start: jmp entryPoint

;*****************
;   Includes
;*****************
    %include "Stdio16.inc"

;*****************
;   Common Variables
;*****************
    welcomeStageTesterMsg db 'Jumped into Stage Tester!... EPK! It worked!', 0x0A, 0xD, 0

entryPoint:
    mov ax, 0x3000
    mov ds, ax
    mov es, ax

    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx

    mov si, welcomeStageTesterMsg
    call print

    mov bx, 0x9000
    mov es, bx
    mov di, 0xFFFF

    mov al, es:[di]
    call dump16Registers

    cli
    hlt
    times 458752 - ($-$$) db 2