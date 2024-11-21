;NAM     COUNTER 0-99
        
ACIA    EQU     $F000       ; ACIA data register
STATUS  EQU     $F001       ; ACIA status register
STACK   EQU     $F87F       ; Stack pointer initial value
COUNT   EQU     $0080       ; Counter storage

        ORG     $FC00

START   LDS     #STACK      ; Initialize stack pointer
        CLR     COUNT       ; Initialize counter to 0
        
CNTLOP  INC     COUNT       ; Increment counter
        LDAA    COUNT       ; Load counter
        CMPA    #$64        ; Compare with 100 (decimal)
        BEQ     HALT        ; If counter reaches 100, halt       

        TAB                 ; Copy to B for division
        LDAA    #$00        ; Clear A for tens digit
DIVIDE  CMPB    #$0A        ; Compare B with 10
        BLT     PRINT       ; If B < 10, print digits
        INCA                ; Increment tens count
        SUBB    #$0A        ; Subtract 10 from ones
        BRA     DIVIDE      ; Continue division

PRINT   PSHA                ; Save tens digit
        TSTA                ; Test if tens digit is zero
        BEQ     ONES        ; If zero, skip to ones digit
        ADDA    #$30        ; Convert tens to ASCII
        JSR     PUTCHR      ; Print tens digit
ONES    TBA                 ; Get ones digit to A
        ADDA    #$30        ; Convert ones to ASCII
        JSR     PUTCHR      ; Print ones

NEWLINE LDAA    #$0D        ; Carriage return
        JSR     PUTCHR
        LDAA    #$0A        ; Line feed
        JSR     PUTCHR

        JSR     DELAY       ; Call delay routine
        BRA     CNTLOP      ; Continue loop

DELAY   LDX     #$FFFF      ; Load delay value
DELAYLP DEX                 ; Decrement X
        BNE     DELAYLP     ; Loop until X is zero
        RTS

PUTCHR  STAA    ACIA        ; Output character to ACIA
        RTS

HALT    WAI                 ; Wait for interrupt

        ORG     $FFFE
RESET   FDB     START       ; Reset vector points to START
        END