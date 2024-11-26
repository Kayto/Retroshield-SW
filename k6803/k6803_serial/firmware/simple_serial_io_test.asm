;******************************************************************************
; File: simple_serial_io_test.asm
; Title: Minimal Serial I/O Test for Motorola 6803 Retroshield
; Author: kayto@github.com
; Date: November 26, 2024
; Version: 1.0
;
; Description:
;   Optimised and Minimal version. Previous versions 
;   contained ACIA init and delay loop
;
; Memory Map:
;   $F000 - 6850 Serial Data Register (Read/Write)
;   $F001 - 6850 Serial Status Register
;   Program located at $FC00-$FFFF
;
; Register Usage:
;   A - Used for character I/O and status checking
;   X - Used for loops
;   SP - Initialized to $F87F
;
; Status Register Bits:
;   Bit 0 - Input Ready (1 = Character available)
;   Bit 1 - Output Ready (1 = Ready to transmit)
;
; Revision History:
;   1.0 - Initial release
;******************************************************************************
; I/O Addresses
TERD    EQU $F000    ; ACIA Data Register
TERS    EQU $F001    ; ACIA Status Register
STACK   EQU $F87F    ; Stack location

        ORG $FC00

;******************************************************************************
; Program Entry
;******************************************************************************
START   LDS #STACK          ; Initialize stack pointer

LOOP    JSR READ           ; Read and echo character
        BRA LOOP           ; Repeat forever

;******************************************************************************
; ACIA Initialization - not required for 6803 Retroshield
;******************************************************************************

;******************************************************************************
; Main Input/Output Loop - Exact copy from working echo
;******************************************************************************
READ    LDAA TERD          ; Read input character
        CMPA #$0D          ; Check for carriage return
        BEQ DO_CR          ; Handle CR if found
        STAA TERD          ; Echo character
        BRA READY          ; Check if ready for next

READY   LDAA TERS          ; Check output status
        BITA #$02          ; Test output ready
        BEQ READY          ; Wait if not ready
        BRA READ           ; Continue reading

DO_CR   LDX #CRLF          ; Point to CRLF
        JSR STROUT1        ; Send it
        BRA READY          ; Return to main loop

;******************************************************************************
; String Output Routines - Exact copy from working echo
;******************************************************************************
STROUT  STAA TERD          ; Output current character
        INX                ; Point to next character
STROUT1 LDAA 0,X           ; Get next character
        CMPA #0            ; Check for end of string
        BNE STROUT         ; Continue if not end
        RTS

;******************************************************************************
; Constants
;******************************************************************************
CRLF    FCB $0D,$0A,$00    ; CR, LF, null terminator

;******************************************************************************
; Vector Table
;******************************************************************************
        ORG $FFF8
        FDB START          ; IRQ Vector
        FDB START          ; SWI Vector
        FDB START          ; NMI Vector
        FDB START          ; Reset Vector

        END START


        
