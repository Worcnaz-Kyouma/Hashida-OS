parseAxRegisterIntoAscii_pointer_asciiRegister_2 db 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x20,0x00, 0x00, 0x00, 0x00, 0x20,0x00, 0x00, 0x00, 0x00, 0x20,0x00, 0x00, 0x00, 0x00, 0x20,0x00, 0x00, 0x00, 0x00, 0x0A, 0xD, 0

print_2:
    mov edi, 0xb8000

    pusha
    .loop_printing:
    lodsb
    or al,al
    jz .loopEnd_printing
    mov [edi], ' '
    add edi, 2
    jmp .loop_printing

    .loopEnd_printing:
        popa
        ret

dump16Registers_2:

    ; AX
    mov eax, eax
    call parseAxRegisterIntoAscii_2
    call print_2

    ret
    

parseAxRegisterIntoAscii_2:
    pusha
    lea esi, parseAxRegisterIntoAscii_pointer_asciiRegister_2
    add esi, 38
    mov ecx, 39
    .loop_asciiRegister:
        mov bl, [esi]
        cmp bl, 0x20
        je .loopEnd_asciiRegister

        mov ebx, eax
        and ebx, 00000000000000000000000000000001b
        add bl, 00110000b
        mov [esi], bl

        shr eax, 1
        .loopEnd_asciiRegister:
        dec esi
        loop .loop_asciiRegister

    popa
    
    mov esi, parseAxRegisterIntoAscii_pointer_asciiRegister_2
    ret