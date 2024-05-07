; Test populateAsciiAx
global _start

section .data
populateAsciiAx_pointer_tempArray times 32 db 0
pointer_asciiAxPrologue db 'AX: ', 0
pointer_asciiAx times 40 db 0
teste db 'teste', 0

section .text

populateAsciiAx:
    xor ecx, ecx
    mov esi, populateAsciiAx_pointer_tempArray
    
    populateAsciiAx_loop_binToAscii:
        mov ebx, eax
        and ebx, 00000000000000000000000000000001b
        add bl, 00110000b
        mov [esi], bl

        inc esi
        inc cl
        shr eax, 1
        cmp cl, 32
    	
        jne populateAsciiAx_loop_binToAscii
        
    mov edx, pointer_asciiAx
    mov ebx, 0
    populateAsciiAx_loop_populateAsciiAx:
        dec esi
        dec ecx

        mov al, [esi]
        mov [edx], al

        cmp ecx, 0
        je populateAsciiAx_loopEnd_populateAsciiAx
		
        inc edx
        
        push eax
        push ebx
        push ecx
        push edx
        
        xor edx, edx
        mov eax, ecx
        mov ebx, 4
        div ebx
        cmp edx, 0
        
        pop edx
        pop ecx
        pop ebx
        pop eax
        jne populateAsciiAx_loop_populateAsciiAx

        mov al, ' '
        mov [edx], al

        inc edx
        jmp populateAsciiAx_loop_populateAsciiAx
    populateAsciiAx_loopEnd_populateAsciiAx:
	
	inc edx
    mov bl, 0
    mov [edx], bl
    
    ret

_start:
	mov eax, 10111010001110011011101000111001b
	call populateAsciiAx
	
	pusha
    mov eax, 4
    mov ebx, 1
    mov ecx, pointer_asciiAx
    mov edx, 40
    int 0x80
    popa  

exit:
	mov		eax, 01h		; exit()
	xor		ebx, ebx		; errno
	int		80h