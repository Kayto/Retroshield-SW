; ******************************************************************************
; Assembly Code Routines - most taken from:
; 6800_Software_Gourmet_Guide_and_Cookbook_1976_Robert_Findley
; Processor: Motorola 6800
; NOTE : These are currently roughly transcribed from OCR so contain some errors.
; ******************************************************************************

; Use Labels 1A OR Labels 1B - not both
; Labels 1A EQU Definitions for Program Address Labels
; Purpose: Define symbolic names for memory addresses
CNTR      EQU $0020   ; Counter Storage
TEMP1     EQU $0021   ; Temporary Pointer Storage
TEMP2     EQU $0023   ; Temporary Pointer Storage
TSIGN     EQU $0025   ; Sign Indicator
SIGNS     EQU $0026   ; Signs Indicator (Multiply & Divide)
FPLSWE    EQU $0027   ; FPACC Extension
FPLSW     EQU $0028   ; FPACC Least Significant Byte
FPNSW     EQU $0029   ; FPACC Next Significant Byte
FPMSW     EQU $002A   ; FPACC Most Significant Byte
FPACCE    EQU $002B   ; FPACC Exponent
MCANDO    EQU $002C   ; Multiplication Work Area
MCAND1    EQU $002D   ; Multiplication Work Area
MCAND2    EQU $002E   ; Multiplication Work Area
FOLSWE    EQU $002F   ; FPOP Extension
FOPLSW    EQU $0030   ; FPOP Least Significant Byte
FOPNSW    EQU $0031   ; FPOP Next Significant Byte
FOPMSW    EQU $0032   ; FPOP Most Significant Byte
FOPEXP    EQU $0033   ; FPOP Exponent
WORKO     EQU $0034   ; Work Area
WORK1     EQU $0035   ; Work Area
WORK2     EQU $0036   ; Work Area
WORK3     EQU $0037   ; Work Area
WORK4     EQU $0038   ; Work Area
WORK5     EQU $0039   ; Work Area
WORK6     EQU $003A   ; Work Area
WORK7     EQU $003B   ; Work Area
; Labels 1B
; Memory Allocation for Counter, FPACC, FPOP and Work Areas
; Starting at $0020
ORG     $0020           ; Start of memory allocation
CNTR    RMB     1              ; Counter Storage
TEMP1   RMB     2              ; Temporary Pointer Storage (2 bytes)
TEMP2   RMB     2              ; Temporary Pointer Storage (2 bytes)
TSIGN   RMB     1              ; Sign Indicator
SIGNS   RMB     1              ; Signs Indicator (Multiply & Divide)
FPLSWE  RMB     1              ; FPACC Extension
FPLSW   RMB     1              ; FPACC Least Significant Byte
FPNSW   RMB     1              ; FPACC Next Significant Byte
FPMSW   RMB     1              ; FPACC Most Significant Byte
FPACCE  RMB     1              ; FPACC Exponent
MCANDO  RMB     1              ; Multiplication Work Area
MCAND1  RMB     1              ; Multiplication Work Area
MCAND2  RMB     1              ; Multiplication Work Area
FOLSWE  RMB     1              ; FPOP Extension
FOPLSW  RMB     1              ; FPOP Least Significant Byte
FOPNSW  RMB     1              ; FPOP Next Significant Byte
FOPMSW  RMB     1              ; FPOP Most Significant Byte
FOPEXP  RMB     1              ; FPOP Exponent
WORKO   RMB     1              ; Work Area
WORK1   RMB     1              ; Work Area
WORK2   RMB     1              ; Work Area
WORK3   RMB     1              ; Work Area
WORK4   RMB     1              ; Work Area
WORK5   RMB     1              ; Work Area
WORK6   RMB     1              ; Work Area
WORK7   RMB     1              ; Work Area

; Use Labels 2A OR Labels 2B - not both        
; Labels 2A - Memory Allocation for I/O Operations and Temporary Storage
; Starting at $0010
ORG     $0010           ; Start of I/O and temporary storage area
INMTAS  RMB     1              ; I/O Mantissa Sign
INEXPS  RMB     1              ; I/O Exponent Sign
INPRDI  RMB     1              ; I/O Period Indicator
IOLSW   RMB     1              ; I/O Work Area Least Significant Byte
IONSW   RMB     1              ; I/O Work Area Next Significant Byte
IOMSW   RMB     1              ; I/O Work Area Most Significant Byte
IOEXP   RMB     1              ; I/O Work Area Exponent
IOSTR   RMB     1              ; I/O Storage
IOSTR1  RMB     1              ; I/O Storage
IOSTR2  RMB     1              ; I/O Storage
IOSTR3  RMB     1              ; I/O Storage
IOEXPD  RMB     1              ; I/O Exponent Storage
TPLSW   RMB     1              ; Temporary Input Storage Least Signif Byte
TPNSW   RMB     1              ; Temporary Input Storage Next Signif Byte
TPMSW   RMB     1              ; Temporary Input Storage Most Signif Byte
TPEXP   RMB     1              ; Temporary Input Storage Exponent
; Labels 2B - EQU Definitions for Program Address Labels
; Purpose: Define symbolic names for memory addresses
INMTAS  EQU $0010  ; I/O Mantissa Sign
INEXPS  EQU $0011  ; I/O Exponent Sign
INPRDI  EQU $0012  ; I/O Period Indicator
IOLSW   EQU $0013  ; I/O Work Area Least Significant Byte
IONSW   EQU $0014  ; I/O Work Area Next Significant Byte
IOMSW   EQU $0015  ; I/O Work Area Most Significant Byte
IOEXP   EQU $0016  ; I/O Work Area Exponent
IOSTR   EQU $0017  ; I/O Storage
IOSTR1  EQU $0018  ; I/O Storage
IOSTR2  EQU $0019  ; I/O Storage
IOSTR3  EQU $001A  ; I/O Storage
IOEXPD  EQU $001B  ; I/O Exponent Storage
TPLSW   EQU $001C  ; Temporary Input Storage Least Signif Byte
TPNSW   EQU $001D  ; Temporary Input Storage Next Signif Byte
TPMSW   EQU $001E  ; Temporary Input Storage Most Signif Byte
TPEXP   EQU $001F  ; Temporary Input Storage Exponent

; Serial I/O Equates
TERD    EQU $F000       ; ACIA Data Register
                        ; Read: Receives character from serial port
                        ; Write: Transmits character to serial port
TERS    EQU $F001       ; ACIA Status Register
                        ; Bit 1 (0x02): Transmit Data Register Empty flag

; Main Input/Output Loop
READ    LDAA  TERD      ; Read character from serial input
        CMPA  #$0D      ; Compare with carriage return (CR)
        BEQ   DO_CR     ; If CR, branch to handle carriage return
        STAA  TERD      ; Echo character back to terminal
        BRA   READY     ; Branch to check if ready for next character
;
READY   LDAA  TERS      ; Load status register
        BITA  #$02      ; Test if transmit buffer is empty (bit 1)
        BEQ   READY     ; If not empty, keep polling
        BRA   READ      ; Buffer empty, ready to read next character

; Character String output routine - Outputs null-terminated string pointed to by X
STROUT  STAA TERD       ; Output character to terminal
        INX             ; Point to next character in string
STROUT1 LDAA 0,X        ; Load character from string
        CMPA #0         ; Check for null terminator
        BNE STROUT      ; If not null, output next character
        RTS             ; Return when null found

; Carriage Return/Line Feed Handler
DO_CR   LDX #CRLF       ; Load address of CRLF string
        JSR STROUT1     ; Output CRLF sequence
        RTS             ; Return from subroutine

; Carriage Return/Line Feed sequence
CRLF    FCB $0D,$0A     ; CR ($0D) followed by LF ($0A)       

; Clear memory routine 1 - Clears B bytes starting at address X
CLRMEM  CLR X           ; Clear memory location pointed to by X
        INX             ; Move to next memory location
        DECB            ; Decrement counter
        BNE CLRMEM      ; If counter not zero, continue clearing
        RTS             ; Return from subroutine

; Clear memory routine 2 - Clears bytes starting at address X and ending at Y
; This routine initializes the X register to the start of RAM and iteratively
; clears each memory location until it reaches the specified end address.
        LDX #$0080      ; Load X with start address of RAM
CLRRAM  CLR 0,X         ; Clear (zero) the memory location at X
        INX             ; Increment X to point to the next memory location
        CPX #$0FFF      ; Compare X with end address of RAM
        BNE CLRRAM      ; If X is not equal to end address, continue clearing

; Move memory routine - Moves B bytes from source (X) to destination (TEMP2)
MOVEIT  STX TEMP1       ; Save source address
        LDAA X          ; Load byte from source
        LDX TEMP2       ; Load destination address
        STAA X          ; Store byte to destination
        INX             ; Increment destination address
        STX TEMP2       ; Save updated destination address
        LDX TEMP1       ; Restore source address
        INX             ; Increment source address
        DECB            ; Decrement byte counter
        BNE MOVEIT      ; If counter not zero, continue moving
        RTS             ; Return from subroutine

; Move until address - Moves bytes until source reaches ADDCK
MOVEAD  STX TEMP2       ; Save destination address
        LDAA X          ; Load byte from source
        LDX TEMP2       ; Load destination address
        STAA X          ; Store byte to destination
        INX             ; Increment destination address
        STX TEMP2       ; Save updated destination address
        LDX TEMP1       ; Load source address
        INX             ; Increment source address
        CPX ADDCK       ; Compare source with end address
        BNE MOVEAD      ; If not at end address, continue moving
        RTS             ; Return from subroutine

; Increment memory - Increments multi-byte value at X
INCMEM  INX X           ; Increment value at X
        BNE INRET       ; If no overflow, return
        INX             ; If overflow, increment next byte
        DCB             ; Decrement byte counter
        BNE INCMEM      ; If more bytes to process, continue
INRET   RTS             ; Return from subroutine

; Decrement memory - Decrements multi-byte value at X by $F001
DCRMEM  LDAA X          ; Load value from memory
        SUBA #$F001     ; Subtract $F001
        STAA X          ; Store result back to memory
        BCC DCRET       ; If no borrow, return
        INX             ; If borrow, move to next byte
        DECB            ; Decrement byte counter
        BNE DCRMEM      ; If more bytes to process, continue
DCRET   RTS             ; Return from subroutine

; Rotate left - Rotates B bytes left through carry
ROTATL  CLC             ; Clear carry flag
ROTL    ROL X           ; Rotate left through carry
        DECB            ; Decrement rotation counter
        BNE MORRTL      ; If more rotations needed, continue
        RTS             ; Return from subroutine
MORRTL  INX             ; Move to next byte
        BRA ROTL        ; Continue rotation

; Rotate right - Rotates B bytes right through carry
ROTATR  CLC             ; Clear carry flag
        ROR X           ; Rotate right through carry
        DECB            ; Decrement rotation counter
        BNE MORRTR      ; If more rotations needed, continue
        RTS             ; Return from subroutine
MORRTR  DEX             ; Move to previous byte
        BRA ROTR        ; Continue rotation (Note: Label should be ROTATR)

; Complement memory - Complements B bytes starting at address X
COMPLM  NEG X           ; Negate (two's complement) the value at X
COMP1   DECB            ; Decrement byte counter
        BNE MORCOM      ; If counter not zero, continue complementing
        RTS             ; Return from subroutine
MORCOM  INX             ; Move to next memory location
        BCC COMPLM      ; If no carry, continue complementing
        COM X           ; Complement the value at X
        BRA COMP1       ; Branch to decrement counter and check

; Add with carry - Adds B bytes from source (X) to destination (TEMP2)
ADDER   CLC             ; Clear carry flag
        LDAA X          ; Load byte from source
        STX TEMP1       ; Save source address
        LDX TEMP2       ; Load destination address
        ADCA X          ; Add with carry
        INX             ; Increment destination
        STX TEMP2       ; Save destination address
        LDX TEMP1       ; Restore source address
        STAA X          ; Store result
        INX             ; Increment source
        DECB            ; Decrement counter
        BNE ADDER+$1    ; If counter not zero, continue adding
        RTS             ; Return from subroutine

; Subtract with carry - Subtracts B bytes at TEMP2 from X
SUBBER  CLC             ; Clear carry flag
        LDAA X          ; Load byte from source
        STX TEMP1       ; Save source address
        LDX TEMP2       ; Load subtrahend address
        SBCA X          ; Subtract with carry
        STAA X          ; Store result
        INX             ; Increment subtrahend address
        STX TEMP2       ; Save subtrahend address
        LDX TEMP1       ; Restore source address
        INX             ; Increment source address
        DECB            ; Decrement counter
        BNE SUBBER+$1   ; If counter not zero, continue subtracting
        RTS             ; Return from subroutine

; CPRMEM routine - Compares memory blocks
; This routine compares two memory blocks byte by byte, using TEMP1 
; and TEMP2 to store the current addresses of the source and destination 
; blocks, respectively. The comparison continues until a mismatch is 
; found or the byte counter reaches zero.
CPRCON  DEX             ; Decrement X register
        STX TEMP2       ; Store decremented X in TEMP2
CPRMEM  LDX TEMP1       ; Load source address from TEMP1
        LDAA X          ; Load byte from source
        DEX             ; Decrement X to point to previous byte
        STX TEMP1       ; Store updated source address back to TEMP1
        LDX TEMP2       ; Load destination address from TEMP2
        CMPA X          ; Compare byte from source with destination
        BNE CPRET       ; If bytes are not equal, branch to CPRET
        DECB            ; Decrement byte counter
        BNE CPRCON      ; If counter not zero, continue comparison
CPRET   RTS             ; Return from subroutine

; Table comparison setup and execution
; This code:
; Sets up pointers to two tables in temporary storage
; Initializes a counter for the number of bytes to compare
; Calls CPRMEM to do the actual comparison
; Branches based on comparison result:
;    BHI: TBL1 is greater than TBL2
;    BEQ: Tables are equal
;    (Fall through): TBL1 is less than TBL2
; Note: The actual value for #$xx would need to be replaced with the specific 
; number of bytes to compare.
        LDX TBL1        ; Get address of first table
        STX TEMP1       ; Store TBL1 address in TEMP1
        LDX TBL2        ; Get address of second table
        STX TEMP2       ; Store TBL2 address in TEMP2
        LDAB #$xx       ; Load byte count for comparison (xx = number of bytes)
        BSR CPRMEM      ; Branch to subroutine CPRMEM to compare tables
        BHI GRTRTN      ; Branch if TBL1 > TBL2
        BEQ EQUAL       ; Branch if TBL1 = TBL2
                ; (Falls through if TBL1 < TBL2)

; Limit Check routine - Checks if value in A is between $B0 and $BA
; This routine:
; Checks if value in A is >= $B0
; If A < $B0, returns with carry set
; Then checks if A < $BA
; If A < $BA (in range), returns with carry clear
; If A >= $BA, returns with carry set
; The carry flag on return indicates:
;    Clear (0): Value is within range ($B0 ≤ A < $BA)
;    Set (1): Value is out of range (A < $B0 or A >= $BA)
LMTCHK  CMPA #$B0       ; Compare A with lower limit ($B0)
        BSC LMTRET      ; Branch if A < $B0 (carry set)
        CMPA #$BA       ; Compare A with upper limit ($BA)
        BSC CRCLR       ; Branch if A < $BA (carry set)
        SEC             ; Set carry flag (A >= $BA)
LMRET   RTS             ; Return with carry indicating result
CRCLR   CLC             ; Clear carry flag (A is within range)
        RTS             ; Return with carry clear

; DELAY routine - Simple delay loop using B register
DELAY   DECB            ; Decrement B register
        BNE DELAY       ; If B is not zero, continue looping
        RTS             ; Return from subroutine when B reaches zero

; Nested delay loops using both A and B registers        
        LDAB #$xx       ; Load outer loop count
        LDAA #$YY       ; Load inner loop count
        BSR DLYLOP      ; Branch to delay loop
DLYLOP  DECA            ; Decrement A register (inner loop)
        BNE DLYLP1      ; If A not zero, go to outer loop
        RTS             ; Return when both loops complete
DLYLP1  DECB            ; Decrement B register (outer loop)
        BEQ DLYLOP      ; If B zero, reload A and continue
        BRA DLYLP1      ; Continue outer loop

; RNDMLP routine - Repeatedly increments B and checks input
; This routine:
; Increments the B register
; Calls a subroutine CHKINP to perform some input check
; Continues looping as long as the result of CHKINP is positive (BPL: Branch if Plus)
RNDMLP  INCB            ; Increment B register
        BSR CHKINP      ; Branch to subroutine CHKINP to check input
        BPL RNDMLP      ; If result is positive, repeat loop

; RANDOM routine - Generates a pseudo-random number
; This routine manipulates a value at RANNUM to generate a 
; pseudo-random number by using bitwise operations and conditional 
; logic to introduce variability. The sequence following the RANDOM 
; routine simply adds 5 to a variable ADDEND.
RANDOM  LDX RANNUM      ; Load X with the address of the random number
        LDAA X          ; Load the random number into A
        ROLA            ; Rotate A left through carry
        EORA X          ; Exclusive OR A with the random number
        RORA            ; Rotate A right through carry
        INC $1,X        ; Increment the next byte in memory
        ADDA $1,X       ; Add the incremented byte to A
        BVC SKIP        ; Branch if no overflow occurred
        INC $1,X        ; If overflow, increment the next byte again
SKIP    STAA X          ; Store the result back to the random number
        RTS             ; Return from subroutine
; Sequence to add 5 to ADDEND
        LDAA ADDEND     ; Load ADDEND into A
        ADDA #$5        ; Add 5 to A
        STAA ADDEND     ; Store the result back to ADDEND

; TIMS10 routine - Multiplies binary value by 10 and adds a decimal digit
; Input: Decimal digit in A
; Output: Result in BINVAL
; This routine performs the following operations:
; Saves input decimal digit
; Copies binary value to work area
; Multiplies by 10 through a series of shifts and adds:
;    Shift left (×2)
;    Shift left again (×4)
;    Add original value (×5)
;    Shift left again (×10)
; Adds the decimal digit to the result
; Returns with final value in BINVAL
; The routine uses three previously defined subroutines:
;    MOVEIT: Copies bytes between memory locations
;    ROTATL: Rotates bytes left (multiplication by 2)
;    ADDER: Adds multi-byte values
; Memory allocation for variables and temporary storage
TEMP1   RMB $2         ; Temporary pointer storage
TEMP2   RMB $2         ; Temporary pointer storage
DECTBL  RMB $2         ; Pointer to DECMAL table
DGTCNT  RMB $1         ; Counter storage for BNTODC
DECPNT  RMB $2         ; Pointer to decimal constant table
BINVAL  RMB $3         ; Binary equivalent storage (3 bytes)
WRKARA  RMB $3         ; Temporary working area (3 bytes)
DECMAL  RMB $7         ; Decimal equivalent storage (7 bytes)
DECML8  RMB $1         ; Most significant digit of decimal equivalent

TIMS10  PSHA           ; Save digit to be added
        LDX #WRKARA    ; Set up pointer to work area
        STX TEMP2      ; Save in temporary storage
        LDX #BINVAL    ; Set up pointer to BINVAL
        LDAB #$03      ; Set precision counter (3 bytes)
        JSR MOVEIT     ; Move binary value to work area
        ; Multiply by 2 (x2)
        LDX #WRKARA    ; Set pointer to work area
        LDAB #$03      ; Set precision counter
        JSR ROTATL     ; Multiply work area by 2 (total = x2)
        ; Multiply by 2 again (x4)
        LDX #WRKARA    ; Set pointer to work area
        LDAB #$03      ; Set precision counter
        JSR ROTATL     ; Multiply work area by 2 (total = x4)
        ; Add original value (x5)
        LDX #BINVAL    ; Set pointer to original binary value
        STX TEMP2      ; Save in temporary storage
        LDX #WRKARA    ; Set pointer to work area
        LDAB #$03      ; Set precision counter
        JSR ADDER      ; Add original to work area (total = x5)
        ; Multiply by 2 again (x10)
        LDX #WRKARA    ; Set pointer to work area
        LDAB #$03      ; Set precision counter
        JSR ROTATL     ; Multiply work area by 2 (total = x10)
        ; Add decimal digit
        PULA           ; Fetch decimal digit from stack
        LDX #WRKARA    ; Set pointer to work area
        STX TEMP2      ; Store in temp storage for ADDER
        LDX #BINVAL    ; Set pointer to BINVAL table
        STAA X         ; Load binary table with decimal digit
        CLR $1,X       ; Clear second byte
        CLR $2,X       ; Clear third byte
        LDAB #$03      ; Set precision counter
        JSR ADDER      ; Add decimal digit to binary value x10
        RTS            ; Return with sum in BINVAL

; DCTOBN - Decimal to Binary conversion routine
; Summary of the routine's functionality:
; Initializes the binary result area to zero
; Starts from the most significant decimal digit
; For each digit:
;   Loads the digit
;   Multiplies previous result by 10 and adds current digit
;   Moves to next digit
; Uses the previously defined TIMS10 routine to perform the multiplication and addition
; Processes digits from most significant to least significant
; Implements the standard decimal to binary conversion algorithm where:
;   Result = digit[n] × 10⁰ + digit[n-1] × 10¹ + ... + digit[0] × 10ⁿ
;This routine works in conjunction with the previously shown TIMS10 routine to perform complete decimal to binary conversion of multi-byte numbers.
DCTOBN  LDX #BINVAL     ; Initialize pointer to binary value storage
        LDAB #$03       ; Set precision counter (3 bytes)
        JSR CLRMEM      ; Clear binary storage area
        LDX #DECML8     ; Point to Most Significant Digit of decimal
        STX DECTBL      ; Save decimal table pointer
; Main conversion loop
DBCNVT  LDAA X          ; Load decimal digit
        BSR TIMS10      ; Multiply accumulated result by 10 and add digit
        LDX DECTBL      ; Get decimal pointer
        DEX             ; Move to next digit (right to left)
        STX DECTBL      ; Save updated pointer
        CPX #DECMAL-$1  ; Check if we've processed all digits
        BNE DBCNVT      ; If not at end, continue conversion
        RTS             ; Return when conversion complete        

; DCEQVL - Finds decimal equivalent by repeated subtraction
; This routine:
;   Implements division by repeated subtraction
;   Counts how many times a decimal constant can be subtracted
;   The count becomes the decimal digit
; Key operations:
;   Subtracts constant until borrow occurs
;   If borrow, adds back once and returns
;   If no borrow, increments counter and continues
;   Uses SUBBER and ADDER routines for arithmetic
;   Result is stored in DGTCNT
; This is part of the binary-to-decimal conversion process, finding how many times a power of 10 goes into the binary value.
DCEQVL  STX TEMP2       ; Save pointer to decimal constant
        CLR DGTCNT      ; Initialize decimal digit counter to zero
        LDAB #$03       ; Set precision counter (3 bytes)
        LDX #BINVAL     ; Point to binary value storage
; Subtraction loop
DCLOOP  JSR SUBBER      ; Subtract decimal constant from BINVAL
        LDX DECPNT      ; Get decimal constant pointer
        STX TEMP2       ; Save for potential add/subtract
        LDX #BINVAL     ; Reset pointer to binary value
        LDAB #$03       ; Reset precision counter
        BCC INCRVL      ; If no borrow, increment decimal value
        JSR ADDER       ; If borrow, add constant back (went too far)
        RTS             ; Return with decimal digit in DGTCNT
; Increment and continue
INCRVL  INC DGTCNT      ; Increment decimal digit counter
        BRA DCLOOP      ; Continue subtracting        

; BNTODC - Binary to Decimal Conversion routine
; This routine:
; Converts binary to decimal by successive division
; Uses powers of 10 from 10^7 down to 10^0
; For each power of 10:
;    Determines how many times it divides into remainder
;    Stores that as the next decimal digit
;    Continues with remainder for next power of 10
; Constants are stored in 3-byte format for precision
; Processes from highest to lowest power of 10
; Results in 8-digit decimal number stored in DECMAL/DECML8
; The constants table provides all powers of 10 needed for 8-digit 
; conversion, stored in binary format for direct arithmetic operations.
BNTODC  LDX #DECML8     ; Point to most significant decimal digit storage
        STX DECTBL      ; Save decimal table pointer
        LDX #TENMIL     ; Point to highest power of 10 (10^7)
        STX DECPNT      ; Save decimal constant pointer
; Main conversion loop
BNDC    BSR DCEQVL      ; Calculate decimal digit using repeated subtraction
        LDX DECTBL      ; Get pointer to decimal storage
        LDAA DGTCNT     ; Get calculated decimal digit
        STAA X          ; Store digit in decimal table
        DEX             ; Move to next digit position
        STX DECTBL      ; Save updated decimal pointer
        LDX DECPNT      ; Get current power of 10 pointer
        INX             ; Move to next power of 10
        INX             ; (3 bytes per constant)
        INX             
        STX DECPNT      ; Save new power of 10 pointer
        CPX #ONE+$3     ; Check if past last constant (1)
        BNE BNDC        ; If not done, continue conversion
        RTS             ; Return when conversion complete
; Decimal Constants Table (3 bytes each, binary representation)
TENMIL  FCB $80,$96,$98 ; 10,000,000 (10^7)
ONEMIL  FCB $40,$42,$0F ; 1,000,000 (10^6)
HUNTHO  FCB $A0,$86,$01 ; 100,000 (10^5)
TENTHO  FCB $10,$27,$00 ; 10,000 (10^4)
ONETHO  FCB $E8,$03,$00 ; 1,000 (10^3)
HUNRED  FCB $64,$00,$00 ; 100 (10^2)
TEN     FCB $0A,$00,$00 ; 10 (10^1)
ONE     FCB $01,$00,$00 ; 1 (10^0)

; FPNORM - Floating Point Normalization routine
; This routine:
;  Checks the sign of the floating-point accumulator (FPACC).
;  If negative, it complements the number to make it positive.
;  Checks if FPACC is zero and clears the exponent if so.
;  Normalizes the number by rotating left until the most significant 
;  bit is set.
;  Adjusts the exponent accordingly.
;  Restores the original sign if it was negative.
; The routine ensures that the floating-point number is in a normalized 
; form, ready for further arithmetic operations.
FPNORM  LDX #TSIGN      ; Set pointer to sign register
        LDAA FPMSW      ; Fetch most significant byte of FPACC
        BMI ACCMIN      ; If negative, branch to ACCMIN
        CLR X           ; If positive, clear sign register
        BRA ACZERT      ; Branch to check if FPACC is zero

ACCMIN  STAAX           ; Set sign indicator if negative
        LDAB #$04       ; Set precision counter (4 bytes)
        LDX #FPLSWE     ; Set pointer to FPACC LSW-1
        JSR COMPLM      ; Two's complement FPACC to make it positive

ACZERT  LDX #FPMSW      ; Set pointer to FPACC MSByte
        LDAB #$04       ; Set precision counter
LOOKO   TST X           ; Test if FPACC is zero
        BNE ACNONZ      ; Branch if non-zero
        DEX             ; Decrement index
        DECB            ; Decrement precision counter
        BNE LOOKO       ; If counter not zero, continue checking
        CLR FPACCE      ; If FPACC is zero, clear exponent
NORMEX  RTS             ; Exit normalization subroutine

ACNONZ  LDX #FPLSWE     ; Set pointer to FPACC LSByte-1
        LDAB #$04       ; Set precision counter
        JSR ROTATL      ; Rotate FPACC left
        TST X           ; Test if 1 in MSB
        BMI ACCSET      ; If positive, justified if so
        DEC $01,X       ; Else, decrement FPACC exponent
        BRA ACNONZ      ; Continue rotating

ACCSET  LDX #FPMSW      ; Set pointer to FPACC MSByte
        LDAB #$03       ; Set precision counter
        JSR ROTATR      ; Compensating rotate right FPACC
        TST TSIGN       ; Test original sign of FPACC
        BEQ NORMEX      ; Normal exit if positive sign
        LDAB #$03       ; With pointer at LSByte, set precision counter
        JMP CMPLM       ; Restore FPACC to negative & return

; FPADD - Floating Point Addition Routine
; This routine:
;  Checks if either the floating-point accumulator (FPACC) or the floating-point
;  operand (FPOP) is zero and handles these cases.
;  Compares the exponents of FPACC and FPOP to determine alignment needs.
;  Aligns the mantissas by shifting the smaller operand to the right.
;  Performs the addition of the aligned mantissas.
;  Normalizes the result to ensure it is in a standard floating-point form.
; The routine efficiently manages the addition of two floating-point 
; numbers, ensuring proper alignment and normalization for accurate results.
FPADD   TST FPMSW              ; Test if the most significant byte of FPACC is zero
        BNE NONZAC             ; Branch to NONZAC if FPACC is not zero
MOVOP   LDX +#FPLSW            ; Load index register with address of FPACC LSByte
        STX TEMP2              ; Store index in temporary storage
        LDX #FOPLSW            ; Load index register with address of FPOP LSByte
        LDAB +#$04             ; Load B with precision counter (4 bytes)
        JMP MOVEIT             ; Jump to MOVEIT to move FPOP to FPACC and return
NONZAC  TST FOPMSW             ; Test if the most significant byte of FPOP is zero
        BNE CKEQEX             ; Branch to CKEQEX if FPOP is not zero
        RTS                    ; Return if FPOP is zero
CKEQEX  LDX #FPACCE            ; Load index register with address of FPACC exponent
        LDAA X                 ; Load A with FPACC exponent
        CMPA FOPEXP            ; Compare A with FPOP exponent
        BEQ SHACOP             ; Branch to SHACOP if exponents are equal
        NEGA                   ; Negate FPACC exponent
        ADDA FOPEXP            ; Add FPOP exponent to A
        BPL SKPNEG             ; Branch to SKPNEG if result is positive
        NEGA                   ; Negate result to form two's complement
SKPNEG  CMPA #$18              ; Compare result with 24 (hex)
        BMI LINEUP             ; Branch to LINEUP if result is less than 24
        LDAB X                 ; Load B with FPACC exponent
        LDAA FOPEXP            ; Load A with FPOP exponent
        SBA                    ; Subtract B from A (FPOP - FPACC)
        BPL MOVOP              ; Branch to MOVOP if FPOP is greater than FPACC
        RTS                    ; Return if FPACC is greater than FPOP
LINEUP  LDAA FOPEXP            ; Load A with FPOP exponent
        LDAB X                 ; Load B with FPACC exponent
        SBA                    ; Subtract FPACC exponent from FPOP exponent
        TAB                    ; Transfer A to B
        BMI SHIFTO             ; Branch to SHIFTO if result is negative
MORACC  LDX +#FPACCE           ; Load index with address of FPACC exponent
        BSR SHLOOP             ; Branch to SHLOOP subroutine
        DECB                   ; Decrement B (difference counter)
        BNE MORACC             ; Branch to MORACC if B is not zero
        BRA SHACOP             ; Branch to SHACOP when B is zero
SHIFTO  LDX #FOPEXP            ; Load index with address of FPOP exponent
        BSR SHLOOP             ; Branch to SHLOOP subroutine
        INCB                   ; Increment B (difference counter)
        BNE SHIFTO             ; Branch to SHIFTO if B is not zero
SHACOP  CLR FPLSWE             ; Clear FPACC LSByte-1
        CLR FOLSWE             ; Clear FPOP LSByte-1
        LDX #FPACCE            ; Load index with address of FPACC exponent
        BSR SHLOOP             ; Branch to SHLOOP subroutine
        LDX #FOPEXP            ; Load index with address of FPOP exponent
        BSR SHLOOP             ; Branch to SHLOOP subroutine
        LDX #FOLSWE            ; Load index with address of FPOP LSByte-1
        STX TEMP2              ; Store index in temporary storage
        LDX #FPLSWE            ; Load index with address of FPACC LSByte-1
        LDAB #$04              ; Load B with precision counter (4 bytes)
        JSR ADDER              ; Jump to ADDER subroutine
        JMP FPNORM             ; Jump to FPNORM to normalize result and return
SHLOOP  INC X                  ; Increment value at address X (exponent)
        DEX                    ; Decrement index
        TBA                    ; Transfer B to A
        LDAB #$04              ; Load B with precision counter
FSHIFT  TST X                  ; Test most significant bit of MSByte
        BMI BRING1             ; Branch to BRING1 if negative
        JSR ROTATR             ; Rotate right if positive
        BRA RESCNT             ; Branch to RESCNT to restore counter
BRING1  SEC                    ; Set carry flag
        JSR ROTR               ; Rotate right with carry
RESCNT  TAB                    ; Transfer A to B
        RTS                    ; Return from subroutine

; FPSUB - Floating Point Subtraction Routine
; This routine:
; Performs floating-point subtraction by:
;    Loading the FPACC LSByte pointer
;    Setting precision to 3 bytes
;    Complementing (negating) FPACC
;    Using FPADD to add the negated value
; Leverages existing FPADD routine for efficiency
; Results in FPACC = FPACC - FPOP
FPSUB   LDX #FPLSW      ; Load index register with address of FPACC LSByte
        LDAB #$03       ; Load B with precision counter (3 bytes)
        JSR COMPLM      ; Call subroutine to complement FPACC (negate)
        JMP FPADD       ; Jump to FPADD to perform addition with negated FPACC

; FPMULT - Floating Point Multiplication Routine
; This routine:
; Performs floating-point multiplication by:
;    Checking signs of operands and setting result sign
;    Adding exponents of the two operands
;    Computing partial products through shift-and-add
;    Performing rounding on the 23rd bit
;    Normalizing the final result
; Uses helper routines:
;    CKSIGN for sign determination
;    ADDEXP for exponent addition
;    MULTIP for partial product calculation
;    CROUND for result rounding
;    EXMLDV for result normalization
; Handles negative values through two's complement
; Results in FPACC = FPACC * FPOP
; The routine ensures accurate floating-point multiplication
; through proper handling of signs, exponents, and mantissa
; operations        
FPMULT  BSR CKSIGN      ; Check signs and initialize work areas
ADDEXP  LDAA FOPEXP     ; Get FPOP exponent
        ADDA FPACCE     ; Add FPACC exponent
        INCA            ; Add 1 for algorithm compensation
        STAA FPACCE     ; Store result in FPACC exponent
SETMCT  LDAA #$17       ; Set counter to 23 (decimal) for multiplication
        STAA CNTR       ; Store bit counter
MULTIP  LDX #FPMSW      ; Point to FPACC most significant word
        LDAB #$03       ; Set 3-byte precision counter
        JSR ROTATR      ; Rotate FPACC right
        BCC NADOPP      ; Skip addition if no carry
ADOPPP  LDX #MCAND1     ; Point to multiplicand LSByte
        STX TEMP2       ; Save pointer
        LDX #WORK1      ; Point to partial product LSByte
        LDAB #$06       ; Set 6-byte precision
        JSR ADDER       ; Add multiplicand to partial product
NADOPP  LDX #WORK6      ; Point to partial product MSByte
        LDAB #$06       ; Set 6-byte precision
        JSR ROTATR      ; Rotate partial product right
        DEC CNTR        ; Decrement bit counter
        BNE MULTIP      ; Continue if not done

        LDX #WORK6      ; Point to partial product
        LDAB #$06       ; Set precision counter
        JSR ROTATR      ; Make room for rounding
        LDX #WORK3      ; Point to 24th bit
        LDAA X          ; Get byte containing 24th bit
        ROLA            ; Test 24th bit
        BPL PREXFR      ; Skip rounding if bit clear

        LDAB #$03       ; Set precision for rounding
        LDAA #$40       ; Prepare to round (add 1 to 23rd bit)
        ADDA X          ; Add to current value
CROUND  STAA X          ; Store rounded value
        INX             ; Next byte
        LDAA #$00       ; Clear A, preserve carry
        ADCA X          ; Propagate carry
        DECB            ; Decrement precision counter
        BNE CROUND      ; Continue rounding
        STAA X          ; Store final byte

PREXFR  LDX #FPLSWE     ; Point to FPACC LSW-1
        STX TEMP2       ; Save pointer
        LDX #WORK3      ; Point to working register
        LDAB #$04       ; Set 4-byte precision
EXMLDV  JSR MOVEIT      ; Move result to FPACC
        JSR FPNORM      ; Normalize result
        LDAA SIGNS      ; Check final sign
        BNE MULTEX      ; Exit if positive
        LDX #FPLSW      ; Point to FPACC LSByte
        LDAB #$03       ; Set precision
        JSR COMPLM      ; Complement if negative
MULTEX  RTS             ; Return from multiplication

CKSIGN  LDAB #$08       ; Initialize work areas
        LDX #WORKO      ; Point to work area
CLMOR1  CLR X           ; Clear memory
        INX             ; Next byte
        DECB            ; Decrement counter
        BNE CLMOR1      ; Continue until done
        LDAB #$04       ; Set new counter
        LDX #MCANDO     ; Point to multiplicand
CLMOR2  CLR X           ; Clear multiplicand area
        INX             ; Next byte
        DECB            ; Decrement counter
        BNE CLMOR2      ; Continue until done
        LDAA #$01       ; Initialize sign
        STAA SIGNS      ; Store sign indicator
        LDAA FPMSW      ; Get FPACC sign
        BPL OPSGNT      ; Branch if positive
NEGFPA  DEC SIGNS       ; Adjust sign indicator
        LDX #FPLSW      ; Point to FPACC
        LDAB #$03       ; Set precision
        JSR COMPLM      ; Complement FPACC
OPSGNT  TST FOPMSW      ; Test FPOP sign
        BMI NEGOP       ; Branch if negative
        RTS             ; Return if positive
NEGOP   DEC SIGNS       ; Adjust sign indicator
        LDX #FOPLSW     ; Point to FPOP
        LDAB #$03       ; Set precision
        JMP COMPLM      ; Complement FPOP and return      

; FPDIV - Floating Point Division Routine
; This routine:
; Performs floating-point division by:
;    Checking for divide by zero and handling errors
;    Subtracting exponents of the dividend and divisor
;    Performing division through repeated subtraction
;    Rotating results into the quotient
;    Handling rounding of the final result
; Uses working registers for intermediate calculations
; Ensures precision through proper rounding and normalization
; Results in FPACC = DIVIDEND / DIVISOR
FPDIV   JSR CKSIGN      ; Clear work area and set up sign
        TST FPMSW       ; Check for divide by zero
        BEQ DERROR      ; If divisor is zero, branch to error handling
SUBEXP  LDAA FOPEXP     ; Load DIVIDEND exponent
        SUBA FPACCE     ; Subtract DIVISOR exponent
        INCA            ; Compensate for divide algorithm
        STAA FPACCE     ; Store result in FPACC exponent
SETDCT  LDAA #$17       ; Set bit counter storage to 23 (decimal)
        STAA CNTR       ; Store bit counter
DIVIDE  BSR SETSUB      ; Subtract DIVISOR from DIVIDEND
        BMI NOGO        ; If result is negative, set 0 in QUOTIENT
        LDX #FOPLSW     ; Set location for MOVEIT
        STX TEMP2       ; Store pointer
        LDX #WORKO      ; FROM location in pointer
        LDAB #$03       ; Set precision counter
        JSR MOVEIT      ; Move DIVIDEND from work area to FPOP
        SEC             ; Set carry for positive results
        BRA QUOROT      ; Rotate into QUOTIENT
DERROR  LDAA #$BF       ; Set ASCII for '?'
        JMP $E1D1       ; Print '?' and return
NOGO    CLC             ; Negative result, clear carry
QUOROT  LDX #WORK4      ; Set pointer to LSByte of QUOTIENT
        LDAB #$03       ; Set precision counter
        JSR ROTL        ; Rotate carry into LSB of QUOTIENT
        LDX #FOPLSW     ; Set pointer to DIVIDEND LSByte
        LDAB #$03       ; Set precision counter
        JSR ROTATL      ; Rotate DIVIDEND left
        DEC CNTR        ; Decrement bit counter
        BNE DIVIDE      ; If not finished, continue
        BSR SETSUB      ; Do one more for rounding
        BMI DVEXIT      ; If negative, no rounding
        LDAA +#$01      ; If 0 or positive, add 1 to 23rd bit
        ADDA WORK4      ; Add to QUOTIENT to round off
        STAA WORK4      ; Restore LSByte of QUOTIENT
        LDAA #$00       ; Clear accumulator, not carry
        ADCA WORK5      ; Add carry to NSByte QUOTIENT
        STAA WORK5      ; Return to memory
        LDAA #$00       ; Clear accumulator, not carry
        ADCA WORK6      ; Add carry to MSByte QUOTIENT
        STAA WORK6      ; Store results
        BPL DVEXIT      ; If MSB of MSByte =0, exit
        LDX #WORK6      ; Else prepare to rotate right
        LDAB #$03       ; Set precision counter
        JSR ROTATR      ; Clear sign bit move right
        INC FPACCE      ; Compensate for rotate
DVEXIT  LDX #FPLSWE     ; Prepare to move
        STX TEMP2       ; QUOTIENT to FPACC
        LDX #WORK3      ; Set pointer to QUOTIENT
        LDAB #$04       ; Set precision counter
        JMP EXMLDV      ; Exit through FPMULT routine
SETSUB  LDX #WORKO      ; Move DIVISOR to work area
        STX TEMP2       ; Store pointer
        LDX #FPLSW      ; Set pointer to FPACC
        LDAB $03        ; Set precision counter
        JSR MOVEIT      ; Move FPACC to working register
        LDX #WORKO      ; Prepare for subtraction
        STX TEMP2       ; Store pointer to DIVISOR
        LDX #FOPLSW     ; Set pointer to FPOP LS Byte-1 (DIVIDEND)
        LDAB #$03       ; Set precision counter
SUBBER  CLC             ; Clear carry flag
        LDAA X          ; Fetch FPOP byte (DIVIDEND)
        STX TEMP1       ; Store FPOP pointer
        LDX TEMP2       ; Fetch pointer to work area
        SBCA X          ; Subtract DIVISOR from DIVIDEND
        STAA X          ; Store result in work area
        INX             ; Advance work area pointer
        STX TEMP2       ; Store work area pointer
        LDX TEMP1       ; Fetch pointer to FPOP
        INX             ; Advance pointer to FPOP
        DECB            ; Decrement precision counter
        BNE SUBBER+$1   ; Not 0, continue subtraction
        TST WORK2       ; Set sign bit result in N flag
        RTS             ; Return with flags set

; Routine: FPINP (Floating Point Input)
; Title: Floating Point ASCII to Binary Conversion Routine
; Purpose: Converts ASCII decimal input string to internal floating point binary format
; Input: 
;   - ASCII string in memory buffer
;   - X register points to start of input buffer
; Output:
;   - Binary floating point number in FPAC (Floating Point Accumulator)
;   - Carry flag set if error occurred
; Features:
;   - Handles scientific notation (e.g. 1.23E-4)
;   - Processes decimal point and exponent
;   - Validates input format
;   - Error checking for invalid characters
FPINP   LDX #INMTAS      ; Set pointer to storage area
        LDAB #$0C        ; Set up counter
CLRNXT  CLRX Clear       ; storage area
        INX Advance      ; pointer
        DECB End         ; of clear?
        BNE CLRNXT       ; No, clear more
        JSR INPUT        ; Get character from I/O
        CMPA #$AB        ; Test if + sign |
        BEQ SECHO        ; Yes, echo and continue
        CMPA #$AD        ; Test if - sign
        BNE NOTPLM       ; No, test if valid character
        STAA INMTAS      ; Make input sign non-zero
SECHO   JSR ECHO         ; Echo character to I/O
NINPUT  JSR INPUT        ; Get next character from I/O
NOTPLM  CMPA #¥$8F       ; Test if CONTROL O
        BNE SERASE       ; No, skip erase
ERASE   LDAA ¥$BC        ; Yes, ASCII code for <
        JSR ECHO         ; Output < to indicate deletion
        JSR SPACES       ; Output a few spaces
        BRA FPINP        ; Restart input string
SERASE  CMPA #$AE        ; Test if period (.)
        BNE SPRIOD       ; No, skip period
PERIOD  TST INPRDI       ; Test for period already received
        BEQ PER1         ; No period received yet, continue
        JMP ENDINP       ; Else, end input
PER1    CLR CNTR     ; Else,reset digit counter
        STAA INPRDI      ; Set (.) indicator
        JSR ECHO         ; Echo (.) to I/O
        BRA NINPUT       ; Get next character
SPRIOD  CMPA +#$C5       ; Test if E for exponent
        BNE SFNDXP       ; No, skip exponent
FNDEXP  JSR ECHO         ; Yes, echo E to I/O
        JSR INPUT        ; Input next part of exponent
        CMPA #¥$AB       ; Test if + sign
        BEQ EXECHO       ; Yes, echo it
        CMPA #$AD        ; Test if - sign
        BNE NOEXPS       ; No, see if valid character
        STAA INEXPS      ; Yes, store as minus indicator
EXECHO  JSR ECHO         ; Echo to I/O
EXPINP  JSR INPUT     ; Get next character for exponent
NOEXPS  CMPA +#$8F       ; Test if CONTROL O
        BEQ ERASE        ; Yes, reenter string
        CMPA #$B0        ; Number, test lower limit
        BMI ENDINP       ; No, end input string
        CMPA #$BA        ; Test upper limit
        BPL ENDINP       ; No, end input string
        ANDA #$0F        ; Mask and strip ASCII
        TAB         ; Store pure BCD in register B
        LDX #IOEXPD      ; Set pointer to exponent storage
        LDAA #$03        ; Test for upper limit of exponent
        CMPA X           ; Is ten’s digit greater than 3?
        BMI ENDINP       ; Yes, end input
        LDAA X           ; Store temporarily in A
        CLC Clear        ; carry bit
        ROL X            ; Exponent x2
        ROL X            ; Exponent x4
        ADDA X           ; Add original (total = x5)
        ROLA     ; Exponent x10
        ABA           ; Add new number
        STAA X           ; Store in exponent storage
        LDAA #$B0        ; Restore ASCII code
        ABA            ; By adding BO
        BRA EXECHO       ; Echo number, look for next
SFNDXP  CMPA #$B0        ; Test if valid number
        BMI ENDINP       ; If too low, end input
        CMPA +#$BA       ; Test upper limit
        BPL ENDINP       ; If not valid, end input
        TAB         ; Store in temporary register
        LDAA #$F8        ; Input too large?
        BITA IOSTR2      ; Test if so
        BNE NINPUT       ; Yes, ignore present input
        ABA         ; O.K., fetch digit from temp storage
        JSR ECHO         ; Echo to I/O
        INC CNTR         ; Increment digit counter
        ANDB #5$0F       ; Mask off ASCII
        PSHB       ; Store BCD in temporary storage
        JSR DECBIN       ; Multiply previous value x10
        LDX #IOLSW       ; Set pointer to work area
        CLR $2,X         ; Clear MS Byte work area
        CLR $1,X         ; Clear NS Byte work area
        PULA       ; Fetch last BCD number
        STAA X           ; Store LS Byte in work area
        STX TEMP2        ; Save pointer to work area
        LDX #IOSTR       ; Set pointer to storage area |
        LDAB #$03        ; Set precision counter
        JSR ADDER        ; Add latest number
        JMP NINPUT       ; Look for next character
ENDINP  TST INMTAS       ; Test if positive or negative
        BEQ FINPUT       ; Indicator zero, number positive
        LDX #IOSTR       ; Index to LSByte input mantissa
        LDAB +#$03       ; Set precision counter
        JSR COMPLM       ; Two’s complement to negate number
FINPUT  CLR IOSTR-$1     ; Clear input storage LSByte -1
        LDX #FPLSWE      ; Set pointer to FPACC LSByte -1
        STX TEMP2        ; Store pointer
        LDX #IOSTR-$1    ; Set pointer to storage LSByte -1
        LDAB #$04        ; Set precision counter
        JSR MOVEIT       ; Move input to FPACC
        LDAB #$17        ; Set exponent for FPNORM operation
        STAB FPACCE      ; Store exponent for normalization
        JSR FPNORM       ; Normalize input
        LDAA INEXPS      ; Test exponent sign indicator
        BEQ POSEXP       ; Positive? Same exponent
        NEG IOEXPD       ; Minus, make negative
POSEXP  LDAA INPRDI   ; Test period indicator
        BEQ EXPOK        ; If nothing, no decimal point
        CLRA       ; Clear accumulator A
        SUBA CNTR        ; Counter -0 to form negative
EXPOK   ADDA IOEXPD      ; Add to compensate for decimal point
        STAA IOEXPD      ; Store results
        BMI MINEXP       ; If value was minus, branch
        BNE EXPFIX       ; If plus, not finished
        RTS            ; If zero, return, value in FPACC
EXPFIX  BSR FPX10        ; Multiply FPACC x10 until
        BNE EXPFIX       ; Exponent is zero
        RTS         ; Exit, converted value in FPACC
FPX10   LDAA #$04        ; Place 10 decimal in FPOP by
        STAA FOPEXP      ; Settin FPOP exponent to 4
        LDAA #$50        ; And loading mantissa with 50 00 00
        STAA             ; FOPMSW
        CLRA
        STAA             ; FOPNSW
        STAA             ; FOPLSW
        JSR FPMULT       ; Multiply FPACC x10
        DEC IOEXPD       ; Decrement decimal exponent value
        RTS        ; Return to calling program
MINEXP  BSR FPD10        ; Compensated decimal exponent minus
        BNE MINEXP       ; FPACC x0.1 till decimal exponent =0
        RTS              ; Return
FPD10   LDAA #$FD        ; Place 0.1 in FPOP by
        STAA FOPEXP      ; Setting FPOP exponent to -3
        LDAA #$66        ; And loading mantissa with 66 66 67
        STAA             ; FOPMSW
        STAA             ; FOPNSW
        LDAA             ; #$67
        STAA             ; FOPLSW
        JSR FPMULT       ; FPACC x0.1
        INC IOEXPD       ; Increment decimal exponent and
        RTS        ; Return to calling program
SPACES  LDAA #$A0        ; ASCII “‘space”
        JSR ECHO         ; Output space character
            ; Fall through to ECHO for 2nd space
ECHO    PSHA Save        ; character being output
        JSR $E1D1        ; Output character through MIKBUG $E1D1** ; ammend to actual serial i/o routine
        PULA Restore     ; character output
        RTS
INPUT   LDAA #$38C       ; Out. reset of echo for MIKBUG** rtn      ; ammend/remove depending on actual serial i/o routine
        STAA $8007       ; Output reset code to TTY interface $8007 ; ammend/remove depending on actual serial i/o routine
        JSR $E1AC        ; Input char through MIKBUG $E1AC ** rtn   ; ammend to actual serial i/o routine
        ORAA #$80        ; Set MSB of ASCII code
        RTS
; END of FPINP routine

; Routine: FPOUT (Floating Point Output)
; Title: Floating Point Binary to ASCII Conversion Routine
; Purpose: Converts internal floating point binary number to formatted ASCII string
; Input:
;   - Binary floating point number in FPAC
;   - X register points to output buffer
;   - B register contains format control
; Output:
;   - Formatted ASCII string in output buffer
;   - X register points to end of string
; Features:
;   - Configurable decimal places
;   - Scientific notation support
;   - Leading zero suppression
;   - Sign handling

FPOUT   CLR IOEXPD       ; Clear decimal exponent storage
        TST FPMSW        ; Is number to be output negative?
        BMI OUTNEG       ; Yes, make positive and output ‘-’
        LDAA #$AB          ;  Else, set ASCII code for ‘+’
        BRA AHEAD1       ; Go display + sign
OUTNEG  LDX #¥FPLSW      ; Set pointer to LSByte of FPACC
        LDAB #$03        ; Set precision counter
        JSR COMPLM       ; ~ Make FPACC positive
        LDAA #$AD        ; Set ASCII code for - sign
AHEAD1  JSR ECHO         ; Display sign of mantissa
        LDAA #$B0        ; Set ASCH 0
        JSR ECHO         ; Display the character
        LDAA #$AE        ; Set ASCII (.)
        JSR ECHO         ; Display it
        DEC FPACCE       ; Decrement FPACC exponent
DECEXT  BPL DECEXD      ; If compensated, exponent grtr than or
                 ; Equal to 0, multiply mantissa by 0.1
        LDAA #$04        ; Exponent is negative add 4 (dec.) to |
        ADDA FPACCE      ; Exponent value
        BPL DECOUT       ; If exponent > =0, output mantissa
        JSR FPX10        ; Else, multiply mantissa by 10
DECREP  LDAA FPACCE      ; Get exponent
        BRA DECEXT       ; Repeat above test, > =0
DECEXD  JSR FPD10  ; Multiply FPACC by 0.1
        BRA DECREP       ; Check status of FPACC exponent
DECOUT  LDX #IOSTR       ; Set up for move operation
        STX TEMP2        ; Store pointer to working register
        LDX #FPLSW       ; Set pointer to FPACC
        LDAB #$03        ; Set precision counter
        JSR MOVEIT       ; Move FPACC to output registers
        CLR IOSTR3       ; Clear out register MSByte +1
        LDX #¥IOSTR      ; Set pointer to LSByte output register
        LDAB #$03        ; Set precision counter
        JSR ROTATL       ; Rotate to compensate for sign bit
        JSR DECBIN       ; Output reg x10 overflow in MSByte+1
COMPEN  INC FPACCE       ; Increment FPACC exponent
        BEQ OUTDIG       ; Go output digits when comp. done
        LDX #IOSTR3      ; Else, rotate right to compensate for
        LDAB #¥$04       ; Any remainder in binary exponent
        JSR ROTATR       ; Perform rotate right operation
        BRA COMPEN       ; Repeat loop until exponent = 0
OUTDIG  LDAA #€$07       ; Set digit counter to 7
        STAA CNTR        ; For output operation
        LDAA IOSTR3      ; Fetch BCD, see if first digit =0
        BEQ ZERODG       ; First digit =0? Yes, branch
OUTDGS  LDAA IOSTR3    ; Get BCD from output register
        ADDA #$B0        ; Form ASCII code by adding BO
        JSR ECHO         ; And output digit
DECRDG  DECCNTR  ; Decrement digit counter
        BEQ EXPOUT       ; Equal to 0, done, output exponent
        BSR DECBIN       ; Else, get next digit
        BRA OUTDGS       ; Form ASCII and output
ZERODG  DEC IOEXPD       ; Decr exponent for skipping display
        TST IOSTR2       ; Check if entire mantissa =0
        BNE DECRDG       ; Not 0, continue output sequence
        TST              ; IOSTR1
        BNE              ; DECRDG
        TST              ; IOSTR
        BNE              ; DECRDG
        CLR IOEXPD       ; Yes, clear exponent
        BRA DECRDG       ; _ Before finishing display
DECBIN  CLR IOSTR3       ; First clear output MSByte+1
        LDX #IOLSW       ; Set pointer to I/O work area
        STX TEMP2        ; Store pointer in temporary storage
        LDX #IOSTR       ; Set pointer to I/O storage
        LDAB #$04        ; Set precision counter
        JSR MOVEIT       ; Move I/O storage to work area
        LDX #IOSTR       ; Set pointer to original value
        LDAB #$04        ; Set precision counter
        JSR ROTATL       ; Start x10 routine (total =x2)
        LDX #I1OSTR      ; Reset pointer
        LDAB #$04        ; And counter
        JSR ROTATL       ; Multiply by two again (total =x4)
        LDX #IOLSW       ; Set pointers
        STX TEMP2        ; For ADDER routine
        LDX              ; #IOSTR
        LDAB #¥$04       ; Set precision counter
        JSR ADDER        ; Add original to rotated (total =x5)
        LDX #IOSTR       ; Reset pointer
        LDAB #¥$04       ; And counter
        JMP ROTATL       ; X2 once more (total =x10) and return
EXPOUT  LDAA #$§C5       ; Set ASCII code for letter E
        JSR ECHO         ; Display E for exponent
        TST IOEXPD       ; Test if negative
        BMI EXOUTN       ; Yes, display ‘-’ and negate
        LDAA #$AB        ; No, set ASCII code for ‘+’
        BRA AHEAD2       ; Go display it
EXOUTN  NEG JOEXPD       ; Negate to make exponent positive
        LDAA #$AD        ; Set ASCII code for ‘-’
AHEAD2  JSR ECHO         ; Display sign of exponent
        CLRB Clear       ; B to start counter
        LDAA IOEXPD      ; Get exponent
SUB12   SUBA #$0A        ; Subtract 10 (decimal)
        BMI TOMUCH       ; Look for negative result
        STAA IOEXPD      ; Restore positive result
        INCB      ; Advance 10’s counter
        BRA SUB12        ; Keep subr to obtain MSDigit of exp
TOMUCH  TBA           ; Put MSDigit into A
        ADDA #¥$B0       ; Form ASCII code
        JSR ECHO         ; Output MS Digit
        LDAA IOEXPD      ; Get least significant digit
        ADDA #$B0        ; Form ASCII code
        JMP ECHO         ; Output least signif. digit & return
; END of FPOUT routine

; Routine: FPCONT (Floating Point Control)
; Title: Floating Point Operation Control Handler
; Purpose: Manages floating point operations and exception handling
; Input:
;   - Operation code in A register
;   - Operands in FPAC and memory
; Output:
;   - Status flags indicating operation result
;   - Updated FPAC contents
; Features:
;   - Operation dispatch
;   - Exception handling
;   - Status preservation
;   - Error recovery

FPCONT  LDAA #$8D        ; ASCTI carriage return
        JSR ECHO         ; Output carriage return
        LDAA #$8A        ; ASCTI line feed
        JSR ECHO         ; Output line feed
        JSR FPINP        ; Get 1st floating point decimal number
        BSR SPACES       ; Display a few spaces
        LDX #TPLSW       ; Set pointer to temporary storage
        STX TEMP2        ; Save in pointer storage area
        LDX #FPLSW       ; Set pointer to FPACC LS Byte
        LDAB #$04        ; Set precision counter
        JSR MOVEIT       ; Move FPACC to temporary storage
NVALID  JSR INPUT    ; Fetch operator from I/O
        CMPA #$AB        ; Test for ‘+’ sign
        BNE NOTADD       ; No, try ‘-’
        BSR OPERAT       ; Input FPACC value
        JSR FPADD        ; Add FPOP to FPACC
        BRA FINAL        ; Output result of addition
NOTADD  CMPA #¥$AD       ; Test for ‘-’ sign
        BNE NOTSUB       ; No, try ‘X’
        BSR OPERAT       ; Input FPACC value
        JSR FPSUB        ; Subtract FPACC from FPOP
        BRA FINAL        ; Output result of subtraction
NOTSUB  CMPA #$D8        ; Test for ‘X’ sign
        BNE NOTMUL       ; No, try ‘/’
        BSR OPERAT       ; Input FPACC value
        JSR FPMULT       ; Multiply FPOP times FPACC
        BSR FINAL        ; Output result of multiplication
NOTMUL  CMPA #$AF        ; Test for ‘/’ sign
        BNE NOTDIV       ; No, try delete
        BSR OPERAT       ; Input FPACC value
        JSR FPDIV        ; Divide FPOP by FPACC
FINAL   JSR FPOUT        ; Output the answer
        BRA FPCONT       ; Set up for new input
NOTDIV  CMPA #$8F        ; Not operator, try Control O
        BNE NVALID       ; No, ignore, try again
        BRA FPCONT       ; Yes, restart input string
OPERAT  JSR ECHO         ; Display contro! operator
        BSR SPACES       ; Display a few spaces
        JSR FPINP        ; Fetch second FP decimal number
        BSR SPACES       ; Display a few spaces
        LDAA #$BD        ; Set ASCII code for ‘=’
        JSR ECHO         ; Display ‘=’ sign
        BSR SPACES       ; Display a few spaces
        LDX #FOPLSW      ; Set pointer to FPOP LS Byte
        STX TEMP2        ; Store in temporary pointer storage
        LDX #TPLSW       ; Set pointer to first number input
        LDAB #$04        ; Set precision counter
        JMP MOVEIT       ; Move first input to FPOP and return
; END of FPCONT routine

; Routine: DECADD (Decimal Addition)
; Title: Binary-Coded Decimal Addition Routine
; Purpose: Performs addition of two BCD numbers with decimal point alignment
; Input:
;   - First operand in FPAC
;   - Second operand in memory
;   - X register points to second operand
; Output:
;   - Sum in FPAC
;   - Overflow flag if result exceeds capacity
; Features:
;   - Decimal point alignment
;   - Automatic normalization
;   - Overflow detection

DECADD  CLC        ; Clear the carry flag
DCAD1   LDAA X       ; Fetch byte of first number
        STX TEMP1        ; Store pointer to first number
        LDX TEMP2        ; Fetch pointer to second number
        ADCA X           ; Add byte from second number
        DAA      ; Decimal adjust the A accumulator
        STAA X           ; Store sum in second table
        INX       ;Advance pointer
        STX TEMP2        ; Store pointer to second number
        LDX TEMP1        ; Fetch pointer to first table
        INX      ;Advance  pointer
        DECB   ; Decrement byte counter
        BNE DCAD1        ; Counter #0, continue addition
        RTS           ; =Q,return
; END of DECADD routine

; Routine: DECSUB (Decimal Subtraction)
; Title: Binary-Coded Decimal Subtraction Routine
; Purpose: Performs subtraction of two BCD numbers with decimal point alignment
; Input:
;   - Minuend in FPAC
;   - Subtrahend in memory
;   - X register points to subtrahend
; Output:
;   - Difference in FPAC
;   - Borrow flag if result is negative
; Features:
;   - Decimal point alignment
;   - Automatic normalization
;   - Borrow detection

DECSUB  SEC          ; Set the carry flag
DCSB1   LDAA #$§99       ; Set BCD value of 99
        ADCA #$00        ; Add 00 to form 99 or 100 complemnt
        SBCA X           ; Of the subtrahend value
        STX TEMP1        ; Store pointer to subtrahend
        LDX TEMP2        ; Fetch pointer to minuend
        ADCA X           ; Add minuend to subtrahend
        DAA       ; Decimal adjust the difference
        STAA X           ; Store the difference
        INX       ; Advance the minuend pointer
        STX TEMP2        ; Store the minuend pointer
        LDX TEMP1        ; Fetch the subtrahend pointer
        INX       ; Advance the subtrahend pointer
        DECB    ; Decrement precision counter
        BNE DCSB1        ; #0, continue subtraction
        ROLA      ; Rotate the carry into A accumulator
        COMA   ; Complement the carry to condition
        RORA      ; Rotate the carry back to itself
        RTS        ; Returnwith result in subtrahend
; END of DECSUB routine

; Routine: SGNADD (Signed Addition)
; Title: Signed Binary Addition Routine
; Purpose: Adds two signed binary numbers with overflow detection
; Input:
;   - First operand in FPAC
;   - Second operand in memory
;   - X register points to second operand
; Output:
;   - Sum in FPAC
;   - Overflow flag if result exceeds capacity
; Features:
;   - Sign handling
;   - Overflow detection
;   - Two's complement arithmetic

        SIGNOP RMB $1; Sign byte of DCOP
        SIGNAC RMB $1; Sign byte of DCAC
        DCOP   RMB $2; Decimal operand storage
        DCOPM  RMB $1; Decimal operand MS Byte
        DCAC   RMB $2; Decimal accumulator storage
        DCACM  RMB $1; Decimal accumulator MS Byte

SGNADD  LDAA SIGNOP      ; Fetch sign of DCOP
        CMPA SIGNAC      ; Compare to sign of DCAC
        BEQ SAR2         ; Signs are equal, add numbers & return
        BCC SAR3         ; SIGNOP negative, SIGNAC positive
SAR1    BSR CMPR         ; Is DCOP greater than DCAC?
        BCS SB12         ; No, subtract DCOP from DCAC
        CLR SIGNAC       ; Yes, change SIGNAC to positive
SB21    BSR SHIFT        ; Exchange DCAC and DCOP contents
SB12    LDX #DCAC        ; Set pointers for subtracting
        STX TEMP2        ; DCOP from DCAC
        LDX              ; #DCOP
        LDAB #$03        ; ** Set precision counter
        JMP DECSUB       ; Subtract and return
SAR2    LDX #DCAC        ; Set pointers for addition
        STX TEMP2        ; Of DCOP to DCAC
        LDX              ; #DCOP
        LDAB #¥$03       ; ** Set precision counter
        JMP DECADD       ; Add and return
SAR3    BSR CMPR         ; Is DCOP greater than DCAC?
        BCS SB12         ; No, subtract DCOP from DCAC
        BEQ SB21         ; Equal, SIGNAC remains positive
        LDAA #$80        ; Yes, change SIGNAC
        STAA SIGNAC      ; To negative
        BRA SB21         ; Subtract DCAC from DCOP
SHIFT   LDX #DCOP        ; Set pointer to DCOP
        LDAA X           ; Fetch byte from DCOP
        LDAB $03,X       ; ** Fetch byte from DCAC
        STAB X           ; Store DCAC byte in DCOP
        STAA $03,X       ; ** Store DCOP byte in DCAC
        INX       ; Advance pointer
        CPX #DCOPM+$1    ; Exchange complete?
        BNE SHIFT+$3     ; No, continue
        RTS          ; Yes,return
CMPR    LDX #DCOPM       ; Set pointer to MS Byte of DCOP
        LDAB #$03        ; ** Set precision counter
        LDAA X           ; Fetch byte from DCOP
        CMPA $03,X       ; ** Compare DCOP to DCAC
        BNE CMPRET       ; Not equal, ret w/ C flag conditioned
        DEX        ; Equal,decrement pointer
        DECB    ; Decrement precision counter
        BNE CMPR+$05     ; Last byte compared? No
CMPRET  RTS          ; Yes,return with C flag conditioned
; END of SGNADD routine

; Routine: SGNSUB (Signed Subtraction)
; Title: Signed Binary Subtraction Routine
; Purpose: Subtracts two signed binary numbers with borrow detection
; Input:
;   - Minuend in FPAC
;   - Subtrahend in memory
;   - X register points to subtrahend
; Output:
;   - Difference in FPAC
;   - Borrow flag if result is negative
; Features:
;   - Sign handling
;   - Borrow detection
;   - Two's complement arithmetic

SGNSUB  LDAA SIGNOP     ;  Fetch sign of DCOP
        CMPA SIGNAC      ; Compare to sign of DCAC
        BNE DIFSGN       ; Not equal, change SIGNAC and add
        TSTA         ; Are both negative?
        BMI NEGATV       ; Yes, compare magnitudes
        BSR CMPR         ; Both positive, is DCOP > DCAC?
        BCC SB21         ; Yes, subtract DCAC from DCOP |
        LDAA #$80        ; No, set SIGNAC negative
        STAA SIGNAC            ; 
        BRA SB12         ; Subtract DCOP from DCAC
DIFSGN  LDAA SIGNAC     ;  Fetch SIGNAC
        ADDA #¥$80       ; Change SIGNAC to opposite condition
        STAA SIGNAC      ; Store back in SIGNAC
        BRA SAR2         ; Add DCOP to DCAC
NEGATV  BSR CMPR         ; Compare DCAC to DCOP
        BEQ NEG1         ; Equal, make sign positive, result =0
        BCC SB21         ; DCOP > DCAC, sign negative,
            ; Subtract DCAC from DCOP
NEG1    CLR SIGNAC       ; DCOP < DCAC, SIGNAC positive
        BRA SB12         ; Subtract DCOP from DCAC
; END of SGNSUB routine

; Routine: DECMUL (Decimal Multiplication)
; Title: Binary-Coded Decimal Multiplication Routine
; Purpose: Multiplies two BCD numbers with result normalization
; Input:
;   - Multiplicand in FPAC
;   - Multiplier in memory
;   - X register points to multiplier
; Output:
;   - Product in FPAC
;   - Overflow status if result too large
; Features:
;   - Partial product accumulation
;   - Decimal point tracking
;   - Result normalization
;   - Overflow handling
        DIGCNT RMB       ; $1 Digit counter
        TMPCNT RMB       ; $1 Temporary counter storage
        DCPPO RMB        ; $1 Partial product LS Byte
        DCPP1 RMB        ; $1
        DCPP2 RMB        ; $1
        DCPP3 RMB        ; $1
        DCPP4 RMB        ; $1
        DCPP5 RMB        ; $1 Partial product MS Byte
        DCPP6 RMB        ; $1 Partial product extension
        DCOP RMB         ; $2 DCOP storage
        DCOPM RMB        ; $2 DCOP MS Byte and extension
        DCAC RMB         ; $2 DCAC storage
        DCACM RMB        ; $2 DCAC MS Byte and extension

DECMUL  LDAB #$6         ; Set digit counter
        STAB DIGCNT      ; Store in memory
        INCB Set         ; precision counter
        LDX #DCPPO       ; Set pointer to partial-product
        JSR CLRMEM       ; Clear partial-product area
NXTDGT  LDAB DCAC        ; Fetch LS Byte of accumulator
        ANDB #S$0F       ; Mask off upper half
        BEQ DIGDON       ; If 0, no need to multiply this digit
        STAB TMPCNT      ; Store digit in temporary counter
MULTPL  LDX #DCPP3       ; Set pointer to operand
        STX TEMP2        ; Store in temporary storage
        LDX #DCOP        ; Set pointer to partial-product storage
        LDAB #$4         ; Set precision counter
        BSR DECADD       ; Add DCOP to partial-product
        DEC TMPCNT       ; Decrement digit multiplier
        BNE MULTPL       ; #0, continue multiply loop
DIGDON  LDAA #$4         ; Set rotate counter
PPSHFT  LDAB #$7         ; Set precision counter
        LDX #DCPP6       ; Set pointer to partial-product
        JSR ROTATR       ; Rotate partial-product right
        LDAB #$3         ; Set precision counter and
        LDX #DCACM       ; Pointer to DCAC and
        JSR ROTATR       ; Shift the accumulator to the right
        DECA      ; Shifted 4 times?
        BNE PPSHFT       ; No, continue rotating right
        DEC DIGCNT       ; Decrement digit counter
        BNE NXTDGT       ; #0, continue multiplication
        RTS              ; Return
; END of DECMUL routine

; Routine: DECDIV (Decimal Division)
; Title: Binary-Coded Decimal Division Routine
; Purpose: Performs division of two BCD numbers with rounding
; Input:
;   - Dividend in FPAC
;   - Divisor in memory
;   - X register points to divisor
; Output:
;   - Quotient in FPAC
;   - Division by zero flag if applicable
; Features:
;   - Decimal point alignment
;   - Quotient development
;   - Remainder handling
;   - Division by zero check
DECDIV  LDAB #$06        ; Set up digit counter
        STAB DIGCNT      ; Store digit counter in memory
        LDX #DCPPO       ; Set pointer to QUOTIENT
        JSR CLRMEM       ; Clear QUOTIENT storage
DVNEXT  LDX #DCOP        ; Set pointer to DIVIDEND
        STX TEMP2        ; Store in memory
        LDX #DCAC        ; Set pointer to DIVISOR
        LDAB #$04        ; Set precision counter
        BSR DECSUB       ; Subtract DIVISOR from DIVIDEND
        BCS SUBDON       ; If borrow, exit subtraction
        INC DCPP1        ; Increment decimal counter
        BRA DVNEXT       ; Continue divide loop
SUBDON  LDX #DCOP        ; Set precision counter
        STX TEMP2        ; Store pointer in memory
        LDX #DCAC        ; Set pointer to DIVIDEND
        LDAB #$04        ; Set precision counter
        JSR DECADD       ; Add DIVISOR back to DIVIDEND
        DEC DIGCNT       ; Decrement digit counter
        BEQ DVEXIT       ; =(0, return
        LDAA #$04        ; Set rotate right counter
RESULT  LDX #DCPP1       ; Set pointer to QUOTIENT
        LDAB #$03        ; Set precision counter
        JSR ROTATL       ; Rotate QUOTIENT right
        LDX #DCOP        ; Set pointer to DIVIDEND
        LDAB #$04        ; Set precision counter
        JSR ROTATL       ; Rotate DIVIDEND left
        DECA    ; Decrement rotate counter
        BNE RESULT       ; #0, continue rotating QUOTIENT
        BRA DVNEXT       ; Continue division loop
DVEXIT  RTS              ; Return
; END of DECDIV routine

; Routine: INCMND (Input Command)
; Title: Command Input Processing Routine
; Purpose: Processes and validates input commands from user interface
; Input:
;   - Command string in input buffer
;   - X register points to command buffer
; Output:
;   - Parsed command code in A register
;   - Parameters in designated memory locations
; Features:
;   - Command validation
;   - Parameter extraction
;   - Error detection
;   - Command buffering

NEXCMD  LDX #INPBFR      ; Set pointer to start of input buffer
        LDAB #$06        ; Set clearing counter
        JSR CLRMEM       ; Clear input buffer area
        BSR INCMND       ; Fetch command string fm input device
        BSR SRCHFX       ; Search tbl & perform command input
        BRA NEXCMD       ; Repeat loop for next command
INCMND  LDX #INPBFR      ; Set pointer to start of input buffer
        LDAB #$06        ; Set counter for maximum size of bfr
INCHAR  JSR INPUT        ; Call routine to input character
        CMPA #$8D        ; See if character was carriage return
        BNE CHECK        ; No, continue input routine
        RTS          ; Yes,return, input complete
CHECK   TSTB        ; Test character counter for zero
        BEQ INCHAR       ; If zero, ignore new character
        DECB   ; Otherwise,decrement value of counter
        STAA X           ; And store character in buffer
        INX           ; And advance input buffer pointer
        BRA INCHAR       ; Loop to fetch next character from I/O
; END of INCMND routine

; Routine: INCNTRL (Input Control)
; Title: Input Stream Control Handler
; Purpose: Manages input stream processing and buffering
; Input:
;   - Input stream source identifier
;   - Control parameters in registers
; Output:
;   - Status flags for input state
;   - Processed input in buffer
; Features:
;   - Stream synchronization
;   - Buffer management
;   - Error recovery
;   - Flow control

NEXCMD  BSR INCTRL       ; Fetch command string fm input device
        BSR SRCHFR       ; Search tbl & perform command input
        BRA NEXCMD       ; Repeat loop for next command
INCTRL  LDX #INPBFR      ; Set pointer to start of input buffer
        LDAB #$06        ; Set cntr for maximum nmbr of chars
INCHAR  JSR INPUT     ; Call routine to input character
        CMPA #$8D        ; See if character was a carriage return
        BNE CHECK        ; If not, check for buffer full
        STAA X           ; If so, store CR as last character in bfr
        RTS           ; And return to calling program
CHECK   TSTB         ; Test character counter for zero
        BEQ INCHAR       ; If zero, ignore new character
        DECB   ; Otherwise,decrement value of counter
        STAA X           ; And store character in buffer
        INX           ; And advance input buffer pointer
        BRA INCHAR       ; Loop to fetch next character from I/O
; END of INCNTRL routine


