; File: 8031_serial_echo.asm
; Title: Serial Echo Program with PAULMON2 autobaud detection
; Author: kayto@github.com
; Date: December 02, 2024
; Version: 1.0
; 
; Based on PAULMON2 by Paul Stoffregen
; Minimal implementation for Serial Echo
;
.org    0x0000          ; Start at address 0x0000
ljmp    start           ; Jump to main program

.org    0x0030          ; cout
cout:   jnb     ti, cout        ; Wait for transmit buffer empty
        clr     ti              ; Clear transmit flag
        mov     sbuf, a         ; Send character
        ret

.org    0x0038          ; Input routine 
cin:    jnb     ri, cin         ; Wait for receive buffer full
        clr     ri              ; Clear receive flag
        mov     a, sbuf         ; Get character
        ret

.org    0x0042          ; autobaud
autobaud:
        mov     pcon, #0x80     ; Configure UART, fast baud
        mov     tmod, #0x21     ; Timer 1, mode 2 (8-bit auto-reload)
        mov     th1, #0xFF      ; Initial baud rate
        mov     tl1, #0xFF      ; Start ASAP
        mov     scon, #0x52     ; Mode 1, receive enable
        setb    ren             ; Enable serial receive
        setb    tr1             ; Start timer 1
        ret

.org    0x0100          ; Main program start
start:  
        acall   autobaud        ; Initialize serial port
        
echo_loop:               
        acall   cin             ; Wait for character
        acall   cout            ; Echo it back
        sjmp    echo_loop       ; Loop forever
