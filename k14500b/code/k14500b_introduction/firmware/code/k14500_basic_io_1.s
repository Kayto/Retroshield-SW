;
; Filename: k14500_basic_io_1.s
; Title: Basic I/O Operations for k14500B
; Date: 17/03/2025
;
; This program demonstrates basic I/O operations for the k14500B.
; It includes examples of reading button states, controlling LEDs,
; inverting button states, conditional LED control, and latching LED states.
; The code is designed to run on the RetroShield k14500B platform.
;

.include "system.inc"

.segment "CODE"
    .org $00
; init
    orc  RR             ; $00
    ien  RR             ; $01
    oen  RR             ; $02

loop:
; read button and write to LED
    ld   IN1            ; $0D
    sto  OUT1           ; $0E
; invert button state to LED
    ldc  IN2            ; $0F
    sto  OUT2           ; $10
; conditional LED control
    ld   IN3            ; $11
    skz                 ; $12
    sto  OUT3           ; $13
; latch an LED state with on - no_toggle routine
    ld   IN4            ; $14
    or   MEM0           ; $15   
    sto  MEM0           ; $16
    sto  OUT4           ; $17

    jmp  loop           ; $18



