# 2650	Serial Echo
 Serial Echo code modified to incorporate delay routines to support Teensy 3.6.
 
 Adding an extra nop within dlay (bdly) proved more stable.
 
 
# Notes

## Delay Modifications required to original pipbug ROM
```
// Modify DLAY and DLY subroutines to count down to 0x20 and 0x05
rom_bin[0x02A9 - 0x0000] = 0x04;    // LODI,R0 H'20'
rom_bin[0x02AA - 0x0000] = 0x20;

rom_bin[0x02AD - 0x0000] = 0xC0;    // NOP
rom_bin[0x02AE - 0x0000] = 0xC0;    // NOP

rom_bin[0x02AF - 0x0000] = 0x04;    // LODI,R0 H'05'
rom_bin[0x02B0 - 0x0000] = 0x05; 
```

## 2650 Original SS50 PIPBUG delays
```
02A8	20		DLAY	eorz	R0
02A9	F8 7E			bdrr,R0	$
02AB	F8 7E			bdrr,R0	$	
02AD	F8 7E		DLY	bdrr,R0	$
02AF	04 E5			lodi,R0	H'E5'
02B1	F8 7E			bdrr,R0	$
02B3	17			retc,un
```
## Modified Code as a result of ROM patch
```
02A8	20		DLAY	eorz	R0			6cp
02A9	04 20			lodi,R0	H'20'		
02AB	F8 7E			bdrr,R0	$			9cp
02AD	C0			NOP				6cp
02AE	C0			NOP				6cp
02AF	04 05		DLY	lodi,R0	H'05'			9cp		
02B1	F8 7E			bdrr,R0	$			9cp
02B3	17			retc,un
```
