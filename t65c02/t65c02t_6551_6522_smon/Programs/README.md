# 65C02 Test Programs for SMON

This directory contains test programs for the 65C02 processor running under SMON monitor.

## Build System

Each program has its own Makefile that compiles the source to binary format:

- **Assembler**: ca65 (65C02 mode)
- **Linker**: ld65 with custom configuration files
- **Output Directory**: `Programs/build/<program>/`

### Building Programs

Each program directory contains a Makefile. To build a specific program:

```bash
cd Programs/CPU_Tests/<program>
make all
```

This will generate:
- `../../build/<program>/<program>.bin` - Binary executable
- `../../build/<program>/<program>.o` - Object file
- `../../build/<program>/<program>.lst` - Assembly listing

### Converting to Intel HEX

After building, convert binaries to Intel HEX format for loading into SMON:

```bash
python ../../tools/bin2hex.py build/<program>/<program>.bin build/<program>/<program>.hex 0x1000
```

### Cleaning

To remove build artifacts:

```bash
make clean
```

## CPU Stress Tests (`CPU_Tests/`)

### Foldtest (`CPU_Tests/foldtest/`)
13-test comprehensive stress suite covering:
- Data checksums, XOR folding, Fibonacci, Factorial
- Bit manipulation, Memory verify, Loop stress (64K iterations)
- Prime counting, Bubble sort, CRC-16, GCD Euclidean
- Extended folding, Power calculations

**Output**: `build/foldtest/foldtest.hex` (2266 bytes at $1000)

### Memory Sort (`CPU_Tests/memsort/`)
Multiple sorting algorithm stress test with hex dumps and statistics.
- Bubble Sort, Selection Sort, Shell Sort
- Random data generation with LFSR
- Verification and performance metrics

**Output**: `build/memsort/memsort.hex` (1036 bytes at $1000)

### Opcode Test (`CPU_Tests/opcode_test/`)
65C02 instruction validation suite.

**Output**: `build/opcode_test/opcode_test.hex` (1723 bytes at $1000)

### Prime Finder (`CPU_Tests/primes/`)
Full 16-bit prime sweep from 65535 down to 2 (reverse order, hardest first).
- True prime testing via trial division
- 16-bit division algorithm
- Space-separated hex output

**Output**: `build/primes/primes.hex` (603 bytes at $1000)

## Memory Map

All programs use safe memory areas that don't conflict with SMON:
- **Zero Page:** $0010-$004F (SMON uses $0000-$000F and $0050+)
- **BSS:** $0400+ (SMON vectors at $0314-$0319)
- **Code:** $1000+ (SMON ROM at $E000+)

## Loading and Running

In SMON monitor, use the `L` command to load Intel HEX files:
```
L
[paste hex contents from .hex file]
[press Ctrl+D or send EOF]

G 1000
```

Programs return to SMON via `BRK` instruction.

## Technical Details

- **Assembler**: ca65 (65C02 mode)
- **Linker**: ld65 with custom config files
- **Load Address**: $1000 for all programs
- **HEX Format**: Intel HEX with 16 bytes per line
