; Test Program for S Command (Single-Step Test)
; Target: 8086 (assembled for 16-bit mode)
; Load Address: 0500h
; 
; This program initializes registers with known values and then enters a loop
; that increments DI, BX, CX, and DX until DI reaches 0005h. You can use the S 
; command to single-step through the instructions and watch the registers change.
; After the loop finishes, the program executes a RETF to return control to the monitor.

org     0500h

start:
        ; Initialize registers to known values
        mov     ax, 0001h       ; AX = 0001h
        mov     bx, 0002h       ; BX = 0002h
        mov     cx, 0003h       ; CX = 0003h
        mov     dx, 0004h       ; DX = 0004h

single_step_loop:
        ; Increment registers to test single stepping
        inc     ax            ; DI = DI + 1
        inc     bx            ; BX = BX + 1
        inc     cx            ; CX = CX + 1
        inc     dx            ; DX = DX + 1

        ; (Optional: output a marker character so you know the loop executed)
        ; mov     dx, 0F600h    ; Use the monitor’s serial port address
        ; mov     al, '*'       ; Marker character
        ; out     dx, al

        cmp     ax, 0005h     ; Compare AX to 0005h
        jne     single_step_loop

        ; When AX reaches 0005h, exit by returning to the monitor
        retf                  ; Far return

; End of Test Program
