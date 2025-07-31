////////////////////////////////////////////////////////////////////
// RetroShield 6502 for Teensy 3.5
// Apple 1
//
// 2019/09/13
// Version 0.1

// The MIT License (MIT)

// Copyright (c) 2019 Erturk Kocalar, 8Bitforce.com

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
// Date         Comments                                            Author
// -----------------------------------------------------------------------------
// 09/13/2019   Bring-up on Teensy 3.5.                             Erturk
// 01/11/2024   Added Teensy 4.1 support.                           Erturk
// 03/25/2024   Changed to more accurate timing for 1MHz op.        Erturk

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

unsigned long clock_cycle_count;
unsigned long clock_cycle_last;

word          uP_ADDR;
byte          uP_DATA;

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
  CLK_LOW;
  accurate_delay(NS_TO_TEENSY_CYCLE(50));     // Write HOLD Time  
  xDATA_DIR_IN();
  accurate_delay(NS_TO_TEENSY_CYCLE(150));    // Address Delay Time
  uP_ADDR = ADDR();
  accurate_delay(NS_TO_TEENSY_CYCLE(300));    // C_Low time.

  CLK_HIGH;

  if (STATE_RW_N)
  {
    xDATA_DIR_OUT();

    if ((ROM_START <= uP_ADDR) && (uP_ADDR <= ROM_END))
      DATA_OUT = rom_bin[uP_ADDR - ROM_START];
//    else if ((BASIC_START <= uP_ADDR) && (uP_ADDR <= BASIC_END))
//      DATA_OUT = basic_bin[uP_ADDR - BASIC_START];
    else if ((RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END))
      DATA_OUT = RAM[uP_ADDR - RAM_START];
    else if ((ACIA_DATA <= uP_ADDR) && (uP_ADDR <= ACIA_CONTROL))
      DATA_OUT = m6551_read(uP_ADDR);

    SET_DATA_OUT(DATA_OUT);
    accurate_delay(NS_TO_TEENSY_CYCLE(500)); // C_High time.

#if outputDEBUG
    {
      char tmp[50];
      sprintf(tmp, "-- A=%0.4X D=%0.2X\n\r", uP_ADDR, DATA_OUT);
      Serial.write(tmp);
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

    if ((RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END))
      RAM[uP_ADDR - RAM_START] = DATA_IN;
    else if ((ACIA_DATA <= uP_ADDR) && (uP_ADDR <= ACIA_CONTROL))
      m6551_write(uP_ADDR, DATA_IN);

#if outputDEBUG
    {
      char tmp[50];
      sprintf(tmp, "WR A=%0.4X D=%0.2X\n\r", uP_ADDR, DATA_IN);
      Serial.write(tmp);
    }
#endif

    accurate_delay(NS_TO_TEENSY_CYCLE(250));
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
  Serial.begin(0);
  while (!Serial);

  Serial.write(27);
  Serial.print("[2J");
  Serial.write(27);
  Serial.print("[H");
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
  Serial.println("> EhBASIC for RetroShield 6502");
  Serial.println("> with 6551 ACIA emulation");
  Serial.println("> EhBASIC by Lee Davidson");
  Serial.println("> https://github.com/Klaus2m5/6502_EhBASIC_V2.22");
  Serial.println("=======================================================");
  //Serial.println("Notes:");

  uP_init();
  m6551_init();
  accurate_delay_init();

  uP_assert_reset();
  for (int i = 0; i < 25; i++) cpu_tick();
  uP_release_reset();

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
    m6551_poll(); // poll USB Serial for incoming data
    cpu_tick();

    i++;
    if (i == 0) serialEvent0();
    if (i == 0) Serial.flush();
  }
}
