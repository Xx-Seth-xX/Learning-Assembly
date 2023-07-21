; Executable name: vidbuff1
; Small assembly program in linux for learning the string operandos
; in x86-64 assembly. Creates a fake video buffer that can be printed
; to stdout 
; build using:
;        nasm -f elf64 -g vidbuff1.s
;        ld -o vidbuff1.out vidbuff.s

section .data
        EOL equ 0xa                     ; End Of Line character
        FILLCHR equ 0x20                ; Space character (for filling)
        HBARCHR equ 0xc4                ; Horizontal bar character
        STRROW equ 0x2                  ; Starting row for graph

; Data for drawing hbar
        DataSet db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

        Message db "Testing fake video buffer" 
        MSGLEN equ $-Message
; Escape sequence to clear the screen and set the cursor on position (1,1)
        ClrHome db 0x1b, "[2J",0x1b,"[01;01H"
        CLRLEN equ $-ClrHome            ; Length of ClrHome string

section .bss
        COLS equ 81                     ; Number of cols (80 char + 1 for EOL)
        ROWS equ 25                     ; Number of lines in display
        VidBuff resb COLS * ROWS        ; Buffer size obviously will be COLS * ROWS row-first indexing
section .text

global _start                           ; Nothing new, necessary for linker

%macro ClearTerminal 0                  ; Macro for clearing the screen and resetting cursor to (1,1)
        push rax
        push rdi
        push rsi
        push rdx        
        push rcx                        ; Save registers in stack
        mov rax, 1                      ; Specify sys_write syscall
        mov rdi, 1                      ; Specify stdout file descriptor
        mov rsi, ClrHome                ; Pointer to string
        mov rdx, CLRLEN                 ; Specify no. of bytes to write
        syscall                         ; Execute syscall
        pop rcx
        pop rdx
        pop rsi
        pop rdi
        pop rax                         ; Restore registers
%endmacro

;--------------------------------------------------------------------------------
; WrtStr: Writes string to video buffer at specified x,y position (1-based indexing)
; In:
;         RDI - Address of string to print
;         RSI - X position
;         RDX - Y position
;         RCX - Length of string in no of bytes
; Modifies: VidBuff
; Returns: Nothing
; Calls: Nothing
WrtStr:
        push rax
        push rdi 
        push rsi
        push rdx
        push rcx                        ; Save registers we're going to use
; First we got to calculate position offset = (y - 1) * cols + (x - 1)
; x and y are both 8 bits at most
        dec rsi
        dec rdx                         ; Decrement both registers by 1 because memory is 0-based
        mov rax, rdx                    ; Move to rax (al actually) because there is where mul operand works
        mov ah, COLS                    ; Store COLS size in ah so we can multiply it
        mul ah                          ; ax = ah * al
        add rax, rsi                    ; Now rax holds the offset in vidbuff and rsi and rdx are thrashable
        mov rsi, rdi                    ; RSI is where string operands get source address
        mov rdi, rax                    ; RDI is where string operands get dest. address 
        add rdi, VidBuff                ; Add base address of VidBuff to offset
        cld                             ; Clear Direction Flag so RSI and RDI are incremented by movsb
        rep movsb                       ; Print ECX no of bytes from RSI to RDI
        pop rcx
        pop rdx
        pop rsi
        pop rdi 
        pop rax                         ; Restore registers
        ret                             ; And return

;--------------------------------------------------------------------------------
; PutChar: Put char from register to video buffer at specified x,y position (1-based indexing)
; In:
;         RDI - Char to print
;         RSI - X position
;         RDX - Y position
; Modifies: VidBuff
; Returns: Nothing
; Calls: Nothing
PutChar:
        push rdi 
        push rsi
        push rdx
        push rax                        ; Save registers
; First we got to calculate position offset = (y - 1) * cols + (x - 1)
; x and y are both 8 bits at most
        dec rsi
        dec rdx                         ; Decrement both registers by 1 because memory is 0-based
        mov rax, rdx                    ; Move to rax (al actually) because there is where mul operand works
        mov ah, COLS                    ; Store COLS size in ah so we can multiply it
        mul ah                          ; ax = ah * al
        add rax, rsi                    ; Now rax holds the offset in vidbuff and rsi and rdx are thrashable
        add rax, VidBuff                ; Add base address of VidBuff to offset
        mov byte [rax], dil
        pop rax
        pop rdx
        pop rsi
        pop rdi                         ; Restore registers
        ret                             ; And return

;--------------------------------------------------------------------------------
; ClrVid: Clears video buffer (fills it with space characters)
; In: Nothing
; Modifies: VidBuff
; Returns: Nothing
; Calls: Nothing
ClrVid:
        push rax
        push rdi                        ; Save registers
        mov rdi, VidBuff                ; Store in destination register VidBuffer address
        mov al, FILLCHR                 ; Store in al the filling char (whitespace)
        mov rcx, COLS * ROWS            ; Number of bytes that we need to print (whole buffer)
        rep stosb                       ; Stores AL in VidBuff RCX times
; We now need to place EOL characters at X = 81 in every row
        mov rdi, VidBuff                ; Reset the counter to VidBuff + 0 
        dec rdi                         ; Necessary because of 0-based indexing in memory and 1 in video buffer
        mov rcx, ROWS                   ; Loop counter 
        .loopEol:         
                add rdi, COLS           ; Moves offset to X = 81 and advances 1 row
                mov byte [rdi], EOL     ; Moves EOLCHR to X = 81 and corresponding row of loop 
                loop .loopEol           ; This stops when ECX = 0 so we will go over every row
        pop rdi
        pop rax                         ; restore registers
        ret                             ; and return
;--------------------------------------------------------------------------------
; ShowBuff: Prints buffer to terminal after clearing it with Escape Sequence 
; In: Nothing
; Modifies: VidBuff
; Returns: Nothing
; Calls: ClearTerminal macro
ShowBuff: 
        push rax
        push rdi
        push rsi
        push rdx  
        push rcx                        ; Save registers        
        mov rax, 1                      ; Specify sys_write syscall
        mov rdi, 1                      ; Specify stdout file descriptor
        mov rsi, VidBuff                ; Pointer to buffer
        mov rdx, ROWS * COLS            ; No. of bytes to write
        syscall                         ; Execute syscall 
        pop rcx
        pop rdx
        pop rsi
        pop rdi
        pop rax                         ; Restore registers
        ret

_start: 
        call ClrVid
        mov rdi, 0x41
        mov rsi, 1
        mov rdx, 1
lnumberloop:
        call PutChar
        inc rdi
        inc rdx
        cmp rdx, 25
        jbe lnumberloop
        call ShowBuff
Exit: 
        mov rax, 0x3c                   ; Specify sys_exit
        mov rdi, 0                      ; Specify return value
        syscall
        
