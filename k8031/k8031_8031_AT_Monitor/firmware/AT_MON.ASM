; ** 8031_AT_MON.ASM - Rev A modified for Retroshield 25/12/2024
; ** Based on MONITORB.ASM - Rev B Started 01/31/21 
; ** by Frank Rudley
; ** converted to asm31-sdcc231-pj3 asm 
;
; ** AT_MON.ASM Comments
; 8031 Monitor Program
;
; This is a Monitor Program for the 8031 Microcontroller
; It is based on the Monitor Program by Frank Rudley
; It is modified to work with the Retroshield
;
; Usage:
; - I: Read/Write Internal RAM
; - E: Read/Write External RAM
; - S: Display Special Function Registers (SFRs)
; - B: Display 256-byte block of ROM/RAM
; - R: Display 128-byte block of Internal RAM
; - C: Check External RAM
; - F: Fill External RAM
; - J: Jump to run programs - in progress
; - L: Load HEX file for programs - in progress
; - N: List menu
;
.equ    BITRATE, 0xFF   ; For 57600 @ 11.0592MHz
.equ    EXIT, 81
.equ    exitlc, 113
.equ    CKSUM, 0x10
.equ    NEWPROG, 0x2000
.equ    LF, 10
.equ    CR, 13
.equ    NULL, 0x00
;
; Setup Serial Stuff
;
        mov    pcon, #0x80     ; Configure UART, fast baud
        MOV    TMOD, #0x21     ; T1 Mode Auto Reload Mode
        MOV    TH1, #BITRATE   ; Set baud rate
        MOV    TL1, #BITRATE   ; Set baud rate
;
; Serial in Mode 1, Enable Serial reception, Set TI
;
        MOV    SCON, #0x52     ; Serial mode 1, enable reception
        SETB   TR1             ; Start Timer for Serial Port
;
MENU:   LCALL  WT_STRING
        .db     "8031 AT(@)_MONITOR",LF,CR 
        .db     "Based on 8031 MONITOR Rev B",LF,CR 
        .db     "by Frank Rudley",LF,CR
        .db     NULL

;        ACALL  RAM_CHECK
;        ACALL  CLR_RAM
;
GETSEL: LCALL  WT_STRING
        .db     LF,CR,"8031>"     ; Prompt
        .db     NULL
;
        LCALL  RD_CHAR
;
        ANL    A,#0x5F      ; Upcase, Strip Parity
;
R_TEST: CJNE   A,#'I',O_TEST; If Not I, Then Repeat Menu
        LCALL  R_RUN        ; I, So Run Read Internal RAM
;
O_TEST: CJNE   A,#'E',S_TEST; If Not E, Then Repeat Menu
        LCALL  O_RUN        ; E, So Run Read ROM
;
S_TEST: CJNE   A,#'S',B_TEST; If Not S, Then Repeat Menu
        LCALL  S_RUN        ; S, So Display SFRs
;
B_TEST: CJNE   A,#'B',D_TEST; If Not B, Then Repeat Menu
        LCALL  B_RUN        ; B, Display 256 byte Block of Rom
;
D_TEST: CJNE   A,#'R',J_TEST; If Not R, Then Repeat Menu
        LCALL  D_RUN        ; R, Display 128 byte Block of internal Ram
;
J_TEST: CJNE   A,#'J',E_TEST; If Not J, Then Repeat Menu
        LCALL  J_RUN        ; J, Then Jump to New Program at 0800h
;
E_TEST: CJNE   A,#'L',N_TEST; If Not L, Then Repeat Menu
        LCALL  E_RUN        ; L, Allow Upload of Hex File
;
N_TEST: CJNE   A,#'H',C_TEST; If Not N, Then Repeat Menu
        LCALL  N_RUN        ; N, Then List Menu
;
C_TEST: CJNE   A,#'C',F_TEST; If Not C, Then Repeat Menu
        LCALL  RAM_CHK      ; C, Then Check RAM
;
F_TEST: CJNE   A,#'F',J_MENU; If Not F, Then Repeat Menu
        LCALL  CLR_RAM      ; F, Then Clear RAM
;
J_MENU: LCALL  WAIT         ; Wait then show menu
        LJMP   MENU
;
R_RUN:  LCALL  WT_STRING       ; Call subroutine to write a string
        .db     "-Edit Internal RAM $00 to $7F.",LF,CR
        .db     "Enter Start Address in Hex (xx): "
        .db     NULL
        LCALL  READHEX         ; Read a hexadecimal address
        MOV    R0,A            ; Move address to register R0
        LCALL  LFCR            ; Send line feed and carriage return
        LCALL  WT_STRING       ; Call subroutine to write a string  
        .db     "Enter new data after prompt '>'",LF,CR
        .db     "<CR> to skip address, <Q> to exit.",LF,CR
        .db     NULL
R_1:    MOV    A,R0
        LCALL  WRBYTE          ; Write the address to terminal
        MOV    A,#':'
        LCALL  WT_CHAR         ; Write a colon character
        MOV    A,@R0           ; Move value at address to accumulator
        LCALL  WRBYTE          ; Write the value to terminal
        LCALL  WT_STRING       ; Prompt for new data
        .db     " > "
        .db     NULL
        LCALL  RD_CHAR         ; Read a character from terminal
        CJNE   A,#CR,READ_NEW ; If not CR, read new data
        SJMP   SKIP_WR         ; If CR, skip writing new data
READ_NEW:
        CJNE   A,#EXIT,CHK_LC ; If not uppercase EXIT, check lowercase
        SJMP   EXIT_RT
CHK_LC:
        CJNE   A,#exitlc,CONT_RD  ; If not lowercase 'q', continue reading
EXIT_RT:
        LCALL  LFCR
        LJMP   GETSEL          ; If EXIT, exit to GETSEL
CONT_RD:
        LCALL  ASC2HEX         ; Convert ASCII to hex
        SWAP   A
        MOV    R2,A            ; Store upper nibble
        LCALL  RD_CHAR         ; Read next character
        LCALL  ASC2HEX         ; Convert ASCII to hex
        ORL    A,R2            ; Combine nibbles
        MOV    @R0,A           ; Write new data to address
        LCALL  LFCR            ; Send line feed and carriage return
SKIP_WR:
        INC    R0              ; Increment address in R0
        MOV    A,R0
        CJNE   R0,#080H,R_1    ; If not 0x80, repeat loop
        ;LCALL  WAIT            ; Delay for serial
        LCALL  LFCR
        LJMP   GETSEL          ; Exit to GETSEL
;
W_RUN:  LCALL  WT_STRING       ; Call subroutine to write a string
        .db     "-RAM>"
        .db     NULL
        LCALL  READHEX         ; Read a hexadecimal address
        MOV    R0,A            ; Move address to register R0
        MOV    A,#':'          ; Write a colon character
        LCALL  WT_CHAR
        LCALL  READHEX         ; Read data
        MOV    @R0,A           ; Write data to address
        LCALL  LFCR            ; Send line feed and carriage return
        LJMP   GETSEL          ; Exit to GETSEL
;
O_RUN:  LCALL  WT_STRING       ; Call subroutine to write a string
        .db     "-Edit External RAM",LF,CR
        .db     "Enter Start Address in Hex (xxxx): "
        .db     NULL
        LCALL  READHEX         ; Read high byte of address
        MOV    DPH, A          ; Move high byte to DPH
        LCALL  READHEX         ; Read low byte of address
        MOV    DPL, A          ; Move low byte to DPL
        MOV    R3, DPH         ; Store DPH in R3
        MOV    R4, DPL         ; Store DPL in R4
        LCALL  LFCR            ; Send line feed and carriage return
        LCALL  WT_STRING       ; Call subroutine to write a string  
        .db     "Enter new data after prompt '>'",LF,CR
        .db     "<CR> to skip address, <Q> to exit.",LF,CR
        .db     NULL
O_1:    MOV    DPH, R3         ; Restore DPH
        MOV    DPL, R4         ; Restore DPL
        MOV    A, DPH
        LCALL  WRBYTE          ; Write high byte of address to terminal
        MOV    A, DPL
        LCALL  WRBYTE          ; Write low byte of address to terminal
        MOV    A, #':'
        LCALL  WT_CHAR         ; Write a colon character
        CLR    A
        MOVX   A, @DPTR        ; Move value at address to accumulator
        LCALL  WRBYTE          ; Write the value to terminal
        MOV    R3, DPH         ; Store DPH in R3
        MOV    R4, DPL         ; Store DPL in R4
        LCALL  WT_STRING       ; Prompt for new data
        .db     " > "
        .db     NULL
        MOV    DPH, R3         ; Restore DPH
        MOV    DPL, R4         ; Restore DPL
        LCALL  RD_CHAR         ; Read a character from terminal
        CJNE   A, #CR,READ_NEW_O ; If not CR, read new data
        SJMP   SKIP_WR_O       ; If CR, skip writing new data
READ_NEW_O:
        CJNE   A,#EXIT,CHK_LC_O ; If not uppercase EXIT, check lowercase
        SJMP   EXIT_RT_O
CHK_LC_O:
        CJNE   A,#exitlc,CONT_RD_O  ; If not lowercase 'q', continue reading
EXIT_RT_O:
        LCALL  LFCR            ; Delay for serial
        LJMP   GETSEL          ; If EXIT, exit to GETSEL
CONT_RD_O:
        LCALL  ASC2HEX         ; Convert ASCII to hex
        SWAP   A
        MOV    R2, A           ; Store upper nibble
        LCALL  RD_CHAR         ; Read next character
        LCALL  ASC2HEX         ; Convert ASCII to hex
        ORL    A, R2           ; Combine nibbles
        MOVX   @DPTR, A        ; Write new data to address
        LCALL  LFCR            ; Send line feed and carriage return
SKIP_WR_O:
        INC    DPL             ; Increment low byte of address
        MOV    A, DPL
        CJNE   A, #00H, O_2    ; If not 0x00, repeat loop
        INC    DPH             ; Increment high byte of address if low byte wrapped around
O_2:    MOV    R3, DPH         ; Store DPH in R3
        MOV    R4, DPL         ; Store DPL in R4
        SJMP   O_1             ; Repeat loop
;
; Display P0
;
S_RUN:  LCALL  WT_STRING       ; Display SFR Routine
        .db     "SFRs",LF,LF,LF,CR
        .db     "P0   = "
        .db     NULL
        MOV    A,P0
        LCALL  WRBYTE          ; Display P0
;
; Display P1
;
        LCALL  WT_STRING
        .db     "    P1   = "
        .db     NULL
        MOV    A,P1
        LCALL  WRBYTE          ; Display P1
;
; Display P2
;
        LCALL  WT_STRING
        .db     "    P2   = "
        .db     NULL
        MOV    A,P2
        LCALL  WRBYTE          ; Display P2
;
; Display P3
;
        LCALL  WT_STRING
        .db     "    P3   = "
        .db     NULL
        MOV    A,P3
        LCALL  WRBYTE          ; Display P3
;
; Display TMOD
;
        LCALL  WT_STRING
        .db     LF,CR,"TMOD = "
        .db     NULL
        MOV    A,TMOD
        LCALL  WRBYTE          ; Display TMOD
;
; Display TCON
;
        LCALL  WT_STRING
        .db     "    TCON = "
        .db     NULL
        MOV    A,TCON
        LCALL  WRBYTE          ; Display TCON
; 
; Display SCON
;
        LCALL  WT_STRING
        .db     "    SCON = "
        .db     NULL
        MOV    A,SCON
        LCALL  WRBYTE          ; Display SCON
;
; Display PSW
;
        LCALL  WT_STRING
        .db     "    PSW  = "
        .db     NULL
        MOV    A,PSW
        LCALL  WRBYTE          ; Display PSW
;
; Display PCON
;
        LCALL  WT_STRING
        .db     LF,CR,"PCON = "
        .db     NULL
        MOV    A,PCON
        LCALL  WRBYTE          ; Display PCON
;
; Display TH0
;
        LCALL  WT_STRING
        .db     "    TH0  = "
        .db     NULL
        MOV    A,TH0
        LCALL  WRBYTE          ; Display TH0
;
; Display TL0
;
        LCALL  WT_STRING
        .db     "    TL0  = "
        .db     NULL
        MOV    A,TL0
        LCALL  WRBYTE          ; Display TL0
;
; Display TH1
;
        LCALL  WT_STRING
        .db     "    TH1  = "
        .db     NULL
        MOV    A,TH1
        LCALL  WRBYTE          ; Display TH1
;
; Display TL1
;
        LCALL  WT_STRING
        .db     "    TL1  = "
        .db     NULL
        MOV    A,TL1
        LCALL  WRBYTE          ; Display TL1
        LCALL  LFCR            ; Send line feed and carriage return
        LJMP   GETSEL          ; Exit to GETSEL
;
B_RUN:  LCALL  WT_STRING       ; Call subroutine to write a string
        .db     "-List a 256 Byte Block of ROM/RAM",LF,LF,CR
        .db     "Block>"
        .db     NULL
        LCALL  READHEX         ; Read high byte of address
        MOV    R1,A            ; Move high byte to R1
        LCALL  WT_STRING       ; Call subroutine to write a string
        .db     LF,CR,"      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F",LF,CR
        .db     NULL
        MOV    DPH,R1          ; Move high byte to DPH
        MOV    R0,#00H         ; Initialize R0 to 0
B_2:    MOV    DPL,R0          ; Move low byte to DPL
        LCALL  LFCR            ; Send line feed and carriage return
        MOV    A,DPH
        LCALL  WRBYTE          ; Write high byte of address to terminal
        MOV    A,DPL
        LCALL  WRBYTE          ; Write low byte of address to terminal
        MOV    A,#' '
        LCALL  WT_CHAR         ; Write a space character
        LCALL  WT_CHAR         ; Write another space character
B_1:    MOV    DPL,R0   
        CLR    A
        MOVC   A,@A+DPTR       ; Read ROM
        LCALL  WRBYTE          ; Write the value to terminal
        MOV    A,#' '
        LCALL  WT_CHAR         ; Write a space character
        INC    R0              ; Increment R0
        MOV    A,R0
        ANL    A,#00FH
        CJNE   A,#000H,B_1     ; If not end of line, repeat loop
        CJNE   R0,#000H,B_2    ; If not end of block, repeat loop
        LCALL  LFCR            ; Send line feed and carriage return
        LJMP   GETSEL          ; Exit to GETSEL
;
D_RUN:  LCALL  WT_STRING       ; Call subroutine to write a string
        .db     "-List the 128 Byte Block of Internal RAM",LF,CR
        .db     LF,CR,"    4 BANKS OF 8 REGISTERS (R0-R7)",LF,CR
        .db     "    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F",LF,CR
        .db     "    R0 R1 R2 R3 R4 R5 R6 R7 R0 R1 R2 R3 R4 R5 R6 R7",LF,CR
        .db     NULL
        MOV    R0,#00H         ; Initialize R0 to 0
D_2:    LCALL  LFCR            ; Send line feed and carriage return
        CJNE   R0,#020H,SKIP_20 ; If not address 20, skip placeholder
        LCALL  WT_STRING       ; Placeholder for new string
        .db     LF,CR,"    BIT-ADDRESSABLE SPACE",LF,CR
        .db     "    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F",LF,CR
        .db     NULL
        LCALL  LFCR            ; Send line feed and carriage return
SKIP_20:
        CJNE   R0,#030H,SKIP_30 ; If not address 30, skip placeholder
        LCALL  WT_STRING       ; Placeholder for new string
        .db     LF,CR,"    SCRATCHPAD AREA",LF,CR
        .db     "    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F",LF,CR
        .db     NULL
        LCALL  LFCR            ; Send line feed and carriage return
SKIP_30:
        MOV    A,R0
        LCALL  WRBYTE          ; Write high byte of address to terminal
        MOV    A,#' '
        LCALL  WT_CHAR         ; Write a space character
        LCALL  WT_CHAR         ; Write another space character
D_1:    MOV    A,@R0           ; Read internal RAM
        LCALL  WRBYTE          ; Write the value to terminal
        MOV    A,#' '
        LCALL  WT_CHAR         ; Write a space character
        INC    R0              ; Increment R0
        MOV    A,R0
        ANL    A,#00FH
        CJNE   A,#000H,D_1     ; If not end of line, repeat loop
        MOV    A,R0
        CJNE   A,#080H,CONT_D2 ; If not end of block, continue
        SJMP   END_D2          ; If end of block, jump to end
CONT_D2:
        LJMP   D_2             ; Continue loop
END_D2:
        LCALL  LFCR            ; Send line feed and carriage return
        LJMP   GETSEL          ; Exit to GETSEL
;
J_RUN:  LJMP   NEWPROG
;
E_RUN:  LCALL  WT_STRING       ; Call subroutine to write a string
        .db     "-Upload Hex File",LF,CR
        .db     NULL
;
E_1:    LCALL  RD_CHAR
        CJNE   A,#':',E_X ; Exit if not a ":"
;
        LCALL  READHEX    ; Get Word Count
        MOV    R1,A       ; Load Word Count to R1
;
        LCALL  READHEX    ; Read Address and put into Data Pointer        
        MOV    DPH,A      ; Upper Byte
;
        LCALL  READHEX    ; Lower Byte
        MOV    DPL,A
;
        LCALL  READHEX    ; Read Record Type
        CJNE   A,#0,E_Y   ; Done and Exit
;
E_2:    LCALL  READHEX    ; Read Data
        MOVX   @DPTR,A    ; Burn ROM
        LCALL  WAIT       ; Wait for Burn Time
        INC    DPTR       ; Increment Data Pointer
        DJNZ   R1,E_2     ; Loop Till Out of Words
        LCALL  READHEX    ; Read Checksum but don't do anything with it
        LCALL  LFCR
        SJMP   E_1
;
; Done and Exit Read Last Byte
;
E_Y:    LCALL  READHEX
        LCALL  WT_STRING
        .db     LF,CR,"DONE LOAD!! ",LF,CR
        .db     NULL
E_X:    LCALL  LFCR
        LJMP   GETSEL
;
; List Out The Menu
;
N_RUN:  LCALL  WT_STRING
        .db     LF,CR,"I = Read/Write Int RAM",LF,CR ;keep
        .db           "E = Read/Write Ext RAM",LF,CR;keep
        .db           "S = Display SFRs",LF,CR ;keep
        .db           "B = List 256 bytes of EXT ROM/RAM",LF,CR;keep
        .db           "R = List 128 bytes of Int RAM",LF,CR ; keep
        .db           "C = Check EXT RAM",LF,CR ;keep
        .db           "F = Fill EXT RAM",LF,CR  ;keep
        .db           "J = Jump to run Progs",LF,CR
        .db           "L = Load HEX File for Progs",LF,CR
        .db           "H = This Menu",LF,CR
        .db     NULL
        LJMP   GETSEL
;
;
;$INCLUDE(READHEX.ASM) $07E1
; This Subroutine Reads a Hex Byte and Puts it in A
;
READHEX:
        LCALL  RD_CHAR         ; Read a character from terminal
        LCALL  ASC2HEX         ; Convert ASCII to hex
        SWAP   A               ; Swap nibbles
        MOV    R2,A            ; Store upper nibble
        LCALL  RD_CHAR         ; Read next character
        LCALL  ASC2HEX         ; Convert ASCII to hex
        ORL    A,R2            ; Combine nibbles
        RET                    ; Return from subroutine

;$INCLUDE(WRBYTE.ASM) $07ED
; This Subroutine Writes a BYTE 
;
WRBYTE: MOV    R2,A            ; Store value in R2
        SWAP   A               ; Swap nibbles
        LCALL  HEX2ASC         ; Convert hex to ASCII
        LCALL  WT_CHAR         ; Write character
        MOV    A,R2            ; Restore value from R2
        LCALL  HEX2ASC         ; Convert hex to ASCII
        LCALL  WT_CHAR         ; Write character
        RET                    ; Return from subroutine
;
; $INCLUDE(WT_STRIN.ASM) $077C
; This Subroutine Writes Out A String Through RS232
;
WT_STRING: POP    DPH          ; Load DPTR with First Character
           POP    DPL
           CLR    A            ; Zero Offset
           MOVC   A,@A+DPTR    ; Get First Character in String
MEN_1:     JNB    TI,MEN_1     ; Wait until transmitter ready
           CLR    TI           ; Set Not Ready
           MOV    SBUF,A       ; Output Character
           INC    DPTR         ; Increment Data Pointer
           CLR    A            ; Zero Offset
           MOVC   A,@A+DPTR    ; Get Next Character
           CJNE   A,#NULL,MEN_1 ; Loop until read null character
           MOV    A,#1
           JMP    @A+DPTR      ; Return After read null character

; $INCLUDE(RD_CHAR.ASM) $0792
; This Subroutine Reads a Character and Echos it back.
;
RD_CHAR:  JNB    RI,RD_CHAR    ; Wait until character received
          CLR    RI            ; Clear receive interrupt flag
          MOV    A,SBUF        ; Move received character to accumulator
          ANL    A,#07FH       ; Mask parity bit
          LCALL  WT_CHAR       ; Echo character back
          RET                  ; Return from subroutine
;
; $INCLUDE(WT_CHAR.ASM) $079E
; This Subroutine Writes out a Character
;
WT_CHAR:  JNB    TI,WT_CHAR    ; Wait until transmitter ready
          CLR    TI            ; Clear transmit interrupt flag
          MOV    SBUF,A        ; Move character to serial buffer
          RET                  ; Return from subroutine
;
; $INCLUDE(ASC2HEX.ASM) $07A6
; This Subroutine converts Hex to ASCII
;
ASC2HEX: CLR    CY             ; Clear carry flag
         SUBB   A,#'0'         ; Subtract ASCII '0'
         MOV    B,A            ; Store result in B
         SUBB   A,#10          ; Subtract 10
         JB     CY,A2LT10      ; If result is less than 10, jump to A2LT10
         MOV    A,B            ; Restore result from B
         SUBB   A,#7           ; Subtract 7
         MOV    B,A            ; Store result in B
A2LT10:  MOV    A,B            ; Restore result from B
         RET                   ; Return from subroutine

;$INCLUDE(HEX2ASC.ASM) $07BA
; This Subroutine Converts Hex to ASCII
;
HEX2ASC:  ANL    A,#00FH       ; Mask upper nibble
          CLR    CY            ; Clear carry flag
          MOV    B,A           ; Store result in B
          SUBB   A,#10         ; Subtract 10
          MOV    A,B           ; Restore result from B
          JB     CY,H2LT10     ; If result is less than 10, jump to H2LT10
          ADD    A,#7          ; Add 7
H2LT10:   ADD    A,#'0'        ; Add ASCII '0'
          RET                  ; Return from subroutine

;$INCLUDE(LFCR.ASM) $07CC
; This Subroutine Does a Line-Feed Cariage Return
;
LFCR:   MOV    A,#00AH         ; Load line feed character
        LCALL  WT_CHAR         ; Write character
        MOV    A,#00DH         ; Load carriage return character
        LCALL  WT_CHAR         ; Write character
        RET                    ; Return from subroutine
;
;$INCLUDE(WAIT.ASM) $07D5
; This Subroutine Causes a Pause for a Fraction of a Second
;
WAIT:   MOV    A,#10           ; Load delay count
WAIT1:  MOV    B,#0FFH         ; Load inner loop count
WAIT2:  DJNZ   B,WAIT2         ; Decrement inner loop count
        DEC    A               ; Decrement delay count
        JNZ    WAIT1           ; Repeat until delay count is zero
        RET                    ; Return from subroutine
;
RAM_CHK:
        LCALL  WT_STRING        ; Call subroutine to write a string
        .db     "-Checking RAM...",LF,CR
        .db     NULL

        ; Warning of memory erase
        LCALL  WT_STRING        ; Call subroutine to write a string
        .db     "Warning: This will erase memory.",LF,CR
        .db     "Press <CR> to continue or <Q> to exit."
        .db     NULL

        ; Read user input
        LCALL  RD_CHAR
        CJNE   A, #CR, CHECK_EXIT ; If not CR, check for exit
        SJMP   CONTINUE_RAM_CHK   ; If CR, continue RAM check

CHECK_EXIT:
        CJNE   A, #EXIT, CHECK_EXIT_LC ; If not uppercase Q, check lowercase
        LJMP   GETSEL                ; If uppercase Q, exit to GETSEL

CHECK_EXIT_LC:
        CJNE   A, #exitlc, CONTINUE_RAM_CHK ; If not lowercase q, continue RAM check
        LJMP   GETSEL                ; If lowercase q, exit to GETSEL

CONTINUE_RAM_CHK:
        MOV    DPTR, #2000H     ; Start at address $2000

RAM_LOOP:
        MOV    A, #01H          ; Load 01 into accumulator
        MOVX   @DPTR, A         ; Write 01 to external RAM at DPTR
        NOP                     ; Small delay
        MOVX   A, @DPTR         ; Read back from external RAM at DPTR
        CJNE   A, #01H, RAM_END ; If not equal to 01, RAM end found
        INC    DPTR             ; Increment DPTR
        SJMP   RAM_LOOP         ; Continue checking

RAM_END:
        ; RAM end address is in DPTR
        MOV    A, DPL           ; Move low byte of DPTR to accumulator
        DEC    A                ; Decrement accumulator by 1
        MOV    DPL, A           ; Move accumulator back to DPL
        CJNE   A, #0FFH, SKIP_DEC ; If DPL is not 0xFF, skip decrementing DPH
        MOV    A, DPH           ; Move high byte of DPTR to accumulator
        DEC    A                ; Decrement accumulator by 1
        MOV    DPH, A           ; Move accumulator back to DPH
        MOV    DPL, #0FFH       ; Set DPL to 0xFF
SKIP_DEC:

        ; Save DPTR values
        PUSH   DPL
        PUSH   DPH

        ; Print RAM start address
        LCALL  WT_STRING        ; Call subroutine to write a string
        .db     LF,LF,CR,"RAM Start $2000",LF,CR
        .db     "RAM End   $"
        .db     NULL

        ; Restore DPTR values
        POP    DPH
        POP    DPL

        ; Print RAM end address
        MOV    A, DPH           ; Move high byte of RAM end address to accumulator
        LCALL  WRBYTE           ; Print high byte of RAM end address
        MOV    A, DPL           ; Move low byte of RAM end address to accumulator
        LCALL  WRBYTE           ; Print low byte of RAM end address

        LCALL  WT_STRING        ; Call subroutine to write a string
        .db     LF,LF,CR
        .db     NULL
        LJMP   GETSEL           ; Return from subroutine

CLR_RAM:
        ; Input start address
        LCALL  WT_STRING        ; Call subroutine to write a string
        .db     "-Fill RAM",LF,CR
        .db     "Enter Start Address in Hex (xxxx): "
        .db     NULL
        LCALL  READHEX          ; Read high byte of start address
        MOV    R5, A            ; Store high byte in R5
        LCALL  READHEX          ; Read low byte of start address
        MOV    R6, A            ; Store low byte in R6

        ; Input end address
        LCALL  WT_STRING        ; Call subroutine to write a string
        .db     LF,CR,"Enter End Address in Hex (xxxx)  : "
        .db     NULL
        LCALL  READHEX          ; Read high byte of end address
        MOV    R3, A            ; Store high byte in R3
        LCALL  READHEX          ; Read low byte of end address
        MOV    R4, A            ; Store low byte in R4

        ; Input fill value
        LCALL  WT_STRING        ; Call subroutine to write a string
        .db     LF,CR,"Enter Value in Hex (xx)          : "
        .db     NULL
        LCALL  READHEX          ; Read the fill value from user input
        MOV    R7, A            ; Store the fill value in R7
        LCALL  LFCR             ; Send line feed and carriage return

        ; Set DPTR to start address
        MOV    DPH, R5          ; Restore high byte to DPH
        MOV    DPL, R6          ; Restore low byte to DPL

CLR_LOOP:
        MOV    A, R7            ; Load the fill value into accumulator
        MOVX   @DPTR, A         ; Write the fill value to external RAM at DPTR
        MOV    A, DPL           ; Move low byte of DPTR to accumulator
        MOV    B, R4            ; Move end low byte to B
        CJNE   A, B, CONT_CLR   ; If not reached end address, continue clearing
        MOV    A, DPH           ; Move high byte of DPTR to accumulator
        MOV    B, R3            ; Move end high byte to B
        CJNE   A, B, CONT_CLR   ; If not reached end address, continue clearing
        SJMP   CLR_DONE         ; If reached end address, exit loop
CONT_CLR:
        INC    DPTR             ; Increment DPTR
        SJMP   CLR_LOOP         ; Continue clearing
CLR_DONE:
        LJMP   GETSEL           ; Return from subroutine

RAM_CHK_NO_OUTPUT:
        MOV    DPTR, #2000H     ; Start at address $2000
RAM_LOOP_NO_OUTPUT:
        MOV    A, #01H          ; Load 01 into accumulator
        MOVX   @DPTR, A         ; Write 01 to external RAM at DPTR
        NOP                     ; Small delay
        MOVX   A, @DPTR         ; Read back from external RAM at DPTR
        CJNE   A, #01H, RAM_END_NO_OUTPUT ; If not equal to 01, RAM end found
        INC    DPTR             ; Increment DPTR
        SJMP   RAM_LOOP_NO_OUTPUT ; Continue checking
RAM_END_NO_OUTPUT:
        ; RAM end address is in DPTR
        MOV    A, DPL           ; Move low byte of DPTR to accumulator
        DEC    A                ; Decrement accumulator by 1
        MOV    DPL, A           ; Move accumulator back to DPL
        CJNE   A, #0FFH, SKIP_DEC_NO_OUTPUT ; If DPL is not 0xFF, skip decrementing DPH
        MOV    A, DPH           ; Move high byte of DPTR to accumulator
        DEC    A                ; Decrement accumulator by 1
        MOV    DPH, A           ; Move accumulator back to DPH
        MOV    DPL, #0FFH       ; Set DPL to 0xFF
SKIP_DEC_NO_OUTPUT:
        RET                     ; Return from subroutine
;
;        END
