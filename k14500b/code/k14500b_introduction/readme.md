# MC14500B Retroshield Usage Guide

## 1\. System Overview

### 14500 Background

The MC14500B is a 1-bit CMOS microprocessor launched by Motorola in 1977 for industrial control. It was built to replace relay systems in automation, designed by Vern Gregory and a Motorola team in Phoenix. Used into the 1990s, it’s a simple, low-cost chip for basic control tasks like switching outputs based on inputs.

### Key Features

* 1-Bit Processing: Works with one bit at a time using a single Result Register (RR), used as an accumulator.
* 16 Instructions: Includes simple commands like load, AND, OR, store, and jump.
* No Internal Memory: Needs external memory and a counter for instructions.

This guide covers its operation with the Retroshield memory and I/O configuration:

* 8 momentary push-button switches as inputs **(IN0 to IN7)**.
* 8 LEDs as outputs **(OUT0 to OUT7)**.
* Shared I/O addresses `0x8 - 0xF` for buttons and LEDs, controlled by `IEN` and `OEN`.
* Status LEDs for `JMP`, `RTN`, `FLAG0`, `FLAGF`, and `RR`.

### Memory Mapping:

* **0x0 - 0x7**: General-purpose memory (8 locations for data or states).
* **0x8 - 0xF**: Shared I/O space:
    * Inputs: `0x8` = button IN0, `0x9` = button IN1, ..., `0xF` = button 8 (requires `IEN = 1`).
    * Outputs: `0x8` = LED OUT0, `0x9` = LED OUT1, ..., `0xF` = LED 8 (requires `OEN = 1`).
    * Address `0x8` also serves as the Result Register (`RR`), with both a button and an LED.

### Status LEDs:

* `JMP`: Active during a `JMP` instruction.
* `RTN`: Active during a `RTN` instruction.
* `FLAG0`: Reflects the `FLAG0` pin state.
* `FLAGF`: Reflects the `FLAGF` pin state.
* `RR`: Shows the current `RR` value (0 or 1).

![Block Diagram](C:%5CMyPrograms%5C14500%5Cmedia/img_0.png)

## 2\. Core Components

* **RR (Result Register, 0x8):** Stores operation results, tied to button IN0 and OUT0 at `0x8`, visible on the `RR` LED.
* **D\_IN (Data Input):** Reads button states from `0x8 - 0xF` when `IEN = 1`.
* **IEN (Input Enable):**
    * `IEN = 1`: Enables button input to `RR`.
    * `IEN = 0`: Forces `D_IN` to 0, blocking button reads.
* **OEN (Output Enable):**
    * `OEN = 1`: Enables enables LED updates and allows STO to store RR values.
    * `OEN = 0`: Prevents LED updates.

*Operation:* At `0x8 - 0xF`, `IEN` enables input (buttons), and `OEN` enables output (LEDs). Both must be set for intended behavior.

### Limitations

As the Result Register `RR` shares `IN0` and `OUT0` (0x08), input and output cannot function in the same cycle because of how OEN and IEN resets RR.

This is a hardware limitation of the MC14500B and not fixable through instruction ordering. The only way to work around this is to use separate memory locations for input and output.

### Comparison to Retroshield Implementation

In traditional MC14500B-based systems, inputs and outputs are handled via:

* Input selectors (multiplexers like MC14512)
* Output latches (like MC14599B)

##### How Inputs Work in Traditional Design

* The MC14512 is used as an input multiplexer.
* It selects which input (e.g., sensors, switches) is read by the ICU.
* The ICU reads the selected input bit and processes it.

##### How Outputs Work in Traditional Design

* The MC14599B is used as an output latch.
* The ICU writes a single-bit result to the output.
* The output remains latched until updated by the ICU.

##### The Result Register (RR)

The RR (Result Register) is the only storage register in the MC14500B, acting as a 1-bit accumulator for all logic operations.

* All input values must be loaded into RR (LD) before processing.
* All logic operations (AND, OR, XNOR) modify RR, updating its value.
* All outputs are written from RR (STO) to digital output pins.
* Program control (SKZ, JMP) depends on RR's value, determining conditional execution.

In the Retroshield implementation, RR is simulated as a boolean variable (bool RR), with:

* `RR = digitalReadFast(uP_Ix)`; for loading inputs.
* `RR = RR && digitalReadFast(uP_Iy)`; for logic operations.
* `digitalWriteFast(uP_OUTP_Dx, RR)`; for storing results to outputs.
* `if (RR == 0) { PC += 1; }` for skipping instructions.

##### JMP

The JMP instruction in the MC14500B isn’t a full branch command by itself. It merely generates a one-clock-cycle pulse (a jump flag) that must be externally “captured” to modify the program counter.

Simple MC14500B systems may only capture a JMP instruction to act solely as a reset (`JMP 0x00`). External circuitry (such as a 74LS574 8-bit address latch) is needed to use that jump pulse to load a new address into the 8‑bit program counter. That counter can, in theory, address up to 256 memory locations.

In the Retroshield implemenation, the JMP instruction is handled by directly checking the dedicated JMP pin. When `digitalReadFast(uP_JMP)` returns true, the code sets the program counter (uP\_ADDR) equal to the value on the I/O address lines (`uP_IOADDR`).

It simply overwrites uP\_ADDR with the jump target. This target is limited to 4-bits `JMP 0x00 to 0x0F` (i.e., only the first 16 addresses).

##### Summary

* Instead of MC14512 multiplexers, the Retroshield implementation directly reads GPIO inputs.
* Instead of MC14599B output latches, the Retroshield implementation uses GPIO outputs.
* Memory, Program Counter, RR Storage, Flow Control are performed in software.

| **Component** | **Typical MC14500B System** | **Retroshield 14500 Implementation** |
| --------- | ----------------------- | -------------------------------- |
| **Inputs** | MC14512 multiplexer | `digitalReadFast(uP_Ix)` (Direct GPIO reads) |
| **Outputs** | MC14599B latch | `digitalWriteFast(uP_OUTP_Dx)` (Direct GPIO writes) |
| **Memory** | External RAM (1-bit words) | Simulated via software (array-based) |
| **Program Counter** | MC14516B Up Counter | Simulated via software loop |
| **RR Storage** | 1-bit hardware register | Monitored by Arduino, but **not modified** |
| **Reading Inputs** | MC14512 multiplexer | `digitalReadFast(uP_Ix)` |
| **Performing Logic** | Internal logic unit (**Executed by MC14500B**) | **Only monitored/logged by Arduino, NOT executed** |
| **Storing Outputs** | MC14599B latch | `digitalWriteFast(uP_OUTP_Dx)` |
| **Flow Control** | SKZ, JMP, RTN (**Executed by MC14500B**) | **Only monitored/logged by Teensy, NOT executed** |
| **Instruction Decoder** | Hardware decoder in MC14500B | **Arduino extracts opcodes for logging, debugging, and routing, but MC14500B still executes them** |
| **Clock Generator** | External clock (crystal oscillator, 555 timer) | **Arduino-generated clock signal** |
| **Control Signals** | IEN, OEN, FLAG pins controlled by MC14500B | Arduino monitors/logs IEN, OEN, FLAG states but does not modify execution |
| **Power Supply** | +5V logic | MCU's onboard voltage regulator |
| **Bus Interface** | Direct address/data buses | Emulated via GPIO |
| **Cycle Timing** | Fixed by clock speed | Dependent on software execution time |
| **Address Decoding** | Discrete logic (74LS138) | **Software-based address selection** |
| **I/O Latching** | MC14599B latch (persistent storage) | **Software-controlled GPIO state (non-persistent)** |

## 3\. Instruction Set

The MC14500B supports 16 instructions, each a 4-bit code. For `0x8 - 0xF`, the state is a button (input) or LED (output), depending on `IEN`, `OEN`, and the instruction. Logic formulas are included.

| Hex | Binary | Mnemonic | Description |
| --- | ------ | -------- | ----------- |
| `0x0` | `0000` | **NOP** | No operation. |
| `0x1` | `0001` | **LD** | Load state into `RR`. Formula: `RR = (D_IN & IEN)` (button state if `IEN = 1`, else 0). |
| `0x2` | `0010` | **LDC** | Load complement of state into `RR`. Formula: `RR = !(D_IN & IEN)` (NOT button state if `IEN = 1`, else 1). |
| `0x3` | `0011` | **AND** | Logical AND with `RR`. Formula: `RR = RR & (D_IN & IEN)` (RR AND button state if `IEN = 1`, else RR & 0). |
| `0x4` | `0100` | **ANDC** | Logical AND with complement. Formula: `RR = RR & !(D_IN & IEN)` (RR AND NOT button state if `IEN = 1`). |
| `0x5` | `0101` | **OR** | Logical OR with `RR`. Formula: `RR = RR | (D_IN & IEN)` (RR OR button (if IEN = 1, else RR unchanged) |
| `0x6` | `0110` | **ORC** | Logical OR with complement. Formula: `RR = RR | !(D_IN & IEN)` (RR OR NOT button state if `IEN = 1`). |
| `0x7` | `0111` | **XNOR** | Logical XNOR with `RR`. Formula: `RR = (RR == !(D_IN & IEN))` (RR XNOR NOT button state if `IEN = 1`). |
| `0x8` | `1000` | **STO** | Store `RR` to LED at address. Formula: `Output = RR` (if `OEN = 1`). |
| `0x9` | `1001` | **STOC** | Store complement of `RR` to LED. Formula: `Output = !RR` (if `OEN = 1`). |
| `0xA` | `1010` | **IEN** | Set `IEN = RR`. Enables/disables button input. |
| `0xB` | `1011` | **OEN** | Set `OEN = RR`. Enables/disables LED output. |
| `0xC` | `1100` | **JMP** | Jump to specified address, limited to the first 16 bits - (activates `JMP` LED). |
| `0xD` | `1101` | **RTN** | Return from subroutine, skip next instruction (activates `RTN` LED). |
| `0xE` | `1110` | **SKZ** | Skip next instruction if `RR = 0`. |
| `0xF` | `1111` | **NOP** | No operation. |

*Note:* Load instructions (`LD`, `LDC`, `AND`, `ANDC`, `OR`, `ORC`, `XNOR`) use button states from `0x8 - 0xF` when `IEN = 1`. Store instructions (`STO`, `STOC`) affect LEDs at `0x8 - 0xF` when `OEN = 1`. All instructions operate on RR; IEN/OEN must be set correctly for I/O to work.

## 4\. Useful Instruction Sequences

### Enable Button Input (IEN = 1)

``` assembly
68    ; ORC  8  ; RR = !(D_IN & IEN) from 0x8 (RR = 1 if 0x8 = 0)
A8    ; IEN     ; Set IEN = RR (IEN = 1, enables buttons)
```

*Purpose: Required to read button states at 0x9 - 0xF.*

### Enable LED Output (OEN = 1)

``` assembly
68    ; ORC  8  ; RR = !(D_IN & IEN) from 0x8 (RR = 1 if 0x8 = 0)
B8    ; OEN     ; Set OEN = RR (OEN = 1, enables LEDs)
```

*Purpose: Required to write to LEDs at 0x8 - 0xF.*

### Read Button and Write to LED

``` assembly
68    ; ORC  8  ; RR = !(D_IN & IEN) from 0x8 (RR = 1)
A8    ; IEN     ; Set IEN = 1
B8    ; OEN     ; Set OEN = 1
19    ; LD   9  ; RR = button IN1 state (0x9)
89    ; STO  9  ; LED 1 (0x9) = RR
```

*Effect: Button IN1 press sets LED OUT1 on; released turns it off.*

### Invert Button State to LED

``` assembly
68    ; ORC  8  ; RR = !(D_IN & IEN) from 0x8 (RR = 1)
A8    ; IEN     ; Set IEN = 1
B8    ; OEN     ; Set OEN = 1
29    ; LDC  9  ; RR = !(button 1 state at 0x9)
89    ; STO  9  ; LED 1 (0x9) = RR
```

*Effect: Button IN1 pressed turns LED OUT1 off; released turns it on.*

### Conditional LED Control

``` assembly
68    ; ORC  8  ; RR = !(D_IN & IEN) from 0x8 (RR = 1)
A8    ; IEN     ; Set IEN = 1
B8    ; OEN     ; Set OEN = 1
1A    ; LD   A  ; RR = button 2 state (0xA)
E     ; SKZ     ; Skip next if RR = 0
8A    ; STO  A  ; LED 2 (0xA) = RR
```

*Effect: Conditional Routine: LED OUT2 turns on when button IN2 is pressed and stays in its last state when released (no explicit off).*

### Latch an LED State

``` assembly
68    ; ORC  8  ; RR = !(D_IN & IEN) from 0x8 (RR = 1)
A8    ; IEN     ; Set IEN = 1
B8    ; OEN     ; Set OEN = 1
19    ; LD   9  ; RR = button 1 state (0x9)
50    ; OR   0  ; RR = RR | (D_IN & IEN) from 0x0
80    ; STO  0  ; Store latched state to 0x0
89    ; STO  9  ; LED 1 (0x9) = RR
C3    ; JMP  3  ; Jump back to loop start (address 0x3)
```

*Effect: Latched Routine: LED IN1 turns on when button OUT1 is pressed and stays on permanently due to the latched state in Memory[0].*

## 5\. Summary

* 0x0 - 0x7: General-purpose memory.
* 0x8 - 0xF: Shared I/O (buttons with IEN = 1, LEDs with OEN = 1).
* `RR` (0x8): Operation register, also button `IN0` and LED `OUT0`.
* As `RR` shares `IN0` and `OUT0` (0x08) - IEN and OEN cannot be used in the same cycle.
* IEN/OEN: Enable input or output at shared addresses.
*

## 6\. Operational Notes

* Initialization Essential: Operation fails without proper IEN and OEN settings. Execute IEN = 1 and OEN = 1 sequences at program start. If buttons are unresponsive, IEN is likely 0. If LEDs do not change, OEN is likely 0. These must be verified before any I/O activity.
* Address Overlap: At 0x8 - 0xF, LD reads buttons and STO writes LEDs. Simultaneous input/output on the same address requires careful IEN/OEN control. As the Result Register `RR` shares `IN0` and `OUT0` (0x08), input and output cannot function in the same cycle because of how OEN and IEN resets RR.
* JMP: This target is limited to 4-bits `JMP 0x00 to 0x0F\` (i.e., only the first 16 addresses).
* Monitoring: The RR LED displays button states or results; JMP and RTN LEDs show program flow; FLAG0 and FLAGF reflect pin states.
* Troubleshooting: If I/O does not work, re-execute initialization and check RR LED for expected values.