;******************
;   General utilities, like print things in screen
;   Functions:
;       - print: prints array of chars that ends with 0, based in SI register
;       - dumpRegisters: dumb all 16 bits registers into the screen
;******************

%ifndef __STDIO16_INC_3444_INCLUDED__
%define __STDIO16_INC_3444_INCLUDED__

bits 16

print:
    lodsb
    or al,al
    jz .printDone
    mov ah, 0x0e
    int 10h
    jmp print

    .printDone:
        ret

%endif ; __STDIO16_INC_3444_INCLUDED__