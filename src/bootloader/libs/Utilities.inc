;******************
;   Easy utilities to speed up the code development, with macros and functions
;   Functions:
;       - prepareFAT12Params: Prepare extern and intern params necessary to disk communication
;       - parseLBAtoCHS: Parse LBA value to CHS values, already in good registers for int 13h interface (CX[7:6][15:8] = cylinder, CL[5:0] = sector, dh = head)
;       - resetDiskSystem: Reset the disk system... what more you expected?
;       - populateDiskParameters: Populate important params of FAT12 code, like numberOfHeads, numberOfCylinders and numberOfSectors
;******************

%ifndef __UTILITES_INC_3444_INCLUDED__
%define __UTILITES_INC_3444_INCLUDED__

bits 16

;*****************
;   Utility variables
;*****************

;*****************
;   Macros
;*****************
%macro mul_simple 2
    mov ax, %1
    push bx
    mov bx, %2
    
    xor dx, dx
    mul bx

    pop bx
%endmacro

%macro mul_simple_8 2
    mov al, %1
    push bx
    mov bl, %2

    xor dx, dx
    mul bl

    pop bx
%endmacro

%macro div_simple 2
    mov ax, %1
    push bx
    mov bx, %2

    xor dx, dx
    div bx

    pop bx
%endmacro

%macro div_simple_8 2
    mov al, %1
    push bx
    mov bl, %2

    xor dx, dx
    div bl

    pop bx
%endmacro

;*****************
;   Functions
;*****************

%endif ; __UTILITES_INC_3444_INCLUDED__