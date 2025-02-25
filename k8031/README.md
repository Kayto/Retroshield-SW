# Retroshield 8031
 Some simple routines and a new monitor.

## Credits

Special thanks to [8bitforce](https://8bitforce.com) for the amazing hardware and supporting code.

## Repo Folder Contents

- `k8031_8031_AT_Mon`: Monitor Program for the 8031 Microcontroller. It is based on the Monitor Program by Frank Rudley and is modified to work with the Retroshield.
- `k8031_8031_Monitor_Frank_Rudley`:  Monitor Program by Frank Rudley modified to work with the Retroshield and source converted to as31 syntax.
- `k8031_hello_world`:  Hello World example, asm31 syntax.
- `k8031_serial_echo`:  Serial Echo example, various development versions, as31 syntax.
- `ESD8031.pdf`: 8031 reference guide.

## Prerequisites

### k8031.ino

Grab the latest k8031 repo from [8bitforce](https://gitlab.com/8bitforce).

The k8031 `.ino` file provides firmware for the RetroShield 8031, designed to run on the Arduino Mega. The firmware includes support for various peripherals and memory configurations.

#### File Descriptions

The projects in this repo generally intend to retain the existing `.ino` structure unmodified. The projects are therefore primarily modifications to the ROM array which is contained in the `.ino`. However additional changes are present to add instructions, credits, titles and sometimes debugging.

- `.ino`: Overall firmware. ROM arrays are the variable.
- `pins2_arduino.h`: Defines the pin mappings. UNCHANGED from original.

### ASM31 Compiler

Obtain a standalone executable of AS31:
- [AS31](https://www.pjrc.com/tech/8051/tools/as31-doc.html)

### SRecord (to create ROM array)

Obtain SRecord from the following link:
- [SRecord Download](http://srecord.sourceforge.net/)

## Usage

### Compilation of Source files (Windows)

To compile ASM files to 8031 using AS31, use the following command line (remember to update the path to ASM31):
```sh
as31.exe -l -F 8031_hello_world.asm
```
- `-l`: Generates a listing file output.
- `-F`: output file format, default `.hex`.

### Preparing ROM Array

To compile the assembled output into an array, use the following command line (remember to update the path to srecord):
```sh
srecord\bin\srec_cat.exe 8031_hello_world.hex -intel -o 8031_hello_world.c -C-Array rom_bin
```
- `-intel`: Specifies the input file format as Intel HEX.
- `-o 8031_hello_world.c`: Specifies the output file name as `8031_hello_world.c`.
- `-C-Array rom_bin`: Specifies the output format as a C array with the name `rom_bin`.

### Adding ROM to `.ino` project

Prepared ROM images should be placed within the `.ino` file contained within:
```cpp
PROGMEM const unsigned char rom_bin[] = {

};
```
A tool `replace_array.py` is provided to automate this.

#### Using `replace_array.py`

To use the `replace_array.py` script to automate the replacement of the ROM array in `.ino`, follow these steps:

1. Ensure that the `.c` file containing the new ROM array and the `.ino` file is in the same directory as the script.
2. Run the script using Python:
```sh
python replace_array.py
```
The script will extract the array from `.c` and replace the existing array in `.ino`.

### License

This project is licensed under the MIT License. See the LICENSE file for details.

