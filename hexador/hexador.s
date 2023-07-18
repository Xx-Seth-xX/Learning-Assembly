; Executable name: hexador
; Dumps data from file in hexadecimal format
; Compile command:
;        nasm -f elf64 -g hexador.s
;        ld -o hexador hexador.o

section .data 
        HexString: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", 10
        HEXSTRINGLEN: equ $-HexString   ; HexString will be string template for output
section .bss
        BUFFLEN equ 16
        Buffer: resb BUFFLEN            ; We will buffer 16 bytes (one line)
section .text
global _start                           ; Entry point of program must be public

start:
Read: 
        mov rax, 0                      ; Code for sys_read system call
        mov rdi, 0                      ; File descriptor 
        mov rsi, Buffer                 ; Pointer to where data will be stored
        mov rdx, BUFFLEN                ; no. of bytes to read
        syscall
        cmp rax, 0                      
        jz Exit                         ; If we read 0 no bytes we'll exit the program      
        jmp Read
Exit: 
        mov rax, 3Ch                    ; Code for exit sys_exit
        mov rdi, 0                      ; 0 return value for program
        syscall

