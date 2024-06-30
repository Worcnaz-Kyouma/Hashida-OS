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

    failedStage2Msg db 'Failed to pass stage 2 of the bootloader... Sorry bro D:, good luck to fix/improve it(probably fixing it, i trust you)'

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
    jc .failedStage2

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

    .failedStage2:
        mov si, failedStage2Msg
        call print

        cli
        hlt

;*****************
;   Entry point to inner stage 3
;*****************

bits 32

;*****************
;   32 Bits Functions
;*****************
parseRealModeAddressing:
    push ebp
    mov ebp, esp

    ; [ebp + 8] -> Segment
    ; [ebp + 10] -> Offset

    movzx eax, word [ebp + 10]
    movzx edx, word [ebp + 8]

    shl edx, 4
    add eax, edx

    mov esi, eax

    mov esp, ebp
    pop ebp
    ret

fetchKernelTo1MB:
    push ebp
    mov ebp, esp

    push esi

    add esi, 0x1C 
    mov eax, [esi] ; Start of program header table offset

    pop esi 
    push esi

    mov edx, esi

    add esi, eax    ; Start of program header table

    .fetchingKernel:
        call fetchSegment   ; Fetches a segment and automatic update esi to next entry, return 0 in eax if finished
        cmp eax, 0
        jne .fetchingKernel

    pop esi

    mov esp, ebp
    pop ebp
    ret

fetchSegment:
    push ebp
    mov ebp, esp

    push esi

    mov eax, [esi]

    cmp eax, 0
    je .finishedAllFetches

    cmp eax, 1
    jne .goNextFetch    ; Not a load segment

    add esi, 0x10
    mov ecx, [esi]
    pop esi
    push esi    ; Size of segment in ELF

    add esi, 8
    mov edi, [esi]  ; Segment start in memory
    pop esi
    push esi

    add esi, 4
    mov eax, [esi]
    pop esi
    push esi
    mov esi, edx    ; This takes the real offset of ELF
    add esi, eax    ; Segment start in ELF

    .fetchingSegment
        mov al, [esi]
        mov [edi], al

        add esi, 1
        add edi, 1
        loop .fetchingSegment

    .goNextFetch:
    pop esi
    add esi, 0x20

    mov esp, ebp
    pop ebp
    ret
    
    .finishedAllFetches:
    pop esi
    
    mov eax, 0

    mov esp, ebp
    pop ebp
    ret

getEntryPoint:
    push ebp
    mov ebp, esp

    add esi, 0x18

    mov edi, [esi]

    mov esp, ebp
    pop ebp
    ret

;*****************
;   32 Code
;*****************
innerStage3:
    mov		ax, 0x10		; set data segments to data selector (0x10)
	mov		ds, ax
	mov		ss, ax
	mov		es, ax
    mov     esp, 90000h

    push word [kernelOffset + 0x10000]
    push word [kernelSegment + 0x10000]
    call parseRealModeAddressing    ; esi = start of Kernel ELF ;

    call fetchKernelTo1MB
    call getEntryPoint      ; edi = entry point to jump into

    jmp edi

    hlt

; Developer Note: Bro, I just stopped programming assembly for 1 month and I feel dumb just thinking about this piece of heaven I'm cooking