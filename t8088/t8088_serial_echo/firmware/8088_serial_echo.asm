; Standalone 80C88 Serial Echo program using SCP 8086 Monitor routines
; Reads from UART and echoes back, runs indefinitely
; Based on SCP Monitor v1.5 structure and UART handling
; Current date: February 25, 2025

CPU     8086            ; Target 80C88 (8086-compatible)

; Constants from SCP Monitor
BASE    EQU     0F0H            ; CPU Support base port address
STAT    EQU     BASE+7          ; UART status port (0F7H)
DATA    EQU     BASE+6          ; UART data port (0F6H)
TDRE    EQU     02h             ; UART transmitter ready bit
RDRF    EQU     01h             ; UART data available bit

        SECTION .text           ; All in text section (ROM-like)

; Reset vector entry point (matches SCP Monitor)
RESET:
        CLD                     ; Clear direction flag
        XOR     AX, AX          ; Zero AX
        MOV     SS, AX          ; Set SS to 0
        MOV     SP, 1000h       ; Stack at 0000:1000h (safe location)
        MOV     DS, AX          ; Set DS to 0
        MOV     ES, AX          ; Set ES to 0

echo_loop:
        CALL    IN              ; Read a character from UART
        CALL    OUT             ; Echo it back
        JMP     echo_loop       ; Repeat forever

; Input character from UART (exact copy of SCP’s IN)
IN:
        CLI                     ; Disable interrupts (poll mode)
IN_WAIT:
        IN      AL, STAT        ; Read UART status
        TEST    AL, RDRF        ; Check data available bit
        JZ      IN_WAIT         ; Wait until data ready
        IN      AL, DATA        ; Read character from UART
        AND     AL, 7FH         ; Strip to 7 bits (ASCII)
        STI                     ; Re-enable interrupts
        RET                     ; Return with char in AL

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

; Pad to reset vector location (matches SCP Monitor)
        TIMES   0FFF0H - ($ - $$) DB 90H  ; Fill with NOPs to 0FFF0H
        DB      0EAH            ; Far JMP opcode
        DW      RESET, 0F000H   ; Jump to RESET at F000:0000
        TIMES   10000H - ($ - $$) DB 00H  ; Fill to 64KB






