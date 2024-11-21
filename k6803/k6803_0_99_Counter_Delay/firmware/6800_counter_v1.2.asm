;NAM     COUNTER 0-999
        
ACIA    EQU     $F000       ; ACIA data register
STATUS  EQU     $F001       ; ACIA status register
STACK   EQU     $F87F       ; Stack pointer initial value
COUNT   EQU     $0080       ; Counter storage
HUNDREDS EQU    $0081       ; Hundreds storage
TENS    EQU     $0082       ; Tens storage
ONES    EQU     $0083       ; Ones storage

        ORG     $FC00

START   LDS     #STACK      ; Initialize stack pointer
        CLR     COUNT       ; Initialize counter to 0
        CLR     HUNDREDS    ; Initialize hundreds to 0
        CLR     TENS        ; Initialize tens to 0
        CLR     ONES        ; Initialize ones to 0
        
CNTLOP  INC     ONES        ; Increment ones
        LDAA    ONES        ; Load ones
        CMPA    #10         ; Compare with 10
        BNE     PRINT       ; If not 10, print
        CLR     ONES        ; Reset ones
        INC     TENS        ; Increment tens
        LDAA    TENS        ; Load tens
        CMPA    #10         ; Compare with 10
        BNE     PRINT       ; If not 10, print
        CLR     TENS        ; Reset tens
        INC     HUNDREDS    ; Increment hundreds
        LDAA    HUNDREDS    ; Load hundreds
        CMPA    #10         ; Compare with 10
        BEQ     HALT        ; If 10, halt

PRINT   LDAA    HUNDREDS    ; Load hundreds
        BEQ     PRINT_TENS  ; If zero, skip to tens
        ADDA    #$30        ; Convert to ASCII
        JSR     PUTCHR      ; Print hundreds
        BRA     FORCE_TENS  ; Always print tens after hundreds

PRINT_TENS 
        LDAA    TENS        ; Load tens
        BEQ     PRINT_ONES  ; If zero and no hundreds, skip to ones
        ADDA    #$30        ; Convert to ASCII
        JSR     PUTCHR      ; Print tens
        BRA     PRINT_ONES

FORCE_TENS
        LDAA    TENS        ; Load tens
        ADDA    #$30        ; Convert to ASCII
        JSR     PUTCHR      ; Print tens regardless of value

PRINT_ONES 
        LDAA    ONES        ; Load ones
        ADDA    #$30        ; Convert to ASCII
        JSR     PUTCHR      ; Print ones

NEWLINE LDAA    #$0D        ; Carriage return
        JSR     PUTCHR
        LDAA    #$0A        ; Line feed
        JSR     PUTCHR

        JSR     DELAY       ; Call delay routine
        BRA     CNTLOP      ; Continue loop

DELAY   LDX     #$0FFF      ; Load delay value
DELAYLP DEX                 ; Decrement X
        BNE     DELAYLP     ; Loop until X is zero
        RTS

PUTCHR  STAA    ACIA        ; Output character to ACIA
        RTS

HALT    WAI                 ; Wait for interrupt

        ORG     $FFFE
RESET   FDB     START       ; Reset vector points to START
        END