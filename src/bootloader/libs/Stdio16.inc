;******************
;   General IO utilities, like print things in screen
;   Functions:
;       - print: prints array of chars that ends with 0, based in SI register
;       - dumpRegisters: dump all 16 bits registers into the screen
;******************

%ifndef __STDIO16_INC_3444_INCLUDED__
%define __STDIO16_INC_3444_INCLUDED__

bits 16

;*****************
;   Utility variables
;*****************

; General
    breakline db 0x0A, 0

; dump16Registers
    dump16Registers_pointer_axPrologue db 'AX: ', 0
    dump16Registers_pointer_bxPrologue db 'BX: ', 0
    dump16Registers_pointer_cxPrologue db 'CX: ', 0
    dump16Registers_pointer_dxPrologue db 'DX: ', 0

; parseAxRegisterIntoAscii
    parseAxRegisterIntoAscii_pointer_asciiRegister db 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x0A, 0xD, 0

;*****************
;   Functions
;*****************

print:
    pusha
    .loop_printing:
    lodsb
    or al,al
    jz .loopEnd_printing
    mov ah, 0x0e
    int 10h
    jmp .loop_printing

    .loopEnd_printing:
        popa
        ret

print_di:
    pusha
    .loop_printing:
    mov al, es:[di]
    inc di
    or al,al
    jz .loopEnd_printing
    mov ah, 0x0e
    int 10h
    jmp .loop_printing

    .loopEnd_printing:
        popa
        ret

dump16Registers:

    ; AX
    mov si, dump16Registers_pointer_axPrologue
    call print
    mov ax, ax
    call parseAxRegisterIntoAscii
    call print

    ; BX
    mov si, dump16Registers_pointer_bxPrologue
    call print
    mov ax, bx
    call parseAxRegisterIntoAscii
    call print

    ; CX
    mov si, dump16Registers_pointer_cxPrologue
    call print
    mov ax, cx
    call parseAxRegisterIntoAscii
    call print

    ; DC
    mov si, dump16Registers_pointer_dxPrologue
    call print
    mov ax, dx
    call parseAxRegisterIntoAscii
    call print

    ret
    

parseAxRegisterIntoAscii:
    pusha
    lea si, parseAxRegisterIntoAscii_pointer_asciiRegister
    add si, 18
    mov cx, 19
    .loop_asciiRegister:
        mov bl, [si]
        cmp bl, 0x20
        je .loopEnd_asciiRegister

        mov bx, ax
        and bx, 0000000000000001b
        add bl, 00110000b
        mov [si], bl

        shr ax, 1
        .loopEnd_asciiRegister:
        dec si
        loop .loop_asciiRegister

    popa
    
    mov si, parseAxRegisterIntoAscii_pointer_asciiRegister
    ret
;

%endif ;__STDIO16_INC_3444_INCLUDED__