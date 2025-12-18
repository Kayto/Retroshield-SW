# SMON_E000 - SMON Monitor ROM for RetroShield 6502

This is the SMON monitor ROM source for the **Teensy 4.1 RetroShield 6502** implementation.

## Purpose

This directory contains the 6502 assembly source that gets compiled into an 8KB ROM binary and converted to a C array for inclusion in the Teensy 4.1 firmware. The build process automatically updates `memorymap.h` in the Teensy project.

See [CHANGES.md](CHANGES.md) for detailed modifications from the original SMON.

## Memory Map

| Address Range | Usage | Size |
|--------------|-------|------|
| $E000-$FF80 | SMON ROM | ~8K |
| $FF81-$FFF9 | Jump table | 121 bytes |
| $FFFA-$FFFF | Vectors | 6 bytes |

**Filler:** $8000-$DFFF filled with $EA (NOP)

## Building

### From VS Code (Recommended - Using Docker)

**Why Docker?** I generally use Dawid Buchwald's prebuilt `dawidbuchwald/cc65-tools-make` Docker image which includes all necessary build tools (ca65, ld65, make). This is especially convenient for Windows environments where installing native 6502 development tools can be challenging.


### Manual Build (Command Line with Docker)

```cmd
REM From workspace root:
docker run --rm -v%CD%:/mnt/project dawidbuchwald/cc65-tools-make all
```

Output: `build/rom/SMON_E000.bin` (8KB ROM image)

### Clean

```cmd
docker run --rm -v%CD%:/mnt/project dawidbuchwald/cc65-tools-make clean
```

### Building Without Docker (Native Tools)

If you prefer to build without Docker, install the **cc65 toolchain** from https://cc65.github.io/ and use `make all` from the workspace root.

## Source Files

- **smon_e000.s** - SMON monitor implementation
- **config.s** - RetroShield configuration (memory map, UART at $8400)
- **uart_6551.s** - 6551 ACIA driver (emulated by Teensy)
- **smon_e000.cfg** - Linker script (ROM at $E000-$FFFF)
- **Makefile** - Build rules

## SMON Commands

Type `H` in the serial monitor for full command help. Key commands:

- **M xxxx** - Memory dump
- **:xxxx nn nn** - Store bytes  
- **D xxxx** - Disassemble
- **A xxxx** - Assemble
- **G xxxx** - Run program
- **TW xxxx** - Trace walk (single-step with 6522 VIA timer)
- **R** - Display/modify registers

## Hardware Requirements

**Teensy 4.1 with RetroShield 6502**
- WDC 65C02 CPU at 1MHz
- 32KB RAM ($0000-$7FFF)
- 8KB ROM ($E000-$FFFF) emulated from Teensy PROGMEM
- 6551 ACIA ($8400) emulated by Teensy
- 6522 VIA ($9000) emulated by Teensy (for trace commands)

Serial communication is handled by the Teensy firmware (115200 baud via USB).

## Credits

- **SMON** - Original 1984 C64 monitor by Norfried Mann & Dietrich Weineck
- **SMON6502** - Standalone 6502 port by dhansel (2023)
- **RetroShield** - Hardware interface by Erturk Kocalar (8Bitforce.com)
- **Retroshield Teensy 4.1 port** - kayto@github.com (2025)

