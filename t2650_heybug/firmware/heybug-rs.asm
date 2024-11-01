NOFOLD
; //=======================================================
; //> HEYBUG Firmware for the Signetics 2650
; //>
; //> PIPBUG Source code written by Signetics taken from
; //> Signetics 2650 microprocessor application memo SS50
; //
; //> Uses some code transcription of the original 
; //> SS50 listing from Jim's repo
; //> https://github.com/jim11662418/Signetics-2650-SBC
; //>
; //> and code from;
; //>
; //> HYBUG
; //> : written by Brian L Young in 1979
; //> 
; //> Published article by Amateur Radio Action
; //> Volume 2 No. 13, Australia. 1979"
; //>
; //> Hybug BIOS as incorporated into Winarcadia 33.3
; //> by James Jacobs from
; //> http://amigan.1emu.net/releases/
; //=======================================================
;
; PIPBUG has been modified as follows:
;  - the serial i/o delays modified by AdamT117
;    (kayto@github)to get the timing working 
;    for Teensy 3.6 Retroshield
; 
; compile with VACS
;
; memory map:
;   0000-03FF   PIPBUG in ROM
;   0400-043F   PIPBUG scratch pad RAM
;   
PAGE 255
WIDTH 160

;2650 specific equates
Z           equ  0
P           equ  1
EQ          equ  0
GT          equ  1
LT          equ  2
UN          equ  3            

sense       equ $80                   ;sense bit in program status, upper
flag        equ $40                   ;flag bit in program status, upper
ii          equ $20                   ;interrupt inhibit bit in program status, upper
rs          equ $10                   ;register select bit in program status, lower
wc          equ $08                   ;with/without carry bit in program status,lower

spac        equ $20                   ;ASCII space
dele        equ $7F                   ;ASCII delete
CR          equ $0D                   ;ASCII carriage return
LF          equ $0A                   ;ASCII line feed
star        equ ':'
bmax        equ 1                     ;maximum number of breakpoints
blen        equ 20                    ;size of input buffer


X3C43		equ	$3C43


            org $0000
            
init:       lodi,R3 63
            eorz    R0
aini:       stra,R0 com,R3,-
            brnr,R3 aini              ;clear memory $0400-$04FF
            lodi,R0 $077              ;opcode for 'ppsl'
            stra,R0 xgot
            lodi,R0 $1B               ;opcode for 'bctr,un'
            stra,R0 xgot+2
            lodi,R0 $80
            stra,R0 xgot+3
            bctr,un mbug              ;do an absolute branch to 'start' function in page 3

vec:        db hi(bk01),lo(bk01)
            db hi(bk02),lo(bk02)

;====================================================================
;command handler
;====================================================================
ebug:       lodi,R0 '?'
            bsta,UN cout
mbug:       cpsl    $FF
            bsta,UN crlf
            lodi,R0 '>'
            bsta,UN cout
            bstr,UN line
            eorz    R0
            stra,R0 bptr
            loda,R0 buff
            comi,R0 'A'         ; Alter Memory
            bcta,EQ alte
            comi,R0 'B'
            bcta,EQ bkpt        ; set breakpoints
            comi,R0 'C'
            bcta,EQ clr
            comi,R0 'D'         ; dump to tape
            bcta,EQ dump            
            comi,R0 'G'         ; goto code
            bcta,EQ goto
            comi,R0 'L'         ;load code from tape
            bcta,EQ load
            comi,R0 'S'         ;set and alter registers
            bcta,EQ sreg
            bcta,UN mbug1       ;out of space so fit extended menu somewhere else               
            
;        ; PIPBUG users expect the 'line' function to be located at $005B
;        if $ > $005B
;            WARNING 'Address MUST be $005A'
;        else                    
;            ds $005B-$,0               
;        endif

;====================================================================
;input a cmd line into buffer
;code is 1=CR 2=LF 3=MSG+CR 4=MSG+LF
;====================================================================
line:       lodi,R3 $FF
            stra,R3 bptr
llin:       comi,R3 blen
            bctr,EQ elin
            bsta,UN chin
            comi,R0 dele
            bcfr,EQ alin
            comi,R3 $FF
            bctr,EQ llin
            loda,R0 buff,R3
            bsta,UN cout
            subi,R3 1
            bctr,UN llin
            
alin:       comi,R0 CR
            bcfr,EQ blin
elin:       lodi,R1 1
clin:       lodz    R3
            bctr,LT dlin
            addi,R1 2
dlin:       stra,R1 code
            stra,R3 cnt
crlf:       lodi,R0 CR
            bsta,UN cout
            lodi,R0 LF
            bsta,UN cout
            retc,UN
            
blin:       lodi,R1 2
            comi,R0 LF
            bctr,EQ clin
            stra,R0 buff,R3,+
            bsta,UN cout
            bcta,UN llin
;====================================================================
;store two bytes in R1 and R2 into temp and temp+1
;====================================================================
strt:       stra,R1 temp
            stra,R2 temp+1
            retc,UN
;====================================================================
; display and alter memory
;====================================================================            
alte:       bsta,UN gnum
lalt:       bstr,UN strt
            bsta,UN bout
            loda,R1 temp+1
            bsta,UN bout
            bsta,UN form
            loda,R1 *temp
            bsta,UN bout
            bsta,UN form
            bsta,UN line
            loda,R0 code
            comi,R0 2
            bcta,LT mbug
            bctr,EQ dalt
calt:       stra,R0 temr
            bsta,UN gnum
            stra,R2 *temp
            loda,R0 temr
            comi,R0 4
            bcfa,EQ mbug
dalt:       lodi,R2 1
            adda,R2 temp+1
            lodi,R1 0
            ppsl    wc
            adda,R1 temp
            cpsl    wc
            bcta,UN lalt
;====================================================================
; selectively display and alter register
;====================================================================
sreg:       bsta,UN gnum
lsre:       comi,R2 8
            bcta,GT ebug
            stra,R2 temr
            loda,R0 com,R2
            strz    R1
            bsta,UN bout
            bsta,UN form
            bsta,UN line
            loda,R0 code
            comi,R0 2
            bcta,LT mbug
            bctr,EQ csre
asre:       stra,R0 temq
            bsta,UN gnum
            lodz    R2
            loda,R2 temr
            stra,R0 com,R2
            comi,R2 8
            bcfr,EQ bsre
            stra,R0 xgot+1
bsre:       loda,R0 temq
            comi,R0 3
            bcta,EQ mbug
csre:       loda,R2 temr
            addi,R2 1
            bcta,UN lsre
;====================================================================
; goto address
;====================================================================
goto:       bsta,UN gnum                ;get the address
            bsta,UN strt                ;save the address in temp and temp+1   
            loda,R0 com+7
            lpsu                        ;restore program status, upper
            loda,R1 com+1               ;restore R1 in register bank 0
            loda,R2 com+2               ;restore R2 in register bank 0
            loda,R3 com+3               ;restore R3 in register bank 0
            ppsl    rs
            loda,R1 com+4               ;restore R1 in register bank 1
            loda,R2 com+5               ;restore R2 in register bank 1
            loda,R3 com+6               ;restore R3 in register bank 1
            loda,R0 com                 ;restore R0
            cpsl    $FF                 ;clear program status, lower
            bcta,UN xgot                ;branch to the address in 'xgot' which branches to the address in temp and temp+1
;====================================================================
; breakpoint runtime code
;====================================================================
bk01:       stra,R0 com
            spsl
            stra,R0 com+8
            stra,R0 xgot+1
            lodi,R0 0
            bctr,UN bken
bk02:       stra,R0 com
            spsl
            stra,R0 com+8
            stra,R0 xgot+1
            lodi,R0 1
bken:       stra,R0 temr
            spsu
            stra,R0 com+7
            ppsl    rs
            stra,R1 com+4
            stra,R2 com+5
            stra,R3 com+6
            cpsl    rs
            stra,R1 com+1
            stra,R2 com+2
            stra,R3 com+3
            loda,R2 temr
            bstr,UN clbk
            loda,R1 temp
            bsta,UN bout
            loda,R1 temp+1
            bsta,UN bout
            bcta,UN mbug
;====================================================================
; clear a breakpoint
;====================================================================
clbk:       eorz    R0
            stra,R0 mark,R2
            loda,R0 hadr,R2
            stra,R0 temp
            loda,R0 ladr,R2
            stra,R0 temp+1
            loda,R0 hdat,R2
            stra,R0 *temp
            loda,R0 ldat,R2
            lodi,R3 1
            stra,R0 *temp,R3
            retc,UN
;break point mark indicates if set
;hadr+ladr is breakpoint address hdat+ldat is two byte
clr:        bstr,UN nok
            loda,R0 mark,R2
            bcta,EQ ebug
            bstr,UN clbk
            bcta,UN mbug        
nok:        bsta,UN gnum
            subi,R2 1
            bcta,LT abrt
            comi,R2 bmax
            bcta,GT abrt
            retc,UN
bkpt:       bstr,UN nok
            loda,R0 mark,R2
            bsfa,EQ clbk
            stra,R2 temr
            bsta,UN gnum
            bsta,UN strt
            loda,R3 temr
            lodz    R2
            stra,R0 ladr,R3
            lodz    R1
            stra,R0 hadr,R3
            loda,R0 *temp
            stra,R0 hdat,R3
            lodi,R1 $9B
            stra,R1 *temp
            lodi,R2 1
            loda,R0 *temp,R2
            stra,R0 ldat,R3
            loda,R0 disp,R3
            stra,R0 *temp,R2
            lodi,R0 $FF
            stra,R0 mark,R3
            bcta,UN mbug
disp:       db  vec+$80
            db  vec+$80+2

;        ; PIPBUG users expect the 'bin' function to be located at $0224
;        if $ > $0224
;            WARNING 'Address MUST be $0224'
;        else
;            ds $0224-$,0                
;        endif         
;====================================================================
; input two hex characters and form a byte in R1
;====================================================================
bin:        bsta,UN chin
            bstr,UN lkup
            rrl,R3
            rrl,R3
            rrl,R3
            rrl,R3
            stra,R3 tems
            bsta,UN chin
            bstr,UN lkup
            iora,R3 tems
            lodz    R3
            strz    R1
            bstr,UN cbcc       
            retc,UN
;====================================================================           
; calculate the BCC, EOR and then rotate left
;====================================================================
cbcc:       lodz    R1         
            eora,R0 bcc         
            rrl,R0             
            stra,R0 bcc        
            retc,UN            
;        ; PIPBUG users expect the 'lkup' function to be located at $0246
;        if $ > $0246
;            WARNING 'Address MUST be $0246'
;        else
;            ds $0246-$,0                
;        endif          
;lookup ASCII char in hex value table
lkup:       lodi,R3 16
alku        coma,R0 ansi,R3,-
            retc,EQ
            comi,R3 1
            bcfr,LT alku
;abort exit from any level of subroutine
;use ras ptr since possible bkpt prog using it
abrt:       loda,R0 com+7
            iori,R0 $40
            spsu
            bcta,UN ebug
            
ansi:       db  "0123456789ABCDEF"

        ; PIPBUG users expect the 'bout' function to be located at $0269
        if $ > $0269
            WARNING 'Address MUST be $0269'
        else
            ds $0269-$,0                
        endif         
;====================================================================
; output byte in R1 as 2 hex characters
;====================================================================
bout:       stra,R1 tems
            ;bstr,un cbcc
            rrr,R1
            rrr,R1
            rrr,R1
            rrr,R1
            andi,R1 $0F
            loda,R0 ansi,R1
            bsta,UN cout
            loda,R1 tems
            andi,R1 $0F
            loda,R0 ansi,R1
            bsta,UN cout
            retc,UN
            
;        ; PIPBUG users expect the 'chin' function to be located at $0286
;        if $ > $0286
;            WARNING 'Address MUST be $0286'
;        else
;            ds $0286-$,0                
;        endif
;====================================================================
; pipbug serial input function
;====================================================================
chin:       ppsl    rs                 ;select register bank 1
            lodi,R0 $80
            wrtc,R0
            lodi,R1 0                  ;initialize R1
            lodi,R2 8                  ;load R2 with the number of bits to receive
achi:       spsu                       ;store program status, upper containing the sense input to R0
            bctr,LT chin               ;branch back if the sense input is "1" (wait for the start bit)
            eorz    R0               
            wrtc,R0
            bstr,UN dly                ;delay 1/2 bit time
bchi:       bstr,un	dlay
            spsu
            andi,r0 $80
            rrr,r1
            iorz	r1
            strz	r1
            bdrr,r2	bchi
            bstr,un	dlay
            andi,r1	$7F
            lodz	r1
            cpsl	rs+wc
            retc,un
;********************************************************************
; adjusted delays for Teensy3.6 Retroshield
;********************************************************************
dlay:       eorz    r0
            lodi,r0 $20    
            bdrr,r0 $
            nop
            nop  
dly:        lodi,R0 $05
            bdrr,R0 $
            retc,UN
;********************************************************************
; original PIPBUG delays - 
;********************************************************************
; dlay:
	        ; eorz	r0
	        ; nop
	        ; nop
	        ; nop
	        ; nop
; dly:
	        ; bdrr,r0	dly
	        ; lodi,r0	$60
; L02B1:
	        ; bdrr,r0	L02B1
	        ; retc,un
;********************************************************************
;        ; PIPBUG users expect the 'cout' function to be located at $02B4
        if $ > $02B4
;            WARNING 'Address MUST be $02B4'
        else
            ds $02B4-$,0                
        endif
;====================================================================
; pipbug serial output function
;====================================================================
cout:       ppsl    rs                  ;select register bank 1
            ppsu    flag                ;set FLAG output to "1" (send MARK)
            strz    R2                  ;save the character (now in R0) in R2
            lodi,R1 8                   ;load R1 with the number of bits to send
            bstr,UN dlay                ;timing adjustments
            bstr,UN dlay
            cpsu    flag                ;clear the FLAG output (send start bit)           
acdu:       bstr,UN dlay                ;delay one bit time
            rrr,R2                      ;rotate the next bit of R2 into bit 7  
            bctr,LT one                 ;branch if bit 7 was "1"
            cpsu    flag                ;else, send "0" (SPACE)
            bctr,UN zero
one:        ppsu    flag                ;send "1" (MARK)
zero:       bdrr,R1 acdu                ;loop until all 8 bits are sent
            bstr,UN dlay
            ppsu    flag                ;preset the FLAG output (send stop bit)         
            cpsl    rs                  ;select register bank 0
            retc,UN    
;get a number from the buffer into R1-R2
dnum:       loda,R0 code
            bctr,EQ lnum
            retc,UN
gnum:       eorz    R0
            strz    R1
            strz    R2
            stra,R0 code
lnum:       loda,R3 bptr
            coma,R3 cnt
            retc,EQ
            loda,R0 buff,R3,+
            stra,R3 bptr
            comi,R0 spac
            bctr,EQ dnum
bnum:       bsta,UN lkup
cnum:       lodi,R0 $0F
            rrl,R2
            rrl,R2
            rrl,R2
            rrl,R2
            andz    R2
            rrl,R1
            rrl,R1
            rrl,R1
            rrl,R1
            andi,R1 $F0
            andi,R2 $F0
            iorz    R1
            strz    R1
            lodz    R3
            iorz    R2
            strz    R2
            lodi,R0 1
            stra,R0 code
            bctr,UN lnum
dump:       bstr,un	gnum
            bsta,un	strt
            bstr,un	gnum
            addi,r2	$01
            ppsl	wc
            addi,r1	$00
            cpsl	wc
            stra,r1	temq
            stra,r2	temq+1
fdum:       bstr,un	gap
            lodi,r0	$FF
            stra,r0	cnt
            bsta,un	crlf
            lodi,r0	star
            bsta,un	cout
            eorz	r0
            stra,r0	bcc
            loda,r1	temq
            loda,r2	temq+1
            suba,r2	temp+1
            ppsl	wc
            suba,r1	temp
            cpsl	wc
            bcta,LT	ebug
            bctr,gt	adum
            brnr,r2	bdum
            lodi,r3	$04
cdum:       bsta,un	bout
            bdrr,r3	cdum
            bstr,un	gap
            bcta,un	mbug
form:       lodi,r3	$03
            bctr,un	agap
gap:        lodi,r3	$32
agap:       lodi,r0	spac
            bsta,un	cout
            bdrr,r3	agap
            retc,un
adum:       lodi,r2	$FF
bdum:       stra,r2	mcnt
            loda,r1	temp
            bsta,un	bout
            loda,r1	temp+1
            bsta,un	bout
            loda,r1	mcnt
            bsta,un	bout
            loda,r1	bcc
            bsta,un	bout
ddum:       loda,r3	cnt
            loda,r0	*temp,r3,+
            coma,r3	mcnt
            bctr,eq	edum
            stra,r3	cnt
            strz	r1
            bsta,un	bout
            bctr,un	ddum
edum:       loda,r1	bcc
            bsta,un	bout
            loda,r2	temp+1
            adda,r2	mcnt
            lodi,r1	$00
            ppsl	wc
            adda,r1	temp
            cpsl	wc
            bsta,un	strt
            bcta,un	fdum
load:      bsta,un	chin
            comi,r0	star
            bcfr,eq	load
            eorz	r0
            stra,r0	bcc
            bsta,un	bin
            stra,r1	temp
            bsta,un	bin
            stra,r1	temp+1
            bsta,un	bin
            brnr,r1	aloa
            bcta,un	*temp			;INFO: indirect jump
aloa:       stra,r1	mcnt
            bsta,un	bin
            loda,r0	bcc
            bcfa,eq	ebug
            strz	r3
bloa:       stra,r3	cnt
            bsta,un	bin
            loda,r3	cnt
            coma,r3	mcnt
            bctr,eq	cloa
            lodz	r1
            stra,r0	*temp,r3
            birr,r3	bloa
cloa:
            loda,r0	bcc
            bcfa,eq	ebug
            bcta,un	load           
            db	$00,$00





;==================================================================== 
; 2650 Line Assembler - Improved
; by A. M. KOLLOSCHE Higginbotham Avenus. Armidals NSW 2350 
; ELECTRONICS Austraila, .February, 1980
;=================================================================== 			
;temp remove
;            ds  $1590-$,0               ;fill empty space with zeros
;            org $1590
; lass:
			; bsta,un	crlf                           ;15C0 : 3F 00 8A		"?  "	[3]		
			; bcta,un	L1600                           ;15C3 : 1F 16 00		"   "	[3]				




; ;modification for improved error handling
            ; ds  $159E-$,0               ;fill empty space with zeros
            ; org $159E

            ; db $00,$00

; L15A0:            ;load and store subr
            ; loda,r1 $040D
            ; loda,r2 $040e
            ; strr,r1 $159E
            ; strr,r2 $159F
            ; retc,un
; L15AB:            ;load addr subr
            ; lodr,r1 $159E
            ; lodr,r2 $159F
            ; retc,un
; L15B0:            ;new error handling routine
            ; cpsl $FF
            ; cpsu $0F
            ; lodi,r1 $08
            ; loda,r1 *$15c3
            ; zbsr *$0020
            ; bdrr,r1 $15b6
            ; zbsr *$0025
            ; bstr,un $15ab
            ; bcta,un $160c
; L15C4:            ;error message
            ; db $52,$4f,$52
            ; db $52,$45,$20
            ; db $20,$3F			

 ;====================================================================           
           ds  $15C0-$,0               ;fill empty space with zeros
           org $15C0
lass:       bsta,UN crlf
           bcta,UN L1600
           ds  $15CC-$,0               ;fill empty space with zeros
           org $15CC

	db $F4,$0C,$18,$02
    db	$45,$1F,$6D,$04,$2A,$1F,$17,$5B,$F4,$04,$98,$0F,$3F,$1A,$95,$CE
    db	$84,$0D,$3B,$0F,$EF,$04,$29,$9A,$25,$1B,$71,$3B,$F0,$1B,$1D,$02
    db	$69,$1A,$CD,$0D,$04,$0D,$0E,$04,$0E,$DA,$02,$D9,$00,$1F,$00,$A4
L1600: ;$1600
	;db $20,$07,$14,$CF,$5A,$40,$5B,$7B,$3F,$1A,$55,$C0
    db	$20,$07,$14,$CF,$5A,$40,$5B,$7B,$3F,$1A,$55,$C0
	
	
;==================================================================== 
; 2650 Line Assembler - Improved
; by A. M. KOLLOSCHE Higginbotham Avenus. Armidals NSW 2350 
; ELECTRONICS Austraila, .February, 1980
;=================================================================== 
; *MODIFIED START SEQUENCE
    ; BSTR,UN *$15FE      ; 160C 3BF0  		;         
    ; BSTA,UN $15A0       ; 160E 3F15A0		;  ;Go to new subr
    ; BSTR,UN *$15EF      ; 1611 3BDC			; 
    ; LODZ    r2          ; 1613 02			; 
    ; STRZ    r1          ; 1614 C1			; 
    ; BSTR,UN *$15EF      ; 1615 3BD8			; 
    ; LODI,R0 $2E         ; 1617 042E			; 
    ; BSTA,UN $02B4       ; 1619 3F02B4		; 
    ; BSTR,UN *$15F1      ; 161C 3BD3			; 
;=================================================================== 


;       0   1   2   3   4   5   6   7   8   9  A   B   C    D   E   F
;$160c                                              
													db $3B,$F0,$0D,$04	;ok comment out for improved line assembler 
	db $0D,$3B,$DC,$0D,$04,$0E,$3B,$D7,$04,$2E,$BB,$A0,$3B,$D3			;ok comment out for improved line assembler 
;$161e                                                      
                                                            db $0C,$1A	;ok
;$1620
	;db $02,$E4,$2A,$18,$69,$E4,$40,$98,$3C,$0F,$3A,$02,$A4,$30,$1E,$30	; modified
;$162F
    db $02,$E4,$2A,$18,$69,$E4,$40,$98,$3C,$0F,$3A,$02,$A4,$30,$1E,$02	;ok comment out for improved line assembler
    db	$50,$C3,$E7,$09,$19,$F9,$D3,$06,$01,$0F,$7A,$40,$CC,$04,$0F,$C1
    db	$0F,$7A,$41,$CC,$04,$10,$61,$18,$1A,$0C,$84,$0F,$CF,$7A,$40,$0E
    db	$E4,$0F,$CF,$7A,$41,$0C,$04,$0D,$CC,$84,$0F,$0C,$04,$0E,$CE,$E4
    db	$0F,$1B,$56,$07,$02,$20,$CC,$04,$2A,$3B,$BE,$3F,$17,$7A,$CC,$04
    db	$11,$60,$9A,$2B,$44,$0F,$1C,$00,$22,$F4,$02,$98,$9C,$3B,$AA,$0F
    db	$7A,$02,$C2,$0F,$3A,$02,$EF,$04,$29,$9E,$16,$0E,$E2,$18,$FB,$CC
    db	$84,$0D,$02,$3F,$15,$F3,$C2,$1B,$6A,$15,$D8,$C0,$C0,$1A,$95,$CE
    db	$84,$0D,$E4,$10,$9A,$21,$87,$01,$3F,$17,$6B,$0F,$7A,$02,$E4,$40

    ;$16B0
	;db $99,$0A,$3F,$17,$7A,$84,$10,$18,$05,$1F,$2B  ;modified
;$16BA                                          
    db $99,$0A,$3F,$17,$7A,$84,$10,$18,$05,$1F,$02  ;ok comment out for improved line assembler                                
;$16BB                                          
                                                db $50,$3B,$DF,$46,$03	;ok
    db	$0C,$84,$0D,$62,$CC,$84,$0D,$3B,$CB,$0C,$04,$11,$F4,$01,$1C,$16
    db	$0E,$F4,$02,$1C,$17,$22,$3B,$D1,$0F,$7A,$02,$E4,$30,$9A,$1B,$87
    db	$01,$05,$FF,$ED,$37,$CF,$18,$06,$E5,$04,$1A,$77,$1B,$CC,$D1,$D1
    db	$D1,$D1,$D1,$6D,$04,$2A,$C9,$FC,$1B,$5C,$E4,$40,$98,$24,$0F,$3A

    ;$1700
	;db $02,$A4,$30,$1E,$05  ;modified
;$1704
    db $02,$A4,$30,$1E,$02  ;ok comment out for improved line assembler
;$1705                  
                        db $50,$C3,$E7,$09,$19,$F9,$D3,$0F,$7A,$40,$C1	;ok
    db	$0F,$7A,$41,$C2,$0C,$04,$0D,$CF,$7A,$40,$0C,$04,$0E,$CF,$7A,$41
    db	$1B,$B7,$3F,$1A,$95,$0C,$04,$11,$F4,$08,$18,$AD,$F4,$04,$98,$24
    db	$77,$09,$A6,$01,$A5,$00,$77,$01,$AE,$04,$0E,$AD,$04,$0D,$75,$08  
;$1740
	;db $18,$0D,$85,$01,$9C,$46  ;modified
;$1745                    
	db $18,$0D,$85,$01,$9C,$02  ;ok comment out for improved line assembler
                            db $50,$F6,$C0,$98,$FA,$46,$7F,$1B,$05,$04	;ok
    db	$C0,$42,$98,$F1,$6E,$04,$2A,$1B,$0A,$15,$CC,$CD,$84,$0D,$02,$3F
    db	$15,$F3,$C2,$CE,$84,$0D,$3B,$F8,$1F,$16,$0E,$04,$20,$FB,$00,$EF
    db	$3A,$02,$18,$7B,$EF,$04,$29,$9A,$CC,$17,$06,$FC,$A7,$01,$0F,$3A
    db	$02,$EB,$F2,$9A,$0D,$E4,$30,$1A,$09,$CE,$79,$40,$DA,$70,$87,$01
    db	$1B,$07,$04,$20,$CE,$79,$40,$DA,$7B,$CF,$04,$28,$75,$01,$77,$08
    db	$05,$17,$06,$D4,$CD,$04,$0F,$CE,$04,$10,$07,$FF,$0F,$A4,$0F,$1C

;$17B0
	db $02;ok comment out for improved line assembler
    ;db $B1  ;modified
        db $50,$EF,$7A,$3C,$18,$06,$86,$06,$85,$00,$1B,$67,$E7,$03,$1A	;ok
    db	$6B,$0F,$A4,$0F,$C2,$0F,$A4,$0F,$0F,$04,$28,$75,$08,$17,$00,$2C
    db	$2B,$2D,$23,$2A,$52,$30,$20,$20,$00,$F0,$52,$31,$20,$20,$01,$F0
    db	$52,$32,$20,$20,$02,$F0,$52,$33,$20,$20,$03,$F0,$50,$20,$20,$20
    db	$01,$F0,$5A,$20,$20,$20,$00,$F0,$4E,$20,$20,$20,$02,$F0,$4C,$54
    db	$20,$20,$02,$F0,$45,$51,$20,$20,$00,$F0,$47,$54,$20,$20,$01,$F0
    db	$55,$4E,$20,$20,$03,$F0,$45,$4E,$44,$20,$00,$80,$4F,$52,$47,$20
    db	$00,$81,$41,$53,$43,$49,$00,$82,$4C,$4F,$44,$5A,$00,$01,$4C,$4F
    db	$44,$49,$04,$02,$4C,$4F,$44,$52,$08,$04,$4C,$4F,$44,$41,$03,$08
    db	$53,$54,$52,$5A,$C0,$01,$53,$54,$52,$52,$C8,$04,$53,$54,$52,$41
    db	$CC,$08,$49,$4F,$52,$5A,$60,$01,$49,$4F,$52,$49,$64,$02,$49,$4F
    db	$52,$52,$68,$04,$49,$4F,$52,$41,$6C,$08,$41,$4E,$44,$5A,$40,$01
    db	$41,$4E,$44,$49,$44,$02,$41,$4E,$44,$52,$48,$04,$41,$4E,$44,$41
    db	$4C,$08,$45,$4F,$52,$5A,$20,$01,$45,$4F,$52,$49,$24,$02,$45,$4F
    db	$52,$52,$28,$04,$45,$4F,$52,$41,$2C,$08,$42,$43,$54,$52,$18,$04
    db	$42,$43,$54,$41,$1C,$0C,$42,$43,$46,$52,$98,$04,$42,$43,$46,$41
    db	$9C,$0C,$43,$4F,$4D,$5A,$E0,$01,$43,$4F,$4D,$49,$E4,$02,$43,$4F
    db	$4D,$52,$E8,$04,$43,$4F,$4D,$41,$EC,$08,$41,$44,$44,$5A,$80,$01
    db	$41,$44,$44,$49,$84,$02,$41,$44,$44,$52,$88,$04,$41,$44,$44,$41
    db	$8C,$08,$53,$55,$42,$5A,$A0,$01,$53,$55,$42,$49,$A4,$02,$53,$55
    db	$42,$52,$A8,$04,$53,$55,$42,$41,$AC,$08,$52,$45,$54,$43,$14,$01
    db	$52,$45,$54,$45,$34,$01,$42,$53,$54,$52,$38,$04,$42,$53,$54,$41
    db	$3C,$0C,$42,$53,$46,$52,$B8,$04,$42,$53,$46,$41,$BC,$0C,$52,$52
    db	$52,$20,$50,$01,$52,$52,$4C,$20,$D0,$01,$43,$50,$53,$55,$74,$12
    db	$43,$50,$53,$4C,$75,$12,$50,$50,$53,$55,$76,$12,$50,$50,$53,$4C
    db	$77,$12,$42,$52,$4E,$52,$58,$04,$42,$52,$4E,$41,$5C,$0C,$42,$49
    db	$52,$52,$D8,$04,$42,$49,$52,$41,$DC,$0C,$42,$44,$52,$52,$F8,$04
    db	$42,$44,$52,$41,$FC,$0C,$42,$53,$4E,$52,$78,$04,$42,$53,$4E,$41
    db	$7C,$0C,$4E,$4F,$50,$20,$C0,$11,$48,$41,$4C,$54,$40,$11,$54,$4D
    db	$49,$20,$F4,$02,$57,$52,$54,$44,$F0,$01,$52,$45,$44,$44,$70,$01
    db	$57,$52,$54,$43,$B0,$01,$52,$45,$44,$43,$30,$01,$57,$52,$54,$45
    db	$D4,$02,$52,$45,$44,$45,$54,$02,$5A,$42,$53,$52,$BB,$10,$5A,$42
    db	$52,$52,$9B,$10,$54,$50,$53,$55,$B4,$12,$54,$50,$53,$4C,$B5,$12
    db	$4C,$50,$53,$55,$92,$11,$4C,$50,$53,$4C,$93,$11,$53,$50,$53,$55
    db	$12,$11,$53,$50,$53,$4C,$13,$11,$42,$53,$58,$41,$BF,$1C,$42,$58
    db	$41,$20,$9F,$1C,$44,$41,$52,$20,$94,$01,$4C,$44,$50,$4C,$10,$1C
    db	$53,$54,$50,$4C,$11,$1C,$44,$41,$54,$41,$00,$84,$00,$00,$00,$00
    db	$00,$00

            ds  $1a55-$,0               ;fill empty space with zeros
            org $1a55
;       0   1   2   3   4   5   6   7   8   9  A   B   C    D   E   F
	                    db $05,$1A,$06,$6C,$3F,$00,$A4,$07,$FF,$0F,$A4	;ok
;$1a60
    db	$0D,$18,$04,$BB,$A0,$1B,$77,$05,$04,$06,$40,$17,$32,$36,$35,$30
    db	$20,$4C,$49,$4E,$45,$20,$41,$53,$53,$45,$4D,$42,$4C,$45,$52,$0D
    db	$0A,$0A,$00,$00,$A4,$30,$1A,$0A,$E4,$0A,$16,$A4,$07,$1A,$03,$E4
;$1a90
	;db $10,$16,$1F,$94  ;modified
;$1a93
    db	$10,$16,$1F,$02 ;comment out for improved line assembler
                    db $50,$20,$C1,$C2,$CC,$04,$12,$08,$FC,$15,$EF,$04	;ok
	db $29,$14,$0F,$7A,$02,$E4,$20,$98,$02,$DB,$70,$3B,$57,$D2,$D2,$D2	;ok
	db $D2,$CE,$04,$28,$46,$F0,$62,$C2,$D1,$D1,$D1,$D1,$45,$F0,$08,$F2	;ok
;$1ac0
	db $44,$0F,$61,$C1,$04,$01,$C8,$D1,$DB,$54,$0A,$0D,$5E
;$1acd    
   db $07,$00,$E7														;ok comment out for improved line assembler
	db $3C,$1C,$00,$1D,$3F,$02,$86,$E4,$7F,$98,$0A,$03,$18,$71,$0F,$5A	;ok comment out for improved line assembler
	db $02,$BB,$A0,$1B,$6A,$05,$03,$ED,$7A,$C9,$18,$09,$F9,$79,$CF,$7A	;ok comment out for improved line assembler
	db $02,$BB,$A0,$DB,$5A,$CF,$04,$29,$CD,$04,$2A,$07,$00,$9B,$A5		;ok comment out for improved line assembler

;==================================================================== 
; 2650 Line Assembler - Improved
; by A. M. KOLLOSCHE Higginbotham Avenus. Armidals NSW 2350 
; ELECTRONICS Austraila, .February, 1980
;===================================================================     
    
;modified line input routine                                                           							; ;
; L1ACD:                                             ; 1ACD								
		; lodi,r3	$00                                        ; 1ACD : 07 00			   "  "	[2]
; L1ACF:                                             ; 1ACF								
		; comi,r3	$3C                                      ; 1ACF : E7 3C			   " <"	[2]
		; ;bcta,eq	L15B0                                      ; 1AD1 : 1C 15 B0	   "   "	[3]
        ; db $1c,$d3,$b0
		; bsta,un	$0286                                      ; 1AD4 : 3F 02 86	   "?  "	[3]
		; comi,r0	$7F                                      ; 1AD7 : E4 7F			   "  "	[2]
; X1AD9:                                             ; 1AD9								
		; bcfr,eq	L1AE6                                      ; 1AD9 : 98 0B		    "  "	[3]
		; lodz	r3                                         ; 1ADB : 03			    " "		[2]
		; bctr,eq	L1ACF                                      ; 1ADC : 18 71		    " q"	[3]
		; lodi,r0	$08                                      ; 1ADE : 04 08		    "  "	[2]
		; zbsr	*$0020			;INFO: indirect jump     ; 1AE0 : BB A0		    "  "	[3]
		; subi,r3	$01                                      ; 1AE2 : A7 01		    "  "	[2]
		; bctr,un	L1ACF                                      ; 1AE4 : 1B 69		    " i"	[3]
                                                           							; ; ;
; L1AE6:                                             ; 1AE6								
		; lodi,r1	$03                                      ; 1AE6 : 05 03		    "  "	[2]
; L1AE8:                                             ; 1AE8								
		; coma,r1	$1AC9                                      ; 1AE8 : ED 1A C9	   "   "	[4]
		; bctr,eq	L1AF6                                      ; 1AEB : 18 09			   "  "	[3]
		; bdrr,r1	L1AE8                                      ; 1AED : F9 79			   " y"	[3]
		; stra,r3	$1A02                                      ; 1AEF : CF 1A 02	    "   "	[4]
		; zbsr	*$0020			;INFO: indirect jump     ; 1AF2 : BB A0			   "  "	[3]
		; birr,r3	L1ACF                                      ; 1AF4 : DB 59			   " Y"	[3]
		; L1AF6:                                             ; 1AF6								
		; stra,r3	$0429                                      ; 1AF6 : CF 04 29	    "  )"	[4]
		; stra,r1	$042A                                     ; 1AF9 : CD 04 2A	    "  *"	[4]
		; lodi,r3	$00                                        ; 1AFC : 07 00			   "  "	[2]
		; zbrr	*$0025			;INFO: indirect jump	 ; 1AFE : 9B A5			   "  "	[3]		

;==================================================================== 
; An improved 2650 disassembler
; by JAMIESON ROWE 
; ELECTRONICS Australia, August, 1979
;==================================================================== 
        ds  $1B00-$,0               ;fill empty space with zeros
        org $1B00
        db	$76,$60,$77,$02,$3F,$02,$DB,$3F,$1C,$1C,$3B,$F9
        db	$CD,$1A,$48,$CE,$1A,$49,$E9,$AB,$19,$07,$1E,$02
        db	$50,$EA,$AA,$99,$FA,$3B,$E6,$CE,$1A,$40,$08,$FC
        db	$CC,$1A,$41,$18,$08,$05,$1D,$06,$9E,$3F,$1D,$8A
        db	$C0,$07,$FF,$04,$20,$CF,$3A,$02,$E7,$22,$98,$79
        db	$07,$FF,$0C,$1A,$46,$3F,$1D,$30,$0C,$1A,$47,$3B
        db	$F9,$87,$01,$0C,$9A,$46,$3B,$F2,$75,$09,$77,$02
        db	$07,$00,$06,$12,$EF,$7B,$6B,$18,$06,$87,$02,$FA
        db	$77,$1B,$2C,$05,$19,$0F,$3B,$6B,$C2,$1B,$36,$74
        db	$2A,$75,$30,$76,$36,$77,$3C,$C0,$72,$40,$78,$BB
        db	$A8,$9B,$AE,$B4,$B4,$B5,$BA,$92,$C0,$93,$C6,$12
        db	$CC,$13,$D2,$BF,$D8,$9F,$DE,$10,$EA,$11,$F0,$05
        db	$18,$06,$28,$44,$FC,$3F,$1D,$55,$E7,$00,$98,$08
        db	$07,$07,$1F,$1B,$ED,$3F,$1D,$4E,$06,$04,$07,$FF
        db	$0F,$BA,$42,$CF,$7A,$11,$FA,$78,$07,$05,$0F,$FA
        db	$42,$C2,$C3,$46,$0F,$47,$F0,$E6,$0C,$1C,$1C,$C9
        db	$E6,$08,$1C,$1C,$9B,$E6,$04,$1C,$1C,$65,$E6,$02
        db	$1C,$1C,$48,$E6,$01,$1C,$1C,$25,$3F,$1D,$0D,$3F
        db	$1C,$EF,$3F,$1D,$70,$C2,$20,$F6,$80,$98,$02,$04
        db	$1F,$07,$18,$3F,$1D,$30,$02,$3B,$FB,$20,$CF,$3A
        db	$02,$05,$1A,$06,$02,$3F,$1D,$8A,$3F,$1C,$FB,$ED
        db	$1A,$48,$1D,$00,$22,$1A,$05,$EE,$1A,$49,$19,$F7
        db	$75,$09,$04,$FF,$8C,$1A,$41,$C8,$FC,$E4,$00,$9C
        db	$1B,$31,$3F,$02,$86,$1F,$1B,$22,$CD,$1A,$46,$CE
        db	$1A,$47,$17,$C0,$C0,$F7,$10,$18,$1A,$0C,$9A,$46
        db	$C1,$44,$03,$45,$DC,$25,$14,$98,$04,$06,$EC,$1B
        db	$02,$06,$D4,$05,$17,$3F,$1D,$55,$3F,$1D,$78,$07
        db	$16,$1F,$1B,$ED,$F7,$10,$18,$0D,$0C,$9A,$46,$44
        db	$03,$05,$17,$06,$D4,$3B,$E7,$3B,$E8,$3F,$1D,$0D
        db	$07,$18,$3F,$1D,$30,$07,$1A,$1B,$E1,$0C,$9A,$46
        db	$C1,$44,$03,$F5,$10,$18,$04,$06,$D4,$1B,$02,$06
        db	$EC,$05,$17,$3F,$1D,$55,$3F,$1D,$78,$3B,$DB,$3F
        db	$1C,$EF,$3F,$1D,$70,$C1,$77,$09,$8C,$1A,$47,$C2
        db	$3F,$1D,$BD,$C1,$3F,$1D,$23,$02,$3B,$C9,$07,$1C
        db	$1F,$1B,$ED,$0C,$9A,$46,$44,$03,$05,$17,$06,$D4
        db	$3B,$D2,$3B,$D3,$3F,$1D,$0D,$3F,$1C,$EF,$50,$50
        db	$50,$50,$50,$44,$03,$1B,$07,$C3,$0F,$77,$CF,$CC
        db	$1A,$1F,$3F,$1D,$23,$3F,$1D,$17,$07,$1D,$1F,$1B
        db	$ED,$0C,$9A,$46,$F4,$40,$18,$04,$06,$EC,$1B,$02
        db	$06,$D4,$05,$17,$44,$03,$3F,$1D,$55,$3F,$1D,$78
        db	$3B,$2B,$3B,$0B,$44,$7F,$3F,$1D,$2B,$3B,$2C,$07
        db	$1C,$1B,$D8,$F5,$80,$16,$04,$2A,$07,$17,$CF,$3A
        db	$02,$01,$17,$77,$0A,$75,$01,$0D,$1A,$46,$0E,$1A
        db	$47,$86,$01,$85,$00,$3F,$1C,$1C,$17,$3B,$6C,$0C
        db	$9A,$46,$07,$06,$3B,$1A,$17,$3B,$62,$0C,$9A,$46
        db	$3B,$12,$07,$08,$3B,$0E,$17,$45,$1F,$0C,$1A,$46
        db	$44,$60,$61,$07,$18,$3B,$01,$17,$C1,$75,$0A,$50
        db	$50,$50,$50,$3B,$05,$01,$3B,$02,$01,$17,$44,$0F
        db	$E4,$0A,$1A,$04,$84,$37,$1B,$02,$84,$30,$CF,$3A
        db	$02,$17,$CD,$1A,$42,$CE,$1A,$43,$17,$3B,$77,$07
        db	$04,$EF,$FA,$42,$14,$75,$01,$77,$08,$86,$06,$85
        db	$00,$E5,$19,$98,$6C,$E6,$F6,$1A,$68,$07,$00,$17
        db	$44,$7F,$F4,$40,$16,$64,$80,$17,$04,$2C,$CC,$1A
        db	$15,$06,$02,$07,$FF,$0F,$BA,$42,$CF,$7A,$16,$FA
        db	$78,$17,$CD,$1A,$44,$CE,$1A,$45,$75,$08,$07,$FF
        db	$0F,$BA,$44,$1C,$00,$8A,$BB,$A0,$1B,$76,$0D,$0A
        db	$32,$36,$35,$30,$20,$44,$49,$53,$41,$53,$53,$45
        db	$4D,$42,$4C,$45,$52,$20,$56,$45,$52,$53,$49,$4F
        db	$4E,$20,$32,$0A,$00,$B5,$01,$98,$07,$01,$1A,$0B
        db	$04,$01,$1B,$08,$01,$9A,$04,$04,$FF,$1B,$01,$20
        db	$75,$09,$8C,$1A,$46,$17
;==================================================================== 
;       *ROUTINE TO PROVIDE COMMENT ADDITION
;       *FACILITY FOR THE IMPROVED 2650
;       *DISASSEMBLER. J.ROWE 1/ 4/ 1979
;==================================================================== 
        BSTA,UN $0286
        COMI,R0 $0D
        BCTA,Z  $008A
        COMI,R0 $09
        BCTR,Z  $1DE6
        ZBSR    *0020
        BCTR,UN $1DD6
        ZBSR    *$0025
        LODI,R3 $0F
        BSTA,UN $0361
        BCTR,UN $1DD6
;==================================================================== 
;        *ROUTINE TO PRINT OUT ASCII MESSAGES
;        *STORED IN MEMORY. J ROWE APRIL 1979
;        *USES MESSAGE PRINTING SUBR IN MY
;        *IMPROVED DISASSEMBLER. ALSO GNUM IN
;        *PIPBUG. GALL BY GIDF0 AAAA. WHERE
;        *AAAA IS START OF MESSAGE. NOTE THAT
;        *MESSAGE MUST END WITH A NULL
;==================================================================== 
        ds  $1DF0-$,0               ;fill empty space with zeros
        org $1DF0     
        
        ppsu $60
        bsta,un $02db
        bsta,un $1d8a
        zbrr $0022
;==================================================================== 
; The High (HY) ROM and Extended (E) function section
; HY+E = HEY?
;==================================================================== 
            ds  $3000-$,0               ;fill empty space with zeros
            org $3000               
;==================================================================== 
; ran out of space in the command handler function 'mbug', continue here
; display 'help' when '?' is entered 
 ;====================================================================           
 mbug1:     comi,R0 '?'
            bcta,EQ help
            COMI,r0 'H'                                     
            BCTA,eq hexlist   
            COMI,r0 'F'                                     
            BCTA,eq search
            COMI,r0 'X'                                     
            BCTA,eq find
            COMI,r0 'M'                                     
            BCTA,eq move
            COMI,r0 'R'                                     
            BCTA,eq lass
            ;COMI,r0 'Z'                                     
            ;BCTA,eq basic
            COMI,r0 'Y'                                     
;add extras here
            bcta,UN ebug 
;====================================================================
; help displayed when '?' is entered at the PIPBUG prompt
;====================================================================
; really inefficient code - welcoming a fix
help:       bsta,UN crlf                ;start on a new line
            lodi,R3 $FF                 ;256 R3 is pre-incremented in the instruction below
help1:      loda,R0 helptxt,R3,+        ;load the character into R0 from the text below indexed by R3
            comi,R0 $00                 ;is it zero? (end of string)
            bcta,EQ help2               ;branch back to pipbug when done
            bsta,UN cout                ;else, print the character using pipbug serial output
            bctr,UN help1               ;loop back for the next character in the string
help2:      lodi,R3 $FF     
help3:      loda,R0 helptxt1,R3,+       ;load the character into R0 from the text below indexed by R3
            comi,R0 $00                 ;is it zero? (end of string)
            bcta,EQ help4                ;branch back to pipbug when done
            bsta,UN cout                ;else, print the character using pipbug serial output
            bctr,UN help3
help4:      lodi,R3 $FF     
help5:      loda,R0 helptxt2,R3,+       ;load the character into R0 from the text below indexed by R3
            comi,R0 $00                 ;is it zero? (end of string)
            bcta,EQ mbug                ;branch back to pipbug when done
            bsta,UN cout                ;else, print the character using pipbug serial output
            bctr,UN help5                          
helptxt:    db "PIPBUG Commands:",CR,LF,LF              ;16
            db "Alter Memory aaaa   Aaaaa<CR>",CR,LF     ;28
            db "Set Breakpoint n    Bn aaaa<CR>",CR,LF   ;30
            db "Clear Breakpoint n  Cn<CR>",CR,LF        ;25
            db "Dump to tape        Daaaa bbbb<CR>",CR,LF        ;25
            db "Goto Address aaaa   Gaaaa<CR>",CR,LF     ;28         
            db "Load Hex File       L<CR>",CR,LF         ;24
            db "See Register Rn     Sn<CR>",CR,LF,LF,$00     ;25     =156
            
helptxt1:   db "Utility Routines:",CR,LF,LF
            db "Find Hex String     Faaaa bbbb xxyy<CR>",CR,LF
            db "Find Hex Value      Xaaaa bbbb xx<CR>",CR,LF
            db "Hex List            Haaaa bbbb<CR>",CR,LF   
            db "Move                Maaaa bbbb cccc<CR>",CR,LF
;            db "Fill Memory        Iaaaa bbbb xx<CR>",CR,LF,$00
            db "2650 Line Assembler R<CR>",CR,LF,$00

helptxt2:
            db "Disassembler        G1B00 aaaa bbbb xx<CR>",CR,LF
            db "Print ASCII         G1DF0 aaaa<CR>",CR,LF,$00
;Official Utility EPROM Label Equates-------------------------------------
;GPAR            equ $3C07        ;(R/w) EPROM subroutine
;INCRT           equ $3C2A        ;(R/w) EPROM subroutine
;PADR            equ $3C3C        ;(R/w) EPROM subroutine
;HEXLIST         equ $3C50        ;(R/w) EPROM subroutine
;SEARCH          equ $3C6A        ;(R/w) EPROM subroutine
;HEXIN           equ $3C8A        ;(R/w) EPROM subroutine
;VERIFY          equ $3CDD        ;(R/w) EPROM subroutine
;OK              equ $3CF8        ;(R/w) EPROM code section
;FAULTY          equ $3D0E        ;(R/w) EPROM code section
;MOVE            equ $3D3B        ;(R/w) EPROM subroutine
;Z3OUT           equ $3DBE        ;(R/w) EPROM subroutine (300 baud)
;Z3IN            equ $3DE4        ;(R/w) EPROM subroutine (300 baud)
;ZDUMP           equ $3E02        ;(R/w) EPROM subroutine (300 baud)
;ZLOAD           equ $3E53        ;(R/w) EPROM subroutine (300 baud)
;ZVERIFY         equ $3EA2        ;(R/w) EPROM subroutine (300 baud)

            ds  $3C00-$,0               ;fill empty space with zeros
            org $3C00         
L3C00: ;$3C00
            stra,r1	X2FFA
            stra,r2	X2FFA+1
            retc,un
gpar: ;$3C07
            PPSU    flag                                     ;  9,2 $3C07 76 40    PSU |= $40 & %01100111;
;Set Flag (F) bit
            PPSL    $02                                      ;  9,2 $3C09 77 02    PSL |= 2;
;Set Compare (COM) bit (now unsigned/logical)
            CPSL    RS+wc                                    ;  9,2 $3C0B 75 18    PSL &= ~($18);
;Clear Register Select (RS) bit (now Register 1..Register 3)
;Clear With Carry (wc) bit
            BSTA,un gnum                                     ;  9,3 $3C0D 3F 02 DB gosub L02DB;
            BSTR,un L3C00                                    ;  9,2 $3C10 3B 6E    gosub L3C00;
            BSTR,un *$3C0E ;[gnum]                           ; 15,2 $3C12 3B FA    gosub *$3C0E [L02DB];
            BSTR,un L3C25                                    ;  9,2 $3C14 3B 0F    gosub L3C25;
            STRA,r1 X2FFC                                    ; 12,3 $3C16 CD 0F FC *($2FFC) = r1;
            STRA,r2 X2FFD                                    ; 12,3 $3C19 CE 0F FD *($2FFD) = r2;
            BSTR,un *$3C0E ;[gnum]                           ; 15,2 $3C1C 3B F0    gosub *$3C0E [L02DB];
            STRA,r1 X2FFE                                    ; 12,3 $3C1E CD 0F FE *($2FFE) = r1;
            STRA,r2 X2FFF                                    ; 12,3 $3C21 CE 0F FF *($2FFF) = r2;
            RETC,un                                          ;  9,1 $3C24 17       return;            
L3C25:
            birr,r2	L3C29
            birr,r1	L3C29
L3C29:
            retc,un
L3C2A:
            loda,r1	X2FFA
            loda,r2	X2FFB
            bstr,un	L3C25
            bstr,un	L3C00
            coma,r1	X2FFC
            retc,lt
            coma,r2	X2FFD
            retc,un
L3C3C:
            bsta,un	crlf
            loda,r1	X2FFA
            bsta,un	bout            ;$0269
            loda,r1	X2FFB
            bstr,un	*$3C43	        ;$0269 ;INFO: indirect jump
L3C4A:
            lodi,r0	$20
            bsta,un	cout            ;$02B4
            retc,un
;====================================================================
; HEX list function - Haaaa bbbb
;====================================================================
hexlist: ;$3C50
            BSTA,un gpar                                     ;  9,3 $3C50 3F 3C 07 gosub L3C07;
L3C53: ;$3C53
            BSTR,un L3C3C                                    ;  9,2 $3C53 3B 67    gosub L3C3C;
L3C55: ;$3C55
            LODA,r1 *X2FFA                                   ; 18,3 $3C55 0D 8F FA r1 = *(*$2FFA);
            BSTR,un *$3C43 ;[bout]                           ; 15,2 $3C58 3B E9    gosub *$3C43 [L0269];
;Warning: indirect branch!
            BSTR,un L3C4A                                    ;  9,2 $3C5A 3B 6E    gosub L3C4A;
            BSTR,un L3C2A                                    ;  9,2 $3C5C 3B 4C    gosub L3C2A;
            BCFA,lt mbug                                     ;  9,3 $3C5E 9E 00 22 if CC != LT then goto L0022;
            LODA,r0 X2FFB                                    ; 12,3 $3C61 0C 0F FB r0 = *($2FFB);
            ANDI,r0 $0F                                      ;  6,2 $3C64 44 0F    r0 &= $F;
            BCFR,eq L3C55                                    ;  9,2 $3C66 98 6D    if CC != EQ then goto L3C55;
            BCTR,un L3C53                                    ;  9,2 $3C68 1B 69    goto L3C53;
;====================================================================
; Find HEX string function - Faaaa bbbb xxyy
;====================================================================    
search: ;$3C6A
            BSTR,un *$3C51 ;[L3C07]                          ; 15,2 $3C6A 3B E5    gosub *$3C51 [L3C07];
;Warning: indirect branch!
            BSTR,un *$3C3D ;[L008A]                          ; 15,2 $3C6C 3B CF    gosub *$3C3D [L008A];
;Warning: indirect branch!
L3C6E: ;$3C6E
            LODA,r0 *X2FFA                                   ; 18,3 $3C6E 0C 8F FA r0 = *(*$2FFA);
            COMA,r0 X2FFE                                    ; 12,3 $3C71 EC 0F FE compare r0 against *($2FFE);
            BCFR,eq L3C83                                    ;  9,2 $3C74 98 0D    if CC != EQ then goto L3C83;
            LODI,r3 1                                        ;  6,2 $3C76 07 01    r3 = 1 [SOH];
            LODA,r0 *X2FFA,r3                                ; 18,3 $3C78 0F EF FA r0 = *(*$2FFA + r3);
            COMA,r0 X2FFF                                    ; 12,3 $3C7B EC 0F FF compare r0 against *($2FFF);
            BCFR,eq L3C83                                    ;  9,2 $3C7E 98 03    if CC != EQ then goto L3C83;
            BSTA,un L3C3C                                    ;  9,3 $3C80 3F 3C 3C gosub L3C3C;
L3C83: ;$3C83
            BSTA,un L3C2A                                    ;  9,3 $3C83 3F 3C 2A gosub L3C2A;
            BCFR,lt *$3C5F ;[mbug]                           ;6+9,2 $3C86 9A D7    if CC != LT then goto *$3C5F [L0022];
;Warning: indirect branch!
            BCTR,un L3C6E                                    ;  9,2 $3C88 1B 64    goto L3C6E; 
;====================================================================
; Find HEX  function - Eaaaa bbbb xx
;==================================================================== 
find:                
            BSTR,un *$3C51 ;[L3C07]                           ; 15,2 $3C6A 3B E5    gosub *$3C51 [L3C07];
;Warning: indirect branch!
            bsta,un     crlf
find2: ;$3C6E
            LODA,r0 *X2FFA                                   ; 18,3 $3C6E 0C 8F FA r0 = *(*$2FFA);
            COMA,r0 X2FFF                                    ; 12,3 $3C7B EC 0F FF compare r0 against *($2FFF);
            BCFR,eq find3                                    ;  9,2 $3C7E 98 03    if CC != EQ then goto L3C83;
            BSTA,un L3C3C                                    ;  9,3 $3C80 3F 3C 3C gosub L3C3C;
find3: ;$3C83
            BSTA,un L3C2A                                    ;  9,3 $3C83 3F 3C 2A gosub L3C2A;
            BCFa,lt *$3c5f;$3C87 ;[mbug]                     ;6+9,2 $3C86 9A D7    if CC != LT then goto *$3C5F [L0022];
;Warning: indirect branch!
            BCTR,un find2   			
;====================================================================
; Move  function - Faaaa bbbb xx
;====================================================================    
move:
	    bsta,un	gpar
	    coma,r1	X2FFA
	    bctr,gt	*$3CAE				      ;INFO: indirect jump
	    coma,r2	X2FFB
	    bcta,gt	L3D84
L3D49:
            loda,r0	*X2FFA
            stra,r0	*X2FFE
            bsta,un	L3C2A
            bcfa,lt	mbug
            bstr,un	L3D5E
            bsta,un	L3C25
            bstr,un	L3D65
            bctr,un	L3D49
L3D5E:
            loda,r1	X2FFE
            loda,r2	X2FFF
            retc,un
L3D65:
            stra,r1	X2FFE
            stra,r2	X2FFF
            retc,un
L3D6C:
            loda,r1	X2FFC
            loda,r2	X2FFD
            bstr,un	L3D7B
            stra,r1	X2FFC
            stra,r2	X2FFD
            retc,un
L3D7B:
            bdrr,r2	L3D7D
L3D7D:
            comi,r2	$FF
            bcfr,eq	L3D83
            bdrr,r1	L3D83
L3D83:
            retc,un
L3D84:
            bstr,un	L3D6C
            ppsl	$09
            bstr,un	L3D5E
            suba,r2	X2FFB
            suba,r1	X2FFA
            cpsl	$01
            adda,r2	X2FFD
            adda,r1	X2FFC
            bstr,un	L3D65
            cpsl	$08
            loda,r0	*X2FFC
            stra,r0	*X2FFE
L3DA2:
            bsta,un	L3D5E
            bstr,un	L3D7B
            bsta,un	L3D65
            bstr,un	L3D6C
            loda,r0	*X2FFC
            stra,r0	*X2FFE
            coma,r1	X2FFA
            bctr,gt	L3DA2
            coma,r2	X2FFB
            bctr,gt	L3DA2
            zbrr	mbug
;====================================================================
; RAM definitions
;====================================================================
            org $400

com:        ds  1      ;400             ;R0 saved here
            ds  1      ;401             ;R1 in register bank 0 saved here
            ds  1      ;402             ;R2 in register bank 0 saved here
            ds  1      ;403             ;R3 in register bank 0 saved here
            ds  1      ;404             ;R1 in register bank 1 saved here
            ds  1      ;405             ;R2 in register bank 0 saved here
            ds  1      ;406             ;R3 in register bank 0 saved here
            ds  1      ;407             ;program status, upper saved here
            ds  1      ;408             ;program status, lower saved here
xgot:       ds  2      ;409 40A
            ds  2      ;40B 40C
temp:       ds  2      ;40D 40E             ;addresses stored here
temq        ds  2      ;40F 410
temr        ds  1      ;411
tems        ds  1      ;412
buff        ds  blen                ;input buffer
bptr        ds  1
mcnt        ds  1
cnt         ds  1
bcc         ds  1
code        ds  1
mark        ds  bmax+1              ;used by breakpoint
hdat        ds  bmax+1              ;used by breakpoint
ldat        ds  bmax+1              ;used by breakpoint
hadr        ds  bmax+1              ;used by breakpoint
ladr        ds  bmax+1              ;used by breakpoint

hdata:      ds  1                   ;used by hex load - hex data byte
cksum:      ds  1                   ;used by hex load - checksum
bytcnt:     ds  1                   ;used by hex load - byte count
addhi:      ds  1                   ;used by hex load - address hi byte
addlo:      ds  1                   ;used by hex load - address lo byte
rectyp:     ds  1                   ;used by hex load - record type
;====================================================================
;Official Utility RAM Label Equates----------------------------------
;START           equ $2FFA        ;(R/W) RAM data
;END             equ $2FFC        ;(R/W) RAM data
;NEW             equ $2FFE        ;(R/W) RAM data
;====================================================================
            org $2fd0
X2FD0:       ds  1   ;2ff0 2ff1 2ff2 2ff3 2ff4 2ff5 2ff6 2ff7 2ff8 2ff9  
X2FD1:       ds  1 
X2FD2:  ds  1 
X2FD3:  ds  1 
X2FD4:  ds  1 
X2FD5:  ds  1 
X2FD6:  ds  1 
X2FD7:  ds  1 
X2FD8:  ds  1 
X2FD9:  ds  1 
X2FDA:  ds  1 
X2FDB:  ds  1 
X2FDC:  ds  1 
X2FDD:  ds  1 
X2FDE:  ds  1 
            org $2ffa
X2FFA:     ds  1   ;2ffa        ;start
X2FFB:     ds  1   ;2ffb
X2FFC:     ds  1   ;2ffc        ;end
X2FFD:     ds  1   ;2ffd
X2FFE:     ds  1   ;2ffe
X2FFF:     ds  1   ;2fff        ;new

            end
