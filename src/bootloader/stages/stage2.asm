bits 16

org 0x0 ; 0x8000:0x0

start: jmp entryPoint

;*****************
;   Includes
;*****************
    %include "Utilities.inc"
    %include "Stdio16.inc"
    ; %include "FAT12.inc"
;*****************

;*****************
;   Common Variables
;*****************
    welcomeStage2Msg db 'Jumped into Stage 2!... EPK', 0x0A, 0xD, 0
    ; kernelName db 'KERNEL  BIN'
    kernelName db 'STAGE2  BIN'

    kernelOffset:    resb 2
    kernelSegment:   resb 2

;*****************
;   FAT12 Params
;*****************
    rootDirOffset:  dw 0x0
    rootDirSegment: dw 0x9000

    FATOffset:      dw 0x0
    FATSegment:     dw 0x1000

;*****************
;   Code
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

    ; B U G
    mov bx, 0x8000
    mov es, bx
    mov di, 1024
    mov ax, es:[di]
    call dump16Registers

    cli
    hlt   
    times 2048 - ($-$$) db 2