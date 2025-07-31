# Retroshield 65c02
 Some simple routines, monitors and BASIC.

## Credits

Special thanks to [8bitforce](https://8bitforce.com) for the amazing hardware and supporting code.

## Repo Folder Contents

- `t65c02t_6551acia_EhBASIC`: Implements a 6551 ACIA emulation to run a version of EhBASIC by Lee Davidson.

## Prerequisites

### t65c02.ino

Grab the latest t65c02 repo from [8bitforce](https://gitlab.com/8bitforce).

The t65c02 `.ino` file provides firmware for the RetroShield 65c02, designed to run on the Arduino Mega. The firmware includes support for various peripherals and memory configurations.

#### File Descriptions

The projects in this repo generally intend to retain the existing `.ino` structure unmodified. The projects are therefore primarily modifications to the ROM array which is contained in the `memorymap.h`. However additional changes are present to add instructions, credits, titles and sometimes debugging.

- `.ino`: Overall firmware. 
- `memorymap.h`: contains the ROM arrays.
- `6551.h`: Defines the 6551 ACIA for i/o.

### Compiler

To document

### SRecord (to create ROM array)

Obtain SRecord from the following link:
- [SRecord Download](http://srecord.sourceforge.net/)

## Usage
 To document
### Compilation of Source files (Windows)

To document

### Preparing ROM Array

To document

### Adding ROM to `.ino` project

To document

### License

This project is licensed under the MIT License. See the relevant LICENSE file for specfic details relating to individual ROMs.

