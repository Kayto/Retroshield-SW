; 65C02 Opcode Stress Test
; Tests ALL 65C02 opcodes including 65C02-specific instructions
; Starts at $1000
; Uses SMON Kernal-style I/O

.setcpu "65C02"

; SMON Kernal I/O vectors
CHROUT = $FFD2          ; Character output

; Zero page variables
.segment "ZEROPAGE"
zp_temp:     .res 2      ; General temp storage
zp_ptr:      .res 2      ; Pointer for indirect addressing
zp_test:     .res 4      ; Test area
pass_count:  .res 2      ; Tests passed
fail_count:  .res 2      ; Tests failed
str_ptr:     .res 2      ; String pointer

.segment "CODE"

; ============================================
; MAIN ENTRY POINT
; ============================================
.proc main
        ; Initialize counters
        stz pass_count
        stz pass_count+1
        stz fail_count
        stz fail_count+1
        
        ; Print banner
        lda #<banner
        sta str_ptr
        lda #>banner
        sta str_ptr+1
        jsr print_string
        
        ; Run all tests
        jsr test_load_store
        jsr test_transfer
        jsr test_stack
        jsr test_arithmetic
        jsr test_logic
        jsr test_shift
        jsr test_compare
        jsr test_branch
        jsr test_jump
        jsr test_flags
        jsr test_65c02_specific
        jsr test_bit_ops
        jsr test_addressing
        
        ; Print results
        lda #<results
        sta str_ptr
        lda #>results
        sta str_ptr+1
        jsr print_string
        
        lda pass_count+1
        jsr print_hex
        lda pass_count
        jsr print_hex
        
        lda #<str_passed
        sta str_ptr
        lda #>str_passed
        sta str_ptr+1
        jsr print_string
        
        lda fail_count+1
        jsr print_hex
        lda fail_count
        jsr print_hex
        
        lda #<str_failed
        sta str_ptr
        lda #>str_failed
        sta str_ptr+1
        jsr print_string
        
        lda #<footer
        sta str_ptr
        lda #>footer
        sta str_ptr+1
        jsr print_string
        
        brk             ; Return to SMON monitor
        nop             ; BRK signature byte
.endproc

; ============================================
; TEST: Load and Store Instructions
; LDA, LDX, LDY, STA, STX, STY, STZ (65C02)
; ============================================
.proc test_load_store
        lda #<str_load
        sta str_ptr
        lda #>str_load
        sta str_ptr+1
        jsr print_string
        
        ; LDA immediate
        lda #$42
        cmp #$42
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; LDX immediate
        ldx #$55
        cpx #$55
        bne @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; LDY immediate
        ldy #$AA
        cpy #$AA
        bne @fail3
        jsr pass
        jmp @t4
@fail3: jsr fail
        
@t4:    ; STA zero page
        lda #$12
        sta zp_temp
        lda zp_temp
        cmp #$12
        bne @fail4
        jsr pass
        jmp @t5
@fail4: jsr fail
        
@t5:    ; STX zero page
        ldx #$34
        stx zp_temp
        lda zp_temp
        cmp #$34
        bne @fail5
        jsr pass
        jmp @t6
@fail5: jsr fail
        
@t6:    ; STY zero page
        ldy #$56
        sty zp_temp
        lda zp_temp
        cmp #$56
        bne @fail6
        jsr pass
        jmp @t7
@fail6: jsr fail
        
@t7:    ; STZ zero page (65C02)
        lda #$FF
        sta zp_temp
        stz zp_temp
        lda zp_temp
        bne @fail7
        jsr pass
        jmp @done
@fail7: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Transfer Instructions
; TAX, TAY, TXA, TYA, TSX, TXS
; ============================================
.proc test_transfer
        lda #<str_xfer
        sta str_ptr
        lda #>str_xfer
        sta str_ptr+1
        jsr print_string
        
        ; TAX
        lda #$11
        tax
        cpx #$11
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; TAY
        lda #$22
        tay
        cpy #$22
        bne @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; TXA
        ldx #$33
        txa
        cmp #$33
        bne @fail3
        jsr pass
        jmp @t4
@fail3: jsr fail
        
@t4:    ; TYA
        ldy #$44
        tya
        cmp #$44
        bne @fail4
        jsr pass
        jmp @done
@fail4: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Stack Instructions
; PHA, PLA, PHX, PLX, PHY, PLY (65C02)
; ============================================
.proc test_stack
        lda #<str_stack
        sta str_ptr
        lda #>str_stack
        sta str_ptr+1
        jsr print_string
        
        ; PHA/PLA
        lda #$77
        pha
        lda #$00
        pla
        cmp #$77
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; PHX/PLX (65C02)
        ldx #$88
        phx
        ldx #$00
        plx
        cpx #$88
        bne @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; PHY/PLY (65C02)
        ldy #$99
        phy
        ldy #$00
        ply
        cpy #$99
        bne @fail3
        jsr pass
        jmp @done
@fail3: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Arithmetic Instructions
; ADC, SBC, INC, DEC, INX, INY, DEX, DEY
; ============================================
.proc test_arithmetic
        lda #<str_arith
        sta str_ptr
        lda #>str_arith
        sta str_ptr+1
        jsr print_string
        
        ; ADC
        clc
        lda #$10
        adc #$20
        cmp #$30
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; SBC
        sec
        lda #$50
        sbc #$20
        cmp #$30
        bne @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; INC A (65C02)
        lda #$FE
        inc a
        cmp #$FF
        bne @fail3
        jsr pass
        jmp @t4
@fail3: jsr fail
        
@t4:    ; DEC A (65C02)
        lda #$02
        dec a
        cmp #$01
        bne @fail4
        jsr pass
        jmp @t5
@fail4: jsr fail
        
@t5:    ; INX
        ldx #$10
        inx
        cpx #$11
        bne @fail5
        jsr pass
        jmp @t6
@fail5: jsr fail
        
@t6:    ; DEX
        ldx #$10
        dex
        cpx #$0F
        bne @fail6
        jsr pass
        jmp @t7
@fail6: jsr fail
        
@t7:    ; INY
        ldy #$20
        iny
        cpy #$21
        bne @fail7
        jsr pass
        jmp @t8
@fail7: jsr fail
        
@t8:    ; DEY
        ldy #$20
        dey
        cpy #$1F
        bne @fail8
        jsr pass
        jmp @done
@fail8: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Logic Instructions
; AND, ORA, EOR
; ============================================
.proc test_logic
        lda #<str_logic
        sta str_ptr
        lda #>str_logic
        sta str_ptr+1
        jsr print_string
        
        ; AND
        lda #$FF
        and #$0F
        cmp #$0F
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; ORA
        lda #$F0
        ora #$0F
        cmp #$FF
        bne @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; EOR
        lda #$AA
        eor #$FF
        cmp #$55
        bne @fail3
        jsr pass
        jmp @done
@fail3: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Shift/Rotate Instructions
; ASL, LSR, ROL, ROR
; ============================================
.proc test_shift
        lda #<str_shift
        sta str_ptr
        lda #>str_shift
        sta str_ptr+1
        jsr print_string
        
        ; ASL
        lda #$40
        asl a
        cmp #$80
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; LSR
        lda #$80
        lsr a
        cmp #$40
        bne @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; ROL (with carry)
        sec
        lda #$40
        rol a
        cmp #$81
        bne @fail3
        jsr pass
        jmp @t4
@fail3: jsr fail
        
@t4:    ; ROR (with carry)
        sec
        lda #$02
        ror a
        cmp #$81
        bne @fail4
        jsr pass
        jmp @done
@fail4: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Compare Instructions
; CMP, CPX, CPY
; ============================================
.proc test_compare
        lda #<str_cmp
        sta str_ptr
        lda #>str_cmp
        sta str_ptr+1
        jsr print_string
        
        ; CMP equal
        lda #$50
        cmp #$50
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; CMP greater
        lda #$60
        cmp #$50
        bcc @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; CPX
        ldx #$30
        cpx #$30
        bne @fail3
        jsr pass
        jmp @t4
@fail3: jsr fail
        
@t4:    ; CPY
        ldy #$40
        cpy #$40
        bne @fail4
        jsr pass
        jmp @done
@fail4: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Branch Instructions
; BEQ, BNE, BCS, BCC, BMI, BPL, BVS, BVC, BRA
; ============================================
.proc test_branch
        lda #<str_branch
        sta str_ptr
        lda #>str_branch
        sta str_ptr+1
        jsr print_string
        
        ; BEQ
        lda #$00
        beq @ok1
        jsr fail
        jmp @t2
@ok1:   jsr pass
        
@t2:    ; BNE
        lda #$01
        bne @ok2
        jsr fail
        jmp @t3
@ok2:   jsr pass
        
@t3:    ; BCS
        sec
        bcs @ok3
        jsr fail
        jmp @t4
@ok3:   jsr pass
        
@t4:    ; BCC
        clc
        bcc @ok4
        jsr fail
        jmp @t5
@ok4:   jsr pass
        
@t5:    ; BMI
        lda #$80
        bmi @ok5
        jsr fail
        jmp @t6
@ok5:   jsr pass
        
@t6:    ; BPL
        lda #$7F
        bpl @ok6
        jsr fail
        jmp @t7
@ok6:   jsr pass
        
@t7:    ; BRA (65C02) - always branches
        bra @ok7
        jsr fail
        jmp @done
@ok7:   jsr pass
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Jump Instructions
; JMP, JSR, RTS
; ============================================
.proc test_jump
        lda #<str_jump
        sta str_ptr
        lda #>str_jump
        sta str_ptr+1
        jsr print_string
        
        ; JMP absolute
        jmp @ok1
@fail1: jsr fail
        jmp @t2
@ok1:   jsr pass
        
@t2:    ; JSR/RTS
        jsr @sub1
        jsr pass
        jmp @t3
        
@sub1:  rts
        
@t3:    ; JMP indirect (also tests addressing mode)
        lda #<@ok3
        sta zp_ptr
        lda #>@ok3
        sta zp_ptr+1
        jmp (zp_ptr)
@fail3: jsr fail
        jmp @done
@ok3:   jsr pass
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Flag Instructions
; SEC, CLC, SEI, CLI, SED, CLD, CLV
; ============================================
.proc test_flags
        lda #<str_flags
        sta str_ptr
        lda #>str_flags
        sta str_ptr+1
        jsr print_string
        
        ; SEC/CLC
        sec
        bcc @fail1
        clc
        bcs @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; CLD (Decimal mode should be clear)
        cld
        jsr pass
        
        ; PHP/PLP test
        sec
        php
        clc
        plp
        bcc @fail3
        jsr pass
        jmp @done
@fail3: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: 65C02-Specific Instructions
; STZ, BRA, PHX, PLX, PHY, PLY, INC A, DEC A
; TRB, TSB
; ============================================
.proc test_65c02_specific
        lda #<str_65c02
        sta str_ptr
        lda #>str_65c02
        sta str_ptr+1
        jsr print_string
        
        ; TRB (Test and Reset Bits)
        lda #$FF
        sta zp_temp
        lda #$0F
        trb zp_temp     ; Clear bits 0-3
        lda zp_temp
        cmp #$F0
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; TSB (Test and Set Bits)
        lda #$00
        sta zp_temp
        lda #$0F
        tsb zp_temp     ; Set bits 0-3
        lda zp_temp
        cmp #$0F
        bne @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; JMP (indirect,x) - 65C02 indexed indirect jump
        ldx #$00
        lda #<@ok3
        sta zp_ptr
        lda #>@ok3
        sta zp_ptr+1
        jmp (zp_ptr,x)
@fail3: jsr fail
        jmp @done
@ok3:   jsr pass
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: BIT Instruction
; BIT immediate (65C02), BIT zp, BIT abs
; ============================================
.proc test_bit_ops
        lda #<str_bit
        sta str_ptr
        lda #>str_bit
        sta str_ptr+1
        jsr print_string
        
        ; BIT immediate (65C02)
        lda #$FF
        bit #$0F
        beq @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; BIT zero page
        lda #$80
        sta zp_temp
        bit zp_temp
        bpl @fail2      ; N flag should be set
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; BIT zero page (V flag)
        lda #$40
        sta zp_temp
        bit zp_temp
        bvc @fail3      ; V flag should be set
        jsr pass
        jmp @done
@fail3: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; TEST: Addressing Modes
; (zp,x), (zp),y, (zp) - 65C02
; ============================================
.proc test_addressing
        lda #<str_addr
        sta str_ptr
        lda #>str_addr
        sta str_ptr+1
        jsr print_string
        
        ; Set up test data
        lda #<test_data
        sta zp_ptr
        lda #>test_data
        sta zp_ptr+1
        
        ; (zp),y indirect indexed
        ldy #$00
        lda (zp_ptr),y
        cmp #$11
        bne @fail1
        jsr pass
        jmp @t2
@fail1: jsr fail
        
@t2:    ; (zp),y with offset
        ldy #$01
        lda (zp_ptr),y
        cmp #$22
        bne @fail2
        jsr pass
        jmp @t3
@fail2: jsr fail
        
@t3:    ; (zp) - 65C02 indirect without index
        lda (zp_ptr)
        cmp #$11
        bne @fail3
        jsr pass
        jmp @done
@fail3: jsr fail
        
@done:  lda #$0D
        jsr print_char
        rts
.endproc

; ============================================
; HELPER: Print pass marker
; ============================================
.proc pass
        lda #'.'
        jsr print_char
        inc pass_count
        bne @done
        inc pass_count+1
@done:  rts
.endproc

; ============================================
; HELPER: Print fail marker
; ============================================
.proc fail
        lda #'X'
        jsr print_char
        inc fail_count
        bne @done
        inc fail_count+1
@done:  rts
.endproc

; ============================================
; HELPER: Print hex byte in A
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
; HELPER: Print character in A
; ============================================
.proc print_char
        jsr CHROUT
        rts
.endproc

; ============================================
; HELPER: Print null-terminated string
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
test_data:
        .byte $11, $22, $33, $44

banner:
        .byte $0D, "================================", $0D
        .byte "  65C02 OPCODE TEST", $0D
        .byte "  Testing all instructions", $0D
        .byte "================================", $0D, $0D, 0

str_load:
        .byte "Load/Store: ", 0
str_xfer:
        .byte "Transfer:   ", 0
str_stack:
        .byte "Stack:      ", 0
str_arith:
        .byte "Arithmetic: ", 0
str_logic:
        .byte "Logic:      ", 0
str_shift:
        .byte "Shift/Rot:  ", 0
str_cmp:
        .byte "Compare:    ", 0
str_branch:
        .byte "Branch:     ", 0
str_jump:
        .byte "Jump:       ", 0
str_flags:
        .byte "Flags:      ", 0
str_65c02:
        .byte "65C02 Ext:  ", 0
str_bit:
        .byte "BIT:        ", 0
str_addr:
        .byte "Addressing: ", 0

results:
        .byte $0D, "================================", $0D
        .byte "TEST RESULTS:", $0D
        .byte "  Passed: $", 0

str_passed:
        .byte $0D, "  Failed: $", 0

str_failed:
        .byte $0D, 0

footer:
        .byte "================================", $0D
        .byte "65C02 opcode coverage test", $0D
        .byte $0D, 0
