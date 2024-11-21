;NAM HELLO           ; Program name
        
; Memory mapped I/O - Assuming ACIA at $8004
ACIA    EQU $F000          ; ACIA data register
STATUS  EQU $F001          ; ACIA status register
;CONTROL EQU $8006          ; ACIA control register
STACK   EQU $F87F           ; Stack pointer initial value



    ORG $FC00          ; Program starts at $0100

; Reset routine
RESET   LDS #STACK         ; Initialize stack pointer

; Initialize ACIA - not required as ACIA is preset
;LDAA #%00000011    ; Reset ACIA
;STAA CONTROL       ; Store to control register
;LDAA #%00010101    ; 8N1, /16 clock
;STAA CONTROL       ; Configure ACIA

; Clear RAM (assuming RAM from $0000 to $0FFF)
        LDX #$0000         ; Start of RAM
CLRRAM  CLR 0,X           ; Clear location
        INX                ; Next location
        CPX #$0FFF        ; End of RAM?
        BNE CLRRAM        ; If not, continue clearing

        JMP START         ; Jump to main program

; Main program
START   LDX #MESSAGE       ; Load message address into X
LOOP    LDAA 0,X          ; Load character from message
        BEQ HALT          ; If null terminator, we're done
        STAA ACIA         ; output character
        INX               ; Point to next character
        BRA LOOP          ; Repeat for next character
HALT    WAI               ; Wait for interrupt (effectively halts)

MESSAGE FCC 'Hello, World!' ; Message to display
        FCB $0D           ; Carriage return
        FCB $0A           ; Line feed
        FCB $00           ; Null terminator


        ORG $FFFE          ; Reset vector location
        FDB RESET          ; Reset vector points to reset routine        

    END         ; End of program, start at RESET