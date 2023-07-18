; Executable name: Mayusculizador
; Converts all text in stdin to uppercase
; Compile with commands:
;        nasm -f elf64 mayusculizador
;        ld -o mayusculizador mayusculizador.o

section .data                           ; Initialized data (none needed)
section .bss                            ; Uninitialized data 
        BUFFLEN equ 1024
        Buff resb BUFFLEN               ; We reserve 1024 to buffer the text
section .text                           ; Segment with actual code

global _start                           ; We have to make public the startpoint

_start:
        nop                             ; So the debugger doesn't complain (i am not sure if this is actually needed)
Read:
        mov rax, 0                      ; Code for read system call
        mov rdi, 0                      ; File descriptor code (0 = stdin) 
        mov rsi, Buff                   ; Buffer where we will store read data
        mov rdx, BUFFLEN                ; How many bytes we'll read
        syscall                         ; Execute system call
        cmp rax, 0                      ; rax returns the number of bytes read
        jb ErrExit                      ; If rax is < 0 then an error ocurred so we ErrExit
        je Exit                         ; If we have read no bytes we exit the program

;; Now we will set up the registers for the loop

        mov rbp, Buff                   ; If we store the buffer pointer in a register the programm will be faster
        mov rcx, rax                    ; We store the number of bytes read into the counter register
Scan:                                   ; We will scan character by character (byte) the buffer 
                                        ; and transform lowercase to uppercase
        dec rcx                         ; Decrement the counter first because last item is length - 1 (0-based indexing)

;; Now we will filter non lowercase characters
;; Ascii is ordered such that if c < 'a' or c > 'z' we know c is not a lowercase char

        cmp byte [rbp + rcx], 61h       ; 'a' = 61h
        jb ScanNext                     ; If c is below 'a' we skip the rest of the loop
        cmp byte [rbp + rcx], 7Ah       ; 'z' = 79h
        ja ScanNext                     ; Same as above

        sub byte [rbp + rcx], 20h       ; If we substract 20h from any char we get its uppercase counterpart

ScanNext:
        cmp rcx, 0                      ; If counter is equal to 0 we have ended the loop
        jne Scan                        ; If not we scan the next byte        

Write:
        mov rdx, rax                    ; How many bytes we'll print (number of bytes read is stored in rax)
        mov rax, 1                      ; Code for write system call
        mov rdi, 1                      ; File descriptor code (1 = stdout) 
        mov rsi, Buff                   ; Buffer we will print
        syscall                         ; Execute system call
        cmp rax, 0                      ; rax returns the number of bytes read
        jb ErrExit                      ; If rax is < 0 then an error ocurred so we ErrExit
        jmp Read                        ; We go to refill the buffer
        
Exit:
        mov rax, 60                     ; Code to for exit system call
        mov rdi, 0                      ; Return value for program 
        syscall
ErrExit:
        mov rdi, rax                    ; We store rax value into rdi which will be return value from program
        mov rax, 60                     ; Code for exit system call
        syscall 
