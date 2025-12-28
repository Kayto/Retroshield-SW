# 6522 VIA Emulation for SMON Tracewalk

## Overview

This document explains how the 6522 VIA (Versatile Interface Adapter) emulation works with SMON's tracewalk feature on the Teensy 4.1 RetroShield 6502.

SMON uses the VIA Timer 1 in one-shot mode to implement single-step debugging. The timer fires an IRQ after a precise number of CPU cycles, allowing exactly one instruction to execute before the CPU is interrupted and control returns to SMON's trace handler.

---

## How Tracewalk Works

### The Timing Chain

1. **User enters `.TW 1000`** - SMON prepares to trace from address $1000
2. **SMON configures VIA Timer 1**:
   - Sets ACR = $00 (one-shot mode)
   - Writes 73 to T1LL (timer low latch)
   - Writes 0 to T1CH (starts timer with 73-cycle countdown)
   - Enables Timer 1 interrupt (IER = $C0)
3. **SMON executes RTI** - Returns to user code at $1000
4. **Timer expires** - After ~76 cycles (73 + 3 compensation), IRQ fires
5. **CPU vectors to TWINT** - SMON's trace interrupt handler
6. **TWINT displays state** - Shows PC, registers, and next instruction
7. **TWINT waits for keypress** - Timer is paused (one-shot expired)
8. **User presses key** - SMON writes T1CH to restart timer
9. **Cycle repeats** - One instruction executes per keypress

### Timer Value: 73 Cycles

SMON uses a timer value of 73 cycles, carefully tuned so that:
- The timer starts when T1CH is written (during LCD72 setup code)
- 73 cycles later, the IRQ fires just as the CPU completes RTI
- This allows exactly one user instruction to execute before the next IRQ

---

## VIA Emulation Implementation

### Timer 1 Counter

The emulation maintains a 16-bit counter (`via_t1_counter`) that decrements on each CPU clock cycle. When it reaches zero:

```cpp
if (via_t1_counter == 0) {
    regVIA_IFR |= 0x40;  // Set Timer 1 interrupt flag
    regVIA_IFR |= 0x80;  // Set master interrupt flag
    
    if (regVIA_ACR & 0x40) {
        // Free-running mode: reload and continue
        via_t1_counter = ((uint16_t)regVIA_T1LH << 8) | regVIA_T1LL;
    } else {
        // One-shot mode: stop until T1CH written
        via_t1_paused = true;
    }
}
```

### Timer Delay Compensation (+3 Cycles)

The real 6522 VIA has internal synchronization that delays the actual timer expiration by approximately N+1.5 cycles from when the counter is loaded. The emulation adds 3 cycles to compensate:

```cpp
case VIA_T1CH:
    via_t1_counter = ((uint16_t)regVIA_T1LH << 8) | regVIA_T1LL;
    via_t1_counter += 3;  // 6522 timer delay compensation
    via_t1_paused = false;
```

This ensures:
- **+2**: Would fire during RTI (too early, CPU never reaches user code)
- **+3**: Fires just after RTI, one instruction executes ✓
- **+4 or more**: Multiple instructions execute per step

### IRQ Pin Control

The emulation drives the physical IRQ pin to the 65C02:

```cpp
// Assert IRQ (active low)
if ((regVIA_IFR & 0x40) && (regVIA_IER & 0x40)) {
    pinMode(uP_IRQ_N, OUTPUT);
    digitalWriteFast(uP_IRQ_N, LOW);
    via_irq_pin_is_low = true;
}

// Release IRQ (drive high, not pullup - faster response)
if (via_irq_pin_is_low && !(regVIA_IFR & 0x80)) {
    digitalWriteFast(uP_IRQ_N, HIGH);
    via_irq_pin_is_low = false;
}
```

The IRQ is released only when the interrupt flag is cleared (by SMON reading T1CL or writing to IFR).

---

## One-Shot vs Free-Running Mode

The VIA Timer 1 supports two modes controlled by ACR bit 6:

| Mode | ACR Bit 6 | Behavior |
|------|-----------|----------|
| One-shot | 0 | Timer fires once, stops, waits for T1CH write |
| Free-run | 1 | Timer fires, reloads from latch, continues |

SMON uses **one-shot mode** for tracewalk:
- Timer fires → IRQ → TWINT displays state → waits for keypress
- Keypress → SMON writes T1CH → timer restarts → RTI → one instruction → repeat

---

## Key Implementation Details

### Writing T1CH Starts the Timer

Per the 6522 datasheet, writing to T1CH:
1. Copies the written value to T1LH (high latch)
2. Transfers latches (T1LH:T1LL) to counter
3. Clears the Timer 1 interrupt flag
4. Starts the countdown

```cpp
case VIA_T1CH:
    regVIA_T1CH = value;
    regVIA_T1LH = value;  // Also writes high latch
    via_t1_counter = ((uint16_t)regVIA_T1LH << 8) | regVIA_T1LL;
    via_t1_counter += 3;
    via_t1_paused = false;  // Start counting
    regVIA_IFR &= ~0x40;    // Clear interrupt flag
```

### Reading T1CL Clears the Interrupt

Reading T1CL clears the Timer 1 interrupt flag and releases the IRQ line:

```cpp
case VIA_T1CL:
    regVIA_IFR &= ~0x40;
    if ((regVIA_IFR & 0x7F) == 0) regVIA_IFR &= ~0x80;
    if (via_irq_pin_is_low) {
        digitalWriteFast(uP_IRQ_N, HIGH);
        via_irq_pin_is_low = false;
    }
    value = regVIA_T1CL;
    break;
```

---

## SMON Trace Commands

All trace commands work with this VIA emulation:

| Command | Description |
|---------|-------------|
| `.TW xxxx` | Trace Walk - single-step with keypress |
| `.TB xxxx nn` | Trace Break - stop after nn breakpoint hits |
| `.TQ xxxx` | Trace Quick - fast trace to breakpoint |
| `.TS xxxx yyyy` | Trace Stop - run until PC reaches yyyy |
| `.G xxxx` | Go - run without tracing |

---

## Memory Map

| Address | Register | Description |
|---------|----------|-------------|
| $9000 | DRB | Data Register B |
| $9001 | DRA | Data Register A |
| $9002 | DDRB | Data Direction B |
| $9003 | DDRA | Data Direction A |
| $9004 | T1CL | Timer 1 Counter Low |
| $9005 | T1CH | Timer 1 Counter High |
| $9006 | T1LL | Timer 1 Latch Low |
| $9007 | T1LH | Timer 1 Latch High |
| $900B | ACR | Auxiliary Control Register |
| $900D | IFR | Interrupt Flag Register |
| $900E | IER | Interrupt Enable Register |

---

## References

- MOS 6522 VIA Datasheet
- SMON source code (smon.s, lines 1870-1920)
- dhansel/smon6502: https://github.com/dhansel/smon6502/
