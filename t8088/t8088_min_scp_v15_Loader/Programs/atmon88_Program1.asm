; Test Program: "TEST OK" with CRLF then RETF
; Target: 8086 (assembled for 16-bit mode)
; Load address: 0500h

org 0x0500  ; Set the origin to 0500h

start:
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, 'T'     ; Load 'T' into AL
    out dx, al      ; Output 'T' to UART
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, 'E'     ; Load 'E' into AL
    out dx, al      ; Output 'E' to UART
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, 'S'     ; Load 'S' into AL
    out dx, al      ; Output 'S' to UART
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, 'T'     ; Load 'T' into AL
    out dx, al      ; Output 'T' to UART
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, ' '     ; Load space character into AL
    out dx, al      ; Output space to UART
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, 'O'     ; Load 'O' into AL
    out dx, al      ; Output 'O' to UART
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, 'K'     ; Load 'K' into AL
    out dx, al      ; Output 'K' to UART
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, 0x0D    ; Load Carriage Return into AL
    out dx, al      ; Output Carriage Return to UART
    mov dx, 0x00F6  ; Set DX to UART data port address
    mov al, 0x0A    ; Load Line Feed into AL
    out dx, al      ; Output Line Feed to UART
    retf            ; Far return to caller