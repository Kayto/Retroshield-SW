; Prime Number Finder for CA65 - FULL 16-BIT SWEEP (REVERSE)
; Starts at $1000
; Uses SMON Kernal-style I/O routines
; Tests TRUE PRIMES using trial division algorithm
; REVERSE SWEEP: Tests from 65535 DOWN to 2 (hardest first!)

.setcpu "65C02"

; SMON Kernal I/O vectors
CHROUT = $FFD2          ; Character output
CHRIN  = $FFCF          ; Character input

; Zero page variables
.segment "ZEROPAGE"
current:     .res 2      ; Current number to test (16-bit)
divisor:     .res 2      ; Trial divisor (16-bit)
dividend:    .res 2      ; Dividend for division
quotient:    .res 2      ; Quotient result
remainder:   .res 2      ; Remainder result
prime_count: .res 2      ; Count of primes found (16-bit)
test_count:  .res 2      ; Total tests performed
temp:        .res 1
str_ptr:     .res 2
line_pos:    .res 1      ; Position on current line

.segment "CODE"

.proc main
        ; Initialize
        stz prime_count
        stz prime_count+1
        stz test_count
        stz test_count+1
        stz line_pos
        
        ; Start at 65535 (highest, hardest first)
        lda #$FF
        sta current
        sta current+1
        
        ; Print banner
        lda #<banner
        sta str_ptr
        lda #>banner
        sta str_ptr+1
        jsr print_string
        
main_loop:
        ; Test if current is prime
        jsr is_prime
        bcc not_prime       ; Carry clear = not prime
        
        ; It's prime! Print it (space separated)
        lda current+1
        jsr print_hex
        lda current
        jsr print_hex
        lda #' '
        jsr print_char
        
        ; Track line position, newline every 8 primes
        inc line_pos
        lda line_pos
        and #$07        ; Every 8 primes
        bne @no_newline
        lda #$0D
        jsr print_char
@no_newline:
        
        ; Increment prime counter
        inc prime_count
        bne not_prime
        inc prime_count+1
        
not_prime:
        ; Increment test counter
        inc test_count
        bne @no_inc
        inc test_count+1
@no_inc:
        
        ; Next number (16-bit decrement)
        lda current
        bne @no_borrow
        dec current+1
@no_borrow:
        dec current
        
        ; Check if we've gone below 2
        lda current+1
        bne @continue       ; High byte not zero, keep going
        lda current
        cmp #2
        bcs @continue       ; >= 2, keep going
        jmp done            ; Below 2, we're done!
        
@continue:
        jmp main_loop
        
done:
        ; Final newline
        lda #$0D
        jsr print_char
        
        ; Print summary
        lda #<summary1
        sta str_ptr
        lda #>summary1
        sta str_ptr+1
        jsr print_string
        
        lda prime_count+1
        jsr print_hex
        lda prime_count
        jsr print_hex
        
        lda #<summary2
        sta str_ptr
        lda #>summary2
        sta str_ptr+1
        jsr print_string
        
        ; Return to monitor
        brk
        .byte $00
.endproc

; Test if number in 'current' is prime
; Returns: Carry set = prime, Carry clear = not prime
.proc is_prime
        ; Special case: 2 is prime
        lda current+1
        bne @not_two
        lda current
        cmp #2
        bne @not_two
        sec             ; 2 is prime
        rts
        
@not_two:
        ; Even numbers > 2 are not prime
        lda current
        and #1
        bne @odd
        clc             ; Even, not prime
        rts
        
@odd:
        ; Test divisibility from 3 up to sqrt(current)
        lda #3
        sta divisor
        stz divisor+1
        
@div_loop:
        ; First check if divisor*divisor > current
        ; We do: current / divisor = quotient
        ; If quotient < divisor, we've tested all needed divisors -> prime!
        lda current
        sta dividend
        lda current+1
        sta dividend+1
        
        ; Divide current by divisor
        jsr divide16
        
        ; Check if quotient < divisor (means divisor > sqrt(current))
        lda quotient+1
        cmp divisor+1
        bcc @is_prime   ; quotient < divisor, it's prime!
        bne @test_div   ; quotient > divisor, need to test
        lda quotient
        cmp divisor
        bcc @is_prime   ; quotient < divisor, it's prime!
        
@test_div:
        ; If remainder is 0, not prime
        lda remainder
        ora remainder+1
        bne @not_divisible
        clc             ; Divisible, not prime
        rts
        
@not_divisible:
        ; Try next odd divisor
        inc divisor
        inc divisor     ; Add 2 to stay odd
        bne @no_carry
        inc divisor+1
@no_carry:
        
        ; Check if divisor*divisor > current (we've tested enough)
        ; Compare divisor with quotient: if divisor > quotient, done
        lda divisor+1
        cmp quotient+1
        bcc @div_loop   ; divisor < quotient, continue
        bne @is_prime   ; divisor > quotient, it's prime
        lda divisor
        cmp quotient
        bcc @div_loop   ; divisor < quotient, continue
        beq @div_loop   ; divisor = quotient, test once more
        ; divisor > quotient, it's prime
        
@is_prime:
        sec             ; It's prime!
        rts
.endproc

; 16-bit division: dividend / divisor = quotient, remainder
; Input: dividend (16-bit), divisor (16-bit)
; Output: quotient (16-bit), remainder (16-bit)
.proc divide16
        ; Initialize remainder to 0
        stz remainder
        stz remainder+1
        
        ; Handle division by zero
        lda divisor
        ora divisor+1
        bne @start
        rts
        
@start:
        ldx #16         ; 16 bits to process
        
@loop:
        ; Shift dividend left, MSB goes into remainder
        asl dividend
        rol dividend+1
        rol remainder
        rol remainder+1
        
        ; Try to subtract divisor from remainder
        sec
        lda remainder
        sbc divisor
        sta temp
        lda remainder+1
        sbc divisor+1
        
        ; If result is negative (borrow), don't subtract
        bcc @no_sub
        
        ; Result is positive, keep it
        sta remainder+1
        lda temp
        sta remainder
        inc dividend    ; Set bit 0 of dividend (becomes quotient)
        
@no_sub:
        dex
        bne @loop
        
        ; Dividend now contains quotient
        lda dividend
        sta quotient
        lda dividend+1
        sta quotient+1
        rts
.endproc

; Print hex byte in A
.proc print_hex
        pha
        lsr a
        lsr a
        lsr a
        lsr a
        jsr print_nibble
        pla
        and #$0F
print_nibble:
        cmp #10
        bcc @is_digit
        adc #6              ; Add 7 (carry is set from CMP)
@is_digit:
        adc #'0'
        jsr print_char
        rts
.endproc

; Print character in A via SMON
.proc print_char
        jsr CHROUT
        rts
.endproc

; Print null-terminated string
.proc print_string
        ldy #0
@loop:
        lda (str_ptr),y
        beq @done
        jsr CHROUT
        iny
        bne @loop
@done:
        rts
.endproc

; Data section
banner:
        .byte $0D, "================================", $0D
        .byte "  65C02 PRIME STRESS TEST", $0D
        .byte "  REVERSE: 65535 DOWN TO 2", $0D
        .byte "  Hardest first, gets easier!", $0D
        .byte "================================", $0D
        .byte "Primes:", $0D, 0

summary1:
        .byte $0D, "================================", $0D
        .byte "FULL SWEEP COMPLETE!", $0D
        .byte "  Primes found: $", 0

summary2:
        .byte $0D, "  (Tested 2 to 65535)", $0D
        .byte "================================", $0D, 0
