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
        HBARCHR equ '-'                 ; Horizontal bar character
        STRROW equ 0x2                  ; Starting row for graph

; Data for drawing hbar, 0-ending
        DataSet db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,36, 12, 49, 70, 14, 65, 26, 0

        Message db "Testing fake video buffer" 
        MSGLEN equ $-Message
; Escape sequence to clear the screen and set the cursor on position (1,1)
        InitTerm db 0x1b, "[2J",0x1b,"[01;01H"
        INITTERMLEN equ $-InitTerm      ; Length of ClrHome string

section .bss
        COLS equ 81                     ; Number of cols (80 char + 1 for EOL)
        ROWS equ 25                     ; Number of lines in display
        VidBuff resb COLS * ROWS        ; Buffer size obviously will be COLS * ROWS row-first indexing
section .text

global _start                           ; Nothing new, necessary for linker

%macro InitializeTerminal 0             ; Macro for clearing the screen and resetting cursor to (1,1)
        push rax
        push rdi
        push rsi
        push rdx        
        push rcx                        ; Save registers in stack
        mov rax, 1                      ; Specify sys_write syscall
        mov rdi, 1                      ; Specify stdout file descriptor
        mov rsi, InitTerm               ; Pointer to string
        mov rdx, INITTERMLEN            ; Specify no. of bytes to write
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

;--------------------------------------------------------------------------------
; DrawRuler: Draw ruler at position X, Y with given length
; In:
;         RDI - X position
;         RSI - Y position
;         RDX - Length of ruler
; Modifies: VidBuff
; Returns: Nothing
; Calls: Nothing
; Description: Writes a 01234567890123... ruler i.e. goes from 0 to 9 and wraps
;        until given length is fulfilled. If X + Length > 80 then the ruler
;        is cut short so it doesn't writer over EOL character. 
DrawRuler:
; First we got to calculate position offset = (y - 1) * cols + (x - 1)
; x and y are both 8 bits at most
        push rax
        push rdi
        push rsi                        ; Save registers
        push rdx
        push r8
        push rcx
        mov r8, rdi
        add r8, rdx                     ; Now R8 holds rightmost part of ruler
        sub r8, 80                      ; We check if rightmost part of ruler skips over the right border
        jb .continue                    ; If it's below 80 we can continue
                                        ; otherwise, now in R8 we have X + Length - 80 
        sub r8, rdi 
        sub rdx, r8                     ; and now RDX holds Length - X + Length + 80 = 80 - X 
        jbe .exitLoop                   ; If RDX ends up being below 0 or equal then we got nothing to print
.continue:
        dec rdi
        dec rsi                         ; X and Y are 1-based and VidBuff is 0-based
        mov rax, 0                      ; Just in case there is leftovers in higher parts of RAX
        mov al, sil                     ; Store (Y - 1) in RAX for multiplication
        mov ah, COLS                    ; Move value to multiply by
        mul ah                          ; Perform AH * AL and store it in AX        
        add rdi, rax                    ; Now RDI holds the offset to add to VidBuff pointer
        add rdi, VidBuff                ; And now RDI holds the correct memory addres 
        cld                             ; Set DF to 0 so RDI is incremented with STOSB instruction
        mov rcx, rdx                    ; Counter will hold length to print        
        mov rax, '0'                    ; Starting character of ruler
.loop:
        stosb                           ; Store byte located in AL in address located in RDI
                                        ; and increment RDI by one
        inc rax                         ; Jump to next character in ruler
        cmp rax, 0x3a                   ; compare character in RAX with '0' + 1 ASCII character
        loopne .loop                    ; We continue looping if rcx > 0 and the last equality is not meet
                                        ; also decrement RCX
        jrcxz .exitLoop                 ; If RCX = 0 then we exit the loop
        mov rax, '0'                    ; Reset the counter
        jmp .loop                       ; If we have arrived here we reset the loop
.exitLoop:
        pop rcx
        pop r8
        pop rdx
        pop rsi
        pop rdi
        pop rax                         ; Restore registers
        ret
        
;--------------------------------------------------------------------------------
; DrawHB: Draw horizontal bar at position X, Y with given length
; In:
;         RDI - X position
;         RSI - Y position
;         RDX - Length of ruler
; Modifies: VidBuff
; Returns: Nothing
; Calls: Nothing
; Description: Writes a horizontal bar until given length is fulfilled. 
;        If X + Length > 80 then the ruler is cut short so it doesn't write 
;        over EOL character. 
DrawHB:
; First we got to calculate position offset = (y - 1) * cols + (x - 1)
; x and y are both 8 bits at most
        push rax
        push rdi
        push rsi                        ; Save registers
        push rdx
        push r8
        push rcx
        mov r8, rdi
        add r8, rdx                     ; Now R8 holds rightmost part of ruler
        sub r8, 80                      ; We check if rightmost part of ruler skips over the right border
        jb .continue                    ; If it's below 80 we can continue
                                        ; otherwise, now in R8 we have X + Length - 80 
        sub r8, rdi 
        sub rdx, r8                     ; and now RDX holds Length - X + Length + 80 = 80 - X 
        jbe .exitRoutine                ; If RDX ends up being below 0 or equal then we got nothing to print
.continue:
        dec rdi
        dec rsi                         ; X and Y are 1-based and VidBuff is 0-based so we have to convert
        mov rax, 0                      ; Just in case there is leftovers in higher parts of RAX
        mov al, sil                     ; Store (Y - 1) in RAX for multiplication
        mov ah, COLS                    ; Move value to multiply by
        mul ah                          ; Perform AH * AL and store it in AX        
        add rdi, rax                    ; Now RDI holds the offset to add to VidBuff pointer
        add rdi, VidBuff                ; And now RDI holds the correct memory addres 
        cld                             ; Set DF to 0 so RDI is incremented with STOSB instruction
        mov rcx, rdx                    ; Counter will hold length to print        

        mov rax, HBARCHR                ; Starting character of ruler
        rep stosb                       ; Write RCX number of HBARCHR to VidBuff
.exitRoutine:
        pop rcx
        pop r8
        pop rdx
        pop rsi
        pop rdi
        pop rax                         ; Restore registers
        ret
        
_start: 
        InitializeTerminal
        call ClrVid
        mov rdi, 1                      ; X value of ruler to print
        mov rsi, 1                      ; Y value of ruler to print
        mov rdx, COLS - 1               ; Length of ruler

        call DrawRuler
; Now we will draw the horizontal bars from the Dataset values
        mov rdi, 1                      ; Start always at X=1
        mov rsi, 2                      ; Start at Y = 2 (first line is for ruler)
        mov rcx, 0                      ; Counter for looping the Dataset
        mov rdx, 0                      ; Reset just in case there is rubbish in upper bytes
.drawDSLoop:
        mov dl, byte [DataSet+rcx]      ; Store in RDX current data
        cmp dl, 0                       ; Check if current data if 0
        je .finishDrawDSLoop            ; If so exit the loop
        call DrawHB                     ; Call drawing routine
        inc rsi                         ; Increment value of Y so next ruler is in nextline
        inc rcx                         ; Increment counter
        jmp .drawDSLoop                 ; Execute next iteration
.finishDrawDSLoop:
        
        mov rdi, Message                ; Adress of message to print
        mov rsi, (COLS - MSGLEN)/2      ; Where to print it
        mov rdx, ROWS 
        mov rcx, MSGLEN                 ; Length of message
        call WrtStr                     ; Call writing routine             
        call ShowBuff                   ; Print VidBuff to terminal
Exit: 
        mov rax, 0x3c                   ; Specify sys_exit
        mov rdi, 0                      ; Specify return value
        syscall
        
