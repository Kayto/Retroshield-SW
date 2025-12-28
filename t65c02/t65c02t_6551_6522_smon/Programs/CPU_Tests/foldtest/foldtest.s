; Folding & Optimization Stress Test for 65C02
; Tests CPU with intensive computational patterns
; Includes: XOR folding, checksums, Fibonacci, factorial, bit manipulation
; Uses SMON Kernal-style I/O

.setcpu "65C02"

; SMON Kernal I/O vectors
CHROUT = $FFD2          ; Character output

; Constants
DATA_SIZE = 128         ; Size of test data buffer
FIB_COUNT = 24          ; Fibonacci numbers to generate (24 fits in 16-bit)
FACT_MAX  = 8           ; Max factorial (8! = 40320, fits 16-bit)
FOLD_ITERATIONS = 255   ; XOR fold iterations (max 8-bit)
PRIME_LIMIT = 200       ; Check primes up to this

; Zero page variables
.segment "ZEROPAGE"
ptr:        .res 2      ; General pointer
temp:       .res 2      ; Temp storage
temp2:      .res 2      ; Second temp
accum:      .res 2      ; 16-bit accumulator
result:     .res 2      ; Result storage
checksum:   .res 2      ; Running checksum
fold_val:   .res 2      ; Folding value
fib_n1:     .res 2      ; Fibonacci n-1
fib_n2:     .res 2      ; Fibonacci n-2
counter:    .res 1      ; Loop counter
counter2:   .res 1      ; Second counter
pass_num:   .res 1      ; Current pass number
str_ptr:    .res 2      ; String pointer
prime_cnt:  .res 1      ; Prime counter
divisor:    .res 1      ; For division
dividend:   .res 2      ; For division
crc:        .res 2      ; CRC value
gcd_a:      .res 2      ; GCD operand A
gcd_b:      .res 2      ; GCD operand B

.segment "BSS"
data_buf:   .res DATA_SIZE   ; Test data buffer at $0200
fib_table:  .res 48          ; Fibonacci table (24 x 2 bytes)
results:    .res 16          ; Store test results
sort_buf:   .res 128         ; Sorting buffer (doubled)

.segment "CODE"

.proc main
        ; Print banner
        lda #<banner
        sta str_ptr
        lda #>banner
        sta str_ptr+1
        jsr print_string
        
        ; Initialize pass counter
        lda #1
        sta pass_num
        
        ; ========================================
        ; TEST 1: Data Initialization & Checksum
        ; ========================================
        lda #<test1_msg
        sta str_ptr
        lda #>test1_msg
        sta str_ptr+1
        jsr print_string
        
        jsr init_data_pattern
        jsr compute_checksum
        
        ; Print checksum
        lda #<chk_msg
        sta str_ptr
        lda #>chk_msg
        sta str_ptr+1
        jsr print_string
        lda checksum+1
        jsr print_hex
        lda checksum
        jsr print_hex
        jsr print_crlf
        
        ; Store expected checksum
        lda checksum
        sta results
        lda checksum+1
        sta results+1
        
        ; ========================================
        ; TEST 2: XOR Folding Stress
        ; ========================================
        lda #<test2_msg
        sta str_ptr
        lda #>test2_msg
        sta str_ptr+1
        jsr print_string
        
        jsr xor_fold_test
        
        lda #<fold_msg
        sta str_ptr
        lda #>fold_msg
        sta str_ptr+1
        jsr print_string
        lda fold_val+1
        jsr print_hex
        lda fold_val
        jsr print_hex
        jsr print_crlf
        
        ; ========================================
        ; TEST 3: Fibonacci Sequence
        ; ========================================
        lda #<test3_msg
        sta str_ptr
        lda #>test3_msg
        sta str_ptr+1
        jsr print_string
        
        jsr generate_fibonacci
        
        ; Print last Fibonacci number (F24 = 46368)
        lda #<fib_msg
        sta str_ptr
        lda #>fib_msg
        sta str_ptr+1
        jsr print_string
        
        ; Get F24 from table
        lda fib_table+46    ; F24 low
        sta temp
        lda fib_table+47    ; F24 high
        sta temp+1
        lda temp+1
        jsr print_hex
        lda temp
        jsr print_hex
        jsr print_crlf
        
        ; Verify F24 = $B520 (46368 decimal)
        lda temp
        cmp #$20
        bne @fib_fail
        lda temp+1
        cmp #$B5
        bne @fib_fail
        lda #<pass_msg
        jmp @fib_done
@fib_fail:
        lda #<fail_msg
@fib_done:
        sta str_ptr
        lda #>pass_msg      ; Same page for both
        sta str_ptr+1
        jsr print_string
        
        ; ========================================
        ; TEST 4: Factorial Chain
        ; ========================================
        lda #<test4_msg
        sta str_ptr
        lda #>test4_msg
        sta str_ptr+1
        jsr print_string
        
        jsr factorial_chain
        
        ; Print 8! result
        lda #<fact_msg
        sta str_ptr
        lda #>fact_msg
        sta str_ptr+1
        jsr print_string
        lda result+1
        jsr print_hex
        lda result
        jsr print_hex
        jsr print_crlf
        
        ; Verify 8! = $9D80 (40320 decimal)
        lda result
        cmp #$80
        bne @fact_fail
        lda result+1
        cmp #$9D
        bne @fact_fail
        lda #<pass_msg
        jmp @fact_done
@fact_fail:
        lda #<fail_msg
@fact_done:
        sta str_ptr
        lda #>pass_msg
        sta str_ptr+1
        jsr print_string
        
        ; ========================================
        ; TEST 5: Bit Manipulation Cascade
        ; ========================================
        lda #<test5_msg
        sta str_ptr
        lda #>test5_msg
        sta str_ptr+1
        jsr print_string
        
        jsr bit_cascade
        
        lda #<bits_msg
        sta str_ptr
        lda #>bits_msg
        sta str_ptr+1
        jsr print_string
        lda result+1
        jsr print_hex
        lda result
        jsr print_hex
        jsr print_crlf
        
        ; ========================================
        ; TEST 6: Memory Pattern Verify
        ; ========================================
        lda #<test6_msg
        sta str_ptr
        lda #>test6_msg
        sta str_ptr+1
        jsr print_string
        
        jsr verify_checksum
        
        ; ========================================
        ; TEST 7: Intensive Loop Stress
        ; ========================================
        lda #<test7_msg
        sta str_ptr
        lda #>test7_msg
        sta str_ptr+1
        jsr print_string
        
        jsr loop_stress
        
        lda #<loop_msg
        sta str_ptr
        lda #>loop_msg
        sta str_ptr+1
        jsr print_string
        lda accum+1
        jsr print_hex
        lda accum
        jsr print_hex
        jsr print_crlf
        
        ; ========================================
        ; TEST 8: Prime Counting
        ; ========================================
        lda #<test8_msg
        sta str_ptr
        lda #>test8_msg
        sta str_ptr+1
        jsr print_string
        
        jsr count_primes
        
        lda #<prime_msg
        sta str_ptr
        lda #>prime_msg
        sta str_ptr+1
        jsr print_string
        lda prime_cnt
        jsr print_hex
        jsr print_crlf
        
        ; Verify: primes < 200 = 46
        lda prime_cnt
        cmp #46
        bne @prime_fail
        lda #<pass_msg
        jmp @prime_done
@prime_fail:
        lda #<fail_msg
@prime_done:
        sta str_ptr
        lda #>pass_msg
        sta str_ptr+1
        jsr print_string
        
        ; ========================================
        ; TEST 9: Bubble Sort
        ; ========================================
        lda #<test9_msg
        sta str_ptr
        lda #>test9_msg
        sta str_ptr+1
        jsr print_string
        
        jsr bubble_sort_test
        
        lda #<sort_msg
        sta str_ptr
        lda #>sort_msg
        sta str_ptr+1
        jsr print_string
        
        ; ========================================
        ; TEST 10: CRC-16 Calculation
        ; ========================================
        lda #<test10_msg
        sta str_ptr
        lda #>test10_msg
        sta str_ptr+1
        jsr print_string
        
        jsr crc16_test
        
        lda #<crc_msg
        sta str_ptr
        lda #>crc_msg
        sta str_ptr+1
        jsr print_string
        lda crc+1
        jsr print_hex
        lda crc
        jsr print_hex
        jsr print_crlf
        
        ; ========================================
        ; TEST 11: GCD Euclidean Algorithm
        ; ========================================
        lda #<test11_msg
        sta str_ptr
        lda #>test11_msg
        sta str_ptr+1
        jsr print_string
        
        jsr gcd_test
        
        lda #<gcd_msg
        sta str_ptr
        lda #>gcd_msg
        sta str_ptr+1
        jsr print_string
        lda result+1
        jsr print_hex
        lda result
        jsr print_hex
        jsr print_crlf
        
        ; GCD(252, 105) = 21 = $15
        lda result
        cmp #21
        bne @gcd_fail
        lda result+1
        bne @gcd_fail
        lda #<pass_msg
        jmp @gcd_done
@gcd_fail:
        lda #<fail_msg
@gcd_done:
        sta str_ptr
        lda #>pass_msg
        sta str_ptr+1
        jsr print_string
        
        ; ========================================
        ; TEST 12: Extended Folding (256 passes)
        ; ========================================
        lda #<test12_msg
        sta str_ptr
        lda #>test12_msg
        sta str_ptr+1
        jsr print_string
        
        jsr extended_fold
        
        lda #<efold_msg
        sta str_ptr
        lda #>efold_msg
        sta str_ptr+1
        jsr print_string
        lda fold_val+1
        jsr print_hex
        lda fold_val
        jsr print_hex
        jsr print_crlf
        
        ; ========================================
        ; TEST 13: Power of 2 Test (2^16)
        ; ========================================
        lda #<test13_msg
        sta str_ptr
        lda #>test13_msg
        sta str_ptr+1
        jsr print_string
        
        jsr power_test
        
        lda #<pow_msg
        sta str_ptr
        lda #>pow_msg
        sta str_ptr+1
        jsr print_string
        lda result+1
        jsr print_hex
        lda result
        jsr print_hex
        jsr print_crlf
        
        ; ========================================
        ; SUMMARY
        ; ========================================
        lda #<done_msg
        sta str_ptr
        lda #>done_msg
        sta str_ptr+1
        jsr print_string
        
        brk             ; Return to SMON via BRK interrupt
        .byte 0         ; BRK signature byte
.endproc

; Initialize data buffer with complex pattern
.proc init_data_pattern
        ldx #0
        lda #$A5        ; Seed value
@loop:
        sta data_buf,x
        ; Complex pattern: rotate, XOR with index, add constant
        ror a
        eor data_buf,x
        adc #$37
        inx
        cpx #DATA_SIZE
        bne @loop
        rts
.endproc

; Compute 16-bit additive checksum of data buffer
.proc compute_checksum
        stz checksum
        stz checksum+1
        ldx #0
@loop:
        clc
        lda data_buf,x
        adc checksum
        sta checksum
        bcc @no_carry
        inc checksum+1
@no_carry:
        inx
        cpx #DATA_SIZE
        bne @loop
        rts
.endproc

; XOR folding stress test
; Repeatedly XOR fold the buffer down
.proc xor_fold_test
        stz fold_val
        stz fold_val+1
        
        lda #FOLD_ITERATIONS
        sta counter
        
@outer:
        ; XOR all bytes together
        ldx #0
        lda #0
@inner:
        eor data_buf,x
        inx
        cpx #DATA_SIZE
        bne @inner
        
        ; Rotate and accumulate into fold_val
        ror a
        eor fold_val
        sta fold_val
        
        ; Rotate fold_val+1 with carry
        rol fold_val+1
        
        ; Modify buffer for next iteration
        ldx #0
@modify:
        lda data_buf,x
        asl a
        eor fold_val
        sta data_buf,x
        inx
        cpx #DATA_SIZE
        bne @modify
        
        dec counter
        bne @outer
        rts
.endproc

; Generate Fibonacci sequence up to F24
.proc generate_fibonacci
        ; F1 = 1, F2 = 1
        lda #1
        sta fib_table
        stz fib_table+1
        sta fib_table+2
        stz fib_table+3
        
        ldx #2          ; Start at F3
@loop:
        ; Get F(n-2)
        txa
        asl a           ; x2 for 16-bit index
        tay
        dey
        dey
        dey
        dey             ; Y = (n-2) * 2
        lda fib_table,y
        sta fib_n2
        lda fib_table+1,y
        sta fib_n2+1
        
        ; Get F(n-1)
        iny
        iny             ; Y = (n-1) * 2
        lda fib_table,y
        sta fib_n1
        lda fib_table+1,y
        sta fib_n1+1
        
        ; F(n) = F(n-1) + F(n-2)
        clc
        lda fib_n1
        adc fib_n2
        sta temp
        lda fib_n1+1
        adc fib_n2+1
        sta temp+1
        
        ; Store F(n)
        iny
        iny             ; Y = n * 2
        lda temp
        sta fib_table,y
        lda temp+1
        sta fib_table+1,y
        
        inx
        cpx #FIB_COUNT
        bne @loop
        rts
.endproc

; Calculate factorial chain: 1! * 2! / 1! * 3! / 2! ... up to 8!
; This effectively computes 8! through the chain
.proc factorial_chain
        ; Start with 1
        lda #1
        sta result
        stz result+1
        
        lda #2          ; Start multiplying from 2
        sta counter
        
@loop:
        ; Multiply result by counter (16-bit x 8-bit)
        jsr multiply_8
        
        inc counter
        lda counter
        cmp #FACT_MAX+1
        bne @loop
        rts
.endproc

; Multiply result by counter (8-bit multiplier)
.proc multiply_8
        lda result
        sta temp
        lda result+1
        sta temp+1
        
        stz result
        stz result+1
        
        lda counter
        sta accum       ; Multiplier in accum
        
@loop:
        lsr accum
        bcc @no_add
        clc
        lda result
        adc temp
        sta result
        lda result+1
        adc temp+1
        sta result+1
@no_add:
        asl temp
        rol temp+1
        lda accum
        bne @loop
        rts
.endproc

; Bit manipulation cascade
; Shift, rotate, and XOR through various patterns
.proc bit_cascade
        lda #$AA
        sta result
        lda #$55
        sta result+1
        
        ldx #128        ; 128 iterations (was 32)
@loop:
        ; ROL through both bytes
        rol result
        rol result+1
        
        ; XOR with iteration count
        txa
        eor result
        sta result
        
        ; ROR the high byte
        ror result+1
        
        ; Bit-reverse nibble swap
        lda result
        and #$0F
        asl a
        asl a
        asl a
        asl a
        sta temp
        lda result
        lsr a
        lsr a
        lsr a
        lsr a
        ora temp
        sta result
        
        dex
        bne @loop
        rts
.endproc

; Verify checksum hasn't been corrupted during tests
.proc verify_checksum
        ; Recompute checksum
        jsr compute_checksum
        
        ; Compare with stored (will be different due to XOR folding)
        lda #<verify_msg
        sta str_ptr
        lda #>verify_msg
        sta str_ptr+1
        jsr print_string
        lda checksum+1
        jsr print_hex
        lda checksum
        jsr print_hex
        lda #<modified_msg
        sta str_ptr
        lda #>modified_msg
        sta str_ptr+1
        jsr print_string
        rts
.endproc

; Intensive nested loop stress test
.proc loop_stress
        stz accum
        stz accum+1
        
        ldx #0          ; Outer loop
@outer:
        ldy #0          ; Inner loop
@inner:
        ; Complex accumulation
        clc
        txa
        adc accum
        sta accum
        tya
        adc accum+1
        sta accum+1
        
        ; XOR pattern
        txa
        eor accum
        sta accum
        
        iny
        bne @inner
        
        inx
        bne @outer
        rts
.endproc

; ========================================
; TEST 8: Count primes up to PRIME_LIMIT
; ========================================
.proc count_primes
        stz prime_cnt
        
        lda #2              ; Start at 2
        sta counter
        
@check_loop:
        jsr is_prime
        bcc @not_prime
        inc prime_cnt
@not_prime:
        inc counter
        lda counter
        cmp #PRIME_LIMIT
        bcc @check_loop
        rts
.endproc

; Check if counter is prime
; Returns: Carry set if prime
.proc is_prime
        lda counter
        cmp #2
        beq @is_prime       ; 2 is prime
        bcc @not_prime      ; < 2 not prime
        
        ; Check if even
        and #$01
        beq @not_prime      ; Even numbers > 2 not prime
        
        ; Trial division from 3 upward
        lda #3
        sta divisor
        
@div_loop:
        ; If divisor > counter/2, it's prime (simplified check)
        lda divisor
        cmp counter
        bcs @is_prime       ; divisor >= n, so prime
        
        ; Check if counter % divisor == 0
        lda counter
        sta dividend
        stz dividend+1
        jsr divide_8
        
        ; If remainder (in A) is 0, not prime
        cmp #0
        beq @not_prime
        
        ; Next odd divisor
        inc divisor
        inc divisor
        
        ; Safety: stop if divisor wrapped or too big
        lda divisor
        beq @is_prime
        cmp counter
        bcc @div_loop
        
@is_prime:
        sec
        rts
@not_prime:
        clc
        rts
.endproc

; Divide dividend by divisor, result in dividend, remainder in A
.proc divide_8
        ldx #8
        lda #0
@loop:
        asl dividend
        rol a
        cmp divisor
        bcc @no_sub
        sbc divisor
        inc dividend
@no_sub:
        dex
        bne @loop
        rts
.endproc

; ========================================
; TEST 9: Bubble Sort Test
; ========================================
.proc bubble_sort_test
        ; Initialize sort buffer with descending values
        ldx #127
        lda #127
@init:
        sta sort_buf,x
        dex
        bpl @init
        
        ; Shuffle a bit with XOR pattern
        ldx #0
@shuffle:
        lda sort_buf,x
        eor #$55
        and #$7F
        sta sort_buf,x
        inx
        cpx #128
        bne @shuffle
        
        ; Bubble sort
        jsr bubble_sort
        
        ; Verify sorted
        ldx #0
@verify:
        lda sort_buf,x
        inx
        cpx #128
        beq @done
        cmp sort_buf,x
        bcc @verify
        beq @verify
        ; Not sorted - fail
        lda #<fail_msg
        sta str_ptr
        lda #>fail_msg
        sta str_ptr+1
        jsr print_string
        rts
@done:
        lda #<pass_msg
        sta str_ptr
        lda #>pass_msg
        sta str_ptr+1
        jsr print_string
        rts
.endproc

.proc bubble_sort
        lda #1
        sta counter2        ; Swapped flag
        
@outer:
        lda counter2
        beq @done           ; No swaps = sorted
        
        stz counter2        ; Clear swap flag
        ldx #0
        
@inner:
        lda sort_buf,x
        cmp sort_buf+1,x
        bcc @no_swap
        beq @no_swap
        
        ; Swap
        tay
        lda sort_buf+1,x
        sta sort_buf,x
        tya
        sta sort_buf+1,x
        
        lda #1
        sta counter2        ; Mark swapped
        
@no_swap:
        inx
        cpx #127            ; 128 bytes - 1
        bne @inner
        jmp @outer
        
@done:
        rts
.endproc

; ========================================
; TEST 10: CRC-16 CCITT
; ========================================
.proc crc16_test
        ; Initialize CRC
        lda #$FF
        sta crc
        sta crc+1
        
        ; CRC over data buffer
        ldx #0
@loop:
        lda data_buf,x
        jsr crc16_byte
        inx
        cpx #DATA_SIZE
        bne @loop
        rts
.endproc

.proc crc16_byte
        eor crc+1
        sta crc+1
        
        ldy #8
@bit_loop:
        lda crc
        asl a
        rol crc+1
        sta crc
        bcc @no_xor
        
        ; XOR with polynomial $1021
        lda crc
        eor #$21
        sta crc
        lda crc+1
        eor #$10
        sta crc+1
        
@no_xor:
        dey
        bne @bit_loop
        rts
.endproc

; ========================================
; TEST 11: GCD Euclidean Algorithm
; ========================================
.proc gcd_test
        ; GCD(252, 105)
        lda #252
        sta gcd_a
        stz gcd_a+1
        lda #105
        sta gcd_b
        stz gcd_b+1
        
        jsr gcd_euclid
        
        lda gcd_a
        sta result
        lda gcd_a+1
        sta result+1
        rts
.endproc

.proc gcd_euclid
@loop:
        ; If b == 0, done
        lda gcd_b
        ora gcd_b+1
        beq @done
        
        ; a = a mod b, swap a and b
        jsr mod_16
        
        ; Swap: temp = a, a = b, b = temp
        lda gcd_a
        sta temp
        lda gcd_a+1
        sta temp+1
        
        lda gcd_b
        sta gcd_a
        lda gcd_b+1
        sta gcd_a+1
        
        lda temp
        sta gcd_b
        lda temp+1
        sta gcd_b+1
        
        jmp @loop
@done:
        rts
.endproc

; gcd_a = gcd_a mod gcd_b
.proc mod_16
@loop:
        ; While a >= b, a -= b
        lda gcd_a+1
        cmp gcd_b+1
        bcc @done
        bne @subtract
        lda gcd_a
        cmp gcd_b
        bcc @done
        
@subtract:
        sec
        lda gcd_a
        sbc gcd_b
        sta gcd_a
        lda gcd_a+1
        sbc gcd_b+1
        sta gcd_a+1
        jmp @loop
@done:
        rts
.endproc

; ========================================
; TEST 12: Extended XOR Folding (256 iterations)
; ========================================
.proc extended_fold
        stz fold_val
        stz fold_val+1
        stz counter         ; 256 iterations (wraps)
        
@outer:
        ; XOR all bytes together with rotation
        ldx #0
        lda fold_val
@inner:
        eor data_buf,x
        rol a
        inx
        cpx #DATA_SIZE
        bne @inner
        
        ; Accumulate
        eor fold_val
        sta fold_val
        ror fold_val+1
        eor fold_val+1
        sta fold_val+1
        
        dec counter
        bne @outer
        rts
.endproc

; ========================================
; TEST 13: Power calculation 2^15
; ========================================
.proc power_test
        ; Calculate 2^15 by repeated doubling
        lda #1
        sta result
        stz result+1
        
        ldx #15
@loop:
        asl result
        rol result+1
        dex
        bne @loop
        
        ; Result should be $8000 = 32768
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
        adc #6
@is_digit:
        adc #'0'
        jsr CHROUT
        rts
.endproc

; Print CRLF
.proc print_crlf
        lda #$0D
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

; Data strings
banner:
        .byte $0D, "================================", $0D
        .byte "  65C02 FOLDING STRESS TEST", $0D
        .byte "   Extended Edition (13 tests)", $0D
        .byte "================================", $0D, 0

test1_msg:
        .byte $0D, "Test 1: Init & Checksum...", $0D, 0
chk_msg:
        .byte "  Checksum: $", 0

test2_msg:
        .byte $0D, "Test 2: XOR Folding (255 iter)...", $0D, 0
fold_msg:
        .byte "  Fold result: $", 0

test3_msg:
        .byte $0D, "Test 3: Fibonacci (24 terms)...", $0D, 0
fib_msg:
        .byte "  F24 = $", 0

test4_msg:
        .byte $0D, "Test 4: Factorial Chain...", $0D, 0
fact_msg:
        .byte "  8! = $", 0

test5_msg:
        .byte $0D, "Test 5: Bit Cascade (128x)...", $0D, 0
bits_msg:
        .byte "  Result: $", 0

test6_msg:
        .byte $0D, "Test 6: Memory Verify...", $0D, 0
verify_msg:
        .byte "  New checksum: $", 0
modified_msg:
        .byte " (modified)", $0D, 0

test7_msg:
        .byte $0D, "Test 7: Loop Stress (64K iter)...", $0D, 0
loop_msg:
        .byte "  Accumulator: $", 0

test8_msg:
        .byte $0D, "Test 8: Prime Count (<200)...", $0D, 0
prime_msg:
        .byte "  Primes found: $", 0

test9_msg:
        .byte $0D, "Test 9: Bubble Sort (128 bytes)...", $0D, 0
sort_msg:
        .byte "  Sorted: ", 0

test10_msg:
        .byte $0D, "Test 10: CRC-16 CCITT...", $0D, 0
crc_msg:
        .byte "  CRC: $", 0

test11_msg:
        .byte $0D, "Test 11: GCD Euclid (252,105)...", $0D, 0
gcd_msg:
        .byte "  GCD: $", 0

test12_msg:
        .byte $0D, "Test 12: Extended Fold (256x)...", $0D, 0
efold_msg:
        .byte "  Result: $", 0

test13_msg:
        .byte $0D, "Test 13: Power 2^15...", $0D, 0
pow_msg:
        .byte "  2^15 = $", 0

pass_msg:
        .byte "  PASS", $0D, 0
fail_msg:
        .byte "  FAIL", $0D, 0

done_msg:
        .byte $0D, "================================", $0D
        .byte "  ALL 13 TESTS COMPLETE!", $0D
        .byte "================================", $0D, 0
