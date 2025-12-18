# Retroshield 65c02
 Some simple routines, monitors and BASIC.

## Credits

Special thanks to [8bitforce](https://8bitforce.com) for the amazing hardware and supporting code.

## Repo Folder Contents

- `t65c02_6551_6522_smon`: Implements SMON monitor with software-emulated 6551 ACIA and 6522 VIA. Provides a full-featured machine language monitor with trace capabilities over USB serial.
- `t65c02t_6551acia_EhBASIC`: Implements a 6551 ACIA emulation to run a version of EhBASIC by Lee Davidson.

## Prerequisites

### t65c02.ino

The t65c02 `.ino` file provides firmware for the RetroShield 65c02, designed to run on the Arduino Mega. The firmware includes support for various peripherals and memory configurations.

#### File Descriptions

The projects in this repo generally intend to retain the existing `.ino` structure unmodified. The projects are therefore primarily modifications to the ROM array which is contained in the `memorymap.h`. However additional changes are present to add additional preipherals, instructions, credits, titles and sometimes debugging.

- `.ino`: Overall firmware. 
- `memorymap.h`: contains the ROM arrays.
- `6551.h`: Defines the 6551 ACIA for i/o.
- `6522.h`: Defines the 6522 VIA for SMON trace functions.

### Compiler

#### CC65 Toolchain (Recommended)

The **cc65 toolchain** is used for assembling and linking 6502 assembly code. It includes:
- **ca65**: The 6502 assembler
- **ld65**: The linker
- **make**: Build automation

**Option 1: Docker (Recommended)**

The easiest approach is using Docker with a pre-built cc65 environment:
```cmd
docker run --rm -v%CD%:/mnt/project dawidbuchwald/cc65-tools-make all
```

This Docker image (`dawidbuchwald/cc65-tools-make`) includes all necessary build tools and is especially convenient for Windows environments.

**Option 2: Native Installation**

Download and install cc65 from:
- [CC65 Compiler Suite](https://cc65.github.io/)

After installation, ensure `ca65` and `ld65` are in your PATH.

### Python Tools (Included)

The `tools/` directory contains Python utilities for binary conversion:
- **bin2array.py**: Converts binary files to C array format for inclusion in `.ino` projects
- **bin2hex.py**: Converts binary files to Intel HEX format
- **create_array.bat**: Windows batch script that automates the conversion process

**Usage:**
```cmd
python tools\bin2array.py <input.bin> <output.c> <array_name> <start_address>
```

Example:
```cmd
python tools\bin2array.py build\rom.bin build\rom_array.c rom_bin 0xE000
```

## Usage

### Compilation of Source files (Windows)

#### Using Docker (Recommended)

From the project root directory:
```cmd
REM Build all firmware
docker run --rm -v%CD%:/mnt/project dawidbuchwald/cc65-tools-make all

REM Clean build artifacts
docker run --rm -v%CD%:/mnt/project dawidbuchwald/cc65-tools-make clean
```

#### Using Native cc65

If you have cc65 installed locally:
```cmd
REM Navigate to firmware directory
cd firmware\SMON_E000

REM Build
make all

REM Clean
make clean
```

**Output:** Binary ROM image will be created in `build/` directory (e.g., `SMON_E000.bin`)

### Preparing ROM Array

#### Option 1: Using Python Script Directly

Convert the binary ROM to a C array:
```cmd
python tools\bin2array.py firmware\SMON_E000\build\SMON_E000.bin ^^
       memorymap.h rom_bin 0xE000
```

#### Option 2: Automated Batch Script (Recommended)

Use the provided batch script (combines build and conversion):
```cmd
cd t65c02_6551_6522_smon
tools\create_array.bat
```

### Adding ROM to `.ino` project

1. **Build the ROM** using one of the methods above
2. **Generate C array** - the `memorymap.h` file will be created/updated
3. **Copy to Arduino project** (if needed) - the build process typically updates the file in place
4. **Compile and upload** the `.ino` project using Arduino IDE or PlatformIO
5. **Connect via serial** at 115200 baud to interact with the monitor


### License

This project is licensed under the MIT License. See the relevant LICENSE file for specfic details relating to individual ROMs.

