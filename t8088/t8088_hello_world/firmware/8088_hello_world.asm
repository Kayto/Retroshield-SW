; Standalone 80C88 Hello World program using SCP 8086 Monitor routines
; Matches SCP Monitor v1.5 structure and UART handling exactly
; Current date: February 25, 2025

CPU     8086            ; Target 80C88 (8086-compatible)

; Constants from SCP Monitor
BASE    EQU     0F0H            ; CPU Support base port address
STAT    EQU     BASE+7          ; UART status port (0F7H)
DATA    EQU     BASE+6          ; UART data port (0F6H)
TDRE    EQU     02h             ; UART transmitter ready bit

        SECTION .text           ; All in text section (ROM-like)

; Reset vector entry point (matches SCP Monitor)
RESET:
        CLD                     ; Clear direction flag (forward string ops)
        XOR     AX, AX          ; Zero AX
        MOV     SS, AX          ; Set SS to 0
        MOV     SP, 1000h       ; Stack at 0000:1000h (safe location)
        MOV     DS, AX          ; Set DS to 0
        MOV     ES, AX          ; Set ES to 0

        MOV     SI, HELLOMSG    ; Point SI to Hello World string in CS
        CALL    PRINTMES        ; Print the string (exact SCP routine)
        JMP     $               ; Infinite loop (halt equivalent)

; Print ASCII message (exact copy of SCP’s PRINTMES)
PRINTMES:
        CS                      ; Fetch from code segment
        LODSB                   ; Load next char from [CS:SI] into AL, increment SI
        CALL    OUT             ; Output the character
        SHL     AL, 1           ; Shift left to check high bit
        JNC     PRINTMES        ; If no carry, high bit not set, continue
        RET                     ; High bit set, end of string

; Output character to UART (exact copy of SCP’s OUT)
OUT:
        PUSH    AX              ; Save character in AL
OUT1:
        IN      AL, STAT        ; Read UART status
        AND     AL, TDRE        ; Check transmitter ready bit
        JZ      OUT1            ; Wait until ready
        POP     AX              ; Restore character
        OUT     DATA, AL        ; Send to UART
        RET                     ; Return

; String placed in code segment (like SCP’s HEADER)
HELLOMSG: 
        DB      "Hello World", 13, 10+80H  ; String with CR/LF, high bit on last char

; Pad to reset vector location (matches SCP Monitor)
        TIMES   0FFF0H - ($ - $$) DB 90H  ; Fill with NOPs to 0FFF0H
        DB      0EAH            ; Far JMP opcode
        DW      RESET, 0F000H   ; Jump to RESET at F000:0000
        TIMES   10000H - ($ - $$) DB 00H  ; Fill to 64KB






