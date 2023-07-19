; Executable name: hexador2
; Dumps data from file in hexadecimal format
; Now with procedures!
; Compile command:
;        nasm -f elf64 -g hexador.s
;        ld -o hexador hexador.o
section .data                           ; Initialized data
; Template line for hex characters
DumpLin: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", 0x09
DUMPLEN: equ $-DumpLin 
; Template line for ascii characters
AsciiLin: db "|................|",10,0
ASCIILEN: equ $-AsciiLin - 1
; Hex characters 
HexDigits: db "0123456789ABCDEF",0
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
        mov rdx, 0x0F                   ; We have to clean 16=Fh spaces
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
;        al: value to write
;        rdx: pointer (0 to 15) of where to dump the byte
; Returns: Nothing
; Modifies: rax, AsciiLin, DumpLin
; Calls: DumpChar
DumpChar:
        push rbx                        ; We push rbx to stack as we'll use it
        push rdi                        ; same as above
; First we will print ascii char because dumping hex value is destructive
        and rax, 0xFF                   ; We clean all subbytes but al
        mov bl, byte [LUTable + rax]    ; We go through look up table
        mov [AsciiLin + 1 + rdx], bl    ; We need to + 1 as first character is '|'
; Now we'll generate offset for dumping hex
        lea rdi, [rdx * 2 + rdx]        ; In rdi we will store actual offset i.e. rdi = rdx * 3

        mov rbx, rax                    ; Restore rbx as byte to dump        
        and rax, 0xF0                   ; Mask out high nybble
        shr rax, 4                      ; Shift 4 to right so high nybble becomes valid in al
        and rbx, 0x0F                   ; Mask out low nybble
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
        push rdx                        ; Save registers
        mov rax, 1                      ; Code for sys_write
        mov rdi, 1                      ; Code for stdout
        mov rsi, DumpLin                ; startpoint of line to write
        mov rdx, ASCIILEN + DUMPLEN     ; We will write both strings so we'll need both sizes
        syscall
        pop rdx
        pop rsi
        pop rdi
        pop rax                         ; Restore registers
        ret
;--------------------------------------------------------------------------------
; FillBuffer: Fill buffer with data from stdin
; In: Nothing
; Returns: #no of bytes read in EBP
; Modifies: RAX, R8, Buff
; Description:
;        Fills the Buff with data from stdin (BUFFLEN bytes) using sys_read
;        RAX returns the number of bytes read, so if it's 0 we reached EOF
;        a negative value on EBP indicates error so program must test it
;        R8 is reseted because buffer has to be read from 0 to BUFFLEN - 1
; Calls: sys_read
FillBuffer:
        push rsi
        push rdi
        push rdx                        ; Save registers
        mov rax, 0                      ; code for sys_read
        mov rdi, 0                      ; Code for stdin file descriptor
        mov rsi, Buff                   ; Pointer to buffer
        mov rdx, BUFFLEN                ; How many bytes to read
        mov r8, 0                       ; Reset counter
        syscall
        pop rdx
        pop rdi
        pop rsi                         ; Restore registers
        ret

global _start
_start:
        call FillBuffer                 ; We fill the buffer with data from stdin, now R8 = 0
        cmp rax, 0                      ; We test rax 
        jbe Exit                        ; If rax <= We reached EOF or encoutered an error
        mov rdx, 0                      ; Counter for no of chars processed in a line 
        mov r9, rax                     ; R9 now contains number of bytes in buffer
Scan: 
        movzx rax, byte [Buff + r8]     ; Now RAX contains the byte to dump (we move with zero expansion)
; As RDX already contains no of byte to process we can directly call DumpChar
        call DumpChar                   ; RAX is lost 
; Now we have to check if it's necessary to print line or load the buffer again        
        inc r8                          ; Increment buffer pointer
        cmp r8, r9                      ; Compare buffer pointer with no of bytes in buffer
        jb .testLine                    ; If R8 < RDX we still have buffer to process
                call FillBuffer         ; otherwise we refill the buffer
                cmp rax, 0              ; If buffer reached EOF we can finish the program
                jb Exit                 ; Exit without printing last line because we errored
                je Done                 ; If we simply reached EOF we're done without issues

        .testLine:
                                        ; If RDI > 16 we have to print line and clear it
                inc rdx
                and rdx, 0x0F           ; 16 = 10h so this will give 0 in such case, otherwise it doesn't affect it 
                jnz Scan                ; If it's not zero we can scan next byte without issues
                call PrintLine          ; Otherwise we print the line and clear it afterwards
                call ClearLine
                jmp Scan
Done: 
        call PrintLine                  ; Finish printing remaining data
Exit:
        mov rdi, rax                    ; Return value for program
        mov rax, 0x3C                   ; Code for sys_exit
        syscall
