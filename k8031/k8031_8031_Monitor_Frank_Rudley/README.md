# 8031 Monitor by Frank Rudley

https://www.rudley.com/0003-8031-Assembly-Language-Programming-Intro/0003-8031_Assembly_Language_Programming_Intro.html
https://www.youtube.com/watch?v=rZYkIgfUyfw&ab_channel=FrankRudley

See below for details. 
Something to revisit at some point as I have not quite worked out the functionality of the original board.

```
; MONITORA.ASM - Rev A Started 01/02/94
; MONITORB.ASM - Rev B Started 01/31/21 - Same as MONITORA
```
MONITORB_RS.ASM - Rev B modified for Retroshield 25/12/2024
converted to asm31-sdcc231-pj3 asm 
```
; 8031 System #6
;
; This program helps to develop a Monitor for the 8031 system.
; Runs at 9600 Baud
;
; Allows the reading and writing to internal RAM. (R and W functions).
; Allows you to read and write to ROM stuff. (O and M functions)
; It also displays SFRs. (S funtion)
; It writes 256 byte blocks of ROM. (B Function)
; It write all internal Ram (D Function)
; Allow Upload of HEX file for Monitor Program Devel (H Function)
; Do Checksum between load memory and HEX file (C Function)
; Do a Jump to 0800h to run other programs. (J Function)
; Allow Upload of HEX File for Running at 0800h Memory (E Function)
; Do Checksum between load memory and HEX file at 0800 Mem (K Function)
;
; Give a list of functions (Menu) (N Function)
```
## MONITORB_RS.ASM Comments
- UART timings changed
- ASM 'includes' appended into single file
- RAM ammended to 2000
