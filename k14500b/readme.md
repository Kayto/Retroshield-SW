## Repository Overview

This repository contains code development for the Retroshield k14500B. It is intended to supplement the existing project.

## Credits

Special thanks to [8bitforce](https://8bitforce.com) for the amazing hardware and supporting code.

## Folder Contents

* `k14500_basic_io_1`: Basic I/O Operations for k14500B.
* `k14500_basic_io_2`: Latch an LED State with On/Off

- These ROMs are selectable in the `memorymap.h` for the `k14500b_introduction.ino` within
```
// Define which ROM to use: 1 for k14500_basic_io_1, 2 for k14500_basic_io_2
#define SELECT_ROM_VERSION  1  // Change to 2 for k14500_basic_io_2
```
## Prerequisites

### k14500B.ino

Grab the latest k14500B repo from [8bitforce](https://8bitforce.com).

The k14500B `.ino` file provides firmware for the RetroShield 14500, designed to run on the Arduino Mega board. The firmware includes support for various peripheral requirements.

#### File Descriptions

The projects in this repo generally retain the existing `.ino` and `.h` files unmodified. The projects are modifications to the ROM which is contained in `memorymap.h`. So really the only changes are in this file. Where changes are needed to any other files they will be included in this repo.

* `retroshell.h`: Correction to the assembler to remove the hardcoded operand 0x00 for IEN and OEN. For IEN (0xA) and OEN (0xB), the hardcode is now to 8. This ensures that RR is linked to IN0 / OUT0.
* `system.inc`: Addresses beyond $0F are masked to low 4 bits ($00-$0F). Compilation failed using the runtime check, so has been removed. Ensure targets are within $00-$0F manually.
```
.macro __lit_instr op, addr
    .if (addr > $0F)
        .error "Address overflow"
```
### CC65 Compiler and SRecord

This project uses the CC65 compiler suite for assembling and linking, and SRecord for creating ROM arrays.

* Obtain CC65 from [CC65 GitHub](https://github.com/cc65/cc65).
* Obtain SRecord from [SRecord Download](http://srecord.sourceforge.net/).

## Usage

### Compilation of Source Files

To compile the source files, use the provided `mybuild.bat` script. This script automates the assembly, linking, and conversion of binary files into C arrays.

1. Place your `.s` source files in the `code` directory.
2. Run the `mybuild.bat` script:

``` sh
mybuild.bat
```

The script will:

* Assemble the `.s` files using `ca65.exe`.
* Link the object files using `ld65.exe` with the `system.cfg` configuration.
* Convert the resulting binary files into C arrays using `srec_cat.exe`.

### Adding ROM to `.ino` Project

Prepared ROM images should be placed within the `memorymap.h` file contained within:

``` cpp
PROGMEM const unsigned char rom_bin[] = {

};
```


### License

This project is licensed under the MIT License. See the LICENSE file for details.