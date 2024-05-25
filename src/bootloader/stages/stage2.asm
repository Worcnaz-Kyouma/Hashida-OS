bits 16

org 0x0 ; 0x8000:0x0

start: jmp entryPoint

;*****************
;   Includes
;*****************
    %include "Stdio16.inc"
;*****************

;*****************
;   Variables
;*****************
    welcomeStage2Msg db 'Jumped into Stage 2!... EPK', 0x0A, 0xD, 0
;*****************

prepareStage2:
    mov ax, 0x8000
    mov ds, ax
    mov es, ax

    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx

    ret

entryPoint:

    call prepareStage2

    mov si, welcomeStage2Msg
    call print



    cli
    hlt