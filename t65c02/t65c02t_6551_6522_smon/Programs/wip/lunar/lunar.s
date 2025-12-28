; Lunar Lander for 65C02
; Full ASCII visualization with terminal redraws
; Uses only prints and CR/LF (no cursor positioning)

.setcpu "65C02"

; SMON Kernal I/O vectors
CHROUT = $FFD2          ; Character output
CHRIN  = $FFCF          ; Character input

; ACIA hardware (for non-blocking input)
ACIA_STATUS = $8401     ; Status register
ACIA_DATA   = $8400     ; Data register (RX)
ACIA_RX_RDY = %00001000 ; Bit 3 = RX data ready

; Zero page variables
.segment "ZEROPAGE"
altitude:    .res 2      ; Current altitude (meters)
velocity:    .res 2      ; Current velocity (m/s)
fuel:        .res 2      ; Remaining fuel units
thrust:      .res 1      ; Current thrust (0-3)
lander_row:  .res 1      ; Which row to draw lander (0-5)

temp1:       .res 2
temp2:       .res 2
divisor:     .res 2
dividend:    .res 2
quotient:    .res 2
remainder:   .res 2

str_ptr:     .res 2
user_fuel:   .res 1      ; Fuel selection (1-3)
mission_ok:  .res 1      ; Mission success flag
timeout_lo:  .res 1      ; Timeout counter low
timeout_hi:  .res 1      ; Timeout counter high

.segment "CODE"

; ========================================
; MAIN PROGRAM
; ========================================
.proc main
game_start:
        ; Print title
        lda #<title_msg
        ldx #>title_msg
        jsr print_str
        
        ; Select fuel
        lda #<fuel_prompt
        ldx #>fuel_prompt
        jsr print_str
        
        jsr get_key
        jsr CHROUT
        jsr print_crlf
        
        sec
        sbc #'0'
        cmp #1
        bcc @fuel_def
        cmp #4
        bcs @fuel_def
        jmp @fuel_ok
@fuel_def:
        lda #2
@fuel_ok:
        sta user_fuel
        
        ; Set fuel: 1=1500, 2=2000, 3=3000
        tax
        lda fuel_lo-1,x
        sta fuel
        lda fuel_hi-1,x
        sta fuel+1
        
        ; Initialize game state
        jsr init_game
        
        ; Show intro
        lda #<intro_msg
        ldx #>intro_msg
        jsr print_str
        
        jsr wait_key
        
        ; ========================================
        ; DESCENT LOOP WITH ASCII DISPLAY
        ; ========================================
descent_loop:
        ; Draw full frame
        jsr draw_frame
        
        ; Check for landing
        lda altitude+1
        bne @not_landed
        lda altitude
        cmp #50
        bcs @not_landed
        jmp landing
        
@not_landed:
        ; Get thrust input with timeout
        jsr get_key_timed
        bcs @got_key        ; Carry set = got a key
        
        ; Timeout - keep last thrust setting
        lda #'-'
        jsr CHROUT          ; Show timeout indicator
        jsr print_crlf
        jmp @apply          ; Use existing thrust value
        
@got_key:
        pha                 ; Save key before CHROUT/print_crlf destroy A
        jsr CHROUT
        jsr print_crlf
        pla                 ; Restore key
        
        sec
        sbc #'0'
        cmp #4
        bcc @thrust_ok
        lda thrust          ; Invalid = keep last thrust
        jmp @apply
@thrust_ok:
@set_thrust:
        sta thrust
@apply:
        
        ; Apply physics
        jsr apply_physics
        
        ; Check for crash (negative altitude)
        lda altitude+1
        bmi crash
        
        ; Check fuel
        lda fuel+1
        bmi out_of_fuel
        
        ; Continue descent
        jmp descent_loop

crash:
        stz mission_ok
        lda #<crash_msg
        ldx #>crash_msg
        jsr print_str
        jmp game_over
        
out_of_fuel:
        stz mission_ok
        lda #<no_fuel_msg
        ldx #>no_fuel_msg
        jsr print_str
        jmp game_over
        
landing:
        ; Check landing velocity
        lda velocity+1
        bne hard_land
        lda velocity
        cmp #15
        bcs hard_land
        
        ; Soft landing!
        lda #1
        sta mission_ok
        jsr draw_landed_frame
        lda #<soft_msg
        ldx #>soft_msg
        jsr print_str
        jmp game_over
        
hard_land:
        stz mission_ok
        jsr draw_landed_frame
        lda #<hard_msg
        ldx #>hard_msg
        jsr print_str
        
game_over:
        ; Show final stats
        lda #<final_msg
        ldx #>final_msg
        jsr print_str
        
        lda #<vel_lbl
        ldx #>vel_lbl
        jsr print_str
        lda velocity
        ldx velocity+1
        jsr print_dec16
        jsr print_crlf
        
        lda #<fuel_lbl
        ldx #>fuel_lbl
        jsr print_str
        lda fuel
        ldx fuel+1
        jsr print_dec16
        jsr print_crlf
        
        ; Mission result
        lda mission_ok
        beq @failed
        lda #<success_msg
        ldx #>success_msg
        jsr print_str
        jmp @again
@failed:
        lda #<fail_msg
        ldx #>fail_msg
        jsr print_str
        
@again:
        lda #<again_msg
        ldx #>again_msg
        jsr print_str
        
        jsr get_key
        jsr CHROUT
        jsr print_crlf
        
        cmp #'Y'
        beq @restart
        cmp #'y'
        beq @restart
        
        lda #<bye_msg
        ldx #>bye_msg
        jsr print_str
        brk
        .byte $00
        
@restart:
        jmp game_start
        
fuel_lo: .byte <1500, <2000, <3000
fuel_hi: .byte >1500, >2000, >3000
.endproc

; ========================================
; INITIALIZE GAME STATE
; ========================================
.proc init_game
        ; Altitude: 5000 meters
        lda #<5000
        sta altitude
        lda #>5000
        sta altitude+1
        
        ; Velocity: 30 m/s (falling)
        lda #30
        sta velocity
        stz velocity+1
        
        ; Mission starts OK
        lda #1
        sta mission_ok
        
        ; Start with thrust 1 (hover mode)
        lda #1
        sta thrust
        
        rts
.endproc

; ========================================
; APPLY PHYSICS
; ========================================
.proc apply_physics
        ; Gravity: add 4 to velocity
        clc
        lda velocity
        adc #4
        sta velocity
        bcc @grav_ok
        inc velocity+1
@grav_ok:
        
        ; Apply thrust: reduce velocity
        ; thrust 0=0, 1=4, 2=8, 3=12 m/s reduction
        lda thrust
        beq @no_thrust
        
        ; velocity -= thrust * 4
        asl a               ; *2
        asl a               ; *4
        sta temp1
        
        sec
        lda velocity
        sbc temp1
        sta velocity
        bcs @vel_ok
        ; Don't go negative
        stz velocity
        stz velocity+1
@vel_ok:
        
        ; Use fuel: thrust * 12
        lda thrust
        asl a               ; *2
        asl a               ; *4
        sta temp1
        asl a               ; *8
        clc
        adc temp1           ; *12
        sta temp1
        
        sec
        lda fuel
        sbc temp1
        sta fuel
        bcs @fuel_ok
        dec fuel+1
@fuel_ok:
        
@no_thrust:
        ; Update altitude: altitude -= velocity
        sec
        lda altitude
        sbc velocity
        sta altitude
        lda altitude+1
        sbc velocity+1
        sta altitude+1
        
        rts
.endproc

; ========================================
; DRAW FULL FRAME
; ========================================
.proc draw_frame
        ; Check if altitude <= 600 for ASCII mode
        ; 600 = $0258, so check high byte first
        lda altitude+1
        cmp #2              ; High byte of 600 is 2
        bcc @ascii_mode     ; High byte < 2, definitely < 600
        bne @text_mode      ; High byte > 2, definitely > 600
        ; High byte = 2, check low byte
        lda altitude
        cmp #89             ; Low byte of 600 is $58 = 88, so < 89 means <= 600
        bcs @text_mode      ; >= 89 means > 600
        
@ascii_mode:
        jmp draw_ascii_frame
        
@text_mode:
        ; Simple text output - just status line
        jsr print_status_line
        rts
.endproc

; ========================================
; PRINT STATUS LINE (text mode)
; ========================================
.proc print_status_line
        lda #'A'
        jsr CHROUT
        lda #'L'
        jsr CHROUT
        lda #'T'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        lda altitude
        ldx altitude+1
        jsr print_dec16
        
        lda #' '
        jsr CHROUT
        lda #' '
        jsr CHROUT
        lda #'V'
        jsr CHROUT
        lda #'E'
        jsr CHROUT
        lda #'L'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        lda velocity
        ldx velocity+1
        jsr print_dec16
        
        lda #' '
        jsr CHROUT
        lda #' '
        jsr CHROUT
        lda #'F'
        jsr CHROUT
        lda #'U'
        jsr CHROUT
        lda #'E'
        jsr CHROUT
        lda #'L'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        lda fuel
        ldx fuel+1
        jsr print_dec16
        
        lda #' '
        jsr CHROUT
        lda #' '
        jsr CHROUT
        lda #'T'
        jsr CHROUT
        lda #'H'
        jsr CHROUT
        lda #'R'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        lda thrust
        clc
        adc #'0'
        jsr CHROUT
        
        lda #' '
        jsr CHROUT
        lda #' '
        jsr CHROUT
        lda #'['
        jsr CHROUT
        lda #'0'
        jsr CHROUT
        lda #'-'
        jsr CHROUT
        lda #'3'
        jsr CHROUT
        lda #']'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        rts
.endproc

; ========================================
; DRAW ASCII FRAME (altitude <= 600)
; ========================================
.proc draw_ascii_frame
        ; Calculate lander row (0-5 based on altitude 0-600)
        ; row = 5 - (altitude / 100)
        lda altitude
        sta dividend
        lda altitude+1
        sta dividend+1
        lda #100
        sta divisor
        stz divisor+1
        jsr divide16
        
        ; row = 5 - quotient (clamped 0-5)
        lda #5
        sec
        sbc quotient
        bpl @row_ok
        lda #0
@row_ok:
        cmp #6
        bcc @row_ok2
        lda #5
@row_ok2:
        sta lander_row
        
        ; "Clear" screen by printing blank lines
        ldx #47             ; 47 lines to push old frame off (80x47 terminal)
@clear_loop:
        phx
        jsr print_crlf
        plx
        dex
        bne @clear_loop
        
        ; Print top border
        lda #<border_top
        ldx #>border_top
        jsr print_str
        
        ; Print 6 rows (lander takes 2 rows)
        ldx #0
@row_loop:
        phx
        
        cpx lander_row
        beq @draw_lander_top
        
        ; Check if this is lander bottom row (lander_row + 1)
        txa
        sec
        sbc lander_row
        cmp #1
        beq @draw_lander_bot
        
        ; Empty row
        lda #<empty_row
        ldx #>empty_row
        jsr print_str
        jmp @next_row
        
@draw_lander_top:
        ; Top of lander /\
        lda #<lander_top_str
        ldx #>lander_top_str
        jsr print_str
        jmp @next_row
        
@draw_lander_bot:
        ; Bottom of lander /||\
        lda #<lander_bot_str
        ldx #>lander_bot_str
        jsr print_str
        
@next_row:
        plx
        inx
        cpx #6
        bne @row_loop
        
        ; Print ground
        lda #<ground_row
        ldx #>ground_row
        jsr print_str
        
        ; Print bottom border
        lda #<border_bot
        ldx #>border_bot
        jsr print_str
        
        ; Print status line
        lda #' '
        jsr CHROUT
        lda #'A'
        jsr CHROUT
        lda #'L'
        jsr CHROUT
        lda #'T'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        lda altitude
        ldx altitude+1
        jsr print_dec16
        
        lda #' '
        jsr CHROUT
        lda #' '
        jsr CHROUT
        lda #'V'
        jsr CHROUT
        lda #'E'
        jsr CHROUT
        lda #'L'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        lda velocity
        ldx velocity+1
        jsr print_dec16
        
        lda #' '
        jsr CHROUT
        lda #' '
        jsr CHROUT
        lda #'F'
        jsr CHROUT
        lda #'U'
        jsr CHROUT
        lda #'E'
        jsr CHROUT
        lda #'L'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        lda fuel
        ldx fuel+1
        jsr print_dec16
        
        lda #' '
        jsr CHROUT
        lda #' '
        jsr CHROUT
        lda #'T'
        jsr CHROUT
        lda #'H'
        jsr CHROUT
        lda #'R'
        jsr CHROUT
        lda #':'
        jsr CHROUT
        lda thrust
        clc
        adc #'0'
        jsr CHROUT
        jsr print_crlf
        
        ; Print separator
        lda #<separator
        ldx #>separator
        jsr print_str
        
        ; Print prompt
        lda #<thrust_prompt
        ldx #>thrust_prompt
        jsr print_str
        
        rts
.endproc

; ========================================
; DRAW LANDED FRAME
; ========================================
.proc draw_landed_frame
        ; Print top border
        lda #<border_top
        ldx #>border_top
        jsr print_str
        
        ; Print 5 empty rows
        ldx #5
@row_loop:
        phx
        lda #<empty_row
        ldx #>empty_row
        jsr print_str
        plx
        dex
        bne @row_loop
        
        ; Print lander on ground
        lda #<landed_row
        ldx #>landed_row
        jsr print_str
        
        ; Print bottom border
        lda #<border_bot
        ldx #>border_bot
        jsr print_str
        
        rts
.endproc

; ========================================
; UTILITY ROUTINES
; ========================================

; Print string (A=low, X=high)
.proc print_str
        sta str_ptr
        stx str_ptr+1
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

; Print CR/LF
.proc print_crlf
        lda #$0D
        jsr CHROUT
        rts
.endproc

; Get key (blocking)
.proc get_key
        jsr CHRIN
        rts
.endproc

; Get key with timeout
; Returns: Carry set = got key in A, Carry clear = timeout
.proc get_key_timed
        ; Initialize timeout counter (~2 seconds at 1MHz)
        ; Outer loop * middle loop * inner loop = total delay
        ldx #$02            ; Outer count (faster timeout)
        
@outer_loop:
        lda #$FF            ; Middle count
        sta timeout_hi
        
@middle_loop:
        lda #$80            ; Inner count (reduced)
        sta timeout_lo
        
@inner_loop:
        ; Check if key available
        lda ACIA_STATUS
        and #ACIA_RX_RDY
        bne @got_key
        
        ; Decrement inner counter
        dec timeout_lo
        bne @inner_loop
        
        ; Decrement middle counter
        dec timeout_hi
        bne @middle_loop
        
        ; Decrement outer counter
        dex
        bne @outer_loop
        
        ; Timeout - return with carry clear
        clc
        rts
        
@got_key:
        ; Read the key
        lda ACIA_DATA
        sec                 ; Carry set = success
        rts
.endproc

; Wait for any key
.proc wait_key
        lda #<anykey
        ldx #>anykey
        jsr print_str
        jsr get_key
        jsr print_crlf
        rts
.endproc

; Print 16-bit decimal (A=low, X=high)
.proc print_dec16
        sta temp1
        stx temp1+1
        
        ora temp1+1
        bne @not_zero
        lda #'0'
        jsr CHROUT
        rts
        
@not_zero:
        ldy #0
@div_loop:
        lda temp1
        sta dividend
        lda temp1+1
        sta dividend+1
        lda #10
        sta divisor
        stz divisor+1
        jsr divide16
        
        lda remainder
        pha
        iny
        
        lda quotient
        sta temp1
        lda quotient+1
        sta temp1+1
        ora temp1
        bne @div_loop
        
@print_loop:
        pla
        clc
        adc #'0'
        jsr CHROUT
        dey
        bne @print_loop
        rts
.endproc

; 16-bit division
.proc divide16
        stz remainder
        stz remainder+1
        
        ldx #16
@loop:
        asl dividend
        rol dividend+1
        rol remainder
        rol remainder+1
        
        sec
        lda remainder
        sbc divisor
        sta temp2
        lda remainder+1
        sbc divisor+1
        bcc @no_sub
        
        sta remainder+1
        lda temp2
        sta remainder
        inc dividend
        
@no_sub:
        dex
        bne @loop
        
        lda dividend
        sta quotient
        lda dividend+1
        sta quotient+1
        rts
.endproc

; ========================================
; DATA STRINGS
; ========================================

title_msg:
        .byte $0D, "================================", $0D
        .byte "      LUNAR LANDER", $0D
        .byte "   ASCII Terminal Edition", $0D
        .byte "================================", $0D, $0D, 0

fuel_prompt:
        .byte "SELECT FUEL:", $0D
        .byte " 1) 1500 (hard)", $0D
        .byte " 2) 2000 (normal)", $0D
        .byte " 3) 3000 (easy)", $0D
        .byte "Choice [1-3]: ", 0

intro_msg:
        .byte $0D, "MISSION: Land on the Moon!", $0D
        .byte "Use thrust 0-3 to control descent", $0D
        .byte "Land with velocity < 15 m/s", $0D, $0D, 0

anykey:
        .byte "[Press any key]", 0

; Frame elements (80 chars wide)
border_top:
        .byte "================================================================================", $0D, 0

border_bot:
        .byte "================================================================================", $0D, 0

empty_row:
        .byte "|                                                                              |", $0D, 0

; 2-row lander shape
lander_top_str:
        .byte "|                                      /\\                                      |", $0D, 0

lander_bot_str:
        .byte "|                                     /||\\_                                    |", $0D, 0

lander_row_str:
        .byte "|                                      /\\                                      |", $0D, 0

ground_row:
        .byte "|______________________________________________________________________________|", $0D, 0

landed_row:
        .byte "|_____________________________________/||\\_____________________________________|", $0D, 0

separator:
        .byte "--------------------------------------------------------------------------------", $0D, 0

thrust_prompt:
        .byte " Thrust [0-3]: ", 0

vel_lbl:
        .byte " Final VEL: ", 0

fuel_lbl:
        .byte " Remaining FUEL: ", 0

crash_msg:
        .byte $0D, "*** ALTITUDE NEGATIVE - CRASH! ***", $0D, 0

no_fuel_msg:
        .byte $0D, "*** OUT OF FUEL! ***", $0D, 0

soft_msg:
        .byte $0D, ">>> SOFT LANDING! <<<", $0D, 0

hard_msg:
        .byte $0D, ">>> HARD LANDING - CRASH! <<<", $0D, 0

final_msg:
        .byte $0D, "--- FINAL STATUS ---", $0D, 0

success_msg:
        .byte $0D, "================================", $0D
        .byte "   MISSION SUCCESS!", $0D
        .byte "   The Eagle has landed!", $0D
        .byte "================================", $0D, 0

fail_msg:
        .byte $0D, "================================", $0D
        .byte "   MISSION FAILED", $0D
        .byte "   Better luck next time!", $0D
        .byte "================================", $0D, 0

again_msg:
        .byte $0D, "Play again? (Y/N): ", 0

bye_msg:
        .byte $0D, "Safe travels, astronaut!", $0D, 0
