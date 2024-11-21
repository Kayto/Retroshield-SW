;******************************************************************************
; File: 6800_serial_echo_v1.2.asm
; Title: 6800 Serial Echo Program
; Author: kayto@github.com
; Date: November 18, 2024
; Version: 1.2
;
; Description:
;   Serial communication program for Motorola 6800 microprocessor that provides
;   character echo functionality with prompt/CR/LF handling. The program reads
;   characters from a serial input port and echoes them back to the output.
;
; Memory Map:
;   $F000 - 6850 ACIA Data Register (Read/Write)
;   $F001 - 6850 ACIA Status Register (Read only)
;   
;   LORAM_START: 0x0080 - Start of user RAM
;   LORAM_END:   0x0FFF - End of user RAM
;   HIRAM_START: 0xF800 - Start of system RAM
;   HIRAM_END:   0xF8FF - End of system RAM
;   ROM_START:   0xFC00 - Start of program ROM
;   ROM_END:     0xFFF7 - End of program area
;   BOOT_START:  0xFFF8 - Start of vector table
;   BOOT_END:    0xFFFF - End of vector table

;
; Register Usage:
;   A - Used for character I/O and ACIA status checking
;       - Reads ACIA status from TERS ($F001)
;       - Reads/writes character data from/to TERD ($F000)
;   X - Used as pointer for:
;       - Memory operations during RAM clearing
;       - String handling (prompt and CRLF output)
;       - Sequential memory access
;   SP - Stack Pointer, initialized to $F87F
;        Provides stack space from $F87F downward
;
; Status Register Bits:
;   Bit 0 - Receive Data Register Full (RDRF)
;           1 = Character available to read
;           0 = No character available
;   Bit 1 - Transmit Data Register Empty (TDRE)
;           1 = Ready to transmit next character
;           0 = Still transmitting previous character
;
; Revision History:
;   1.2 - added prompt string output routine
;   1.1 - added prompt ">"
;   1.0 - Initial release
;******************************************************************************
; 
; I/O Eequates
TERD	EQU $F000	     ;ACIADA TERMINAL DATA PORT
                             ; Read: Received character
                             ; Write: Character to transmit
TERS	EQU $F001	     ;ACIACS TERMINAL STATUS PORT
;******************************************************************************
; Stack Address at $F87f
STACK   EQU $F87F            ; Top of stack location
                             ; Stack grows downward from this address 
;
;******************************************************************************
        ORG   $FC00          ; Program starts at $FC00

;******************************************************************************
; Program Initialization
;******************************************************************************
; RESET ENTRY POINT
RST     LDS #STACK 	     ; Initialize stack pointer
; Clear RAM (assuming RAM from $0080 to $0FFF)
        LDX #$0080           ; Start of RAM
CLRRAM  CLR 0,X              ; Clear location
        INX                  ; Next location
        CPX #$0FFF           ; End of RAM?
        BNE CLRRAM           ; If not, continue clearing

; ACIA INITIALIZE
;        LDAA	#$03	     ; RESET CODE
;        STAA	TERS
;        NOP
;        LDAA	#$15	     ; 8N1 NON-INTERRUPT
;        STAA	TERS       
;
        BRA START            ; Jump to main program
;
;******************************************************************************
; Entry
;******************************************************************************
START   LDX #PROMPT         ; Load message address into X
LOOP    LDAA 0,X            ; Load character from message
        BEQ READY           ; If null terminator, we're done
        STAA TERD           ; Send character
        INX                 ; Point to next character
        BRA LOOP            ; Repeat for next character
;
;******************************************************************************
; Main Input/Output Loop
;******************************************************************************
;
READ    LDAA  TERD            ; Read input character
        CMPA  #$0D            ; Check for carriage return
        BEQ   DO_CR           ; Handle CR if found
        STAA  TERD            ; Echo character
        BRA   READY           ; No, get next char
;
READY   LDAA  TERS            ; Check output status
        BITA  #$02            ; Test output ready
        BEQ   READY           ; Wait if not ready
        BRA   READ            ; Continue reading
;
;******************************************************************************
; Carriage Return/Line Feed Handler
;******************************************************************************
DO_CR   LDX    #CRLF          ; Point to CRLF
        JSR    STROUT1        ; Send it 
        BRA READY             ; Return to main loop 
;
;******************************************************************************
; Prompt/CRLF
;******************************************************************************
CRLF    FCB    $0D,$0A        ; CR, LF, terminator      
PROMPT  FCC    '>',' '        ; Prompt string
        FCB    $00            ; String terminator
;
;******************************************************************************
; Character String output routine
;******************************************************************************
STROUT	STAA  TERD 		; Output current character
	INX			; Point to next character
STROUT1	LDA A	0,X		; Get next character
	CMP A	#0		; Check for end of string
	BNE	STROUT		; Continue if not end
	RTS
;;******************************************************************************
; Padding and Vector Table
;******************************************************************************
        ; Fill unused space with $FF
        FCB   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Padding bytes
        FCB   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Padding bytes
        FCB   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Padding bytes
;
;******************************************************************************
; Interrupt Vectors
;******************************************************************************
        ORG   $FFF8           ; Vector table start
        FDB   RST             ; IRQ Vector ($FFF8-$FFF9)
        FDB   RST             ; SWI Vector ($FFFA-$FFFB)
        FDB   RST             ; NMI Vector ($FFFC-$FFFD)
        FDB   START           ; Reset Vector ($FFFE-$FFFF)
;
        END        