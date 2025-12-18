# SMON_E000 - SMON Monitor for RetroShield 6502

SMON E000 build for Teensy 4.1 RetroShield 6502, based on David Hansel's adaptation
([dhansel/smon6502](https://github.com/dhansel/smon6502)).

## RetroShield Hardware Configuration

| Component | Address | Notes |
|-----------|---------|-------|
| RAM | $0000-$7FFF | 32KB |
| ROM | $E000-$FFFF | 8KB (SMON) emulated from Teensy PROGMEM |
| ACIA | $8400 | WDC 6551 emulated by Teensy (115200 baud USB) |
| VIA | $9000 | MOS 6522 emulated by Teensy (for trace functions) |

## Boot Flow

| Entry | Trigger | Action |
|-------|---------|--------|
| ENTRY | RESET | Init stack, set BRK vector, print banner, prompt |
| SMON | BRK instruction | Save registers, show 'R' command, prompt |
| X cmd | User input | Cold restart (jmp ENTRY) |

## Changes from Original

### Build System
- VASM → ca65/ld65 toolchain
- Linker config: `smon_e000.cfg`
- Output: 8K binary (no padding)

### UART Driver
- `UAGET`: Non-blocking (returns 0 if no char)
- `LAB_WAIT_Rx`: Blocking receive

### Help System
- Categorized help: `H A`, `H M`, `H F`, `H E`, `H C`, `H R`, `H O`

### Commands
- `X`: Cold restart (reset monitor with banner)
- `S`: Save memory as Intel HEX

### Bug Fixes
- PRTINT leading zero suppression
- GETIN non-blocking UART handling

## Credits

- **Original SMON:** Norfried Mann & Dietrich Weineck (64er Magazine, 1984/85)
- **SMON6502 Port:** David Hansel (2023)
- **Retroshield Teensy 4.1 port** - kayto@github.com (2025)
