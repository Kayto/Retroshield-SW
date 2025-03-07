; -----------------------------------------------------------------
; Test Program for (Single-Step Test) - Stack Operations
; Target: 8086 (assembled for 16-bit mode)
; Load Address: 0500h
;
; This program tests stack behavior by pushing and popping values.
; The stack pointer (SP) is inspected before and after operations.
; You can use the S command to single-step and monitor stack changes.
; After testing, the program halts for debugging.
; -----------------------------------------------------------------
BITS 16                ; Set 16-bit mode (for 8086)
org 0500h              ; execution starts at 0x500

start:
    mov bx, 1234h     ; Load BX with test value
    push ax           ; Push BX onto stack

    mov bx, 5678h     ; Load BX with another test value
    push bx           ; Push BX onto stack

    mov cx, sp        ; Store current SP in CX (before popping)
    
    pop bx            ; Pop back into AX (should be 5678h)
    pop dx            ; Pop back into DX (should be 1234h)

    mov di, sp        ; Store final SP in DI (after popping)
    
    hlt               ; Halt execution (use debugger to inspect registers)
    
    ret               ; Return to Monitor


