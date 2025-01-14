NOFOLD
;2650 Microprocessor
;
;Example 3 - full duplex bit by bit echo, 2400 baud
;8 data bits no parity 1 stop bit
;
;modified by AdamT117 (kayto@github)to get the timing
;for Teensy 3.6 120MHZ working
;
;Original code from Philips Applcation memo
;2650 INPUT/OUTPUT STRUCTURES AND INTERFACES MP54 
;
;compile with VACS
;
;2650 specific equates
car         equ $01 
sense       equ $80     ;sense bit in program status, upper
flag        equ $40     ;flag bit in program status, upper
ii          equ $20     ;interrupt inhibit bit in program status, upper
rs          equ $10     ;register select bit in program status, lower
wc          equ $08     ;with/without carry bit in program status,lower
ovf         equ $04     ;overflow
idc         equ $20     ;inter digit carry
N           equ 2       ;branch condition negative
un          equ 3       ;unconditional
;Number of data bits
DB8         equ $08     ;character has 8 data bits
BP8         equ $80
;routine tested with teensy 3.6 - compile at 120MHZ
;Bit delays
BR24        equ $20     ;setting for teensy that works.
                        ;the actual delay was a lot of trial and error!
                        ;refer to bdlay
;Start bit sample delays 
SD01        equ $A5
SD24        equ $05
;
;*********************************************************
            org $0000
strt:   ppsu    flag    ;set flag to switch off the line
        cpsl    ovf+car+idc
test:   spsu            ;wait for start bit
        bctr,N  test
        lodi,r2 $03     ;set r2 to number of samples
samp:   ;lodi,r1 SD24   ;set r1 to sample delay
        ;bdrr,r1 $
        bstr,un dly
        spsu            ;test for start bit validity
        bctr,N test     ;if not valid go back to test
        bdrr,r2 samp
        lodi,r2 DB8     ;set r2 to number of data bits
        cpsu flag       ;generate start bit
bits:   rrr,r1
        bstr,un bdly    ;go to delay and echo routine
        bdrr,r2 bits    ;test for number of data bits
        lodz    r1
        strz    r2      ;load r2 with character
stop:   lodi,r3 0       ;clear r3
        bstr,un bdly
exi1:   retc,N          ;test stop bit level
        ppsl idc        ;if wrong set idc bit
exi2:   retc,un
;
;***************************************************
;     
; bit delay and echo subroutine
dly:    lodi,r1 SD24    ;set r1 to sample delay
        bdrr,r1 $
;YMMV - adding or removing nops helps if you are having problems!        
bdly:   eorz    r0
        lodi,r0 BR24    ;set r0 to bit delay
        bdrr,r0 $
        nop
        nop
        nop
        spsu            ;test data bit level
        bctr,N one
        cpsu    flag    ;if low, echo a zero
        bctr,un bit1
one:    ppsu    flag    ;if high echo a one
        iori,r1 BP8     ;insert data bit into r1
bit1:   strz    r3
        bstr,un samp    ;ok done back to samp
        ;retc,un
;
        end
   







