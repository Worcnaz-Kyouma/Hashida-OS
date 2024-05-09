pointer_asciiAxPrologue db 'AX: ', 0
pointer_asciiAx db 20 dup(0)
dumpAxRegister:
    mov dx, pointer_asciiAx
    call populateAsciiDxPointer

    mov si, pointer_asciiAxPrologue
    call print
    mov si, pointer_asciiAx
    call print
    mov si, defaultBreakline
    call print

    ret

populateAsciiDxPointer_pointer_tempArray db 16 dup(0)
populateAsciiDxPointer:
    xor cx, cx
    mov si, populateAsciiDxPointer_pointer_tempArray
    populateAsciiDxPointer_loop_binToAscii:
        mov bx, ax
        and bx, 0000000000000001b
        add bl, 00110000b
        mov [si], bl

        inc si
        inc cx
        shr ax, 1
        cmp cx, 16

        jne populateAsciiDxPointer_loop_binToAscii
    
    mov di, dx
    mov bx, 0
    populateAsciiDxPointer_loop_populateAsciiDxPointer:
        dec si
        dec cx

        mov al, [si]
        mov [di], al

        cmp cx, 0
        jz populateAsciiDxPointer_loopEnd_populateAsciiDxPointer

        inc di

        push ax
        push bx
        push cx
        push dx

        xor dx, dx
        mov ax, cx
        mov bx, 4
        div bx
        cmp dx, 0

        pop dx
        pop cx
        pop bx
        pop ax
        jne populateAsciiDxPointer_loop_populateAsciiDxPointer

        mov al, ' '
        mov [di], al

        inc di
        jmp populateAsciiDxPointer_loop_populateAsciiDxPointer
    populateAsciiDxPointer_loopEnd_populateAsciiDxPointer:

    inc di
    mov bl, 0
    mov [di], bl
    ret