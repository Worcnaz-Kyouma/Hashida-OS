bits 16

org 0x0 ; 0x8000:0x0

start: jmp entryPoint

;*****************
;   Includes
;*****************
    %include "Stdio16.inc"
    %include "FAT12.inc"
;*****************

;*****************
;   Common Variables
;*****************
    welcomeStage2Msg db 'Jumped into Stage 2!... EPK', 0x0A, 0xD, 0
    kernelName db 'KERNEL  BIN'

    kernelOffset    resb 2
    kernelSegment   resb 2
;*****************

;*****************
;   FAT12 Params
;*****************
    rootDirOffset   resb 2
    rootDirSegment  resb 2

    FATOffset       resb 2
    FATSegment      resb 2
;*****************

prepareStage2:
    mov ax, 0x8000
    mov ds, ax
    mov es, ax

    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx

    ret

entryPoint:

    call prepareStage2

    mov si, welcomeStage2Msg
    call print

    ; Fix stack? Strange error?

    ; Prepare FAT12.inc
    push word [FATSegment]
    push word [FATOffset]
    push word [rootDirSegment]
    push word [rootDirOffset]
    call prepareFAT12Params

    ; ; Get Kernel Entry
    ; push [rootDirSegment]
    ; push [rootDirOffset]
    ; push kernelName
    ; call getFileEntry           ; di = fileEntry offset

    ; mov es, [rootDirSegment]

    ; mov ax, es:[di + 26]        ; First Kernel Cluster

    ; ; Load Kernel
    ; push [FATSegment]
    ; push [FATOffset]
    ; push [kernelSegment]
    ; push [kernelOffset]
    ; push ax                     ; First cluster
    ; call loadClusters
    
    ; ; Enable A20
    ; ; ????????

    ; ; Enable Protected Mode
    ; ; create GDT
    ; ; set GDTR(LGDT)
    ; ; enable CR0 to Protected Mode

    ; ; Run Kernel
    ; ; ????????

    cli
    hlt