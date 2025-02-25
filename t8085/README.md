# Retroshield t8085
 8K BASIC, TinyBASIC and simple serial echo routine.

## Credits

Special thanks to [8bitforce](https://8bitforce.com) for the amazing hardware and supporting code.

## Repo Folder Contents

- `t8085_8kbasic`: IMSAI 8k BASIC ROM.
- `t8085_tinybasic`: TinyBASIC ROM.
- `t8085_serial`:  Simple serial echo example.

## Prerequisites

### t8085.ino

Grab the latest t2650 repo from [8bitforce](https://8bitforce.com).

The t8085 `.ino` file provides firmware for the RetroShield 8085, designed to run on the Teensy. The firmware includes support for various peripherals and memory configurations.

#### File Descriptions

The projects in this repo generally intend to retain the existing `.ino` structure unmodified. The projects are therefore primarily modifications to the ROM array which is contained in the `memorymap.h`. However additional changes are sometimes present but only to add instructions, credits, titles and sometimes debugging.

- `.ino`: Overall firmware. 
- `memorymap.h`: Defines the ROM.
- `.h`: All other files (terminal, buttons, portmap, setuphold remain unchanged).

### Macro Assembler AS V1.42

Obtain a standalone executable of Macro Assembler AS V1.42:
- [Macro Assembler AS V1.42](http://john.ccac.rwth-aachen.de:8000/as/download.html#WIN32)

### SRecord (to create ROM array)

Obtain SRecord from the following link:
- [SRecord Download](http://srecord.sourceforge.net/)

## Usage

### Compilation of Source files (Windows)

To compile ASM files to 8085 using Macro Assembler AS V1.42, use the following command line example (remember to update the path to ASL):
```sh
asl.exe -L -cpu 8085 test_usart_echo.asm
```
- `-L`: Generates listing file.
- `-cpu 8085`: Specifies the target processor as 8085.

The output defaults to `.p`. This binary then needs conversion to an Intel HEX file. `p2hex` is provided as part of the Macro Assembler AS V1.42 package.
```sh
p2hex.exe -F intel test_usart_echo.p
```

### Preparing ROM Array

To compile the assembled output into an array, use the following command line (remember to update the path to srecord):
```sh
srecord\bin\srec_cat.exe test_usart_echo.hex -intel -o test_usart_echo.c -C-Array rom_bin
```
- `-intel`: Specifies the input file format as Intel HEX.
- `-o test_usart_echo.c`: Specifies the output file name as `test_usart_echo.c`.
- `-C-Array rom_bin`: Specifies the output format as a C array with the name `rom_bin`.

### Adding ROM to `.ino` project

Prepared ROM images should be placed within the `memorymap.h` file contained within :
```cpp
....unsigned char rom_bin[] = {
};
```
A tool `replace_array.py` is provided to automate this.

#### Using `replace_array.py`

To use the `replace_array.py` script to automate the replacement of the ROM array in `memorymap.h`, follow these steps:

1. Ensure that the `.c` file containing the new ROM array and the `memorymap.h` file is in the same directory as the script.
2. Run the script using Python:
```sh
python replace_array.py
```
The script will extract the array from `.c` and replace the existing array in `memorymap.h`.

### License

This project is licensed under the MIT License. See the LICENSE file for details.

