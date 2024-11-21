////////////////////////////////////////////////////////////////////
// RetroShield 6803 - SWTBUG ROM for SWTPC 6800
// 2020/07/13
// Version 0.1
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
// 7/31/2020    Initial Release (Paulmon2).                         E. Kocalar
//
////////////////////////////////////////////////////////////////////
// Options
//   USE_LCD_KEYPAD: Enable LCD/Keyboard Shield
//   outputDEBUG: Print memory access debugging messages.
////////////////////////////////////////////////////////////////////
#define USE_LCD_KEYPAD  0
#define outputDEBUG     0

////////////////////////////////////////////////////////////////////
// include the library code for LCD shield:
////////////////////////////////////////////////////////////////////
#include <avr/pgmspace.h>
#include "pins2_arduino.h"
#include <DIO2.h>

////////////////////////////////////////////////////////////////////
// Configuration
////////////////////////////////////////////////////////////////////
#if USE_LCD_KEYPAD

#include <LiquidCrystal.h>

  /*
    The circuit:
   * LCD RS pin to digital pin 12
   * LCD Enable pin to digital pin 11
   * LCD D4 pin to digital pin 5
   * LCD D5 pin to digital pin 4
   * LCD D6 pin to digital pin 3
   * LCD D7 pin to digital pin 2
   * LCD R/W pin to ground
   * 10K resistor:
   * ends to +5V and ground
   * wiper to LCD VO pin (pin 3)
  */

  #define LCD_RS  8
  #define LCD_EN  9
  #define LCD_D4  4
  #define LCD_D5  5
  #define LCD_D6  6
  #define LCD_D7  7
  #define LCD_BL  10
  #define LCD_BTN  0
  
  #define NUM_KEYS   5
  #define BTN_DEBOUNCE 10
  #define BTN_RIGHT  0
  #define BTN_UP     1
  #define BTN_DOWN   2
  #define BTN_LEFT   3
  #define BTN_SELECT 4
  const int adc_key_val[NUM_KEYS] = { 30, 180, 360, 535, 760 };
  int       key = -1;
  int       oldkey = -1;
  boolean   BTN_PRESS = 0;
  boolean   BTN_RELEASE = 0;

  LiquidCrystal lcd(LCD_RS, LCD_EN, LCD_D4, LCD_D5, LCD_D6, LCD_D7);
  int backlightSet = 25;
#endif


////////////////////////////////////////////////////////////////////
// 6803 DEFINITIONS
////////////////////////////////////////////////////////////////////

// 6803 HW CONSTRAINTS
// !!! TODO !!!
//

////////////////////////////////////////////////////////////////////
// MEMORY LAYOUT
////////////////////////////////////////////////////////////////////

// MEMORY LO - starts at $0080 because 6803 has internal 128 byte memory.
#define RAMLO_START   0x0080
#define RAMLO_END     0x0FFF
byte    RAMLO[RAMLO_END-RAMLO_START+1];

// MEMORY HI - start @ $F800 
#define RAMHI_START   0xF800
#define RAMHI_END     0xF8FF
byte    RAMHI[RAMHI_END-RAMHI_START+1];

// (ROM) - map ROM to end of memory
#define ROM_START   0xFC00
#define ROM_END     (ROM_START + (sizeof(rom_bin)-1) )

// (ROM) - map ROM to start of ROM
#define BOOT_START   0xFFF8
#define BOOT_END     0xFFFF

////////////////////////////////////////////////////////////////////
// File:    6800_counter_v1.1.asm
// Title:   6800 0-99 Counter with Delay
// Author:  kayto@github
// Date:    November 19, 2024
// Version: 1.1
////////////////////////////////////////////////////////////////////


// Convert bin to hex at http://tomeko.net/online_tools/file_to_hex.php?lang=en

PROGMEM const unsigned char rom_bin[] = {
0x8E, 0xF8, 0x7F, 0x7F, 0x00, 0x80, 0x7C, 0x00, 0x80, 0x96, 0x80, 0x81,
0x64, 0x27, 0x35, 0x16, 0x86, 0x00, 0xC1, 0x0A, 0x2D, 0x05, 0x4C, 0xC0,
0x0A, 0x20, 0xF7, 0x36, 0x4D, 0x27, 0x05, 0x8B, 0x30, 0xBD, 0xFC, 0x40,
0x17, 0x8B, 0x30, 0xBD, 0xFC, 0x40, 0x86, 0x0D, 0xBD, 0xFC, 0x40, 0x86,
0x0A, 0xBD, 0xFC, 0x40, 0xBD, 0xFC, 0x39, 0x20, 0xCD, 0xCE, 0xFF, 0xFF,
0x09, 0x26, 0xFD, 0x39, 0xB7, 0xF0, 0x00, 0x39, 0x3E, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
0xFF, 0xFF, 0xFC, 0x00,
};

PROGMEM const unsigned char boot_bin[] = {
  // Mapped to $FFF8 to $FFFF for boot vectors
  // 0xFC, 0x00,     // IRQ
  // 0xFC, 0x0A,     // SWI
  // 0xFC, 0x05,     // NMI
  // 0xFC, 0x21      // RST
  0xFC, 0x00,     // IRQ
  0xFC, 0x00,     // SWI
  0xFC, 0x00,     // NMI
  0xFC, 0x00      // RST
  // 0x00, 0x00,     // IRQ
  // 0x00, 0x00,     // SWI
  // 0x00, 0x00,     // NMI
  // 0x00, 0x00      // RST
};

////////////////////////////////////////////////////////////////////
// 6850 ACIA Implementation
// We use same 6850 for both Terminal and Punch Device
// F001/F002 same as F003/F004
////////////////////////////////////////////////////////////////////
#define M6850_START 0xF000
#define M6850_END   0xF003

#define M6850_CTRL_STAT 0xF001
#define M6850_TX_RX     0xF000

byte m6850_regTXD   = 0x00;
byte m6850_regRXD   = 0x00;
byte m6850_regCTRL  = 0b00010100;
byte m6850_regSTAT  = 0b00000100;

////////////////////////////////////////////////////////////////////
// 6803 Processor Control
////////////////////////////////////////////////////////////////////
//

/* Digital Pin Assignments */
#define DATA_OUT (PORTL)
#define DATA_IN  (PINL)
#define ADDR_H   (PINC)
#define ADDR_L   (PINL)
// 6803 uses multiplexed Addr & Data
#define ADDR     ((unsigned int) (ADDR_H << 8 | ADDR_L))

#define uP_E        22
#define uP_AS       24
#define uP_RW_N     26
#define uP_GPIO     28
#define uP_TIN      23
#define uP_TOUT     25
#define uP_SCLK     27
#define uP_TX       29
#define uP_IRQ1_N   38
#define uP_NMI_N    40
#define uP_RX       39
#define uP_X2       41
#define uP_RESET_N  50
#define uP_CLK      52
#define uP_X3       51
#define uP_X1       53

#define uP_SOD      (uP_TX)
#define uP_SID      (uP_RX)

// Fast routines to drive clock signals high/low; faster than digitalWrite
// required to meet >100kHz clock
//
#define CLK_HIGH      (PORTB = PORTB | 0b00000010)
#define CLK_LOW       (PORTB = PORTB & 0b11111101)

#define STATE_E       (PINA & (1<<0))
#define STATE_RW_N    (PINA & (1<<4))
#define STATE_AS      (PINA & (1<<2))
#define STATE_TX      (PINA & (1<<7))
#define STATE_RESET_N (PINB & (1<<3))

#define DIR_IN     0x00
#define DIR_OUT    0xFF
#define DATA_DIR   DDRL
#define ADDR_H_DIR DDRC
#define ADDR_L_DIR DDRL


unsigned long clock_cycle_count;
unsigned long clock_cycle_last;
unsigned long uP_start_millis;
unsigned long uP_stop_millis;
unsigned long uP_millis_last;

word uP_ADDR;
byte uP_ADDR_L;
byte uP_DATA;

inline __attribute__((always_inline))
void CLK_L_H()
{
  CLK_LOW; 
  delay(5); 
  CLK_HIGH;
  delay(5); 
  // Serial.print(" LH");
}

inline __attribute__((always_inline))
void CLK_H_L()
{
  CLK_HIGH; 
  delay(5); 
  CLK_LOW;
  delay(5); 
}

inline __attribute__((always_inline))
void uP_init()
{
  // Set directions
  DATA_DIR = DIR_IN;
  DATA_OUT = 0xFF;    // Enable Pull-ups
  
  ADDR_H_DIR = DIR_IN;
  ADDR_L_DIR = DIR_IN;

  pinMode(49, INPUT_PULLUP); 

  pinMode(uP_RESET_N, OUTPUT);
  pinMode(uP_CLK,     OUTPUT);
  pinMode(uP_E,       INPUT);
  pinMode(uP_AS,      INPUT);
  pinMode(uP_RW_N,    INPUT);
  pinMode(uP_IRQ1_N,  OUTPUT);
  pinMode(uP_NMI_N,   OUTPUT);
  pinMode(uP_X1,      INPUT);
  pinMode(uP_X2,      INPUT);
  pinMode(uP_X3,      INPUT);
  pinMode(uP_GPIO,    INPUT);
  pinMode(uP_TIN,     INPUT);
  pinMode(uP_TOUT,    INPUT);
  pinMode(uP_SCLK,    INPUT);
  pinMode(uP_TX,      INPUT);
  pinMode(uP_RX,      INPUT_PULLUP);

  uP_assert_reset();
  digitalWrite(uP_CLK, LOW);
  
}

inline __attribute__((always_inline))
void uP_assert_reset()
{
  // Drive RESET conditions
  digitalWrite(uP_RESET_N, LOW);
  
  digitalWrite(uP_IRQ1_N,  HIGH);
  digitalWrite(uP_NMI_N, HIGH);
  digitalWrite(uP_RX, INPUT_PULLUP);

  // Toggle reset to put 6803 in reset 
  CLK_H_L();
  CLK_H_L();
  CLK_H_L();
  CLK_H_L();

  // Upon reset release, 6803 latches port signals 
  // P22_SCLK - P21_TOUT - P20_TIN
  // 010 = Ext ROM, Int RAM  <<== Default
  // 011 = Ext ROM, Ext RAM
  pinMode(uP_SCLK,    OUTPUT); digitalWrite(uP_SCLK,  LOW);
  pinMode(uP_TOUT,    OUTPUT); digitalWrite(uP_TOUT,  HIGH);
  pinMode(uP_TIN,     OUTPUT); digitalWrite(uP_TIN,   LOW);

}

// Un-Reset split into two steps so we can
// initialize the bus mode correctly.
// 
inline __attribute__((always_inline))
void uP_release_reset1()
{
  // Release RESET conditions
  digitalWrite(uP_RESET_N, HIGH);
}

inline __attribute__((always_inline))
void uP_release_reset2()
{
  // Release Mode strap gpio's after RESET is released
  pinMode(uP_SCLK,    INPUT); 
  pinMode(uP_TOUT,    INPUT); 
  pinMode(uP_TIN,     INPUT);
}

////////////////////////////////////////////////////////////////////
// Processor Control Loop
////////////////////////////////////////////////////////////////////
// This is where the action is.
// it reads processor control signals and acts accordingly.
//
// 6803 has multiplexed Data7..0/AD7..0 Bus
// AS: 1->0   -> latch A0..A7
// 

inline __attribute__((always_inline))
void cpu_tick()
{
  // 6803 clock E is CLK/4, so we toggle CLK 4 times

  ////////////////////
  CLK_LOW;  //delay(1);      
  CLK_HIGH; //delay(1);

  ////////////////////
  CLK_LOW;  //delay(1);    
  uP_ADDR = ADDR;               // AS asserted. Latch 16bit address.
  CLK_HIGH; //delay(1); 

  ////////////////////
  CLK_LOW;  //delay(1);
  CLK_HIGH; //delay(1);

  ////////////////////
  CLK_LOW;  //delay(1);
  CLK_HIGH; //delay(1);

  // Do the transaction here:
  if (STATE_RW_N)    
  //////////////////////////////////////////////////////////////////
  // HIGH = READ
  {
    // change DATA port to output to uP:
    DATA_DIR = DIR_OUT;

    // BOOT ROM?
    if ( (BOOT_START <= uP_ADDR) && (uP_ADDR <= BOOT_END) )
    {
      DATA_OUT = pgm_read_byte_near(boot_bin + ((uP_ADDR - BOOT_START) ) );
    }
    else    
    // ROM?
    if ( (ROM_START <= uP_ADDR) && (uP_ADDR <= ROM_END) )
    {
      DATA_OUT = pgm_read_byte_near(rom_bin + ((uP_ADDR - ROM_START) ) );
    }
    else
    // RAM HI?
    if ( (RAMHI_START <= uP_ADDR) && (uP_ADDR <= RAMHI_END) )
      DATA_OUT = RAMHI[uP_ADDR - RAMHI_START];
    else    
    // RAM LO?
    if ( (RAMLO_START <= uP_ADDR) && (uP_ADDR <= RAMLO_END) )
      DATA_OUT = RAMLO[uP_ADDR - RAMLO_START];
    else
    if ( (uP_ADDR == M6850_CTRL_STAT) || (uP_ADDR == M6850_CTRL_STAT+2) )
    {
      DATA_OUT = m6850_regSTAT;
    }
    else
    if ( (uP_ADDR == M6850_TX_RX) || (uP_ADDR == M6850_TX_RX+2) )
    {
      DATA_OUT = m6850_regRXD;
      m6850_regSTAT = m6850_regSTAT & (0b11111101);       // Clear Char Received? bit
    }
    else
    {
      // Unknown device
      DATA_OUT = 0xFF;        
#if outputDEBUG   
      Serial.print("MISSING: READ $"); Serial.println(uP_ADDR, HEX);
#endif
    }

#if outputDEBUG
    char tmp[20];
    // sprintf(tmp, "-- A=%0.4X D=%0.2X TMR=%0.2X\n", uP_ADDR, DATA_OUT, MC14536B_counter);
    // Serial.write(tmp);
    // delay(500);
#endif

  } 
  else 
  //////////////////////////////////////////////////////////////////
  // R/W = LOW = WRITE
  {
    // RAM HI?
    if ( (RAMHI_START <= uP_ADDR) && (uP_ADDR <= RAMHI_END) )
      RAMHI[uP_ADDR - RAMHI_START] = DATA_IN;
    else
    // RAM LO?
    if ( (RAMLO_START <= uP_ADDR) && (uP_ADDR <= RAMLO_END) )
      RAMLO[uP_ADDR - RAMLO_START] = DATA_IN;
    else
    if ( (uP_ADDR == M6850_CTRL_STAT) || (uP_ADDR == M6850_CTRL_STAT+2) )
    {
      m6850_regCTRL = DATA_IN;
    }
    else
    if ( (uP_ADDR == M6850_TX_RX) || (uP_ADDR == M6850_TX_RX+2) )
    {
      Serial.write( m6850_regTXD = DATA_IN );
    }

#if outputDEBUG
    else
    {
      // Unknown device
      Serial.print("MISSING: WRITE $"); Serial.print(uP_ADDR, HEX); Serial.print(" <= $"); Serial.println(DATA_IN, HEX);        
    }
#endif
    
#if outputDEBUG
    char tmp[20];
    // sprintf(tmp, "WR A=%0.4X D=%0.2X TMR=%0.2X\n", uP_ADDR, DATA_IN, MC14536B_counter);
    // Serial.write(tmp);
    // delay(500);
#endif
  }
  
  ////////////////////
  // Set clock low to handle hold times
  // and tristate Arduino's databus.

  CLK_LOW;
  DATA_DIR = DIR_IN;

}

////////////////////////////////////////////////////////////////////
// Serial Event
////////////////////////////////////////////////////////////////////

inline __attribute__((always_inline))
void serialEvent6850() 
{
  if (Serial.available())
    if ((m6850_regSTAT & 0x02) == 0x00)      // read serial byte only if char already processed
    {
      int ch = toupper( Serial.read() );
      m6850_regRXD = ch;               
      m6850_regSTAT = m6850_regSTAT | 0x02;       // set Char Received? bit
    }
  return;
}

////////////////////////////////////////
// Soft-UART for 6803's Hard-UART
////////////////////////////////////////

#define k6803_UART_BAUD (16*12)
byte txd_6803;
word txd_delay = k6803_UART_BAUD*1.5;     // start capturing 1.5 bits later, middle
byte txd_bit = 0;

byte rxd_6803;
word rxd_delay = k6803_UART_BAUD;         // start output 1 bit at a time
byte rxd_bit = 0;

inline __attribute__((always_inline))
void serialEvent6803()
{
  // RXD
  if (rxd_bit == 0 && Serial.available())
  {
    rxd_bit = 9;
    rxd_6803 = Serial.read();
    rxd_delay = 192;

    pinMode2(uP_RX, OUTPUT);
    digitalWrite2(uP_RX, LOW);      // Start bit, low
  }
  else
  if (rxd_bit)
  {
    rxd_delay--;
    if (rxd_delay == 0)
    {
      digitalWrite2(uP_RX, rxd_6803 & 0x01);
      rxd_6803 = (rxd_6803 >> 1);
      rxd_delay = 192;

      // are we done yet?  1bit left, which is stop bit
      rxd_bit--;
      if (rxd_bit == 0x01)
      {
        // set bit0 to output stop bit
        rxd_6803 = 0x01;
      }
      else
      if (rxd_bit == 0)
        pinMode2(uP_RX, INPUT_PULLUP);
    }
  }

  // TXD
  // Check for start bit
  if (txd_bit == 0 && !STATE_TX)
  {
    txd_bit  = 9;   // need to receive 8(data)+1(stop) bits
    txd_6803 = 0;   // OR incoming bits to this.
    txd_delay = 288;
  }
  else
  if (txd_bit)
  {
    txd_delay--;
    if (txd_delay == 0)
    {
      txd_6803 = (txd_6803 >> 1) | (STATE_TX << 4);
      txd_delay = 192;

      // are we done yet?  1bit left, which is stop bit
      if ((--txd_bit) == 0x01)
      {
        Serial.write(txd_6803);
        // no more bits to receive.
        // stop bit will be ignored.
      }
    }
  }  
}

////////////////////////////////////////////////////////////////////
// LCD/Keyboard functions
////////////////////////////////////////////////////////////////////

#if (USE_LCD_KEYPAD)

////////////////////////////////////////////////////////////////////
// int getKey() - LCD/Keyboard function from vendor
////////////////////////////////////////////////////////////////////

int getKey()
{
  key = get_key2();
  if (key != oldkey)
    {
      delay(BTN_DEBOUNCE);
      key = get_key2();
      if (key != oldkey) {
        oldkey = key;
        if (key == -1)
          BTN_RELEASE = 1;
        else
          BTN_PRESS = 1;
      }
    } else {
      BTN_PRESS = 0;
      BTN_RELEASE = 0;
    }
  return (key != -1);
}

int get_key2()
{
  int k;
  int adc_key_in;

  adc_key_in = analogRead( LCD_BTN );
  for( k = 0; k < NUM_KEYS; k++ )
  {
    if ( adc_key_in < adc_key_val[k] )
    {
      return k;
    }
  }
  if ( k >= NUM_KEYS )
    k = -1;
  return k;
}

////////////////////////////////////////////////////////////////////
// Button Press Callbacks - LCD/Keyboard function from vendor
////////////////////////////////////////////////////////////////////

void btn_Pressed_Select()
{
  // toggle LCD brightness
  analogWrite(LCD_BL, (backlightSet = (25 + backlightSet) % 100) );
}

void btn_Pressed_Left()
{
  // Serial.println("Left.");
  digitalWrite(uP_NMI_N, LOW);
}

void btn_Pressed_Right()
{
  // Serial.println("Right.");
  digitalWrite(uP_NMI_N, HIGH);
}

void btn_Pressed_Up()
{
  // Serial.println("Up.");
  
  // release uP_RESET
  digitalWrite(uP_RESET_N, HIGH);
}

void btn_Pressed_Down()
{
  // Serial.println("Down.");
  
  // assert uP_RESET
  digitalWrite(uP_RESET_N, LOW);
  
  // flush serial port
  while (Serial.available() > 0)
    Serial.read();
}

void process_lcdkeypad()
{
  // Handle key presses
  //
  if ( getKey() ) {
    // button pressed
    if ( BTN_PRESS ) {
      if (key == BTN_SELECT) btn_Pressed_Select();
      if (key == BTN_UP)     btn_Pressed_Up();
      if (key == BTN_DOWN)   btn_Pressed_Down();
      if (key == BTN_LEFT)   btn_Pressed_Left();
      if (key == BTN_RIGHT)  btn_Pressed_Right();      
    }
  } else
   // display processor info & performance
   // if (clock_cycle_count % 10 == 0) 
  {
    char tmp[20];
    float freq;
    
    lcd.setCursor(0, 0);
    // lcd.print(clock_cycle_count);
    sprintf(tmp, "A=%0.4X D=%0.2X", uP_ADDR, DATA_OUT);
    lcd.print(tmp);
    lcd.setCursor(0,1);
    
    freq = (float) (clock_cycle_count - clock_cycle_last) / (millis() - uP_millis_last + 1);
    lcd.print(freq);  lcd.print(" kHz  6803");
    clock_cycle_last = clock_cycle_count;
    uP_millis_last = millis();
  }
}
#endif

////////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////////

void setup() 
{

  Serial.begin(115200);

  Serial.write(27);       // ESC command
  Serial.print("[2J");    // clear screen command
  Serial.write(27);
  Serial.print("[H");
  Serial.println("\n");
  Serial.println("Configuration:");
  Serial.println("==============");
  Serial.print("Debug:      "); Serial.println(outputDEBUG, HEX);
  Serial.print("SRAM Size:  "); Serial.print(RAMLO_END - RAMLO_START + 1, DEC); Serial.println(" Bytes");
  Serial.print("SRAM_START: 0x00"); Serial.println(RAMLO_START, HEX); 
  Serial.print("SRAM_END:   0x0"); Serial.println(RAMLO_END, HEX); 
  Serial.print("ROM_START:  0x"); Serial.println(ROM_START, HEX);
  Serial.print("ROM_END:    0x"); Serial.println(ROM_END, HEX);
  Serial.print("BOOT_START: 0x"); Serial.println(BOOT_START, HEX);
  Serial.print("BOOT_END:   0x"); Serial.println(BOOT_END, HEX);
  
  Serial.println("");
  Serial.println("=======================================================");
  Serial.println("> 6800 0-99 Counter with Delay");
//  Serial.println("> Author:  kayto@github");
//  Serial.println("> Date:    November 19, 2024");
//  Serial.println("> Version: 1.1");
//  Serial.println("");
  Serial.println("=======================================================");
    
#if (USE_LCD_KEYPAD)
  pinMode(LCD_BL, OUTPUT);
  analogWrite(LCD_BL, backlightSet);  
  lcd.begin(16, 2);
#endif

  // Initialize processor GPIO's
  uP_init();
  
  //////////////////////////////////////////////////
  // Reset processor while during two things
  // 1: drive bootmode gpios.
  // 2: sync RetroShield to 6803's E output (which is clk / 4)
  //////////////////////////////////////////////////
  uP_assert_reset();
  if (outputDEBUG) Serial.println("Reset - RESET");
  
  // Wait for E go HIGH
  while(STATE_E != true)  CLK_H_L(); 
  if (outputDEBUG) Serial.println("Reset - EHIGH");
  // Wait for E go LOW
  while(STATE_E != false) CLK_H_L(); 
  if (outputDEBUG) Serial.println("Reset - ELOW");

  for(int i=0;i<25;i++) cpu_tick();
  // Go, go, go
  uP_release_reset1();    // Let 6803 latch bootmode gpio's.
  if (outputDEBUG) Serial.println("Reset - BOOTMODE");
  cpu_tick();
  uP_release_reset2();    // Release bootstrap gpio's.
  if (outputDEBUG) Serial.println("Reset - RUN");
}

////////////////////////////////////////////////////////////////////
// Loop()
////////////////////////////////////////////////////////////////////

void loop()
{
  byte i = 0;
  word j = 0;
  
  // Loop forever
  //
  while(1)
  {    
    //////////////////////////////
    cpu_tick();
    if ( (--i) == 0 )
      serialEvent6850();     // handle serial every 256 cpu clock cycles.

#if (0*USE_LCD_KEYPAD)
  // execute lcdkeypad() when word i overflows (simple counter)
    if (j++ == 0) process_lcdkeypad();
#endif
    
#if outputDEBUG
    // delay(100);
#endif
  }
}
