; File: 8031_serial_echo_v2.asm
; Title: Serial Echo Program with PAULMON2 autobaud 
; detection, message and CRLF handling
; Author: kayto@github.com
; Date: December 02, 2024
; Version: 1.0
; 
; Based on PAULMON2 by Paul Stoffregen
; Minimal implementation for Serial Echo with 
; CRLF handling
;
.org    0x0000          ; Start at address 0x0000
ljmp    start           ; Jump to main program


; PAULMON2 cout
.org    0x0030          
cout:   jnb     ti, cout        ; Wait for transmit 
                                ; buffer empty
        clr     ti              ; Clear transmit flag
        mov     sbuf, a         ; Send character
        ret

; PAULMON2 cin
.org    0x0038
cin:    jnb     ri, cin         ; Wait for receive 
                                ; buffer full
        clr     ri              ; Clear receive flag
        mov     a, sbuf         ; Get character
        ret

; PAULMON2 autobaud
.org    0x0042          
autobaud:
        mov     pcon, #0x80     ; Configure UART, 
                                ; fast baud
        mov     tmod, #0x21     ; Timer 1, mode 2 
                                ; (8-bit auto-reload)
        mov     th1, #0xFF      ; Initial baud rate
        mov     tl1, #0xFF      ; Start ASAP
        mov     scon, #0x52     ; Mode 1, receive enable
        setb    ren             ; Enable serial receive
        setb    tr1             ; Start timer 1
        ret

; PAULMON2  pstr
pstr:   clr     a               ; Clear accumulator
        movc    a, @a+dptr      ; Get character from 
                                ; code memory
        jz      pstr_done       ; If zero, we're done
        acall   cout            ; Output character
        inc     dptr            ; Point to next character
        sjmp    pstr            ; Loop for next character
        pstr_done:
        ret        

.org    0x0080                   ; Constants
.equ    CR,      0x0D            ; Carriage Return
.equ    LF,      0x0A            ; Line Feed

.org    0x0100                   ; Main program start
start:  
        acall   autobaud        ; Initialize serial port
        mov dptr, #welcome_msg
        acall pstr

echo_loop:               
        acall   cin             ; Wait for character
        cjne    a, #CR, not_cr  ; Check if character is CR
        acall   cout            ; Echo CR
        mov     a, #LF          ; Send LF after CR
        acall   cout
        sjmp    echo_loop       ; Get next character

not_cr:
        acall   cout            ; Echo character as is
        sjmp    echo_loop       ; Get next character

welcome_msg:
        .db "Welcome to the Serial Echo Program!", 13, 10, 0
