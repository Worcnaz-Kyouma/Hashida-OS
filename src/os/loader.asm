bits 32

section .text
    extern kernelMain
    global loader

loader:
    mov esp, kernel_stack
    call kernelMain

_stop:
    cli
    hlt
    jmp _stop

section .bss
    resb 2*1024*1024
    kernel_stack:
