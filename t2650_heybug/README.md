# 2650	HeyBug
HEYBUG Firmware for the Signetics 2650

My working attempt at providing a HYBUG type firmware.
HyBUG was a modification of PIPBUG which added additional utility routines in high memory. My version is an attempt to add the most useful routines into the existing pipbug monitor.

Note that the delay routines have been modified to get the serial i/o timing working for the Teensy 3.6 Retroshield.
## Current status

PIPBUG remains as is.
The following Utility Routines are working;
- Find Hex String    	Faaaa bbbb xxyy
- Hex List           	Haaaa bbbb
- Move             	Maaaa bbbb cccc
- Find Hex        Xaaaa bbbb xx

# Sources and Credits
 
## PipBug & HyBug
```
; //=======================================================
; //> HEYBUG Firmware for the Signetics 2650
; //>
; //> PIPBUG Source code written by Signetics taken from
; //> Signetics 2650 microprocessor application memo SS50
; //
; //> Uses some code transcription of the original 
; //> SS50 listing from Jim's repo
; //> https://github.com/jim11662418/Signetics-2650-SBC
; //>
; //> and code from;
; //>
; //> HYBUG
; //> : written by Brian L Young in 1979
; //> 
; //> Published article by Amateur Radio Action
; //> Volume 2 No. 13, Australia. 1979"
; //>
; //> Hybug BIOS as incorporated into Winarcadia 33.3
; //> by James Jacobs from
; //> http://amigan.1emu.net/releases/
; //=======================================================
```

