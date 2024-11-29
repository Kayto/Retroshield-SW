; File: 6800_serial_text_handling.asm
; Title: Serial I/O backspace handling and messages
; Author: kayto@github.com
; Date: November 29, 2024
; Version: 1.0
;
; Description:
; Serial i/o with message, CRLF, delete/backspace handling
; For Motorola 6800 with ACIA
; ** i cant correct the bug that drops the 'E' in the
; ** exit message. Debug output added to Arduino code which
; ** shows correct printing so suspect a timing issue somewhere.
;
;RAMLO_START   0x0080
;RAMLO_END     0x0FFF
;RAMHI_START   0xF800
;RAMHI_END     0xF8FF
;
        CPU       6801      
; I/O Addresses
TERD    EQU $F000    ; ACIA Data Register
TERS    EQU $F001    ; ACIA Status Register
STACK   EQU $F87F    ; Stack location

; Constants
CR      EQU $0D      ; Carriage return
LF      EQU $0A      ; Line feed
BS      EQU $08      ; Backspace
ESC     EQU $1B      ; Escape key ($1B = 27)
SPACE   EQU $20      ; Space character
DEL     EQU $7F      ; Delete character
EOT     EQU $00      ; End of transmission (string terminator)

; Variables in zero page
CURPOS  EQU $0080    ; Cursor position (2 bytes)
BUFST   EQU $0085    ; Buffer start (2 bytes)
BUFEND  EQU $0087    ; Buffer end (2 bytes)
CURLINE EQU $0089    ; Current line (2 bytes)
TOTLINE EQU $008B    ; Total lines (2 bytes)
ECHOF   EQU $008D    ; Echo flag (1 = no echo)

        ORG $FC00

START   LDS #STACK          ; Initialize stack pointer
        CLR ECHOF           ; Enable echo
        LDX #LINEBUF        ; Initialize buffer
        STX BUFST           ; Set buffer start
        STX BUFEND          ; Set buffer end
        LDX #MSGWEL         ; Load welcome message
        JSR STROUT          ; Display welcome
MAIN    JSR CHRIN          ; Get character with echo

        JSR STORE_CHAR     ; Store character in buffer
        BRA MAIN           ; Continue main loop

; Character Output
CHROUT  PSHB               ; Save B register
CHR01   LDAB TERS          ; Check if ready to transmit
        ANDB #$04          ; Test transmit ready bit
        BEQ CHR01          ; Loop if not ready
        PULB               ; Restore B
        STAA TERD          ; Output character
        RTS                ; Return from subroutine

; Character Input (Raw)
CHRIN8  LDAA TERS          ; Check if character ready
        ANDA #$02          ; Test receive bit
        BEQ CHRIN8         ; Loop if no character
        LDAA TERD          ; Get character
        RTS

; Character Input with Echo
CHRIN   BSR CHRIN8         ; Get character
        TST ECHOF          ; Check echo flag
        BNE NOECHO         ; Skip echo if flag set
        BSR CHROUT         ; Echo character
NOECHO  RTS

; String Output
STROUT  LDAA 0,X          ; Get character from string
        CMPA #EOT         ; End of string?
        BEQ STROUT_DONE   ; If EOT, we're done
        JSR CHROUT        ; Output character
        INX               ; Point to next
        BRA STROUT        ; Continue
STROUT_DONE
        RTS

; Store character in buffer
STORE_CHAR
        CMPA #BS           ; Check for backspace
        BEQ DO_BS          ; Handle backspace
        CMPA #DEL          ; Check for delete
        BEQ DO_BS          ; Handle delete same as backspace
        CMPA #CR           ; Check for carriage return
        BEQ DO_CRLF        ; Handle CR+LF
        CMPA #ESC          ; Check for ESC key
        BEQ EXIT           ; If ESC, exit
        LDX BUFEND         ; Get buffer end
        STAA 0,X           ; Store character
        INX                ; Move pointer
        STX BUFEND         ; Update buffer end
        RTS

; Handle CR+LF
DO_CRLF LDAA #CR           ; Load CR
        JSR CHROUT         ; Send CR
        LDAA #LF           ; Load LF
        JSR CHROUT         ; Send LF
        RTS

; Handle backspace
DO_BS   LDX BUFEND         ; Get buffer end
        CPX BUFST          ; At start of buffer?
        BEQ BS_DONE        ; Yes, ignore backspace
        DEX                ; Move back one
        STX BUFEND         ; Update buffer end
        LDAA #SPACE        ; Send space
        JSR CHROUT         ; Clear character
        LDAA #BS           ; Send backspace sequence
        JSR CHROUT         ; Move cursor left
BS_DONE RTS

; Welcome message display
WELCOME LDX #MSGWEL   ; Point to welcome message
        JSR STROUT         ; Output it
        RTS

; Exit editor and halt
EXIT    LDX #MSGEXI     ; Point to exit message
        JSR STROUT        ; Output it
        JMP HALT          ; Go to halt routine

; Halt routine
HALT    WAI               ; Wait for interrupt
        RTS

; Messages and Constants

MSGWEL  FCC 'Serial I/O test'
        FCB CR,LF
        FCC 'Type text, ESC to exit'
        FCB CR,LF
        FCB CR,LF
        FCC 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-=[];#,./\'
        FCB CR,LF,EOT
MSGEXI  
        FCC 'EExiting editor'           ;** I can't locate any bug that drops the 'E'
        FCB CR,LF,EOT                   ;** so the workaround is to add an extra!

; Buffer space
LINEBUF RMB 80           ; 80 byte line buffer

        ORG $FFF8
        FDB HALT         ; IRQ Vector
        FDB HALT         ; SWI Vector
        FDB HALT          ; NMI Vector
        FDB START          ; Reset Vector

        END










