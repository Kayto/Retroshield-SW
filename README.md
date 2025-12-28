# Retroshield
 Additional roms and experiments for the RetroShield by Erturk Kocalar@8bitforce https://gitlab.com/8bitforce

## Aims

- For each board, as a minimum I am trying to provide some clear isolation of the serial routines so that it can act as a starting platform for developing further code. (I always find that not having a clear serial i/o base puts a block in the way of moving forward). 

- Document the development environment for each, as knowing which assembler and some simple compilation/ automation scripts also helps!

- Provide assembleable versions of the current 8bitforce repo roms. This allows easier development with known syntax and assemblers.

- Add additional ROMs examples that may not be part of the current 8bitforce repo.

- Develop some new monitors where neccesary adding native assembly/disassembly functions for each board. 


## Repo Contents

### k6803
- `cookbook.asm`: Assembly code with various useful routines.
- `k6803_0_99_Counter_Delay/`: Contains firmware for counter delay.
- `k6803_10M_Counter_Delay/`: Contains firmware for 10M counter delay.
- `k6803_hello_world/`: Contains hello world example.
- `k6803_serial/`: Contains serial communication examples.
- `k6803_serial_echo_backspace/`: Contains serial echo with backspace handling.
- `k6803_serial_echo_prompt/`: Contains serial echo with prompt handling.

### k8031
- `ESD8031.pdf`: Reference Documentation for the 8031 system.
- `k8031_8031_AT_Monitor/`: Contains AT monitor firmware.
- `k8031_8031_Monitor_Frank_Rudley/`: Contains monitor firmware by Frank Rudley. ASM, Listing, hex and bin code.
- `k8031_hello_world/`: Contains hello world example.
- `k8031_serial_echo/`: Contains serial echo example.

### t2650
- `t2650_heybug/`: Contains HeyBug firmware - my go at a new monitor combining useful routines.
- `t2650_pipbug_mwbasic_ram/`: Contains PipBug and MicroWorld BASIC firmware.
- `t2650_serial/`: Contains serial communication examples.

### t8085
- `t8085_8kbasic/`: Contains 8K BASIC firmware.
- `t8085_serial/`: Contains serial communication examples.
- `t8085_tinybasic/`: Contains Tiny BASIC firmware.

### t8088
- `t8088_min_scp_v15`: Seattle Computer Products 8086 Monitor version 1.5  3-19-82 by Tim Paterson. ASM, Listing, hex and bin code.
- `t8088_hello_world`: Simple hello world to isolate serial routines.
- `t8088_serial_echo`: Simple serial echo to isolate serial i/o routines.
- `t8088_min_scp_v15_Loader`: Seattle Computer Products 8086 Monitor version 1.5 3-19-82 by Tim Paterson. I have added in an Intel HEX Loader so that user programs can be uploaded into memory. A Programs folder contains some example programs.

### k14500
* `k14500_basic_io_1`: Basic I/O Operations for k14500B.
* `k14500_basic_io_2`: Latch an LED State with On/Off

### t65c02
* `t65c02t_6551acia_EhBASIC`: Implements 6551 ACIA emulation for EhBASIC i/o.
* `t65c02t_6551_6522_smon`: Implements 6551 ACIA and 6522 emulation for SMON, allowing trace functionality.

### tz80

- `tz80_efex.ino`: Conversion of the Arduino Mega EFEX monitor to Teensy 4.1.





