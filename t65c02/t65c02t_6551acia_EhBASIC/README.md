
## Overview

This project adapts a 65C02/RetroShield hardware setup to use **EhBASIC** as the resident BASIC interpreter and replaces the original Apple‑1 style 6821 PIA/ACI interface with a **software‑emulated 6551 ACIA** for serial I/O. The result boots directly into EhBASIC with i/o over a USB serial connection.

---

## Changes Implemented

### Replacement of 6821 PIA and ACI with 6551 ACIA
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

### Memory Map Adjusted for EhBASIC
- **RAM:** `$0000` (including zero page) to `$7EFF`.
- **ROM:** `$A000` to `$FFFF`.
  - `memorymap.h` provides the EhBASIC binary as a C array.
  - Interrupt vectors at `$FFFA–$FFFF` are part of the ROM image.
- All ACI PROM references at `$C100–$C1FF` were **removed**.

### Loading EhBASIC ROM
- `basic.bin` (8 KB) was converted into a C array (`memorymap.h`).


### Simplified Serial Event Handling
- Removed legacy `serialEvent0()` PIA code.
- The main loop now uses `m6551_poll()` to handle RX data from USB serial.

---

> EhBASIC is free but not copyright free. For non commercial use there is only one restriction, any derivative work should include, in any binary image distributed, the string "Derived from EhBASIC" and in any distribution that includes human readable files a file that includes the above string in a human readable form e.g. not as a comment in an HTML file.
