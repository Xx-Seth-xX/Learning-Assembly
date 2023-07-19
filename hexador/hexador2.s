; Executable name: hexador2
; Dumps data from file in hexadecimal format
; Now with procedures!
; Compile command:
;        nasm -f elf64 -g hexador.s
;        ld -o hexador hexador.o
section .data                           ; Initialized data
; Template line for hex characters
DumpLin: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
DUMPLEN: equ $-DumpLin 
; Template line for ascii characters
AsciiLin: db "|................|",10
ASCIILEN: equ $-AsciiLin
; Hex characters 
HexDigits: db "0123456789ABCDEF"
; Translation table from hex to ascii characters
; All valid ascii characters (lower than 128) are identified with themselves
; and all others values are mapped to the dot char 2Eh
LUTable:
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 29h, 2Ah, 2Bh, 2Ch, 2Dh, 2Eh, 2Fh
        db 30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh
        db 40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h, 48h, 49h, 4Ah, 4Bh, 4Ch, 4Dh, 4Eh, 4Fh
        db 50h, 51h, 52h, 53h, 54h, 55h, 56h, 57h, 58h, 59h, 5Ah, 5Bh, 5Ch, 5Dh, 5Eh, 5Fh
        db 60h, 61h, 62h, 63h, 64h, 65h, 66h, 67h, 68h, 69h, 6Ah, 6Bh, 6Ch, 6Dh, 6Eh, 6Fh
        db 70h, 71h, 72h, 73h, 74h, 75h, 76h, 77h, 78h, 79h, 7Ah, 7Bh, 7Ch, 7Dh, 7Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
        db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh

section .bss                            ; Uninitialized data
        BUFFLEN equ 10                  ; Buffer length
        Buff: resb BUFFLEN              ; Reserve space for the buffer

section .text                           ; Actual code
;--------------------------------------------------------------------------------
; ClearLine: Clear dump line and ascii line (resets them to original values)
; In: Nothing
; Returns: Nothing
; Modifies: Nothing
; Calls: DumpChar
ClearLine:
        push rax
        push rdx                        ; Save the gp registers that will be used
        mov rdx, 0Fh                    ; We have to clean 16=Fh spaces
        .loop:
                mov rax, 0              ; Empty byte that we'll write 
                call DumpChar 
                sub rdx, 1              ; Gotta use sub so it will set the carry flag if result is negative
                jnc .loop               ; If carry flag is not set we loop again (rdx >= 0)        
        pop rdx
        pop rax                         ; Pop the registers (mind the order)
        ret
;--------------------------------------------------------------------------------
; DumpChar: Clear dump line and ascii line (resets them to original values)
; In:
;        rax: value to write
;        rdx: pointer (0 to 15) of where to dump the byte
; Returns: Nothing
; Modifies: rax, AsciiLin, DumpLin
; Calls: DumpChar
DumpChar:
        push rbx                        ; We push rbx to stack as we'll use it
        push rdi                        ; same as above
; First we will print ascii char because dumping hex value is destructive
        mov bl, byte [LUTable + rax]    ; We go through look up table
        mov [AsciiLin + 1 + rdx], bl    ; We need to + 1 as first character is '|'
; Now we'll generate offset for dumping hex
        lea rdi, [rdx * 2 + rdx]        ; In rdi we will store actual offset i.e. rdi = rdx * 3

        mov rbx, rax                    ; Restore rbx as byte to dump        
        and rax, 00000000000000F0h      ; Mask out high nybble
        shr rax, 4                      ; Shift 4 to right so high nybble becomes valid in al
        and rbx, 000000000000000Fh      ; Mask out low nybble
        mov al, byte [HexDigits + rax]  ; Now in rax we have the actual char for hex value
        mov bl, byte [HexDigits + rbx]  ; Now in rbx we have the actual char for hex value

        mov byte [DumpLin + rdi + 1], al; Dump the char stored in rax
        mov byte [DumpLin + rdi + 2], bl; Dump the char stored in rbx
        pop rdi
        pop rbx                         ; We restore both registers
        ret 

;--------------------------------------------------------------------------------
; PrintLine: Prints DumpLin and AsciiLin to stdout
; In: Nothing
; Returns: Nothing
; Modifies: Nothing
; Calls: sys_write
PrintLine:
        push rax 
        push rdi
        push rsi
        push rdx                        ; Stack shenanigans
        mov rax, 1                      ; Code for sys_write
        mov rdi, 1                      ; Code for stdout
        mov rsi, DumpLin                ; startpoint of line to write
        mov rdx, ASCIILEN + DUMPLEN     ; We will write both strings so we'll need both sizes
        syscall
        pop rdx
        pop rsi
        pop rdi
        pop rax                         ; Stack shenanigans
        ret
global _start
_start:
        mov rax, 61h        
        mov rdx, 0
        call DumpChar
        mov rax, 62h        
        mov rdx, 1
        call DumpChar
        mov rax, 64h        
        mov rdx, 2
        call DumpChar
        mov rax, 10h        
        mov rdx, 4
        call DumpChar
        call PrintLine
        call ClearLine
        call PrintLine
Exit:
        mov rax, 3Ch                    ; Code for sys_exit
        mov rdi, 0                      ; Return value for program
        syscall
