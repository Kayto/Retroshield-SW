; NAM     COUNTER 0-9,999,999
    
ACIA    EQU     $F000       ; ACIA data register
STATUS  EQU     $F001       ; ACIA status register
STACK   EQU     $F87F       ; Stack pointer initial value
COUNT   EQU     $0080       ; Counter storage
MILL    EQU     $0081       ; Millions (1000000s)
HTHOUS  EQU     $0082       ; Hundred thousands (100000s)
TTHOUS  EQU     $0083       ; Ten thousands (10000s)
THOUS   EQU     $0084       ; Thousands (1000s)
HUNDS   EQU     $0085       ; Hundreds
TENS    EQU     $0086       ; Tens
ONES    EQU     $0087       ; Ones

        ORG     $FC00

START   LDS     #STACK      ; Initialize stack pointer
        CLR     MILL        ; Initialize millions to 0
        CLR     HTHOUS      ; Initialize hundred thousands to 0
        CLR     TTHOUS      ; Initialize ten thousands to 0
        CLR     THOUS       ; Initialize thousands to 0
        CLR     HUNDS       ; Initialize hundreds to 0
        CLR     TENS        ; Initialize tens to 0
        CLR     ONES        ; Initialize ones to 0
        
CNTLOP  INC     ONES        ; Increment ones
        LDAA    ONES        
        CMPA    #10         
        BNE     PSTART      
        CLR     ONES        
        INC     TENS        
        LDAA    TENS        
        CMPA    #10         
        BNE     PSTART      
        CLR     TENS        
        INC     HUNDS       
        LDAA    HUNDS       
        CMPA    #10         
        BNE     PSTART      
        CLR     HUNDS       
        INC     THOUS       
        LDAA    THOUS       
        CMPA    #10         
        BNE     PSTART      
        CLR     THOUS       
        INC     TTHOUS      
        LDAA    TTHOUS      
        CMPA    #10         
        BNE     PSTART      
        CLR     TTHOUS      
        INC     HTHOUS      
        LDAA    HTHOUS      
        CMPA    #10         
        BNE     PSTART      
        CLR     HTHOUS      
        INC     MILL        
        LDAA    MILL        
        CMPA    #10         
        BEQ     HALT        ; Now closer to loop control

PSTART  JSR     PRNUM       ; Print number subroutine
        JSR     NEWLN       ; Newline subroutine
        JSR     DELAY       ; Delay subroutine
        BRA     CNTLOP      ; Branch back to start

HALT    WAI                 ; Moved HALT closer to loop control

PRNUM   LDAA    MILL        ; Start printing with millions
        BEQ     CHK_HT
        ADDA    #$30
        JSR     PUTCHR
        BRA     FORCE_HT

CHK_HT  LDAA    HTHOUS
        BEQ     CHK_TT
        ADDA    #$30
        JSR     PUTCHR
        BRA     FORCE_TT

FORCE_HT LDAA    HTHOUS
        ADDA    #$30
        JSR     PUTCHR

FORCE_TT LDAA    TTHOUS
        ADDA    #$30
        JSR     PUTCHR
        BRA     FORCE_TH

CHK_TT  LDAA    TTHOUS
        BEQ     CHK_TH
        ADDA    #$30
        JSR     PUTCHR
        BRA     FORCE_TH

FORCE_TH LDAA    THOUS
        ADDA    #$30
        JSR     PUTCHR
        BRA     FORCE_H

CHK_TH  LDAA    THOUS
        BEQ     CHK_H
        ADDA    #$30
        JSR     PUTCHR
        BRA     FORCE_H

FORCE_H LDAA    HUNDS
        ADDA    #$30
        JSR     PUTCHR
        BRA     FORCE_T

CHK_H   LDAA    HUNDS
        BEQ     CHK_T
        ADDA    #$30
        JSR     PUTCHR
        BRA     FORCE_T

FORCE_T LDAA    TENS
        ADDA    #$30
        JSR     PUTCHR
        BRA     PRINT_O

CHK_T   LDAA    TENS
        BEQ     PRINT_O
        ADDA    #$30
        JSR     PUTCHR

PRINT_O LDAA    ONES
        ADDA    #$30
        JSR     PUTCHR
        RTS

NEWLN   LDAA    #$0D
        JSR     PUTCHR
        LDAA    #$0A
        JSR     PUTCHR
        RTS

DELAY   LDX     #$00FF
DELAYLP DEX
        BNE     DELAYLP
        RTS

PUTCHR  STAA    ACIA
        RTS

        ORG     $FFFE
RESET   FDB     START
        END