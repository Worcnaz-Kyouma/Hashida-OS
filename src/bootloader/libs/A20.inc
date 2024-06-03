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
    isKeyboardControllerSupported:  db 0x0
    isSYSControlSupported:          db 0x0
    interruptCallErrorMsg:      db 'Damn, we got an error trying to invoke A20 support of BIOS ;~;', 0x0A, 0xD, 0
    functionNotSupportedMsg:    db 'Damn bro, A20 support call are not supported by our BIOS, painful moment', 0x0A, 0XD, 0

    enableA20Success:           db 'We got it! We enabled the A20! Now we have 32 bits address! Nice one :3', 0x0A, 0xD, 0
    enableA20Fail:              db 'NO! Failed all the methods to enable A20 ;~; Very unlucky bro', 0x0A, 0xD, 0

    SYSControlUnsupported:          db 'NO! Failed all the methods to enable A20 ;~; Very unlucky bro', 0x0A, 0xD, 0

    KeyboardControllerUnsupported:  db 'NO! Failed all the methods to enable A20 ;~; Very unlucky bro', 0x0A, 0xD, 0

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
    mov [isKeyboardControllerSupported], dl

    mov dx, bx
    and dx, 10b
    shr dx, 1
    mov [isSYSControlSupported], dl 

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

enableA20:
    push bp
    mov bp, sp

    ; Populate methods supported by the environment
    call verifyA20SupportBIOS

    ; Enable A20 with BIOS
    call enableA20WithBIOS
    jc .tryAnotherMethods

    mov si, enableA20Success
    call print
    
    mov sp, bp
    pop bp
    ret

    ; Alternative methods to enable A20
    .tryAnotherMethods:

    mov dl, [isSYSControlSupported]
    cmp dx, 1
    jne .keyboardControllerMethod
    call enableA20WithSYSControl
    jc .keyboardControllerMethod

    mov sp, bp
    pop bp
    ret

    .keyboardControllerMethod:

    call enableA20WithKeyboardController
    jc .enableA20Fail

    mov sp, bp
    pop bp
    ret

    .enableA20Fail:
    stc
    mov si, enableA20Fail
    call print

    mov sp, bp
    pop bp
    ret

enableA20WithBIOS:
    push bp
    mov bp, sp

    mov ax, 0x2401
    int 0x15

    mov sp, bp
    pop bp
    ret

enableA20WithSYSControl:
    push bp
    mov bp, sp

    mov si, SYSControlUnsupported
    call print

    mov sp, bp
    pop bp
    ret

enableA20WithKeyboardController:
    push bp
    mov bp, sp

    mov si, KeyboardControllerUnsupported
    call print

    mov sp, bp
    pop bp
    ret

;*****************

%endif  ; __A20_INC_3444_INCLUDED__