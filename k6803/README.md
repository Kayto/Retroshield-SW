# Retroshield 6803
 Some simple routines, nothing too complex but helpful to get things going.
 Code is not very optimised so feel free to tinker.
 It took me a long time to get serial i/o working so there are various serial routines.
 "simple_serial_io_test.asm" seems to be the best working example at the moment.
 
## k6803_serial_echo_backspace a.k.a. 'a cry for help'

 This code led me down a bit of a rabbit hole of debugging. I still fail to get the EXIT message working without a hack.
 I spent some time developing the Arduino code to look at potential 'hardware' related problems, so this .ino has some serialDEBUG options as well as some additional TDRE checks.
 After all that, I still couldnt fix it.
 
 If anyone cares to take a look, then it would be great to know where I am going wrong.
 
 The issue is that the string output routine misses the leading 'E' of the message. All other messages and routines seem to work ok.
 
## MONITOR ROMS
 There are a number of existing ROMs available such as MIKBUG, MINIBUG but not offering much over the BILLBUG rom. I may create a custom monitor at some point but thats a longer term plan.
## COOKBOOK routines
 I have made a start on collating more useful routines from the book 6800_Software_Gourmet_Guide_and_Cookbook_1976_Robert_Findley.
 These are currently roughly transcribed from OCR so contain some errors. 

## Credits

Special thanks to [8bitforce](https://8bitforce.com) for the amazing hardware and supporting code.

## Repo Folder Contents

- `k6803_0_99_Counter_Delay`: Simple counter with delay.
- `k6803_10M_Counter_Delay` : Simple counter with delay.
- `k6803_hello_world`: Hello World example.
- `k6803_serial`: Simple serial echo routine.
- `k6803_serial_echo_backspace`: Development of the simple serial echo routine with backspace handling.
- `k6803_serial_echo_prompt`: Development of the serial echo backspace routine with prompt.
- `cookbook.asm`: work in progress - useful code routines.

## Prerequisites

### k6803.ino

Grab the latest k6803 repo from [8bitforce](https://gitlab.com/8bitforce).

The k6803 `.ino` file provides firmware for the RetroShield 6803, designed to run on the Arduino Mega. The firmware includes support for various peripherals and memory configurations.

#### File Descriptions

The projects in this repo generally intend to retain the existing `.ino` structure unmodified. The projects are therefore primarily modifications to the ROM array which is contained in the `.ino`. However additional changes are present to add instructions, credits, titles and sometimes debugging.

- `.ino`: Overall firmware. ROM arrays are the variable.
- `pins2_arduino.h`: Defines the pin mappings. UNCHANGED from original.

### A68 Compiler

Obtain a standalone executable of A68:
- [A68](https://www.retrotechnology.com/restore/a68.html)

### SRecord (to create ROM array)

Obtain SRecord from the following link:
- [SRecord Download](http://srecord.sourceforge.net/)

## Usage

### Compilation of Source files (Windows)

To compile ASM files to 6803 using A68, use the following command line (remember to update the path to A68):
```sh
a68.exe 6800_hello_world.asm -l 6800_hello_world.lst -o 6800_hello_world.hex
```
- `-l`: Specifies the listing file output.
- `-o`: Specifies the output file name as `6800_hello_world.hex`.

### Preparing ROM Array

To compile the assembled output into an array, use the following command line (remember to update the path to srecord):
```sh
srecord\bin\srec_cat.exe 6800_hello_world.hex -intel -o 6800_hello_world.c -C-Array rom_bin
```
- `-intel`: Specifies the input file format as Intel HEX.
- `-o 6800_hello_world.c`: Specifies the output file name as `6800_hello_world.c`.
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

