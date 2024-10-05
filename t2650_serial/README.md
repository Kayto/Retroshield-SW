# 2650 in progress
 Working on isolating the serial comms routines to provide a simple echo routine.
 From that attempt to modify mwbasic.
 
# Notes

## Modifications to original pipbug

// Modify DLAY and DLY subroutines to count downto 0x20 and 0x05.
rom_bin[0x02A9 - 0x0000] = 0x04;    // LODI,R0 H'20'
rom_bin[0x02AA - 0x0000] = 0x20;

rom_bin[0x02AD - 0x0000] = 0xC0;    // NOP
rom_bin[0x02AE - 0x0000] = 0xC0;    // NOP

rom_bin[0x02AF - 0x0000] = 0x04;    // LODI,R0 H'05'
rom_bin[0x02B0 - 0x0000] = 0x05;

## Original pipbug code disassembly
029C			L029C:
029C : 61		iorz	r1
029D : C1		strz	r1
029E : FA 76	bdrr,r2	L0296
02A0 : 3B 06	bstr,un	L02A8
02A2 : 45 7F	andi,r1	H'7F'
02A4 : 01		lodz	r1
02A5 : 75 18	cpsl	H'18'
02A7 : 17		retc,un
;
02A8			L02A8:
02A8 : 20		eorz	r0
02A9			L02A9:

02A9 : F8 7E	bdrr,r0	L02A9
02AB			L02AB:
02AB : F8 7E	bdrr,r0	L02AB
02AD			L02AD:

02AD : F8 7E	bdrr,r0	L02AD
02AF : 04 E5	lodi,r0	H'E5'
02B1			L02B1:
02B1 : F8 7E	bdrr,r0	L02B1
02B3 : 17		retc,un
;