bits 16

org 0x0 ; 0x1000:0x0

start: jmp entryPoint

;*****************
;   Includes
;*****************
    %include "Utilities.inc"
    %include "Stdio16.inc"
    %include "FAT12.inc"
    %include "PMode.inc"
    %include "A20.inc"
;*****************

;*****************
;   Common Variables
;*****************
    welcomeStage2Msg db 'Jumped into Stage 2!... EPK', 0x0A, 0xD, 0
    kernelName db   'HSKERNELBIN'
    
    kernelOffset:    dw 0x0000
    kernelSegment:   dw 0x3000

    innerStage3Pointer: 
        dd 0
        dw 0x0008

;*****************
;   FAT12 Params
;*****************
    FATOffset:      dw 0x0000
    FATSegment:     dw 0x2000

    rootDirOffset:  dw 0x1200 ; FAT gets the first 9 sectors of the segment
    rootDirSegment: dw 0x2000

    GDTOffset:  dw 0x3000 ; FAT + Root dir gets the first 15 sectors of the segment
    GDTSegment: dw 0x2000

;*****************
;   Code
;*****************
prepareStage2:
    mov ax, 0x1000
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

    ; Prepare FAT12.inc
    push word [FATSegment]
    push word [FATOffset]
    push word [rootDirSegment]
    push word [rootDirOffset]
    call prepareFAT12Params

    ; Get Kernel Entry
    push word [rootDirSegment]
    push word [rootDirOffset]
    push kernelName
    call getFileEntry           ; di = fileEntry offset

    mov es, [rootDirSegment]
    mov ax, es:[di + 26]        ; First Kernel Cluster

    ; Load Kernel
    push word [FATSegment]
    push word [FATOffset]
    push word [kernelSegment]
    push word [kernelOffset]
    push ax                     ; First cluster
    call loadClusters
    
    call enableA20

    push word [GDTSegment]
    push word [GDTOffset]
    call preparePMODE

    xor eax, eax
    xor edx, edx
    mov eax, innerStage3
    mov edx, 0x1000
    shl edx, 4
    add eax, edx

    mov [innerStage3Pointer], eax
    
    ; Enable PMODE
    cli
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Immediate jmp to adjust CS
    jmp far dword [innerStage3Pointer]

;*****************
;   Entry point to inner stage 3
;*****************

bits 32

innerStage3:
    mov		ax, 0x10		; set data segments to data selector (0x10)
	mov		ds, ax
	mov		ss, ax
	mov		es, ax
    
    hlt