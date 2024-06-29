bits 32

section .text
    extern kernelMain
    global loader

loader:
    mov word [0xb8000], 0xF030
    mov esp, kernel_stack
    call kernelMain

_stop:
    cli
    hlt
    jmp _stop

section .bss
    align 4
    resb 2*1024*1024
    kernel_stack:
