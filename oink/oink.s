; Executable name: OINK
; Description : Program to test linux syscalls to write text to screen

section .data ; Section containing initialized data
OinkMsg: db "Oinku!", 10; Message with ending newline
OinkLen: equ $-OinkMsg ; Define a constant with length of message 

section .bss
section .text

global _start

_start:
        nop                ; For the debugger
        mov eax, 4        ; Specify that we want sys_write syscall
        mov ebx, 1        ; Specify file descriptor 1 «standard output»
        mov ecx, OinkMsg  ; Pass the address of the msg
        mov edx, OinkLen ; Pass length of msg 
        int 80H ; Make syscall

        mov eax, 1 ; Exit syscall
        mov ebx, 0 ; 0 return code
        int 80H ; Execute syscall to exit the program
