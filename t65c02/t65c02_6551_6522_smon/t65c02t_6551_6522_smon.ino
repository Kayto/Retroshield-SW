////////////////////////////////////////////////////////////////////
// RetroShield 6502 for Teensy 4.1
// 6502 CPU with 6551 ACIA and 6522 VIA emulation
// SMON Monitor Program
//
// Version 1.0 - 2025/12/17
//
// Credits:
// ---------
// SMON - Original 6502 machine language monitor for C64/C128
//        by Norfried Mann and Dietrich Weineck (1984)
//        Published in 64'er magazine (Nov/Dec 1984, Jan 1985)
//        https://www.c64-wiki.com/wiki/SMON
//
// smon6502 - Port of SMON to standalone 6502 systems
//            by dhansel (2023)
//            https://github.com/dhansel/smon6502/
//            Based on disassembly by Michael (cbmuser)
//            https://github.com/cbmuser/smon-reassembly
//
// RetroShield - 6502 hardware interface for Arduino/Teensy
//               by Erturk Kocalar, 8Bitforce.com (2019)
//               https://www.8bitforce.com/projects/retroshield/
//
// 6551 ACIA & 6522 VIA emulation for Teensy 4.1
//               by kayto@github.com (2025)
//

// The MIT License (MIT)
//
// RetroShield code:
// Copyright (c) 2019 Erturk Kocalar, 8Bitforce.com
//
// smon6502 port (no explicit license, credited here):
// Refer to work by dhansel (2023)
//
// Original SMON (published in 64'er magazine 1984):
// Authors: Norfried Mann, Dietrich Weineck
//
// 6522 VIA emulation:
// Copyright (c) 2025 kayto@github.com

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Date         Comments                                                Author
// -----------------------------------------------------------------------------
// 09/13/2019   Bring-up on Teensy 3.5 (Apple 1).                       Erturk
// 01/11/2024   Added Teensy 4.1 support (Apple 1).                     Erturk
// 03/25/2024   Changed to more accurate timing for 1MHz op (Apple 1).  Erturk
// 2025/12/17   Ported SMON with 6551 and 6522 support.                 kayto
//
////////////////////////////////////////////////////////////////////
// Options
//   outputDEBUG: Print memory access debugging messages.
////////////////////////////////////////////////////////////////////
#define outputDEBUG       0
#define DEBUG_SPEW_DELAY  1000

////////////////////////////////////////////////////////////////////
// BOARD DEFINITIONS
////////////////////////////////////////////////////////////////////
#include "memorymap.h"      // Memory Map (ROM, RAM, PERIPHERALS)
#include "portmap.h"        // Pin mapping to cpu
#include "setuphold.h"      // Delays required to meet setup/hold
#include "6551.h"           // 6551 Emulation
#include "6522.h"           // 6522 Emulation

unsigned long clock_cycle_count;
unsigned long clock_cycle_last;

word          uP_ADDR;
byte          uP_DATA;

// External variables from 6522.h
extern volatile bool trace_walk_active;

void uP_assert_reset()
{
  digitalWriteFast(uP_RESET_N,  LOW);
  digitalWriteFast(uP_IRQ_N,    HIGH);
  digitalWriteFast(uP_NMI_N,    HIGH);
  digitalWriteFast(uP_RDY,      HIGH);
  digitalWriteFast(uP_SO_N,     HIGH);
}

void uP_release_reset()
{
  digitalWriteFast(uP_RESET_N,  HIGH);
}

void uP_init()
{
  configure_PINMODE_ADDR();
  configure_PINMODE_DATA();

  pinMode(uP_RESET_N, OUTPUT);
  pinMode(uP_RW_N,    INPUT_PULLUP);
  pinMode(uP_RDY,     OUTPUT);
  pinMode(uP_SO_N,    OUTPUT);
  pinMode(uP_IRQ_N,   OUTPUT);
  pinMode(uP_NMI_N,   OUTPUT);
  pinMode(uP_CLK_E,   OUTPUT);
  pinMode(uP_GPIO,    INPUT_PULLUP);

  digitalWriteFast(uP_CLK_E, LOW); 
  uP_assert_reset();

  clock_cycle_count = 0;
}

////////////////////////////////////////////////////////////////////
// Processor Control Loop
////////////////////////////////////////////////////////////////////
byte DATA_OUT;
byte DATA_IN;

inline __attribute__((always_inline))
void cpu_tick()
{ 
  static uint32_t input_timeout = 0;

  // Poll 6551 ACIA before each CPU cycle
  m6551_poll();
  
  // Poll VIA BEFORE clock to ensure IRQ pin state is ready
  m6522_poll();

  CLK_LOW;
  accurate_delay(NS_TO_TEENSY_CYCLE(50));     // Write HOLD Time  
  xDATA_DIR_IN();
  accurate_delay(NS_TO_TEENSY_CYCLE(150));    // Address Delay Time
  uP_ADDR = ADDR();
  accurate_delay(NS_TO_TEENSY_CYCLE(300));    // C_Low time.

  CLK_HIGH;

  // RDY is always HIGH - let CPU run freely
  // VIA timer naturally paces tracewalk execution
  digitalWriteFast(uP_RDY, HIGH);

  if (STATE_RW_N)
  {
    xDATA_DIR_OUT();

    if ((ROM_START <= uP_ADDR) && (uP_ADDR <= ROM_END)) {
      DATA_OUT = rom_bin[uP_ADDR - ROM_START];
    }
    else if ((RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END))
      DATA_OUT = RAM[uP_ADDR - RAM_START];
    else if ((ACIA_DATA <= uP_ADDR) && (uP_ADDR <= ACIA_CONTROL))
      DATA_OUT = m6551_read(uP_ADDR);
    else if ((VIA_BASE <= uP_ADDR) && (uP_ADDR <= VIA_BASE + 0xF))
      DATA_OUT = m6522_read(uP_ADDR);  

    SET_DATA_OUT(DATA_OUT);
    accurate_delay(NS_TO_TEENSY_CYCLE(500)); // C_High time.

#if outputDEBUG
    {
      char tmp[50];
      sprintf(tmp, "-- A=%0.4X D=%0.2X\n\r", uP_ADDR, DATA_OUT);
      Serial.print(tmp);
    }
#endif

    if (outputDEBUG && digitalReadFast(uP_RESET_N))
    {
      while (!Serial.available());
      Serial.read();
    }
  }
  else
  {
    accurate_delay(NS_TO_TEENSY_CYCLE(250));
    DATA_IN = xDATA_IN();

    if ((RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END)) {
      RAM[uP_ADDR - RAM_START] = DATA_IN;
    }
    else if ((ACIA_DATA <= uP_ADDR) && (uP_ADDR <= ACIA_CONTROL))
      m6551_write(uP_ADDR, DATA_IN);
    else if ((VIA_BASE <= uP_ADDR) && (uP_ADDR <= VIA_BASE + 0xF))
      m6522_write(uP_ADDR, DATA_IN);
#if outputDEBUG
    {
      char tmp[50];
      sprintf(tmp, "WR A=%0.4X D=%0.2X\n\r", uP_ADDR, DATA_IN);
      Serial.print(tmp);
    }
#endif

    accurate_delay(NS_TO_TEENSY_CYCLE(250));
  }

  // Timeout for trace walk if KGETIN stalls
  if (trace_walk_active) {
    // Disabled: Show CPU is still running
    // if (cycle_count % 50000 == 0) {
    //   Serial.print(F("[CPU] Cycles: "));
    //   Serial.print(cycle_count);
    //   Serial.print(F(" PC: $"));
    //   Serial.println(uP_ADDR, HEX);
    // }
    
    input_timeout++;
    if (input_timeout > 100000000) { // Increased: ~100s timeout for human interaction
      trace_walk_active = false;
      digitalWriteFast(uP_RDY, HIGH);
      m6522_init(); // Reset VIA state
#if ACIA_DEBUG
      Serial.println(F("[CPU] Trace walk timeout, exiting to SMON"));
#endif
      input_timeout = 0;
    }
  } else {
    input_timeout = 0;
  }

#if outputDEBUG
  clock_cycle_count++;
#endif
}

////////////////////////////////////////////////////////////////////
// Serial Event (not used for 6551)
////////////////////////////////////////////////////////////////////
inline __attribute__((always_inline))
void serialEvent0()
{
  // No-op for 6551 emulation
}

////////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////////
void setup() 
{
  Serial.begin(115200); // Explicitly set baud rate
  while (!Serial);

  Serial.println("\n");
  Serial.println("Configuration:");
  Serial.println("==============");
  print_teensy_version();
  Serial.print("Debug:      "); Serial.println(outputDEBUG, HEX);
  Serial.print("SRAM Size:  "); Serial.print(RAM_END - RAM_START + 1, DEC); Serial.println(" Bytes");
  Serial.print("SRAM_START: 0x"); Serial.println(RAM_START, HEX);
  Serial.print("SRAM_END:   0x"); Serial.println(RAM_END, HEX);
  Serial.println("");
  Serial.println("=======================================================");
  Serial.println("> SMON for RetroShield 6502");
  Serial.println("> with 6551 ACIA and 6522 VIA emulation");
  Serial.println("> supporting tracewalk mode");
  Serial.println("> added by kayto@github.com");
  Serial.println("=======================================================");

  uP_init();
  m6551_init();
  m6522_init(); 
  accurate_delay_init();

  uP_assert_reset();
  for (int i = 0; i < 25; i++) cpu_tick();
  uP_release_reset();
  Serial.println("Reset released, starting CPU...");
  Serial.println("\n");
}

////////////////////////////////////////////////////////////////////
// Loop()
////////////////////////////////////////////////////////////////////
void loop()
{
  byte i = 0;
  
  while (1)
  {
    cpu_tick();  // VIA and ACIA polled inside cpu_tick()

    i++;
    if (i == 0) serialEvent0();
    if (i == 0) Serial.flush();
  }
}