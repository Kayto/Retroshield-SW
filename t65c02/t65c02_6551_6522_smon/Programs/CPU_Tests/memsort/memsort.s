; Memory Sort Stress Test for 65C02
; Starts at $1000
; Uses SMON Kernal-style I/O
; Fills memory with random data, then sorts it using multiple algorithms
; INTENSIVE: Tests memory, ALU, branching, addressing modes

.setcpu "65C02"

; SMON Kernal I/O vectors
CHROUT = $FFD2          ; Character output

; Configuration
ARRAY_SIZE = 255        ; Size of array to sort (smaller for testing)
ARRAY_BASE = $0200      ; Array location in RAM (page 2, safe area)

; Zero page variables
.segment "ZEROPAGE"
rand_seed:   .res 2      ; 16-bit LFSR seed
ptr1:        .res 2      ; General pointer
ptr2:        .res 2      ; Second pointer
temp:        .res 1      ; Temp storage
temp2:       .res 1      ; Second temp
swap_count:  .res 2      ; Number of swaps (16-bit)
pass_count:  .res 2      ; Number of passes
compare_cnt: .res 4      ; Comparison count (32-bit)
str_ptr:     .res 2      ; String pointer
min_idx:     .res 1      ; For selection sort
i_idx:       .res 1      ; Outer loop index
j_idx:       .res 1      ; Inner loop index
gap:         .res 1      ; For shell sort
dump_ptr:    .res 2      ; Pointer for hex dump
dump_cnt:    .res 1      ; Counter for hex dump

.segment "CODE"

; ============================================
; MAIN ENTRY POINT
; ============================================
.proc main
        ; Initialize random seed if zero
        lda rand_seed
        ora rand_seed+1
        bne @has_seed
        lda #$DE
        sta rand_seed
        lda #$AD
        sta rand_seed+1
@has_seed:

        ; Print banner
        lda #<banner
        sta str_ptr
        lda #>banner
        sta str_ptr+1
        jsr print_string
        
        ; ========== TEST 1: BUBBLE SORT ==========
        lda #<str_bubble
        sta str_ptr
        lda #>str_bubble
        sta str_ptr+1
        jsr print_string
        
        jsr fill_random
        
        lda #<str_before
        sta str_ptr
        lda #>str_before
        sta str_ptr+1
        jsr print_string
        jsr hex_dump
        
        jsr bubble_sort
        
        lda #<str_after
        sta str_ptr
        lda #>str_after
        sta str_ptr+1
        jsr print_string
        jsr hex_dump
        
        jsr verify_sorted
        jsr show_stats
        
        ; ========== TEST 2: SELECTION SORT ==========
        lda #<str_select
        sta str_ptr
        lda #>str_select
        sta str_ptr+1
        jsr print_string
        
        jsr fill_random
        
        lda #<str_before
        sta str_ptr
        lda #>str_before
        sta str_ptr+1
        jsr print_string
        jsr hex_dump
        
        jsr selection_sort
        
        lda #<str_after
        sta str_ptr
        lda #>str_after
        sta str_ptr+1
        jsr print_string
        jsr hex_dump
        
        jsr verify_sorted
        jsr show_stats
        
        ; ========== TEST 3: SHELL SORT ==========
        lda #<str_shell
        sta str_ptr
        lda #>str_shell
        sta str_ptr+1
        jsr print_string
        
        jsr fill_random
        
        lda #<str_before
        sta str_ptr
        lda #>str_before
        sta str_ptr+1
        jsr print_string
        jsr hex_dump
        
        jsr shell_sort
        
        lda #<str_after
        sta str_ptr
        lda #>str_after
        sta str_ptr+1
        jsr print_string
        jsr hex_dump
        
        jsr verify_sorted
        jsr show_stats
        
        ; ========== FINAL SUMMARY ==========
        lda #<str_done
        sta str_ptr
        lda #>str_done
        sta str_ptr+1
        jsr print_string
        
        brk
        nop
.endproc

; ============================================
; Fill array with random values
; ============================================
.proc fill_random
        ldx #0
@loop:
        jsr random
        sta ARRAY_BASE,x
        inx
        cpx #ARRAY_SIZE
        bne @loop
        rts
.endproc

; ============================================
; Full hex dump of array (16 bytes per line)
; Shows address: XX XX XX ... format
; ============================================
.proc hex_dump
        lda #<ARRAY_BASE
        sta dump_ptr
        lda #>ARRAY_BASE
        sta dump_ptr+1
        
        lda #ARRAY_SIZE
        sta dump_cnt
        
@line_loop:
        ; Print address
        lda dump_ptr+1
        jsr print_hex
        lda dump_ptr
        jsr print_hex
        lda #':'
        jsr print_char
        lda #' '
        jsr print_char
        
        ; Print 16 bytes per line
        ldy #0
@byte_loop:
        lda (dump_ptr),y
        jsr print_hex
        lda #' '
        jsr print_char
        
        dec dump_cnt
        beq @done
        
        iny
        cpy #16
        bne @byte_loop
        
        ; Move pointer to next line
        clc
        lda dump_ptr
        adc #16
        sta dump_ptr
        bcc @no_carry
        inc dump_ptr+1
@no_carry:
        
        ; Print newline
        lda #$0D
        jsr print_char
        jmp @line_loop
        
@done:
        lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; Verify array is sorted
; ============================================
.proc verify_sorted
        ldx #0
@loop:
        cpx #ARRAY_SIZE-1   ; Stop before last element
        beq @pass
        
        lda ARRAY_BASE,x    ; Load array[x]
        cmp ARRAY_BASE+1,x  ; Compare with array[x+1]
        beq @next           ; Equal is OK
        bcc @next           ; Less than is OK (ascending)
        
        ; array[x] > array[x+1] = FAIL
        lda #<str_fail
        sta str_ptr
        lda #>str_fail
        sta str_ptr+1
        jsr print_string
        rts
        
@next:
        inx
        bne @loop
        
@pass:
        lda #<str_pass
        sta str_ptr
        lda #>str_pass
        sta str_ptr+1
        jsr print_string
        rts
.endproc

; ============================================
; Show statistics (swaps, comparisons)
; ============================================
.proc show_stats
        lda #<str_swaps
        sta str_ptr
        lda #>str_swaps
        sta str_ptr+1
        jsr print_string
        lda swap_count+1
        jsr print_hex
        lda swap_count
        jsr print_hex
        
        lda #<str_compares
        sta str_ptr
        lda #>str_compares
        sta str_ptr+1
        jsr print_string
        lda compare_cnt+1
        jsr print_hex
        lda compare_cnt
        jsr print_hex
        
        lda #$0D
        jsr print_char
        lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; BUBBLE SORT - O(n²)
; Classic but slow - many swaps
; ============================================
.proc bubble_sort
        ; Reset counters
        stz swap_count
        stz swap_count+1
        stz compare_cnt
        stz compare_cnt+1
        stz compare_cnt+2
        stz compare_cnt+3
        
        lda #ARRAY_SIZE-1
        sta i_idx       ; Outer loop count (n-1)
        
@outer:
        lda i_idx
        beq @done       ; If i_idx is 0, we're done
        
        ldx #0
        stx temp2       ; swapped flag = false
        
@inner:
        ; Increment comparison counter
        inc compare_cnt
        bne @no_inc1
        inc compare_cnt+1
@no_inc1:
        
        ; Compare adjacent elements
        lda ARRAY_BASE,x
        cmp ARRAY_BASE+1,x
        bcc @no_swap    ; A < next, no swap needed
        beq @no_swap    ; A = next, no swap needed
        
        ; Swap needed: A has larger value at [x], need to swap with [x+1]
        pha             ; Save larger value
        lda ARRAY_BASE+1,x  ; Get smaller value
        sta ARRAY_BASE,x    ; Store at position x
        pla
        sta ARRAY_BASE+1,x  ; Store larger at x+1
        
        inc temp2       ; swapped = true
        
        ; Increment swap counter
        inc swap_count
        bne @no_swap
        inc swap_count+1
        
@no_swap:
        inx
        cpx i_idx       ; Compare with shrinking boundary
        bne @inner
        
        ; If no swaps, array is sorted
        lda temp2
        beq @done
        
        dec i_idx
        jmp @outer
        
@done:
        rts
.endproc

; ============================================
; SELECTION SORT - O(n²)
; Fewer swaps than bubble sort
; ============================================
.proc selection_sort
        ; Reset counters
        stz swap_count
        stz swap_count+1
        stz compare_cnt
        stz compare_cnt+1
        stz compare_cnt+2
        stz compare_cnt+3
        
        stz i_idx       ; Start at 0
        
@outer:
        lda i_idx
        cmp #ARRAY_SIZE-1
        beq @done       ; Done when i reaches n-1
        
        sta min_idx     ; Assume current is minimum
        
        ; j = i + 1
        clc
        adc #1
        sta j_idx
        
@inner:
        lda j_idx
        cmp #ARRAY_SIZE
        beq @do_swap    ; j reached end, do swap
        
        ; Increment comparison counter
        inc compare_cnt
        bne @no_inc1
        inc compare_cnt+1
@no_inc1:
        
        ; Compare array[j] with array[min_idx]
        ldx min_idx
        lda ARRAY_BASE,x
        ldx j_idx
        cmp ARRAY_BASE,x
        bcc @next       ; min < current, keep min
        beq @next
        
        ; Found new minimum
        stx min_idx
        
@next:
        inc j_idx
        jmp @inner
        
@do_swap:
        ; Swap array[i] with array[min_idx] if different
        lda i_idx
        cmp min_idx
        beq @no_swap
        
        ldx i_idx
        ldy min_idx
        lda ARRAY_BASE,x
        sta temp
        lda ARRAY_BASE,y
        sta ARRAY_BASE,x
        lda temp
        sta ARRAY_BASE,y
        
        ; Increment swap counter
        inc swap_count
        bne @no_swap
        inc swap_count+1
        
@no_swap:
        inc i_idx
        jmp @outer

@done:
        rts
.endproc

; ============================================
; SHELL SORT - O(n log n) to O(n²)
; Much faster than bubble/selection
; ============================================
.proc shell_sort
        ; Reset counters
        stz swap_count
        stz swap_count+1
        stz compare_cnt
        stz compare_cnt+1
        stz compare_cnt+2
        stz compare_cnt+3
        
        ; Start with gap = ARRAY_SIZE/2
        lda #ARRAY_SIZE/2
        sta gap
        
@gap_loop:
        lda gap
        beq @done
        sta i_idx       ; i = gap
        
@outer:
        lda i_idx
        cmp #ARRAY_SIZE
        beq @next_gap   ; i >= ARRAY_SIZE, reduce gap
        
        ldx i_idx
        lda ARRAY_BASE,x
        sta temp        ; temp = array[i]
        
        stx j_idx       ; j = i
        
@inner:
        ; Check if j >= gap
        lda j_idx
        cmp gap
        bcc @insert     ; j < gap, done with inner
        
        ; Increment comparison counter
        inc compare_cnt
        bne @no_inc1
        inc compare_cnt+1
@no_inc1:
        
        ; Calculate j - gap
        lda j_idx
        sec
        sbc gap
        tax             ; X = j - gap
        
        ; Compare array[j-gap] with temp
        lda ARRAY_BASE,x
        cmp temp
        bcc @insert     ; array[j-gap] < temp, done
        beq @insert
        
        ; Shift array[j-gap] to array[j]
        ldy j_idx
        sta ARRAY_BASE,y
        stx j_idx       ; j = j - gap
        
        ; Increment swap counter
        inc swap_count
        bne @inner
        inc swap_count+1
        jmp @inner
        
@insert:
        ; array[j] = temp
        ldx j_idx
        lda temp
        sta ARRAY_BASE,x
        
        ; i++
        inc i_idx
        jmp @outer
        
@next_gap:
        ; gap = gap / 2
        lsr gap
        jmp @gap_loop
        
@done:
        rts
.endproc

; ============================================
; 16-bit LFSR Random Number Generator
; ============================================
.proc random
        lda rand_seed
        asl a
        rol rand_seed+1
        bcc @no_eor
        eor #$39
        pha
        lda rand_seed+1
        eor #$B4
        sta rand_seed+1
        pla
@no_eor:
        sta rand_seed
        rts
.endproc

; ============================================
; Print hex byte in A
; ============================================
.proc print_hex
        pha
        lsr a
        lsr a
        lsr a
        lsr a
        jsr @nibble
        pla
        and #$0F
@nibble:
        cmp #10
        bcc @digit
        adc #6
@digit: adc #'0'
        jsr print_char
        rts
.endproc

; ============================================
; Print character in A
; ============================================
.proc print_char
        jsr CHROUT
        rts
.endproc

; ============================================
; Print null-terminated string
; ============================================
.proc print_string
        ldy #0
@loop:
        lda (str_ptr),y
        beq @done
        jsr CHROUT
        iny
        bne @loop
@done:  rts
.endproc

; ============================================
; DATA SECTION
; ============================================
banner:
        .byte $0D, "================================", $0D
        .byte "  65C02 MEMORY SORT STRESS TEST", $0D
        .byte "  64 bytes x 3 algorithms", $0D
        .byte "================================", $0D, $0D, 0

str_bubble:
        .byte ">> BUBBLE SORT", $0D, 0
str_select:
        .byte ">> SELECTION SORT", $0D, 0
str_shell:
        .byte ">> SHELL SORT", $0D, 0

str_before:
        .byte "Before:", $0D, 0
str_after:
        .byte "After:", $0D, 0

str_pass:
        .byte "Verify: PASS", $0D, 0
str_fail:
        .byte "Verify: FAIL!", $0D, 0

str_swaps:
        .byte "Swaps: $", 0
str_compares:
        .byte " Cmp: $", 0

str_done:
        .byte "================================", $0D
        .byte "ALL SORTS COMPLETE!", $0D
        .byte "================================", $0D, 0
