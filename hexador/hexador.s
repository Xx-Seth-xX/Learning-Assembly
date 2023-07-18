; Executable name: hexador
; Dumps data from file in hexadecimal format
; Compile command:
;        nasm -f elf64 -g hexador.s
;        ld -o hexador hexador.o

section .data 
; HexString will be string template for output
        HexString: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", 10
        HEXSTRINGLEN: equ $-HexString   
; Lookup table
        Characters db "0123456789ABCDEF"
section .bss
        BUFFLEN equ 16
        Buffer: resb BUFFLEN            ; We will buffer 16 bytes (one line)
section .text
global _start                           ; Entry point of program must be public

_start:
Read: 
        mov rax, 0                      ; Code for sys_read system call
        mov rdi, 0                      ; File descriptor 
        mov rsi, Buffer                 ; Pointer to where data will be stored
        mov rdx, BUFFLEN                ; no. of bytes to read
        syscall
        cmp rax, 0                      
        jz Exit                         ; If we have finished processing the data we print it     

; We need to go byte by byte from buffer
        mov rcx, 0                      ; We set counter to 0
Scan:
; Now we need to extract low and high nybble from the byte
        mov rdx, 0                      ; Reset the register
        mov dl, byte [Buffer + rcx]     ; We copy the full byte in rdx
        mov rbx, rdx                    ; Duplicate for second nybble
        and dl, 00001111b               ; We mask out the low part of the byte
        shr bl, 4                       ; We shift right the byte 4 places so only the high part will remain

; We have low hex in rax and high hex in rbx
; as such the order for printing is bl al 
; We first need to convert from value to character representation
; by using the lookup table
        mov byte dl, [Characters + edx]
        mov byte bl, [Characters + ebx]
; Second we need to calculate the offset to the string template point
; offset = hexstring + rcx * 3 + 1(2), 1 for dh and 2 for dl      
        mov rsi, rcx                    ; Here we'll store the base offset
        shl rsi, 1                      ; This multiplies rdx times 2
        add rsi, rcx                    ; and this adds once more its original value and so we have multiplied by 3 

        mov [HexString + rsi + 1], bl   ; We write high nybble
        mov [HexString + rsi + 2], dl   ; We write low nybble

; Loop shenanigans
        inc rcx                         ; We increment counter by one
        cmp rcx, rax                    ; If rax has no of bytes read
        jb Scan                         ; If rcx < rax loop has not ended so we scan next byte
; Otherwise loop has ended and we print the string
Write:
        mov rax, 1                      ; Code for sys_write system call
        mov rdi, 1                      ; File descriptor for stdout 
        mov rsi, HexString              ; Pointer to output string
        mov rdx, HEXSTRINGLEN           ; Size of output string
        syscall
        jmp Read                        ; Refill buffer with new data

Exit: 
        mov rax, 3Ch                    ; Code for exit sys_exit
        mov rdi, 0                      ; 0 return value for program
        syscall

