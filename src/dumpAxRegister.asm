; Decrease the size of it, maybe by make a join into these loops
pointer_asciiAxPrologue db 'AX: ', 0
pointer_asciiAx db 20 dup(0)
DumpAxRegister:
    mov dx, pointer_asciiAx
    call PopulateAsciiDxPointer

    mov si, pointer_asciiAxPrologue
    call Print
    mov si, pointer_asciiAx
    call Print
    mov si, defaultBreakline
    call Print

    ret

PopulateAsciiDxPointer_pointer_tempArray db 16 dup(0)
PopulateAsciiDxPointer:
    xor cx, cx
    mov si, PopulateAsciiDxPointer_pointer_tempArray
    PopulateAsciiDxPointer_loop_binToAscii:
        mov bx, ax
        and bx, 0000000000000001b
        add bl, 00110000b
        mov [si], bl

        inc si
        inc cx
        shr ax, 1
        cmp cx, 16

        jne PopulateAsciiDxPointer_loop_binToAscii
    
    mov di, dx
    mov bx, 0
    PopulateAsciiDxPointer_loop_PopulateAsciiDxPointer:
        dec si
        dec cx

        mov al, [si]
        mov [di], al

        cmp cx, 0
        jz PopulateAsciiDxPointer_loopEnd_PopulateAsciiDxPointer

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
        jne PopulateAsciiDxPointer_loop_PopulateAsciiDxPointer

        mov al, ' '
        mov [di], al

        inc di
        jmp PopulateAsciiDxPointer_loop_PopulateAsciiDxPointer
    PopulateAsciiDxPointer_loopEnd_PopulateAsciiDxPointer:

    inc di
    mov bl, 0
    mov [di], bl
    ret