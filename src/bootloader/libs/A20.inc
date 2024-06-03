;******************
;   All logic involving A20 gate, like enabling it to reach 4 GB data address
;   Functions:
;
;******************

%ifndef __A20_INC_3444_INCLUDED__
%define __A20_INC_3444_INCLUDED__

bits 16

;*****************
;   Includes
;*****************
%include "Stdio16.inc"

;*****************
;   Utility variables
;*****************
    interruptCallErrorMsg:      db 'Damn, we got an error trying to invoke A20 support of BIOS ;~;', 0x0A, 0xD, 0
    functionNotSupportedMsg:    db 'Damn bro, A20 support call are not supported by our BIOS, painful moment'

;*****************
;   Functions
;*****************
verifyA20SupportBIOS:
    push bp
    mov bp, sp

    ; Query A20 support
    xor bx, bx
    mov ax, 0x2403
    int 0x15

    ; Verify error and situations
    jc .interruptCallError
    cmp ah, 0x86
    je .functionNotSupported

    ; Persist supported methods to enable A20
    mov dx, bx
    and dx, 1b
    mov [isKeyboardControllerSupported], dx

    mov dx, bx
    and dx, 10b
    shr dx, 1
    mov [isSYSControlSupported], dx 

    mov sp, bp
    pop bp
    ret

    .interruptCallError:
    stc
    mov si, interruptCallErrorMsg
    call print

    mov sp, bp
    pop bp
    ret

    .functionNotSupported:
    stc
    mov si, functionNotSupportedMsg
    call print

    mov sp, bp
    pop bp
    ret

enableA20
enableA20WithSYSControl
enableA20WithBIOS
enableA20WithKeyboardController

;*****************

%endif ;__FAT12_INC_3444_INCLUDED__
%endif  ; __A20_INC_3444_INCLUDED__