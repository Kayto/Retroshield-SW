; File: 8031_serial_echo_v3.asm
; Title: Serial Echo Program with with welcome and exit
; messages, CRLF and backspace/delete handling
; Author: kayto@github.com
; Date: December 02, 2024
; Version: 1.0
;
; Based on PAULMON2 by Paul Stoffregen
; Implementation for Serial Echo with welcome and exit
; messages, CRLF and backspace/delete handling
;
; Constants for special characters
.equ    BS, 0x08                ; ASCII Backspace (^H)
.equ    DEL, 0x7F               ; ASCII Delete
.equ    CR, 0x0D                ; ASCII Carriage Return
.equ    LF, 0x0A                ; ASCII Line Feed
.equ    SPACE, 0x20             ; ASCII Space
.equ    ESC, 0x1B               ; ASCII Escape

.org    0x0000                  ; Reset vector
        ljmp    start           ; Jump to main program

; PAULMON2 cout Output Routine
cout:   
        jnb     ti, cout        ; Wait for transmit 
                                ; buffer empty
        clr     ti              ; Clear transmit flag
        mov     sbuf, a         ; Send character
        ret

; PAULMON2 cin Input routine
cin:    
        jnb     ri, cin         ; Wait for receive 
                                ; buffer full
        clr     ri              ; Clear receive flag                        
        mov     a, sbuf         ; Get character
        ret

; PAULMON2  autobaud
uart:
        mov     pcon, #0x80     ; Configure UART, fast baud
        mov     tmod, #0x21     ; Timer 1, mode 2 
                                ; (8-bit auto-reload)
        mov     th1, #0xFF      ; Initial baud rate 
                                ; (57600 @ 11.0592MHz)
        mov     tl1, #0xFF      ; Start ASAP
        mov     scon, #0x52     ; Mode 1, receive enable
        setb    ren             ; Enable serial receive
        setb    tr1             ; Start timer 1
        ret

; PAULMON2 Print string routine
pstr:   
        ;push    acc             ; Save accumulator
        clr     a               ; Clear accumulator for 
                                ; first read
pstr1:  movc    a, @a+dptr      ; Get character from 
                                ; code memory
        jz      pstr_end        ; If zero, end of string
        lcall   cout            ; Print character
        inc     dptr            ; Increment pointer
        clr     a               ; Clear accumulator for 
                                ; next read
        sjmp    pstr1           ; Repeat
pstr_end:
        ;pop     acc             ; Restore accumulator 
        ret

; Main program start       
start:  
        acall   uart            ; Initialize serial port
entry:  
        mov     dptr, #welcome_msg
        acall   pstr            ; Print welcome message 
                                ; once at startup
        sjmp    echo_loop       ; Jump directly to echo loop
        
echo_loop:               
        lcall   cin             ; Get character
        ; Check for escape key
        cjne    a, #ESC, not_esc
        mov     dptr, #exit_msg
        lcall   pstr            ; Print exit message
        sjmp    halt            ; Jump to halt label

; Character Handlers
not_esc:
        ; First echo the character
        lcall   cout            ; Echo immediately
        ; Check for backspace or delete
        cjne    a, #BS, not_bs
        mov     a, #SPACE       ; Send space to clear
        lcall   cout
        mov     a, #BS          ; Move cursor back
        lcall   cout
        sjmp    echo_loop     
not_bs:
        cjne    a, #DEL, not_del
        mov     a, #BS          ; Send BS
        lcall   cout
        mov     a, #SPACE       ; Clear character
        lcall   cout
        mov     a, #BS          ; Move cursor back
        lcall   cout
        sjmp    echo_loop       
not_del:
        ; Check for CR to add LF
        cjne    a, #CR, echo_loop
        mov     a, #LF
        lcall   cout
        sjmp    echo_loop       ; Return to echo loop 
                                ; without printing welcome

; EXIT handler
halt:
        acall   delay
        mov     a, #CR          ; Send CR
        lcall   cout
        mov     a, #LF          ; Send LF
        lcall   cout
        sjmp    entry           ; delay on exit and restart          

; Delay subroutine
delay:
        mov R1, #255     ; Outer loop counter (10 × 1 ms = 10 ms)
outer_loop:
        mov r0 , #255   ; Inner loop counter (100 × 10 µs = 1 ms) 
inner_loop:
        djnz R0, inner_loop ; Decrement R0 until it reaches 0
        djnz R1, outer_loop ; Decrement R1 until it reaches 0
        ret             ; Return from subroutine

; Messages
exit_msg:
        .byte CR, LF,"Exiting the Serial Echo Program. Goodbye!", CR, LF, 0
    
welcome_msg:
        .byte "Welcome to the Serial Echo Program!", CR, LF
        .byte "Type text, type ESC to exit.", CR, LF, 0
     