## Repository Overview

This repository contains code development for the Retroshield t8088. It is intended to provide supplementary ROMs for the existing project. This repo therefore only contains ROMs, not development or updates to the original code base. Please ensure that you check the original author's repo for the latest firmware.

## Credits

Special thanks to [8bitforce](https://8bitforce.com) for the amazing hardware and supporting code.

### Folder Structure

- `t8088_min_scp_v15`: Seattle Computer Products 8086 Monitor version 1.5  3-19-82 by Tim Paterson. Listing, hex and bin code.
- `t8088_hello_world`: Simple hello world to isolate serial routines.
- `t8088_serial_echo`: Simple serial echo to isolate serial i/o routines.
- `t8088_min_scp_v15_Loader`: Seattle Computer Products 8086 Monitor version 1.5  3-19-82 by Tim Paterson. I have added in an Intel HEX Loader so that user programs can be uploaded into memory. A Programs folder contains some example programs.

## Prerequisites

### t8088.ino

Grab the latest t8088 repo from [8bitforce](https://8bitforce.com).

The t8088 `.ino` file provides firmware for the RetroShield 80C88, designed to run on Teensy 3.5, 3.6, and 4.1 boards. The firmware includes support for various peripherals and memory configurations.

#### File Descriptions

- `memorymap.h`: Defines the memory map for ROM, RAM, and peripherals.
- `portmap.h`: Defines the pin mappings for the CPU.
- `setuphold.h`: Contains delay definitions to meet setup/hold times.
- `buttons.h`: Functions to read buttons on the Teensy adapter board.
- `i8251.h`: Definitions for the 8251 UART.

The projects in this repo generally retain the existing `.ino` and `.h` files unmodified. The projects are modifications to the ROM which is contained in `memorymap.h`. So really the only changes are in this file. Where changes are needed to any other files they will be included in this repo.

### NASM Compiler

Obtain a standalone win32 executable of NASM and place it in the `comp` folder:
- [NASM Release Builds](https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/)
- [Win32 NASM Executable](https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win32/)

### SRecord (to create ROM array)

Obtain SRecord from the following link and place it in the `comp` folder:
- [SRecord Download](http://srecord.sourceforge.net/)

## Usage

### Compilation of Source files (Windows)

To compile ASM files to 8088 using NASM, use the following command line (remember to update the path to NASM):
```sh
nasm.exe -l 8088_hello_world.lst -f bin -o 8088_hello_world.bin 8088_hello_world.asm
```
- `l`: Generates a listing file.
- `-f bin`: Specifies the output format as a flat binary file.
- `-o 8088_hello_world.bin`: Specifies the output file name as `8088_hello_world.bin`.

Not sure why but I like to generate a BIN and HEX. The HEX is a more standardized way to ultimately generate the C-Array that's required.
To generate Intel HEX output using NASM, use the following command line:
```sh
nasm.exe -f ith -o 8088_hello_world.hex 8088_hello_world.asm
```
- `-f ith`: Specifies the output format as Intel HEX.
- `-o 8088_hello_world.hex`: Specifies the output file name as `8088_hello_world.hex`.

### Preparing ROM Array

To compile the assembled output into an array, use the following command line (remember to update the path to srecord):
```sh
srecord\bin\srec_cat.exe 8088_hello_world.hex -intel -o 8088_hello_world.c -C-Array rom_bin
```
- `-intel`: Specifies the input file format as Intel HEX.
- `-o 8088_hello_world.c`: Specifies the output file name as `8088_hello_world.c`.
- `-C-Array rom_bin`: Specifies the output format as a C array with the name `rom_bin`.

### Adding ROM to `.ino` project

Prepared ROM images should be placed within the `memorymap.h` file contained within:
```cpp
PROGMEM const unsigned char rom_bin[] = {

};
```
A tool `replace_array.py` is provided to automate this.

#### Using `replace_array.py`

To use the `replace_array.py` script to automate the replacement of the ROM array in `memorymap.h`, follow these steps:

1. Ensure that the `.c` file containing the new ROM array is in the same directory as the script.
2. Run the script using Python:
```sh
python replace_array.py
```
The script will extract the array from `.c` and replace the existing array in `memorymap.h`.

### License

This project is licensed under the MIT License. See the LICENSE file for details.

