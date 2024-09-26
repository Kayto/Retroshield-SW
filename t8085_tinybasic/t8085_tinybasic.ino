////////////////////////////////////////////////////////////////////
// RetroShield 8085 for Teensy
// 2019/08/12
// Version 1.0
// Erturk Kocalar
//
// The MIT License (MIT)
//
// Copyright (c) 2019 Erturk Kocalar, 8Bitforce.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
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
// 8/12/2019    Initial Release (Paulmon2).                         E. Kocalar
// 8/31/2024    Added teensy 4.1 support.                           E. Kocalar
//
////////////////////////////////////////////////////////////////////
// Options
//   outputDEBUG: Print memory access debugging messages.
////////////////////////////////////////////////////////////////////
#define outputDEBUG     0

////////////////////////////////////////////////////////////////////
// 8085 DEFINITIONS
////////////////////////////////////////////////////////////////////

#include <DIO2.h>           // Fast I/O Library
#include "setuphold.h"      // Delays required to meet setup/hold
#include "portmap.h"        // Pin mapping to cpu
#include "memorymap.h"      // Memory Map (ROM, RAM, PERIPHERALS)
#include "terminal.h"       // terminal Emulation
#include "buttons.h"        // Buttons P & C (optional)

// 8085 HW CONSTRAINTS
// !!! TODO !!!
//

unsigned long clock_cycle_count;

word uP_ADDR;
byte uP_ADDR_L;
byte uP_DATA;

void uP_init()
{
#if outputDEBUG
  Serial.println("uP_init()\n");
#endif

  // Set directions for ADDR & DATA Bus.
  configure_PINMODE_ADDR();
  configure_PINMODE_DATA();
  
  // byte pinTable[] = {
  //   5,21,20,6,8,7,14,2,     // D7..D0
  //   27,26,4,3,38,37,36,35,  // A15..A8
  //   12,11,25,10,9,23,22,15  // A7..A0
  // };
  // for (int i=0; i<24; i++)
  // {
  //   pinMode(pinTable[i],INPUT);
  // } 

  pinMode(uP_RESET,   OUTPUT);
  pinMode(uP_ALE,     INPUT);
  pinMode(uP_IO_M,    INPUT);
  pinMode(uP_RD_N,    INPUT);
  pinMode(uP_WR_N,    INPUT);
  pinMode(uP_S0,      INPUT);
  pinMode(uP_S1,      INPUT);

  pinMode(uP_TRAP,    OUTPUT);
  pinMode(uP_RST75,   OUTPUT);
  pinMode(uP_RST65,   OUTPUT);
  pinMode(uP_RST55,   OUTPUT);
  pinMode(uP_INTR,    OUTPUT);
  pinMode(uP_INTA_N,  INPUT);

  pinMode(uP_SOD,     INPUT);
  pinMode(uP_SID,     OUTPUT);

  pinMode(uP_CLK,     OUTPUT);

  uP_assert_reset();
  digitalWrite(uP_CLK, LOW);
  
  clock_cycle_count = 0;
}

void uP_assert_reset()
{
#if outputDEBUG
  Serial.println("uP_assert_reset()\n");
#endif

  // Drive RESET conditions
  digitalWrite(uP_RESET, LOW);
  digitalWrite(uP_RESET, HIGH); delayMicroseconds(100);
  digitalWrite(uP_RESET, LOW);
  
  digitalWrite(uP_TRAP,  LOW);
  digitalWrite(uP_RST75, LOW);
  digitalWrite(uP_RST65, LOW);
  digitalWrite(uP_RST55, LOW);
  digitalWrite(uP_INTR,  LOW);
  digitalWrite(uP_SID,   HIGH);
}

void uP_release_reset()
{
#if outputDEBUG
  Serial.println("uP_release_reset()\n");
#endif

  // Drive RESET conditions
  digitalWrite(uP_RESET, HIGH);
}

////////////////////////////////////////////////////////////////////
// Processor Control Loop
////////////////////////////////////////////////////////////////////
// This is where the action is.
// it reads processor control signals and acts accordingly.
//
// 80805 is similar to Z80 but has multiplexed Data7..0/AD7..0 Bus
// ALE=HIGH     -> latch A0..A7
// IO_M = LOW -> Low: Memory, High: IO access
// RD_N = LOW   -> Enable RAM data output
// WR_N = LOW   -> Enable RAM data input

// #if outputDEBUG
//   #define DELAY_FACTOR_H() delayMicroseconds(100)
//   #define DELAY_FACTOR_L() delayMicroseconds(100)
// #else
//   #define DELAY_FACTOR_H() asm volatile("nop\nnop\nnop\nnop\n");
//   #define DELAY_FACTOR_L() asm volatile("nop\nnop\nnop\nnop\n");
// #endif

byte prevRD_N = 1;            // for detecting edges.
byte prevWR_N = 1;            // for detecting edges.
byte DATA_latched = 0;        // used for edge detected section.

inline __attribute__((always_inline))
void cpu_tick()
{
  CLK_HIGH;
  DELAY_FACTOR_H();

  ////////////////////////////////////////////////////////////
  // ALE
  ////////////////////////////////////////////////////////////
  if (STATE_ALE)      // need to capture address bits when ALE is high.
  {
    xDATA_DIR_IN(); DELAY_FOR_BUFFER();
    uP_ADDR   = ADDR();
    uP_ADDR_L = (byte) (uP_ADDR & 0xFF);   // (ADDR() & 0xFF))
  } 
  else
  //////////////////////////////////////////////////////////////////////
  // Memory Access?
  //////////////////////////////////////////////////////////////////////
  if (!STATE_IO_M)
  {
    ////////////////////////////////////////////////////////////
    // RD_N Falling Edge
    // Note: We perform actual read operation once during falling
    // edge and then continue to output this value as long as
    // RD_N is low.  This is done to prevent multiple reads from
    // devices like FTDI (not used for 8085, but I like this
    // method for future use. 
    // Similar method is done for WR_N where we perform the actual
    // write on WR_N rising edge.
    ////////////////////////////////////////////////////////////
    if (!STATE_RD_N && prevRD_N)     // Falling edge of RD_N
    {
      // Serial.write("RR \n");
      // digitalWrite(7, HIGH);
      // change DATA port to output to uP:
      // DATA_DIR = DIR_OUT;
      xDATA_DIR_OUT();
      
      // ROM?
      if ( (ROM_START <= uP_ADDR) && (uP_ADDR <= ROM_END) )
        DATA_latched = rom_bin [ (uP_ADDR - ROM_START) ];
      else
      // Execute from RAM?
      if ( (RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END) )
        DATA_latched = RAM[uP_ADDR - RAM_START];
      else
        DATA_latched = 0x00;      // Dummy 0x00 out for unmapped memory locations
  
      // Start driving the databus out
      SET_DATA_OUT( DATA_latched );
      DELAY_FOR_BUFFER();

#if outputDEBUG
      char tmp[40];
      sprintf(tmp, "-- A=%0.4X D=%0.2X\n", uP_ADDR, DATA_latched);
      Serial.write(tmp);
#endif

    } 
    else
    ////////////////////////////////////////////////////////////
    // RD_N
    ////////////////////////////////////////////////////////////
    if (!STATE_RD_N)    // Continue to output data read on falling edge ^^^
    {
      // digitalWrite(7, HIGH);
      // change DATA port to output to uP:
      // DATA_DIR = DIR_OUT;
      xDATA_DIR_OUT();
  
      //uP_TOGGLE_RESET();
      SET_DATA_OUT( DATA_latched );
      DELAY_FOR_BUFFER();

    } 
    else
    ////////////////////////////////////////////////////////////
    // WR_N
    ////////////////////////////////////////////////////////////
    // Start capturing data_in but don't write it to destination yet
    if (!STATE_WR_N)
    {
      xDATA_DIR_IN(); DELAY_FOR_BUFFER();
      DATA_latched = xDATA_IN();
    }
    else
    ////////////////////////////////////////////////////////////
    // WR_N Rising Edge
    ////////////////////////////////////////////////////////////
    // Write data to destination when WR# goes high.
    if (STATE_WR_N && !prevWR_N)
    {
      // digitalWrite(7, HIGH);
      // Memory Write
      if ( (RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END) )
        RAM[uP_ADDR - RAM_START] = DATA_latched;

#if outputDEBUG
      char tmp[20];
      sprintf(tmp, "WR A=%0.4X D=%0.2X\n", uP_ADDR, DATA_latched);
      Serial.write(tmp);
#endif

    }      
  }

  else

  //////////////////////////////////////////////////////////////////////
  // IO Access?
  //////////////////////////////////////////////////////////////////////
  if (STATE_IO_M)
  {    
    // IO Read?
    if (!STATE_RD_N && prevRD_N)    // perform actual read on falling edge
    {
      // digitalWrite(7, HIGH);
      // change DATA port to output to uP:
      // DATA_DIR = DIR_OUT;
      xDATA_DIR_OUT();

      // 8251 access

      if ( uP_ADDR_L == ADDR_8251_DATA)
      {
        // DATA register access
        DATA_latched = reg8251_DATA = toupper( Serial.read() );
        // clear RxRDY bit in 8251
        reg8251_STATUS = reg8251_STATUS & (~STAT_8251_RxRDY);
        // Serial.write("8251 serial read\n");
      }
      else
      if ( uP_ADDR_L == ADDR_8251_MODCMD )
      {
        // Mode/Command Register access
        if (reg8251_STATE == STATE_8251_RESET)
          DATA_latched = reg8251_MODE;
        else
          DATA_latched = reg8251_STATUS;
      }
      // output data at this cycle too
      SET_DATA_OUT( DATA_latched );
      DELAY_FOR_BUFFER();
      
#if (outputDEBUG)
      {
        char tmp[40];
        sprintf(tmp, "IORQ RD#=%0.1X A=%0.4X D=%0.2X\n", STATE_RD_N, uP_ADDR, DATA_latched);
        Serial.write(tmp);
      }
#endif
      
    } 
    else
    // continuing IO Read?
    if (!STATE_RD_N)    // continue output same data
    {
      // digitalWrite(7, HIGH);
      // change DATA port to output to uP:
      xDATA_DIR_OUT();

      SET_DATA_OUT( DATA_latched );
      DELAY_FOR_BUFFER();

    } 
    else
    ////////////////////////////////////////////////////////////
    // WR_N
    ////////////////////////////////////////////////////////////
    // Start capturing data_in but don't write it to destination yet
    if (!STATE_WR_N)
    {
      xDATA_DIR_IN(); DELAY_FOR_BUFFER();
      DATA_latched = xDATA_IN();
    } 
    else
    // IO Write?
    if (STATE_WR_N && !prevWR_N)      // perform write on rising edge
    {
      // digitalWrite(7, HIGH);
      // 8251 access
      if (uP_ADDR_L == ADDR_8251_DATA)
      {
        // write to DATA register
        reg8251_DATA = DATA_latched;
        // TODO: Spit byte out to serial
        Serial.write(reg8251_DATA);        
      }
      else
      if ( uP_ADDR_L == ADDR_8251_MODCMD )
      {
        // write to Mode/Command Register
        if (reg8251_STATE == STATE_8251_RESET)
        {
          // 8251 changes from MODE to COMMAND
          reg8251_STATE = STATE_8251_INITIALIZED;
          // we ignore the mode command for now.
          // reg8251_MODE = DATA_IN
          // Serial.write("8251 reset\n");
          
        } else {
          // Write to 8251 command register
          reg8251_COMMAND = DATA_latched;
          // TODO: process command sent
        }
      }
#if (outputDEBUG)
      {
        char tmp[40];
        sprintf(tmp, "IORQ WR#=%0.1X A=%0.4X D=%0.2X\n", STATE_WR_N, uP_ADDR, DATA_latched);
        Serial.write(tmp);
      }
#endif
      
    } 
  }

  // Capture previous states for edge detection
  prevRD_N = STATE_RD_N;
  prevWR_N = STATE_WR_N;

  //////////////////////////////////////////////////////////////////////
  // start next cycle

  CLK_LOW;    // E goes low
  DELAY_FACTOR_L();
  
  if (STATE_ALE)      // need to capture address bits when ALE is high.
  {
    // xDATA_DIR_IN();
    uP_ADDR   = ADDR();
    uP_ADDR_L = (uP_ADDR & 0xFF);
  } 
  
  // turn databus to input if 8085 is not reading from ROM/RAM/IO.
  if (STATE_RD_N)
  {
    // SET_DATA_OUT(0xFF);
    xDATA_DIR_IN(); DELAY_FOR_BUFFER();
  }
}

////////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////////

void setup() 
{

  Serial.begin(115200);
  while (!Serial);
  
  Serial.write(27);       // ESC command
  Serial.print("[2J");    // clear screen command
  Serial.write(27);
  Serial.print("[H");
  Serial.println("\n");
  Serial.println("Configuration:");
  Serial.println("==============");
  Serial.print("Debug:      "); Serial.println(outputDEBUG, HEX);
  Serial.print("SRAM Size:  "); Serial.print(RAM_END - RAM_START + 1, DEC); Serial.println(" Bytes");
  Serial.print("SRAM_START: 0x"); Serial.println(RAM_START, HEX); 
  Serial.print("SRAM_END:   0x"); Serial.println(RAM_END, HEX); 
  Serial.print("ROM Size:   "); Serial.print(ROM_END - ROM_START + 1, DEC); Serial.println(" Bytes");
  //Serial.print("ROM_START:  0x"); Serial.println(ROM_START, HEX);
  //Serial.print("ROM_END:    0x"); Serial.println(ROM_END, HEX);
  Serial.println("");
  Serial.println("=======================================================");
  Serial.println("> TINY BASIC FOR INTEL 8080 VERSION 2.0");
  Serial.println("> BY LI-CHEN WANG");
  Serial.println("> MODIFIED AND TRANSLATED TO INTEL MNEMONICS");
  Serial.println("> BY ROGER RAUSKOLB");
  Serial.println("> 10 OCTOBER,1976 @COPYLEFT ALL WRONGS RESERVED");
  Serial.println("> downloaded from MiniMax85, located at");
  Serial.println("> https://github.com/skiselev/minimax8085");
  Serial.println("=======================================================");
  // Initialize processor GPIO's
  uP_init();
  intel8251_init();

  Serial.println("\n");

  // Reset processor
  //
  uP_assert_reset();
  for(int i=0;i<25;i++) cpu_tick();
  
  // Go, go, go
  uP_release_reset();
}

////////////////////////////////////////////////////////////////////
// Loop()
////////////////////////////////////////////////////////////////////

void loop()
{
  word j = 0;
  
  // Loop forever
  //
  while(1)
  {    
    //////////////////////////////

    cpu_tick();

    if (j-- == 0)
    {
      serialEvent8251();      // check for incoming chars
      // serialEvent8085();     // handles SOD/SID uart if used.
      
      Serial.flush();
      j = 500;
    }
  }
}
