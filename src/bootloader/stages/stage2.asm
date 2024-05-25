bits 16

org 0x0 ; 0x8000:0x0

start: jmp entry

prepareStage2:
    mov ax, 0x8000
    mov ds, ax
    mov es, ax

    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx

entry:

    call prepareStage2

    cli
    hlt

    times 65536 - ($-$$) db 0