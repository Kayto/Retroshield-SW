
## Overview

This project adapts a 65C02/RetroShield hardware setup to use **SMON** with a **software‑emulated 6551 ACIA** for serial I/O. The result boots directly into SMON with i/o over a USB serial connection amd trace walk functions via a **software-emulated 6522 VIA**.

---

## Changes Implemented

### Replacement of the existing base code 6821 PIA and ACI with 6551 ACIA
- All references to the 6821 PIA (KBD/DSP registers) and Apple Cassette Interface (ACI) were **removed**.
- Introduced a new header **`6551.h`** that defines these memory‑mapped registers:
  - `$8400` : ACIA Data Register (TX/RX)
  - `$8401` : ACIA Status Register
  - `$8402` : ACIA Command Register
  - `$8403` : ACIA Control Register
- Implemented the following helper functions:
  - `m6551_init()` to initialize the emulated ACIA.
  - `m6551_read()` to handle CPU reads from ACIA registers.
  - `m6551_write()` to handle CPU writes (transmit and control).
  - `m6551_poll()` to poll the host USB serial for incoming data.
- The CPU core (`cpu_tick()`) now interfaces directly with these registers for all I/O.

### Development of a 6522 VIA implementation

- A **software-emulated 6522 VIA** was added to provide programmable I/O and timer functionality.
- Key registers (`$9000`–`$900F`) include Port A/B data and direction registers, timers, and auxiliary control.
- For implementation details, see [6522_VIA_Implementation.md](6522_VIA_Implementation.md).

### Memory Map Adjusted for the modified SMON build
- **RAM:** `$0000` (including zero page) to `$7FFF`.
- **ROM:** `$e000` to `$FFFF`.
  - `memorymap.h` provides the SMON binary as a C array.
  - Interrupt vectors at `$FFFA–$FFFF` are part of the ROM image.


### Loading SMON ROM
- `smon_e000.bin` (8 KB) was converted into a C array (`memorymap.h`).

---

## Credits
- SMON - Original 1984 C64 monitor by Norfried Mann & Dietrich Weineck
- SMON6502 - Standalone 6502 port by dhansel (2023)
- RetroShield - Hardware interface by Erturk Kocalar (8Bitforce.com)
- Retroshield Teensy 4.1 SMON port - kayto@github.com (2025)
