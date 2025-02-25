# Retroshield t2650
 BASIC addition, a new monitor and simple serial echo routine.

## Credits

Special thanks to [8bitforce](https://8bitforce.com) for the amazing hardware and supporting code.

## Repo Folder Contents

- `t2650_heybug`: A new Monitor Program for the 8031 Microcontroller retroshield. It is based on a combination of PIPBUG and HYBUG routines.
- `t2650_pipbug_mwbasic_ram`: The addition of mwbasic to the pip bug monitor.
- `t2650_serial`:  Simple serial echo example.


## Prerequisites

### t2650.ino

Grab the latest t2650 repo from [8bitforce](https://8bitforce.com).

The t2650 `.ino` file provides firmware for the RetroShield 2650, designed to run on the Teensy. The firmware includes support for various peripherals and memory configurations.

#### File Descriptions

The `t2650_heybug` and `t2650_pipbug_mwbasic_ram` projects in this repo ammend the existing `.ino` structure. This is primarily to split the ROM array from the existing `.ino` into a dedicated `.h` file. However additional changes are also present to add instructions, credits, titles and sometimes debugging.

- `.ino`: Overall firmware. ROM arrays are the variable or in the instances noted above split out into sperate files.
- `t2650_heybug.h`: The heybug ROM split from the `.ino`.
- `t2650_mwbasic_ram.h`: The MWBASIC ROM split from the `.ino`.
- `t2650_pipbug_rom.h`: The PIPBUG ROM split from the `.ino`.

### VACS Compiler

Obtain a standalone executable of VACS:
- [VACS 1.24j/w32 - Signetics 2650 family assembler](https://github.com/Dennis1000/VACS)

### SRecord (to create ROM array)

Obtain SRecord from the following link:
- [SRecord Download](http://srecord.sourceforge.net/)

## Usage

### Compilation of Source files (Windows)

To compile ASM files to 2650 using VACS 1.24j/w32, use the following command line example (remember to update the path to ASM32):
```sh
asm32.exe

Give source filespec: serial-echo.asm
Give object filespec [NUL]: serial-echo
Give list   filespec [NUL]: serial-echo
Give options [qerd[c[,:;-.]]ismtnpv1..9] or <CR>: Just <CR>
```

### Preparing ROM Array

To compile the assembled output into an array, use the following command line (remember to update the path to srecord):
```sh
srecord\bin\srec_cat.exe serial-echo.hex -intel -o serial-echo.c -C-Array rom_bin
```
- `-intel`: Specifies the input file format as Intel HEX.
- `-o serial-echo.c`: Specifies the output file name as `serial-echo.c`.
- `-C-Array rom_bin`: Specifies the output format as a C array with the name `rom_bin`.

### Adding ROM to `.ino` project

Prepared ROM images should be placed within the `.ino` or `.h` files as described above and contained within one of the following:
```cpp
....unsigned char rom_bin[] = {
};
```
or
```cpp
unsigned char heybug_bin[] = {
};
```
or
```cpp
unsigned char ram_bin[] = {
};
```
or
```cpp
unsigned char rom_bin[] = {
};
```

### License

This project is licensed under the MIT License. See the LICENSE file for details.

