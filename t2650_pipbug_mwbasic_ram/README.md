# 2650	PipBug and MicroWorld BASIC
The PipBug code has been modified to incorporate delay routines to support Teensy 3.6.
This means removal of the code patch that was in the original t2650_pipbug.ino. See notes for the t2650_serial code.
 
I tried assembling a combined pipbug and BASIC rom. Given the overlap on the RAM and ROM in the memory map it fell into the "too hard to do" category. As a result I modified the teensy code to load MicroWorld BASIC into ram at boot.
The code is located at $0800.
 
 The memory map therefore looks like this.
``` 
ROM
   0000-03FF   PIPBUG in ROM
RAM
   0400-043F   PIPBUG scratch pad RAM
   0440-07FF   available RAM (0500-07FF used by BASIC as scratch pad)
   0800-1FFF   MicroWorld BASIC interpreter in RAM
   2000-5FFF   BASIC source program storage RAM
```
#Sources and Credits
 
## PipBug
```
PIPBUG Firmware for the Signetics 2650
Source code written by Signetics taken from
Signetics 2650 microprocessor application memo SS50
Uses some code transcription of the original 
SS50 listing from Jim's repo
https://github.com/jim11662418/Signetics-2650-SBC
```
PIPBUG has been modified as follows:

- the serial i/o delays modified by AdamT117 (kayto@github)to get the timing working for Teensy 3.6

## MicroWorld BASIC

Source code files are not available. 
```
MicroWorld BASIC Interpeter for the 2650
Written by Ian Binnie.
Copyright MicroWorld, 1979
Binary downloaded from Jim's repo
https://github.com/jim11662418/Signetics-2650-SBC
```

