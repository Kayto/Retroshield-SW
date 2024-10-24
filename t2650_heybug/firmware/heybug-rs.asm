NOFOLD
; HEYBUG Firmware for the Signetics 2650
;
; Source code written by Signetics taken from
; Signetics 2650 microprocessor application memo SS50
;
; Uses some code transcription of the original 
; SS50 listing from Jim's repo
; https://github.com/jim11662418/Signetics-2650-SBC
;
; and code from;
;
; Hybug BIOS as incorporated into Winarcadia 33.3
; by James Jacobs from
; http://amigan.1emu.net/releases/
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
EQ          equ  0
GT          equ  1
LT          equ  2
UN          equ  3            

sense       equ $80                     ;sense bit in program status, upper
flag        equ $40                     ;flag bit in program status, upper
ii          equ $20                     ;interrupt inhibit bit in program status, upper
rs          equ $10                     ;register select bit in program status, lower
wc          equ $08                     ;with/without carry bit in program status,lower

spac        equ $20                     ;ASCII space
dele        equ $7F                     ;ASCII delete
CR          equ $0D                     ;ASCII carriage return
LF          equ $0A                     ;ASCII line feed
star        equ ':'
bmax        equ 1                       ;maximum number of breakpoints
blen        equ 20                      ;size of input buffer


X3C43		equ	$3C43


            org $0000
            
init:       lodi,R3 63
            eorz    R0
aini:       stra,R0 com,R3,-
            brnr,R3 aini                ;clear memory $0400-$04FF
            lodi,R0 $077                ;opcode for 'ppsl'
            stra,R0 xgot
            lodi,R0 $1B                 ;opcode for 'bctr,un'
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
; removed to make some space for mbug1
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
chin:       ppsl    rs                  ;select register bank 1
            lodi,R0 $80
            wrtc,R0
            lodi,R1 0                   ;initialize R1
            lodi,R2 8                   ;load R2 with the number of bits to receive
achi:       spsu                        ;store program status, upper containing the sense input to R0
            bctr,LT chin                ;branch back if the sense input is "1" (wait for the start bit)
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
            lodi,r0 $20    ;set r0 to bit delay
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
;
form:       lodi,r3	$03
            bctr,un	agap
;
gap:        lodi,r3	$32
agap:       lodi,r0	spac
            bsta,un	cout
            bdrr,r3	agap
            retc,un
;
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
;
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
;
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
            bcta,un	*temp						;INFO: indirect jump
        ;
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
;add extras here
            COMI,r0 'H'                                     
            BCTA,eq hexlist   
            COMI,r0 'F'                                     
            BCTA,eq search
            COMI,r0 'E'                                     
            BCTA,eq find
            COMI,r0 'M'                                     
            BCTA,eq find





            bcta,UN ebug 
;====================================================================
; help displayed when '?' is entered at the PIPBUG prompt
;====================================================================
; really inefficient code - welcoming a fix
help:       bsta,UN crlf                ;start on a new line
            lodi,R3 $FF                 ;256 R3 is pre-incremented in the instruction below
help1:      loda,R0 helptxt,R3,+        ;load the character into R0 from the text below indexed by R3
            comi,R0 $00                 ;is it zero? (end of string)
            bcta,EQ help2                ;branch back to pipbug when done
            bsta,UN cout                ;else, print the character using pipbug serial output
            bctr,UN help1               ;loop back for the next character in the string
help2:      lodi,R3 $FF     
help3:      loda,R0 helptxt1,R3,+        ;load the character into R0 from the text below indexed by R3
            comi,R0 $00                 ;is it zero? (end of string)
            bcta,EQ mbug                ;branch back to pipbug when done
            bsta,UN cout                ;else, print the character using pipbug serial output
            bctr,UN help3              
helptxt:    db "PIPBUG Commands:",CR,LF,LF              ;16
            db "Alter Memory aaaa  Aaaaa<CR>",CR,LF     ;28
            db "Set Breakpoint n   Bn aaaa<CR>",CR,LF   ;30
            db "Clear Breakpoint n Cn<CR>",CR,LF        ;25
            db "Goto Address aaaa  Gaaaa<CR>",CR,LF     ;28         
            db "Load Hex File      L<CR>",CR,LF         ;24
            db "See Register Rn    Sn<CR>",CR,LF,LF,$00     ;25     =156
            
helptxt1:   db "Utility Routines:",CR,LF,LF
            db "Find Hex String    Faaaa bbbb xxyy<CR>",CR,LF
            db "Find H(E)x         Eaaaa bbbb xx<CR>",CR,LF
            db "Hex List           Haaaa bbbb<CR>",CR,LF   
            db "M Move             Maaaa bbbb cccc<CR>",CR,LF,$00
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
            stra,r1	startu
            stra,r2	startu+1
            retc,un


gpar: ;$3C07
            PPSU    flag                                        ;  9,2 $3C07 76 40    PSU |= $40 & %01100111;
    ;Set Flag (F) bit
            PPSL    $02                                      ;  9,2 $3C09 77 02    PSL |= 2;
    ;Set Compare (COM) bit (now unsigned/logical)
            CPSL    RS+wc                                    ;  9,2 $3C0B 75 18    PSL &= ~($18);
    ;Clear Register Select (RS) bit (now Register 1..Register 3)
    ;Clear With Carry (wc) bit
            BSTA,un gnum                                    ;  9,3 $3C0D 3F 02 DB gosub L02DB;
            BSTR,un L3C00                                    ;  9,2 $3C10 3B 6E    gosub L3C00;
            BSTR,un *$3C0E ;[gnum]                           ; 15,2 $3C12 3B FA    gosub *$3C0E [L02DB];
            BSTR,un L3C25                                    ;  9,2 $3C14 3B 0F    gosub L3C25;
            STRA,r1 endu                                    ; 12,3 $3C16 CD 0F FC *($2FFC) = r1;
            STRA,r2 endu+1                                   ; 12,3 $3C19 CE 0F FD *($2FFD) = r2;
            BSTR,un *$3C0E ;[gnum]                           ; 15,2 $3C1C 3B F0    gosub *$3C0E [L02DB];
            STRA,r1 endu+2                                   ; 12,3 $3C1E CD 0F FE *($2FFE) = r1;
            STRA,r2 new                                   ; 12,3 $3C21 CE 0F FF *($2FFF) = r2;
            RETC,un                                          ;  9,1 $3C24 17       return;            

L3C25:
            birr,r2	L3C29
            birr,r1	L3C29
L3C29:
            retc,un
L3C2A:
            loda,r1	startu
            loda,r2	startu+1
            bstr,un	L3C25
            bstr,un	L3C00
            coma,r1	endu
            retc,lt
            coma,r2	endu+1
            retc,un

L3C3C:
            bsta,un	crlf
            loda,r1	startu
            bsta,un	bout                    ;$0269
            loda,r1	startu+1
            bstr,un	*$3C43					;$0269 ;INFO: indirect jump
L3C4A:
            lodi,r0	$20
            bsta,un	cout                        ;$02B4
            retc,un
;====================================================================
; HEX list function - Haaaa bbbb
;====================================================================
hexlist: ;$3C50
            BSTA,un gpar                                    ;  9,3 $3C50 3F 3C 07 gosub L3C07;
L3C53: ;$3C53
            BSTR,un L3C3C                                    ;  9,2 $3C53 3B 67    gosub L3C3C;
L3C55: ;$3C55
            LODA,r1 *startu                                  ; 18,3 $3C55 0D 8F FA r1 = *(*$2FFA);
            BSTR,un *$3C43 ;[bout]                           ; 15,2 $3C58 3B E9    gosub *$3C43 [L0269];
    ;Warning: indirect branch!
            BSTR,un L3C4A                                    ;  9,2 $3C5A 3B 6E    gosub L3C4A;
            BSTR,un L3C2A                                    ;  9,2 $3C5C 3B 4C    gosub L3C2A;
            BCFA,lt mbug                                    ;  9,3 $3C5E 9E 00 22 if CC != LT then goto L0022;
            LODA,r0 startu+1                                    ; 12,3 $3C61 0C 0F FB r0 = *($2FFB);
            ANDI,r0 $0F                                       ;  6,2 $3C64 44 0F    r0 &= $F;
            BCFR,eq L3C55                                    ;  9,2 $3C66 98 6D    if CC != EQ then goto L3C55;
            BCTR,un L3C53                                    ;  9,2 $3C68 1B 69    goto L3C53;
;====================================================================
; Find HEX string function - Faaaa bbbb xxyy
;====================================================================    
search: ;$3C6A
            BSTR,un *$3C51 ;[L3C07]                           ; 15,2 $3C6A 3B E5    gosub *$3C51 [L3C07];
    ;Warning: indirect branch!
            BSTR,un *$3C3D ;[L008A]                           ; 15,2 $3C6C 3B CF    gosub *$3C3D [L008A];
    ;Warning: indirect branch!
L3C6E: ;$3C6E
            LODA,r0 *startu                                   ; 18,3 $3C6E 0C 8F FA r0 = *(*$2FFA);
            COMA,r0 endu+2                                    ; 12,3 $3C71 EC 0F FE compare r0 against *($2FFE);
            BCFR,eq L3C83                                    ;  9,2 $3C74 98 0D    if CC != EQ then goto L3C83;
            LODI,r3 1                                        ;  6,2 $3C76 07 01    r3 = 1 [SOH];
            LODA,r0 *startu,r3                                ; 18,3 $3C78 0F EF FA r0 = *(*$2FFA + r3);
            COMA,r0 new                                    ; 12,3 $3C7B EC 0F FF compare r0 against *($2FFF);
            BCFR,eq L3C83                                    ;  9,2 $3C7E 98 03    if CC != EQ then goto L3C83;
            BSTA,un L3C3C                                    ;  9,3 $3C80 3F 3C 3C gosub L3C3C;
L3C83: ;$3C83
            BSTA,un L3C2A                                    ;  9,3 $3C83 3F 3C 2A gosub L3C2A;
            BCFR,lt *$3C5F ;[mbug]                           ;6+9,2 $3C86 9A D7    if CC != LT then goto *$3C5F [L0022];
    ;Warning: indirect branch!
            BCTR,un L3C6E                                    ;  9,2 $3C88 1B 64    goto L3C6E;            
;====================================================================
; Find HEX  function - Faaaa bbbb xx
;====================================================================    
find: ;$1DA
            BSTA,un gnum                                    ;  9,3 $01DA 3F 02 DB gosub L02DB;
            BSTA,un strt                                    ;  9,3 $01DD 3F 00 A4 gosub L00A4;
            BSTR,un *$3C8B
            ;[gnum]15,2 $01E0 3B F9    gosub *$1DB [L02DB];
    ;Warning: indirect branch!
            STRA,r1 X2FD0                                  ; 12,3 $01E2 CD 04 00 *(X0400) = r1;
            STRA,r2 X2FD1                                    ; 12,3 $01E5 CE 04 01 *(X0401) = r2;
            BSTR,un *$3C8B
            ;[gnum]15,2 $01E8 3B F1    gosub *$1DB [L02DB];
    ;Warning: indirect branch!
            STRA,r2 X2FD2                                    ; 12,3 $01EA CE 04 02 *(X0402) = r2;
L01ED: ;$1ED
            BSTR,un L0201                                    ;  9,2 $01ED 3B 12    gosub L0201;
            COMR,r0 *$3C9B
            ;[com+2]15,2 $01EF E8 FA    compare r0 against *(*P01EB [X0402]);
            BCFR,eq L01ED                                    ;  9,2 $01F1 98 7A    if CC != EQ then goto L01ED;
            LODR,r1 *$3CB2
            ;[X040D] 15,2 $01F3 09 8D    r1 = *(*P0202 [X040D]);
            BSTA,un bout                                    ;  9,3 $01F5 3F 02 69 gosub L0269;
            LODR,r1 *$3CB5
            ;[temp+1]15,2 $01F8 09 8B    r1 = *(*P0205 [X040E]);
            BSTR,un *$3CA6
            ;[bout]  15,2 $01FA 3B FA    gosub *$1F6 [L0269];
    ;Warning: indirect branch!
            BSTA,un crlf                                    ;  9,3 $01FC 3F 00 8A gosub L008A;
            BCTR,un L01ED   
L0201:
            loda,r1	X2FDD
            loda,r2	X2FDE
            addi,r2	$01
            ppsl	wc
            addi,r1	$00
            cpsl	wc
            bstr,un	*$3c8e						;INFO: indirect jump
            loda,r0	*X2FDD
            comr,r1	*$3C93
            bcfr,eq	L021C
            comr,r2	*$3C96
            bctr,eq	L021D
L021C:
            retc,un
        ;
L021D:
            eorz	r0
L021E:
            bdrr,r3	L021E
            bdrr,r0	L021E
            zbrr	mbug1
            L3D3B:
            bsta,un	L3C07
            coma,r1	X2FFA
            bctr,gt	*X3D47						;INFO: indirect jump
            coma,r2	X2FFB
            bcta,gt	L3D84
;====================================================================
; Move  function - Faaaa bbbb xx
;====================================================================    
L3D49:
            loda,r0	*X2FFA
            stra,r0	*X2FFE
            bsta,un	L3C2A
            bcfa,lt	L0022
            bstr,un	L3D5E
            bsta,un	L3C25
            bstr,un	L3D65
            bctr,un	L3D49
    ;
L3D5E:
            loda,r1	X2FFE
            loda,r2	X2FFF
            retc,un
    ;
L3D65:
            stra,r1	X2FFE
            stra,r2	X2FFF
            retc,un
    ;
L3D6C:
            loda,r1	X2FFC
            loda,r2	X2FFD
            bstr,un	L3D7B
            stra,r1	X2FFC
            stra,r2	X2FFD
            retc,un
    ;
L3D7B:
            bdrr,r2	L3D7D
L3D7D:
            comi,r2	H'FF'
            bcfr,eq	L3D83
            bdrr,r1	L3D83
L3D83:
            retc,un
    ;
    L3D84:
            bstr,un	L3D6C
            ppsl	H'09'
            bstr,un	L3D5E
            suba,r2	X2FFB
            suba,r1	X2FFA
            cpsl	H'01'
            adda,r2	X2FFD
            adda,r1	X2FFC
            bstr,un	L3D65
            cpsl	H'08'
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
            zbrr	L0022
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
X2FFA:     ds  1   ;2ffa
X2FFB:     ds  1   ;2ffb
X2FFC:     ds  1   ;2ffc
X2FFD:     ds  1   ;2ffd
X2FFE:     ds  1   ;2ffe
X2FFF:     ds  1   ;2fff

            end
