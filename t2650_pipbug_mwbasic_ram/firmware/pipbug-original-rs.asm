NOFOLD

; PIPBUG Firmware for the Signetics 2650
;
; Source code written by Signetics taken from
; Signetics 2650 microprocessor application memo SS50
;
; Uses some code transcription of the original 
; SS50 listing from Jim's repo
; https://github.com/jim11662418/Signetics-2650-SBC
; 
; PIPBUG has been modified as follows:
;  - the serial i/o delays modified by AdamT117
;    (kayto@github)to get the timing working 
;    for Teensy 3.6
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
            lodi,R0 '*'
            bsta,UN cout
            bstr,UN line
            eorz    R0
            stra,R0 bptr
            loda,R0 buff
            comi,R0 'A'
            bcta,EQ alte
            comi,R0 'B'
            bcta,EQ bkpt
            comi,R0 'C'
            bcta,EQ clr
            comi,R0 'D'
            bcta,EQ dump            
            comi,R0 'G'
            bcta,EQ goto
            comi,R0 'L'
            bcta,EQ load
            comi,R0 'S'
            bcta,EQ sreg
            bcta,UN ebug               ;oops, out of space
            
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
            bstr,un cbcc
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
;delays
dlay:       eorz    r0
            lodi,r0 $20    ;set r0 to bit delay
            bdrr,r0 $
            nop
            nop  
dly:        lodi,R0 $05
            bdrr,R0 $
            retc,UN

;        ; PIPBUG users expect the 'cout' function to be located at $02B4
;        if $ > $02B4
;            WARNING 'Address MUST be $02B4'
;        else
;            ds $02B4-$,0                
;        endif
            
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

            org $400

;RAM definitions
com:        ds  1                   ;R0 saved here
            ds  1                   ;R1 in register bank 0 saved here
            ds  1                   ;R2 in register bank 0 saved here
            ds  1                   ;R3 in register bank 0 saved here
            ds  1                   ;R1 in register bank 1 saved here
            ds  1                   ;R2 in register bank 0 saved here
            ds  1                   ;R3 in register bank 0 saved here
            ds  1                   ;program status, upper saved here
            ds  1                   ;program status, lower saved here
xgot:       ds  2
            ds  2
temp:       ds  2                   ;addresses stored here
temq        ds  2
temr        ds  1
tems        ds  1
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

            end
