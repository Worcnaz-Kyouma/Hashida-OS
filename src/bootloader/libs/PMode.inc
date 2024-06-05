;******************
;   All the logic to manage protected mode stuffs, like GDT and GDTR
;   Functions:
;       
;******************

%ifndef __PMODE_INC_3444_INCLUDED__
%define __PMODE_INC_3444_INCLUDED__

bits 16

;*****************
;   Includes
;*****************
    %include "Stdio16.inc"

;*****************
;   Utility variables
;*****************
    numberOfDescriptors:    dw 0
    GDTPointer:
        dw 0
        dd 0

;*****************
;   Macros
;*****************
%macro create_descriptor 7
    push byte %7 ; High 8 bits Base
    push byte %6 ; 4 bits Flags[0-3]
    push byte %5 ; 4 bits Limit[0-3]
    push byte %4 ; 8 bits Access
    push byte %3 ; Mid 8 bits Base
    push word %2 ; Low 16 bits Base
    push word %1 ; Low 16 bits Limit
    call createDescriptor
%endmacro

;*****************
;   Functions
;*****************
preparePMODE:
    push bp
    mov bp, sp

    ; [bp + 4]  -> GDT Offset
    ; [bp + 6]  -> GDT Segment

    push word [bp + 6]
    push word [bp + 4]
    call createGDT

    push word [bp + 6]
    push word [bp + 4]
    call loadGDTR

    mov sp, bp
    pop bp
    ret
createGDT:
    push bp
    mov bp, sp

    ; [bp + 4]  -> GDT Offset
    ; [bp + 6]  -> GDT Segment

    mov di, [bp + 4]
    mov es, [bp + 6]
    
    create_descriptor 0x0000, 0x0000, 0x00, 00000000b, 0000b, 0000b, 0x00
    create_descriptor 0xFFFF, 0x0000, 0x00, 10011010b, 1111b, 1100b, 0x00
    create_descriptor 0xFFFF, 0x0000, 0x00, 10010010b, 1111b, 1100b, 0x00

    mov [numberOfDescriptors], dword 0x3

    mov sp, bp
    pop bp
    ret

createDescriptor:
    push bp
    mov bp, sp

    ; [bp + 4]  -> Low 16 bits Limit
    ; [bp + 6]  -> Low 16 bits Base
    ; [bp + 8]  -> Mid 8 bits Base
    ; [bp + 10] -> 8 bits Access
    ; [bp + 12] -> 8 bits Limit[0-3]
    ; [bp + 14] -> 8 bits Flags[0-3]
    ; [bp + 16] -> High 8 bits Base

    ; Low 16 bits limit
    mov dx, [bp + 4]
    mov es:[di], dx
    add di, 2

    ; Low 16 bits base
    mov dx, [bp + 6]
    mov es:[di], dx
    add di, 2

    ; Mid 8 bits base
    movzx dx, byte [bp + 8]
    mov es:[di], dl
    add di, 1

    ; 8 bits Access
    movzx dx, byte [bp + 10]
    mov es:[di], dl
    add di, 1

    ; 4 bits Flags[4-7] 4 High Limit[0-3]
    movzx ax, byte [bp + 12]
    and al, 0x0F
    movzx dx, byte [bp + 14]
    shl dl, 4
    or dl, al
    mov es:[di], dl
    add di, 1

    ; High 8 bits Base
    movzx dx, byte [bp + 16]
    mov es:[di], dl
    add di, 1

    mov sp, bp
    pop bp
    ret

loadGDTR:
    push bp
    mov bp, sp

    ; [bp + 4]  -> GDT Offset
    ; [bp + 6]  -> GDT Segment

    ; Calculate and save the size of GDT
    mul_simple [numberOfDescriptors], 64
    dec ax
    mov [GDTPointer], ax

    ; Calculate and save the GDT base address
    movzx eax, word [bp + 6]
    movzx edx, word [bp + 4]
    shl eax, 4
    add eax, edx
    mov [GDTPointer + 2], eax

    cli
    lgdt [GDTPointer]
    sti

    mov sp, bp
    pop bp
    ret
;*****************

%endif ;__PMODE_INC_3444_INCLUDED__