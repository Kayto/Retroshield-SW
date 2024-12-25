; File: 8031_hello_world.asm
; Title: Minimal implementation for Hello World
; Author: kayto@github.com
; Date: December 02, 2024
; Version: 1.0
; 
; Based on PAULMON2 by Paul Stoffregen
; 
.org    0x0000          ; Start at address 0x0000
ljmp    start           ; Jump to main program

; PAULMON2 standard location for cout
;.org    0x0030         
cout:   jnb ti, cout    ; Wait for transmit buffer empty
        clr     ti              ; Clear transmit flag
        mov     sbuf, a         ; Send character
        ret

; PAULMON2 standard location for pstr
;.org    0x0038   
pstr:   clr     a       ; Clear accumulator
        movc    a, @a+dptr      ; Get character from code memory
        jz      pstr_done       ; If zero, we're done
        acall   cout            ; Output character
        inc     dptr            ; Point to next character
        sjmp    pstr            ; Loop for next character
pstr_done:
        ret

; PAULMON2 standard location for autobaud
;.org    0x0042         
autobaud:
        mov     pcon, #0x80     ; Configure UART, fast baud
        mov     tmod, #0x21     ; Timer 1, mode 2 
                                ; (8-bit auto-reload)
        mov     th1, #0xFF      ; Initial baud rate
        mov     tl1, #0xFF      ; Start ASAP
        mov     scon, #0x52     ; Mode 1, receive enable
        setb    ren             ; Enable serial receive
        setb    tr1             ; Start timer 1
        ret

;.org    0x0100          ; Main program start
start:  
        acall   autobaud        ; Initialize serial port
        mov     dptr, #msg      ; Point to message
        acall   pstr            ; Print the string
        here:   sjmp here       ; Loop forever

; Message with CR/LF and null terminator
msg:    .byte     "Hello World from 8031!",13,10,0

