; Seattle Computer Products 8086 Monitor version 1.5 with Intel HEX Loader
; Original by Tim Paterson, Intel HEX loader added by kayto@github.com
; Hardware: UART only at BASE=0F0H
; Memory: RAM at 0000:0100H, Code at F000:0000H, RESET at 0FFF0H
; Date: March 07, 2025

CPU     8086

BASE:   EQU     0F0H            ; CPU Support base port address
STAT:   EQU     BASE+7          ; UART status port (0F7H)
DATA:   EQU     BASE+6          ; UART data port (0F6H)
RDRF:   EQU     01h             ; UART data available bit
TDRE:   EQU     02h             ; UART transmitter ready bit

BUFLEN: EQU     80              ; Maximum length of line input buffer
BPMAX:  EQU     10              ; Maximum number of breakpoints
BPLEN:  EQU     BPMAX+BPMAX     ; Length of breakpoint table
REGTABLEN:EQU   14              ; Number of registers
PROMPT: EQU     ">"
CAN:    EQU     "@"
ESC:    EQU     1BH             ; Escape key for Intel HEX exit

SECTION .bss

RESB    100H                    ; Reserve 256 bytes before RAM area

; RAM area starts at 0000:0100H
BRKCNT: RESW    1               ; Number of breakpoints (0100H)
TCOUNT: RESW    1               ; Number of steps to trace (0102H)
BPTAB:  RESW    BPMAX           ; Breakpoint table (0104H)
LINEBUF:RESB    BUFLEN+1        ; Line input buffer (0118H)
ALIGNB  2
RESW    50                      ; Working stack area (016AH)
STACK:

; Register save area starts at 01CEH
AXSAVE: RESW    1               ; 01CEH
BXSAVE: RESW    1
CXSAVE: RESW    1
DXSAVE: RESW    1
SPSAVE: RESW    1
BPSAVE: RESW    1
SISAVE: RESW    1
DISAVE: RESW    1
DSSAVE: RESW    1
ESSAVE: RESW    1
RSTACK:                         ; Stack set here
SSSAVE: RESW    1
CSSAVE: RESW    1
IPSAVE: RESW    1
FSAVE:  RESW    1               ; 01E8H

; New variables for Intel HEX loader (starting at 01EAH)
BCS:    RESB    1               ; Byte checksum (01EAH)
BCSERR: RESB    1               ; Checksum error flag (01EBH)
EXITFL: RESB    1               ; Exit flag for Intel HEX (01ECH)

SECTION .text
ORG     0                       ; Code starts at F000:0000H

RESET:
    CLD
    XOR     AX,AX
    MOV     SS,AX
    MOV     DS,AX
    MOV     ES,AX
    MOV     DI,AXSAVE
    MOV     CX,14
    REP
    STOSW                   ; Set register images to zero
    OR      BYTE [FSAVE+1],2 ; Enable interrupts
    MOV     CL,4
    MOV     AL,40H
    MOV     DI,DSSAVE
    REP
    STOSW                   ; Set segment reg. images to 40H
    MOV     BYTE [SPSAVE+1],0CH ; Set user stack to 400H+0C00H
    MOV     SP,STACK

DOMON:
    MOV     SI,HEADER
    CALL    PRINTMES

COMMAND:
    CLD
    XOR     AX,AX
    MOV     DS,AX
    MOV     ES,AX
    MOV     SP,STACK
    MOV     WORD [64H],INT  ; Set UART interrupt vector
    MOV     WORD [66H],CS
    MOV     AL,PROMPT
    CALL    OUT
    CALL    INBUF           ; Get command line
    CALL    SCANB           ; Scan off leading blanks
    JZ      COMMAND         ; Null command?
    MOV     AL,[DI]         ; AL=first non-blank character
    SUB     AL,"B"          ; Low end range check
    JC      ERR1
    CMP     AL,"T"+1-"B"    ; Upper end range check
    JNC     ERR1
    INC     DI
    SHL     AL,1            ; Times two
    CBW                     ; Now a 16-bit quantity
    XCHG    BX,AX           ; In BX we can address with it
    CALL    [CS:BX+COMTAB]  ; Execute command
    JMP     COMMAND
ERR1:
    JMP     ERROR

INBUF:
    MOV     DI,LINEBUF
    XOR     CX,CX
GETCH:
    CALL    IN
    CMP     AL,20H
    JC      CONTROL
    CMP     AL,7FH
    JZ      BACKSP
    CALL    OUT
    CMP     AL,CAN
    JZ      KILL
    STOSB
    INC     CX
    CMP     CX,BUFLEN
    JBE     GETCH
BACKSP:
    JCXZ    GETCH
    DEC     DI
    DEC     CX
    CALL    BACKUP
    JMP     GETCH
CONTROL:
    CMP     AL,8
    JZ      BACKSP
    CMP     AL,13
    JNZ     GETCH
    STOSB
    MOV     DI,LINEBUF

CRLF:
    MOV     AL,13
    CALL    OUT
    MOV     AL,10
    JMP     OUT

KILL:
    CALL    CRLF
    JMP     COMMAND

IN:
    CLI
    IN      AL,STAT
    TEST    AL,RDRF
    JZ      IN
    IN      AL,DATA
    AND     AL,7FH
    STI
    RET

BACKUP:
    MOV     SI,BACMES
PRINTMES:
    CS
    LODSB
    CALL    OUT
    SHL     AL,1
    JNC     PRINTMES
    RET

OUT:
    PUSH    AX
OUT1:
    IN      AL,STAT
    AND     AL,TDRE
    JZ      OUT1
    POP     AX
    OUT     DATA,AL
    RET

SCANP:
    CALL    SCANB
    CMP     BYTE [DI],","
    JNE     EOLCHK
    INC     DI
SCANB:
    MOV     AL," "
    PUSH    CX
    MOV     CL,-1
    REPE
    SCASB
    DEC     DI
    POP     CX
EOLCHK:
    CMP     BYTE [DI],13
    RET

OUTSI:
    MOV     DX,DS
    MOV     AH,0
    CALL    SHIFT4
    ADD     DX,SI
    JMP     OUTADD

OUTDI:
    MOV     DX,ES
    MOV     AH,0
    CALL    SHIFT4
    ADD     DX,DI
OUTADD:
    ADC     AH,0
    CALL    HIDIG
OUT16:
    MOV     AL,DH
    CALL    HEX
    MOV     AL,DL
HEX:
    MOV     AH,AL
    PUSH    CX
    MOV     CL,4
    SHR     AL,CL
    POP     CX
    CALL    DIGIT
HIDIG:
    MOV     AL,AH
DIGIT:
    AND     AL,0FH
    ADD     AL,90H
    DAA
    ADC     AL,40H
    DAA
    JMP     OUT

BLANK:
    MOV     AL," "
    JMP     OUT

TAB:
    CALL    BLANK
    LOOP    TAB
    RET

COMTAB:
    DW      PERR    ; B
    DW      PERR    ; C
    DW      DUMP    ; D
    DW      ENTER   ; E
    DW      FILL    ; F
    DW      GO      ; G
    DW      PERR    ; H
    DW      INPUT   ; I
    DW      PERR    ; J
    DW      PERR    ; K
    DW      LOADHEX ; L - Intel HEX loader
    DW      MOVE    ; M
    DW      PERR    ; N
    DW      OUTPUT  ; O
    DW      PERR    ; P
    DW      PERR    ; Q
    DW      REG     ; R
    DW      SEARCH  ; S
    DW      TRACE   ; T

DUMP:
    CALL    RANGE
    PUSH    AX
    CALL    GETEOL
    POP     DS
    MOV     SI,DX
ROW:
    CALL    OUTSI
    PUSH    SI
BYTE0:
    CALL    BLANK
BYTE1:
    LODSB
    CALL    HEX
    POP     DX
    DEC     CX
    JZ      ASCII
    MOV     AX,SI
    TEST    AL,0FH
    JZ      ENDROW
    PUSH    DX
    TEST    AL,7
    JNZ     BYTE0
    MOV     AL,"-"
    CALL    OUT
    JMP     BYTE1
ENDROW:
    CALL    ASCII
    JMP     ROW
ASCII:
    PUSH    CX
    MOV     AX,SI
    MOV     SI,DX
    SUB     AX,DX
    MOV     BX,AX
    SHL     AX,1
    ADD     AX,BX
    MOV     CX,51
    SUB     CX,AX
    CALL    TAB
    MOV     CX,BX
ASCDMP:
    LODSB
    AND     AL,7FH
    CMP     AL,7FH
    JZ      NOPRT
    CMP     AL," "
    JNC     PRIN
NOPRT:
    MOV     AL,"."
PRIN:
    CALL    OUT
    LOOP    ASCDMP
    POP     CX
    JMP     CRLF

ENTER:
    MOV     CX,5
    CALL    GETHEX
    CALL    GETSEG
    SUB     AH,8
    ADD     DH,80H
    PUSH    AX
    PUSH    DX
    CALL    SCANB
    JNZ     GETLIST
    POP     DI
    POP     ES
GETROW:
    CALL    OUTDI
    CALL    BLANK
GETBYTE:
    MOV     AL,[ES:DI]
    CALL    HEX
    MOV     AL,"-"
    CALL    OUT
    MOV     CX,2
    MOV     DX,0
GETDIG:
    CALL    IN
    MOV     AH,AL
    CALL    HEXCHK
    XCHG    AH,AL
    JC      NOHEX
    CALL    OUT
    MOV     DH,DL
    MOV     DL,AH
    LOOP    GETDIG
WAITIN:
    CALL    IN
NOHEX:
    CMP     AL,8
    JZ      BS
    CMP     AL,7FH
    JZ      BS
    CMP     AL,"-"
    JZ      PREV
    CMP     AL,13
    JZ      EOL
    CMP     AL," "
    JZ      NEXT
    MOV     AL,7
    CALL    OUT
    JCXZ    WAITIN
    JMP     GETDIG
BS:
    CMP     CL,2
    JZ      GETDIG
    INC     CL
    MOV     DL,DH
    MOV     DH,CH
    CALL    BACKUP
    JMP     GETDIG
STORE:
    CMP     CL,2
    JZ      NOSTO
    PUSH    CX
    MOV     CL,4
    SHL     DH,CL
    POP     CX
    OR      DL,DH
    MOV     [ES:DI],DL
NOSTO:
    INC     DI
    RET
EOL:
    CALL    STORE
    JMP     CRLF
NEXT:
    CALL    STORE
    INC     CX
    INC     CX
    CALL    TAB
    MOV     AX,DI
    AND     AL,7
    JNZ     GETBYTE
NEWROW:
    CALL    CRLF
    JMP     GETROW          ; Fixed: Replaced 'Ascension' with 'GETROW'
PREV:
    CALL    STORE
    DEC     DI
    DEC     DI
    JMP     NEWROW
GETLIST:
    CALL    LIST
    POP     DI
    POP     ES
    MOV     SI,LINEBUF
    MOV     CX,BX
    REP
    MOVSB
    RET

FILL:
    CALL    RANGE
    PUSH    CX
    PUSH    AX
    PUSH    DX
    CALL    LIST
    POP     DI
    POP     ES
    POP     CX
    CMP     BX,CX
    MOV     SI,LINEBUF
    JCXZ    BIGRNG
    JAE     COPYLIST
BIGRNG:
    SUB     CX,BX
    XCHG    CX,BX
    PUSH    DI
    REP
    MOVSB
    POP     SI
    MOV     CX,BX
    PUSH    ES
    POP     DS
    JMP     COPYLIST

GO:
    MOV     BX,LINEBUF
    XOR     SI,SI
GO1:
    CALL    SCANP
    JZ      EXEC
    MOV     CX,5
    CALL    GETHEX
    MOV     [BX],DX
    MOV     [BX-BPLEN+1],AH
    INC     BX
    INC     BX
    INC     SI
    CMP     SI,BPMAX+1
    JNZ     GO1
    MOV     AX,5000H+"B"
    JMP     ERR
EXEC:
    MOV     [BRKCNT],SI
    CALL    GETEOL
    MOV     CX,SI
    JCXZ    NOBP
    MOV     SI,BPTAB
SETBP:
    MOV     DX,[SI+BPLEN]
    LODSW
    CALL    GETSEG
    MOV     DS,AX
    MOV     DI,DX
    MOV     AL,[DI]
    MOV     BYTE [DI],0CCH
    PUSH    ES
    POP     DS
    MOV     [SI-2],AL
    LOOP    SETBP
NOBP:
    MOV     WORD [TCOUNT],1
    MOV     WORD [12],BREAKFIX
    MOV     [14],CS
    MOV     WORD [4],REENTER
    MOV     [6],CS
    CLI
    MOV     WORD [64H],REENTER
    MOV     [66H],CS
    MOV     SP,STACK
    POP     AX
    POP     BX
    POP     CX
    POP     DX
    POP     BP
    POP     BP
    POP     SI
    POP     DI
    POP     ES
    POP     ES
    POP     SS
    MOV     SP,[SPSAVE]
    PUSH    WORD [FSAVE]
    PUSH    WORD [CSSAVE]
    PUSH    WORD [IPSAVE]
    MOV     DS,[DSSAVE]
    IRET

INPUT:
    MOV     CX,4
    CALL    GETHEX
    IN      AL,DX
    CALL    HEX
    JMP     CRLF

MOVE:
    CALL    RANGE
    PUSH    CX
    PUSH    AX
    MOV     SI,DX
    MOV     CX,5
    CALL    GETHEX
    CALL    GETEOL
    CALL    GETSEG
    MOV     DI,DX
    POP     BX
    MOV     DS,BX
    MOV     ES,AX
    POP     CX
    CMP     DI,SI
    SBB     AX,BX
    JB      COPYLIST
    DEC     CX
    ADD     SI,CX
    ADD     DI,CX
    STD
    INC     CX
COPYLIST:
    MOVSB
    DEC     CX
    REP
    MOVSB
    RET

OUTPUT:
    MOV     CX,4
    CALL    GETHEX
    PUSH    DX
    MOV     CX,2
    CALL    GETHEX
    XCHG    AX,DX
    POP     DX
    OUT     DX,AL
    RET

REG:
    CALL    SCANP
    JZ      DISPREG
    MOV     DL,[DI]
    INC     DI
    MOV     DH,[DI]
    CMP     DH,13
    JZ      FLAG
    INC     DI
    CALL    GETEOL
    CMP     DH," "
    JZ      FLAG
    MOV     DI,REGTAB
    XCHG    AX,DX
    PUSH    CS
    POP     ES
    MOV     CX,REGTABLEN
    REPNZ
    SCASW
    JNZ     BADREG
    OR      CX,CX
    JNZ     NOTPC
    DEC     DI
    DEC     DI
    MOV     AX,[CS:DI-2]
NOTPC:
    CALL    OUT
    MOV     AL,AH
    CALL    OUT
    CALL    BLANK
    PUSH    DS
    POP     ES
    LEA     BX,[DI+REGDIF-2]
    MOV     DX,[BX]
    CALL    OUT16
    CALL    CRLF
    MOV     AL,":"
    CALL    OUT
    CALL    INBUF
    CALL    SCANB
    JZ      RET3
    MOV     CX,4
    CALL    GETHEX1
    CALL    GETEOL
    MOV     [BX],DX
RET3:
    RET
BADREG:
    MOV     AX,5200H+"B"
    JMP     ERR
DISPREG:
    MOV     SI,REGTAB
    MOV     BX,AXSAVE
    MOV     CX,8
    CALL    DISPREGLINE
    CALL    CRLF
    MOV     CX,5
    CALL    DISPREGLINE
    CALL    BLANK
    CALL    DISPFLAGS
    JMP     CRLF
FLAG:
    CMP     DL,"F"
    JNZ     BADREG
    CALL    DISPFLAGS
    MOV     AL,"-"
    CALL    OUT
    CALL    INBUF
    CALL    SCANB
    XOR     BX,BX
    MOV     DX,[FSAVE]
GETFLG:
    MOV     SI,DI
    LODSW
    CMP     AL,13
    JZ      SAVCHG
    CMP     AH,13
    JZ      FLGERR
    MOV     DI,FLAGTAB
    MOV     CX,32
    PUSH    CS
    POP     ES
    REPNE
    SCASW
    JNZ     FLGERR
    MOV     CH,CL
    AND     CL,0FH
    MOV     AX,1
    ROL     AX,CL
    TEST    AX,BX
    JNZ     REPFLG
    OR      BX,AX
    OR      DX,AX
    TEST    CH,16
    JNZ     NEXFLG
    XOR     DX,AX
NEXFLG:
    MOV     DI,SI
    PUSH    DS
    POP     ES
    CALL    SCANP
    JMP     GETFLG
DISPREGLINE:
    CS
    LODSW
    CALL    OUT
    MOV     AL,AH
    CALL    OUT
    MOV     AL,"="
    CALL    OUT
    MOV     DX,[BX]
    INC     BX
    INC     BX
    CALL    OUT16
    CALL    BLANK
    CALL    BLANK
    LOOP    DISPREGLINE
    RET
REPFLG:
    MOV     AX,4600H+"D"
FERR:
    CALL    SAVCHG
ERR:
    CALL    OUT
    MOV     AL,AH
    CALL    OUT
    MOV     SI,ERRMES
    JMP     PRINT
SAVCHG:
    MOV     [FSAVE],DX
    RET
FLGERR:
    MOV     AX,4600H+"B"
    JMP     FERR
DISPFLAGS:
    MOV     SI,FLAGTAB
    MOV     CX,16
    MOV     DX,[FSAVE]
DFLAGS:
    CS
    LODSW
    SHL     DX,1
    JC      FLAGSET
    MOV     AX,[CS:SI+30]
FLAGSET:
    OR      AX,AX
    JZ      NEXTFLG
    CALL    OUT
    MOV     AL,AH
    CALL    OUT
    CALL    BLANK
NEXTFLG:
    LOOP    DFLAGS
    RET

SEARCH:
    CALL    RANGE
    PUSH    CX
    PUSH    AX
    PUSH    DX
    CALL    LIST
    DEC     BX
    POP     DI
    POP     ES
    POP     CX
    SUB     CX,BX
SCAN:
    MOV     SI,LINEBUF
    LODSB
DOSCAN:
    SCASB
    LOOPNE  DOSCAN
    JNZ     RET
    PUSH    BX
    XCHG    BX,CX
    PUSH    DI
    REPE
    CMPSB
    MOV     CX,BX
    POP     DI
    POP     BX
    JNZ     TEST
    DEC     DI
    CALL    OUTDI
    INC     DI
    CALL    CRLF
TEST:
    JCXZ    RET
    JMP     SCAN
RET:
    RET

TRACE:
    CALL    SCANP
    CALL    HEXIN
    MOV     DX,1
    JC      STOCNT
    MOV     CX,4
    CALL    GETHEX
STOCNT:
    MOV     [TCOUNT],DX
    CALL    GETEOL
STEP:
    MOV     WORD [BRKCNT],0
    OR      BYTE [FSAVE+1],1
EXIT:
    MOV     WORD [12],BREAKFIX
    MOV     [14],CS
    MOV     WORD [4],REENTER
    MOV     [6],CS
    CLI
    MOV     WORD [64H],REENTER
    MOV     [66H],CS
    MOV     SP,STACK
    POP     AX
    POP     BX
    POP     CX
    POP     DX
    POP     BP
    POP     BP
    POP     SI
    POP     DI
    POP     ES
    POP     ES
    POP     SS
    MOV     SP,[SPSAVE]
    PUSH    WORD [FSAVE]
    PUSH    WORD [CSSAVE]
    PUSH    WORD [IPSAVE]
    MOV     DS,[DSSAVE]
    IRET
STEP1:
    JMP     STEP

BREAKFIX:
    XCHG    SP,BP
    DEC     WORD [BP]
    XCHG    SP,BP

REENTER:
    PUSH    AX
    PUSH    DS
    XOR     AX,AX
    MOV     DS,AX
    MOV     [SPSAVE],SP
    MOV     [SSSAVE],SS
    POP     DS
    POP     AX
    XOR     SP,SP
    MOV     SS,SP
    MOV     SP,RSTACK
    PUSH    ES
    PUSH    DS
    PUSH    DI
    PUSH    SI
    PUSH    BP
    DEC     SP
    DEC     SP
    PUSH    DX
    PUSH    CX
    PUSH    BX
    PUSH    AX
    PUSH    SS
    POP     DS
    MOV     SP,[SPSAVE]
    MOV     SS,[SSSAVE]
    ADD     SP,4
    POP     WORD [IPSAVE]
    POP     WORD [CSSAVE]
    POP     AX
    AND     AH,0FEH
    MOV     [FSAVE],AX
    MOV     [SPSAVE],SP
    PUSH    DS
    POP     ES
    PUSH    DS
    POP     SS
    MOV     SP,STACK
    MOV     WORD [64H],INT
    STI
    CLD
    CALL    CRLF
    CALL    DISPREG
    DEC     WORD [TCOUNT]
    JNZ     STEP1
ENDGO:
    MOV     SI,BPTAB
    MOV     CX,[BRKCNT]
    JCXZ    COMJMP
CLEARBP:
    MOV     DX,[SI+BPLEN]
    LODSW
    PUSH    AX
    CALL    GETSEG
    MOV     ES,AX
    MOV     DI,DX
    POP     AX
    STOSB
    LOOP    CLEARBP
COMJMP:
    JMP     COMMAND

GETSEG:
    MOV     AL,DL
    AND     AL,0FH
    CALL    SHIFT4
    MOV     DL,AL
    MOV     AL,DH
    XOR     DH,DH
    RET

SHIFT4:
    SHL     DX,1
    RCL     AH,1
    SHL     DX,1
    RCL     AH,1
    SHL     DX,1
    RCL     AH,1
    SHL     DX,1
    RCL     AH,1
    RET

RANGE:
    MOV     CX,5
    CALL    GETHEX
    PUSH    AX
    PUSH    DX
    CALL    SCANP
    CMP     BYTE [DI],"L"
    JE      GETLEN
    MOV     DX,128
    CALL    HEXIN
    JC      RNGRET
    MOV     CX,5
    CALL    GETHEX
    MOV     CX,DX
    POP     DX
    POP     BX
    SUB     CX,DX
    SBB     AH,BH
    JNZ     RNGERR
    XCHG    AX,BX
    INC     CX
    JMP     RNGCHK
GETLEN:
    INC     DI
    MOV     CX,4
    CALL    GETHEX
RNGRET:
    MOV     CX,DX
    POP     DX
    POP     AX
RNGCHK:
    MOV     BX,DX
    AND     BX,0FH
    JCXZ    MAXRNG
    ADD     BX,CX
    JNC     GETSEG
MAXRNG:
    JZ      GETSEG
RNGERR:
    MOV     AX,4700H+"R"
    JMP     ERR

GETHEX:
    CALL    SCANP
GETHEX1:
    XOR     DX,DX
    MOV     AH,DH
    CALL    HEXIN
    JC      ERROR
    MOV     DL,AL
GETLP:
    INC     DI
    DEC     CX
    CALL    HEXIN
    JC      RET
    JCXZ    ERROR
    CALL    SHIFT4
    OR      DL,AL
    JMP     GETLP

HEXIN:
    MOV     AL,[DI]
    CMP     AL,'a'
    JB      HEXCHK      ; If AL is less than 'a', it's either a digit or already uppercase.
    CMP     AL,'f'
    JA      HEXCHK      ; If AL is greater than 'f', it's not a lowercase hex digit.
    SUB     AL,20H      ; Convert lowercase letter to uppercase.

HEXCHK:
    SUB     AL,"0"
    JC      RET
    CMP     AL,10
    CMC
    JNC     RET
    SUB     AL,7
    CMP     AL,10
    JC      RET
    CMP     AL,16
    CMC
    RET

LISTITEM:
    CALL    SCANP
    CALL    HEXIN
    JC      STRINGCHK
    MOV     CX,2
    CALL    GETHEX
    MOV     [BX],DL
    INC     BX
GRET:
    CLC
    RET
STRINGCHK:
    MOV     AL,[DI]
    CMP     AL,"'"
    JZ      STRING
    CMP     AL,'"'
    JZ      STRING
    STC
    RET
STRING:
    MOV     AH,AL
    INC     DI
STRNGLP:
    MOV     AL,[DI]
    INC     DI
    CMP     AL,13
    JZ      ERROR
    CMP     AL,AH
    JNZ     STOSTRG
    CMP     AH,[DI]
    JNZ     GRET
    INC     DI
STOSTRG:
    MOV     [BX],AL
    INC     BX
    JMP     STRNGLP

LIST:
    MOV     BX,LINEBUF
LISTLP:
    CALL    LISTITEM
    JNC     LISTLP
    SUB     BX,LINEBUF
    JZ      ERROR
GETEOL:
    CALL    SCANB
    JNZ     ERROR
    RET

PERR:
    DEC     DI
ERROR:
    SUB     DI,LINEBUF-1
    MOV     CX,DI
    CALL    TAB
    MOV     SI,SYNERR
PRINT:
    CALL    PRINTMES
    JMP     COMMAND

INT:
    PUSH    AX

    MOV     AL,20H
    OUT     BASE+2,AL

    IN      AL,DATA
    AND     AL,7FH
    CMP     AL,"S"-"@"
    JNZ     NOSTOP
    CALL    IN
NOSTOP:
    CMP     AL,"C"-"@"
    JZ      BREAK
    POP     AX
    IRET
BREAK:
    CALL    CRLF
    JMP     COMMAND

; Intel HEX Loader routines (adapted from ATMONT88)
LOADHEX:
    CALL    GETEOL          ; Ensure no arguments after 'L'
    MOV     SI,LOADMSG
    CALL    PRINTMES        ; Print "Load Intel hex file..."
    XOR     AL,AL
    MOV     [BCSERR],AL     ; Clear checksum error flag
    MOV     [EXITFL],AL     ; Clear exit flag
    CALL    GETREC          ; Start loading records
    CALL    CHKERR          ; Check for checksum errors
    JMP     COMMAND         ; Return to prompt

GETREC:
    MOV     AL,[EXITFL]
    CMP     AL,1
    JE      RECEXIT         ; Exit if done
    CALL    IN              ; Read character
    CMP     AL,ESC
    JE      CHKEXIT         ; Exit on ESC
    CMP     AL,':'
    JNE     GETREC          ; Wait for start of record
    CALL    OUT             ; Echo ':'
    XOR     AL,AL
    MOV     [BCS],AL        ; Clear checksum

    ; Get record length
    XOR     CX,CX
    CALL    GETHX           ; Length in AL
    MOV     CL,AL           ; Save length
    ADD     [BCS],AL        ; Update checksum

    ; Get address
    CALL    GETHX           ; High byte in AL
    MOV     BH,AL
    ADD     [BCS],AL
    CALL    GETHX           ; Low byte in AL
    MOV     BL,AL
    ADD     [BCS],AL        ; BX = address

    ; Save address to SI
    MOV     SI,BX

    ; Get record type
    CALL    GETHX           ; Type in AL
    ADD     [BCS],AL
    CMP     AL,1
    JE      EOFREC          ; End of file record

    ; Data record
    PUSH    CX              ; Save length
    MOV     BX,SI           ; Destination address
    JCXZ    SKPDAT          ; Skip if no data

DATLOP:
    CALL    GETHX           ; Get data byte
    MOV     [BX],AL         ; Write to memory
    ADD     [BCS],AL        ; Update checksum
    INC     BX
    LOOP    DATLOP

SKPDAT:
    POP     CX              ; Restore length

    ; Verify checksum
    MOV     AL,[BCS]
    NOT     AL
    INC     AL              ; Two's complement
    MOV     [BCS],AL
    CALL    GETHX           ; Get record checksum
    CMP     AL,[BCS]
    JE      RECCOR
    MOV     AL,1
    MOV     [BCSERR],AL     ; Set error flag

RECCOR:
    CALL    CRLF
    JMP     GETREC

EOFREC:
    CALL    GETHX           ; Get EOF checksum
    MOV     AL,1
    MOV     [EXITFL],AL     ; Set exit flag
    JMP     RECEXIT

CHKEXIT:
    ;CALL    CRLF
    JMP     CHKERR          ; Check errors and exit

RECEXIT:
    RET

GETHX:
    PUSH    CX
    PUSH    BX
    CALL    IN              ; Read first digit
    MOV     AH,AL
    CALL    TOHEX           ; Convert to nibble
    ROL     AL,1
    ROL     AL,1
    ROL     AL,1
    ROL     AL,1           ; Shift to high nibble
    MOV     BL,AL
    CALL    IN              ; Read second digit
    MOV     BH,AL
    CALL    TOHEX           ; Convert to nibble
    ADD     AL,BL           ; Combine nibbles
    PUSH    AX
    CALL    HEX             ; Echo byte
    CALL    BLANK           ; Space after byte
    POP     AX
    POP     BX
    POP     CX
    RET

TOHEX:
    SUB     AL,'0'
    CMP     AL,10
    JL      ZERONIN
    SUB     AL,7            ; Adjust for A-F (no lowercase support)
ZERONIN:
    RET

CHKERR:
    CALL    CRLF
    MOV     AL,[BCSERR]
    CMP     AL,1
    JNE     NOERR
    MOV     SI,CSERRMSG
    JMP     PRINTMES
NOERR:
    MOV     SI,OKMSG
    JMP     PRINTMES

; Data section
REGTAB:
    DB      "AXBXCXDXSPBPSIDIDSESSSCSIPPC"
REGDIF: EQU     AXSAVE-REGTAB

FLAGTAB:
FLAGTAB:
        DW      0
        DW      0
        DW      0
        DW      0
        DB      "OV"
        DB      "DN"
        DB      "EI"
        DW      0
        DB      "NG"
        DB      "ZR"
        DW      0
        DB      "AC"
        DW      0
        DB      "PE"
        DW      0
        DB      "CY"
        DW      0
        DW      0
        DW      0
        DW      0
        DB      "NV"
        DB      "UP"
        DB      "DI"
        DW      0
        DB      "PL"
        DB      "NZ"
        DW      0
        DB      "NA"
        DW      0
        DB      "PO"
        DW      0
        DB      "NC"

HEADER: DB      13,10,10,"SCP 8086 Monitor 1.5 with Intel HEX Loader",13,10+80H
SYNERR: DB      "^"
ERRMES: DB      " Error",13,10+80H
BACMES: DB      8,32,8+80H
LOADMSG:DB      "Load Intel hex file...",13,10+80H
CSERRMSG:DB     13,10,"Checksum errors!",13,10+80H
OKMSG:  DB      "No errors",13,10+80H

; RESET vector at 0FFF0H
TIMES   0FFF0H - ($-$$) DB 90H
DB      0EAH
DW      RESET, 0F000H
TIMES   10000H - ($-$$) DB 00H