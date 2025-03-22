;
; Filename: k14500_basic_io_2.s
; Title: Latch an LED State with On/Off
; Date: 17/03/2025
;
; This program demonstrates basic I/O operations for the k14500B.
; It includes an example of latching LED states.
; The code is designed to run on the RetroShield k14500B platform.
;
; 
;### Latch an LED State with On/Off
; 
; ORC  RR           ; Perform OR complement on RR.
; (Typically initializes RR to 1 since RR = !(D_IN & IEN))
; IEN  RR           ; Load the Input Enable register with RR (sets IEN = 1).
; OEN  RR           ; Load the Output Enable register with RR (sets OEN = 1).
; ORC  RR           ; Repeat ORC to further stabilize RR.
; ANDC RR           ; Perform AND complement on RR (may clear unwanted bits).
; STO  MEM0         ; Store the current RR value into memory location 0 (latching LED state).
; STO  MEM1         ; Also store RR into MEM1 for later reference.
; JMP  loop         ; Jump to the 'loop' label to start the main routine.
;
; no_toggle:   (Routine to update an alternate output without toggling)
; LD   IN4          ; Load the state of input IN4 into RR.
; STO  MEM1         ; Store this state into MEM1.
; LD   MEM0         ; Load the current latched LED state from MEM0 into RR.
; STO  OUT4         ; Update output OUT4 with the state from MEM0.
; JMP  loop         ; Jump back to the main loop.
;
; loop:        (Main routine for monitoring and toggling the LED latch)
; LD   IN4           ; Load the state of input IN4 into RR.
; SKZ               ; Skip next instruction if RR = 0 (i.e. if IN4 is not pressed).
; JMP  no_toggle    ; If IN4 is pressed, branch to the no_toggle routine.
; XNOR MEM1         ; Exclusive NOR: Compare RR with MEM1.
; (Result: RR becomes 1 if IN4’s current state equals MEM1; used for edge detection)
; SKZ               ; Skip next instruction if RR = 0 (no rising edge detected).
; JMP  no_toggle    ; If no edge detected, branch to no_toggle.
; LD   MEM0         ; Load the current latched LED state from MEM0 into RR.
; LDC  MEM0         ; Load the complement of MEM0 into RR (toggle the latched state).
; STO  MEM0         ; Store the toggled state back into MEM0.
; JMP  no_toggle    ; Jump to no_toggle to update outputs accordingly.
;
; *Effect: When button IN1 is pressed, its state is combined (ORed) with the latched state
;         in MEM0 so that LED OUT1 is turned on and remains on (latched). When button IN5
;         is pressed, the latched state is cleared (via an AND complement operation),
;         turning LED OUT1 off.

.include "system.inc"

.segment "CODE"
    .org $00

    orc  RR             ; $00: OR complement RR (initialize RR to 1).
    ien  RR             ; $01: Enable input (set IEN = 1).
    oen  RR             ; $02: Enable output (set OEN = 1).
    jmp  loop           ; $03: Jump to the main loop.

no_toggle:
    ld   IN4            ; $04: Load input IN4 state into RR.
    sto  MEM1           ; $05: Save input state to MEM1.
    ld   MEM0           ; $06: Load latched LED state from MEM0 into RR.
    sto  OUT4           ; $07: Update OUT4 with latched LED state.
    jmp  loop           ; $08: Return to main loop.

loop:
    ld   IN4            ; $09: Load input IN4 state into RR.
    skz                 ; $0A: Skip next instruction if RR = 0 (button not pressed).
    jmp  no_toggle      ; $0B: Jump to no_toggle if button is pressed.
    xnor MEM1           ; $0C: Compare RR with MEM1 (detect rising edge).
    skz                 ; $0D: Skip next instruction if no rising edge detected.
    jmp  no_toggle      ; $0E: Jump to no_toggle if no edge detected.
    ld   MEM0           ; $0F: Load latched LED state from MEM0 into RR.
    ldc  MEM0           ; $10: Load complement of MEM0 into RR (toggle state).
    sto  MEM0           ; $11: Save toggled state back to MEM0.
    jmp  no_toggle      ; $12: Jump to no_toggle to update outputs.


