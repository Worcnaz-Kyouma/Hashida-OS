bits 16

pointer_asciiAxPrologue db 'AX: ', 0
pointer_asciiAx db 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0
DumpAxRegister:
    lea si, pointer_asciiAx
    add si, 18
    mov cx, 19
    PopulateAsciiPointer_loop_PopulateAsciiPointer:
        mov bl, [si]
        cmp bl, 0x20
        je PopulateAsciiPointer_loop_PopulateAsciiPointerEnd

        mov bx, ax
        and bx, 0000000000000001b
        add bl, 00110000b
        mov [si], bl

        shr ax, 1
        PopulateAsciiPointer_loop_PopulateAsciiPointerEnd:
        dec si
        loop PopulateAsciiPointer_loop_PopulateAsciiPointer

    mov si, pointer_asciiAxPrologue
    call Print
    mov si, pointer_asciiAx
    call Print

    ret