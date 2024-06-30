bits 32

section .text
    extern kernelMain
    global loader

loader:
    jmp 0xffffffff
    mov esp, kernel_stack
    call kernelMain

_stop:
    cli
    hlt
    jmp _stop

section .bss
    resb 2*1024 ; 2KB
    kernel_stack:
