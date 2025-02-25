# Retroshield
 Additional roms and experiments for the RetroShield by Erturk Kocalar@8bitforce https://gitlab.com/8bitforce

## Aims

- For each board, as a minimum I am trying to provide some clear isolation of the serial routines so that it can act as a starting platform for developing further code. (I always find that not having a clear serial i/o base puts a block in the way of moving forward). 

- Document the development environment for each, as knowing which assembler and some simple compilation/ automation scripts also helps!

- Provide assembleable versions of the current 8bitforce repo roms. This allows easier development with known syntax and assemblers.

- Add aditional ROMs examples that may not be part of the current 8bitforce repo.

- Stretch aim, to develop some new monitors where neccesary adding native assembly/disassembly functions for each board. 

## Folder Contents

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
- `k8031_8031_Monitor_Frank_Rudley/`: Contains monitor firmware by Frank Rudley.
- `k8031_hello_world/`: Contains hello world example.
- `k8031_serial_echo/`: Contains serial echo example.

### t2650
- `t2650_heybug/`: Contains HeyBug firmware - my .
- `t2650_pipbug_mwbasic_ram/`: Contains PipBug and MicroWorld BASIC firmware.
- `t2650_serial/`: Contains serial communication examples.

### t8085
- `t8085_8kbasic/`: Contains 8K BASIC firmware.
- `t8085_serial/`: Contains serial communication examples.
- `t8085_tinybasic/`: Contains Tiny BASIC firmware.

### t8088

