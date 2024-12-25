////////////////////////////////////////////////////////////////////
// RetroShield 8031
// 2019/08/12
// Version 1.01
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
// 9/02/2019    GPIO indicates 8031 TXD                             E. Kocalar
//
////////////////////////////////////////////////////////////////////
// Options
//   USE_SPI_RAM: Enable Microchip 128KB SPI-RAM  (Details coming up)
//   USE_LCD_KEYPAD: Enable LCD/Keyboard Shield
//   outputDEBUG: Print memory access debugging messages.
////////////////////////////////////////////////////////////////////
#define USE_SPI_RAM     0
#define USE_LCD_KEYPAD  0
#define outputDEBUG     0

////////////////////////////////////////////////////////////////////
// include the library code for LCD shield:
////////////////////////////////////////////////////////////////////
#include <avr/pgmspace.h>
#include "pins2_arduino.h"
#include <DIO2.h>

////////////////////////////////////////////////////////////////////
// SPI FUNCTIONS
//
// 23L1024 SPI RAM (128K)
// $00000 - $1FFFF
////////////////////////////////////////////////////////////////////
#if (USE_SPI_RAM)

GPIO_pin_t LED1          = DPA4;
GPIO_pin_t LED2          = DPA5;

GPIO_pin_t PIN_SIO3      = DPA3;
GPIO_pin_t PIN_SIO2      = DPA2;
GPIO_pin_t PIN_SIO1      = DPA1;
GPIO_pin_t PIN_SIO0      = DPA0;
GPIO_pin_t PIN_HOLD      = DPA3; // DP7;
GPIO_pin_t PIN_SCK       = DP13; // DP6;
GPIO_pin_t PIN_SI        = DP11; // DP5;
GPIO_pin_t PIN_SO        = DP12; // DP3;
GPIO_pin_t PIN_CS        = DP4;  // DP2;

inline __attribute__((always_inline))
void spi_reset()
{
  digitalWrite2f(PIN_CS, LOW);
  spi_send(0xFF);
  digitalWrite2f(PIN_CS, HIGH);
}

inline __attribute__((always_inline))
byte spi_get_mode()
{
  byte mode;
  
  digitalWrite2f(PIN_CS, LOW);
  spi_send(0x05);
  mode = spi_receive();
  digitalWrite2f(PIN_CS, HIGH);
  return mode;
}

inline __attribute__((always_inline))
byte spi_set_mode(byte mode)
{
  digitalWrite2f(PIN_CS, LOW);
  spi_send(0x01);
  spi_send(mode);
  digitalWrite2f(PIN_CS, HIGH);
  return mode;
}

inline __attribute__((always_inline))
byte spi_get_mode_quad()
{
  byte mode;
  
  digitalWrite2f(PIN_CS, LOW);
  spi_send_quad(0x05);
  mode = spi_receive_quad();
  digitalWrite2f(PIN_CS, HIGH);
  return mode;
}

inline __attribute__((always_inline))
void spi_enter_quad()
{
  digitalWrite2f(PIN_CS, LOW);
  spi_send(0x38);
  digitalWrite2f(PIN_CS, HIGH);
  pinMode2f(PIN_SI, INPUT_PULLUP);
}

inline __attribute__((always_inline))
void spi_exit_quad()
{
  digitalWrite2f(PIN_CS, LOW);
  spi_send(0xFF);
  digitalWrite2f(PIN_CS, HIGH);
  pinMode2f(PIN_SI, OUTPUT);  digitalWrite2f(PIN_SI, LOW);
}

inline __attribute__((always_inline))
void spi_init()
{
  pinMode2f(PIN_CS,   OUTPUT);  digitalWrite2f(PIN_CS, HIGH);
  pinMode2f(PIN_SCK,  OUTPUT);  digitalWrite2f(PIN_SCK,  LOW);
  pinMode2f(PIN_HOLD, INPUT_PULLUP);
  pinMode2f(PIN_SI,   OUTPUT);  digitalWrite2f(PIN_SI, LOW);
  pinMode2f(PIN_SO,   INPUT_PULLUP);
  pinMode2f(PIN_SIO0, INPUT_PULLUP);
  pinMode2f(PIN_SIO1, INPUT_PULLUP);
  pinMode2f(PIN_SIO2, INPUT_PULLUP);
  pinMode2f(PIN_SIO3, INPUT_PULLUP);

  pinMode2f(LED1, OUTPUT);      digitalWrite2f(LED1, LOW);
  pinMode2f(LED2, OUTPUT);      digitalWrite2f(LED2, HIGH);

  spi_reset();
  spi_set_mode(0x40);   // sequantial mode

  spi_enter_quad();
  Serial.print("\nSPI-RAM -   Quad Mode: ");
  Serial.println(spi_get_mode_quad(), HEX);    
}

inline __attribute__((always_inline))
void spi_send(byte working)         // function to actually bit shift the data byte out
{
  pinMode2f(PIN_SI,   OUTPUT);
  digitalWrite2f(PIN_SI,   LOW);

  for(int i = 1; i <= 8; i++)         // setup a loop of 8 iterations, one for each bit
  {                                         
      if (working > 127)              // test the most significant bit
      { 
          digitalWrite2f(PIN_SI,HIGH);   // if it is a 1 (ie. B1XXXXXXX), set the master out pin high
          // digitalWrite2f(LED2, HIGH);
      } else {
          digitalWrite2f(PIN_SI, LOW);   // if it is not 1 (ie. B0XXXXXXX), set the master out pin low
          // digitalWrite2f(LED2, LOW);
      }
      digitalWrite2f(PIN_SCK,HIGH);        // set clock high, the pot IC will read the bit into its register
      // digitalWrite2f(LED1, HIGH);
      working = working << 1;
      // delay(500);
      digitalWrite2f(PIN_SCK,LOW);          // set clock low, the pot IC will stop reading and prepare for the next iteration (next significant bit
      // digitalWrite2f(LED1, LOW);
      // delay(500);
  }
  pinMode2f(PIN_SI,   INPUT_PULLUP);
}

inline __attribute__((always_inline))
byte spi_receive()
{
  byte din = 0;
  
  for(int i = 1; i <= 8; i++)         // setup a loop of 8 iterations, one for each bit
  {                   
    din = din << 1;                      
    digitalWrite2f (PIN_SCK,HIGH);        // set clock high, the pot IC will read the bit into its register
    if (digitalRead2f(PIN_SO))
      din = din | 1;
    digitalWrite2f(PIN_SCK,LOW);          // set clock low, the pot IC will stop reading and prepare for the next iteration (next significant bit
  }
  return(din);
}

inline __attribute__((always_inline))
void spi_write_byte(byte bank, word addr, byte data)
{
  byte hh = (addr & 0xFF00) >> 8;
  byte ll = addr & 0xFF;
  
  digitalWrite2f(PIN_CS, LOW);
  spi_send(0x02);
  spi_send(bank & 0x01);
  spi_send(hh);
  spi_send(ll);
  spi_send(data);    
  digitalWrite2f(PIN_CS, HIGH);    
}

inline __attribute__((always_inline))
byte spi_read_byte(byte bank, word addr)
{
  byte hh = (addr & 0xFF00) >> 8;
  byte ll = addr & 0xFF;
  byte data;
  
  digitalWrite2f(PIN_CS, LOW);
  spi_send(0x03);
  spi_send(bank & 0x01);
  spi_send(hh);
  spi_send(ll);
  data = spi_receive();    
  digitalWrite2f(PIN_CS, HIGH);
  return data;
}

inline __attribute__((always_inline))
byte spi_read_byte_quad(byte bank, word addr)
{
  byte hh = (addr & 0xFF00) >> 8;
  byte ll = addr & 0xFF;
  byte data;

  digitalWrite2f(PIN_CS, LOW);
  spi_send_quad(0x03);
  spi_send_quad(bank & 0x01);
  spi_send_quad(hh);
  spi_send_quad(ll);
  /* dummy read */ spi_receive_quad();
  data = spi_receive_quad();
  digitalWrite2f(PIN_CS, HIGH);

  // Serial.print("SPI_Read: "); Serial.print(data, HEX); Serial.print(" <- "); Serial.println(addr, HEX);
  return data;
}

inline __attribute__((always_inline))
void spi_write_byte_quad(byte bank, word addr, byte data)
{
  byte hh = (addr & 0xFF00) >> 8;
  byte ll = addr & 0xFF;

  // Serial.print("SPI_Write: "); Serial.print(data, HEX); Serial.print(" -> "); Serial.println(addr, HEX);

  digitalWrite2f(PIN_CS, LOW);
  spi_send_quad(0x02);
  spi_send_quad(bank & 0x01);
  spi_send_quad(hh);
  spi_send_quad(ll);
  spi_send_quad(data);
  digitalWrite2f(PIN_CS, HIGH);
}

inline __attribute__((always_inline))
void spi_read_byte_array_quad(byte bank, word addr, word cnt, byte *ptr)
{
  byte hh = (addr & 0xFF00) >> 8;
  byte ll = addr & 0xFF;
  byte data;
  
  digitalWrite2f(PIN_CS, LOW);
  spi_send_quad(0x03);
  spi_send_quad(bank & 0x01);
  spi_send_quad(hh);
  spi_send_quad(ll);
  /* dummy read */ spi_receive_quad();
  while (cnt--) 
    *ptr++ = spi_receive_quad();
  digitalWrite2f(PIN_CS, HIGH);
}

inline __attribute__((always_inline))
void spi_write_byte_array_quad(byte bank, word addr, word cnt, byte *ptr)
{
  byte hh = (addr & 0xFF00) >> 8;
  byte ll = addr & 0xFF;
  
  digitalWrite2f(PIN_CS, LOW);
  spi_send_quad(0x02);
  spi_send_quad(bank & 0x01);
  spi_send_quad(hh);
  spi_send_quad(ll);
  while (cnt--)
  {
    Serial.print("+"); Serial.print(*ptr, HEX); 
    spi_send_quad(*ptr++);
  }
  Serial.println("");
  digitalWrite2f(PIN_CS, HIGH);
}

inline __attribute__((always_inline))
void spi_send_quad(byte working)         // Quad mode
{
  byte hh = (working & 0xF0) >> 4;
  byte ll = (working & 0x0F);

  // digitalWrite2f(LED1, HIGH);

  pinMode2f(PIN_SIO0, OUTPUT);
  pinMode2f(PIN_SIO1, OUTPUT);
  pinMode2f(PIN_SIO2, OUTPUT);
  pinMode2f(PIN_SIO3, OUTPUT);

  PORTF = (PINF & 0xF0) | hh; 

  digitalWrite2f(PIN_SCK,HIGH);
  digitalWrite2f(PIN_SCK,LOW);

  PORTF = (PINF & 0xF0) | ll; 

  digitalWrite2f(PIN_SCK,HIGH);
  digitalWrite2f(PIN_SCK,LOW);

  pinMode2f(PIN_SIO0, INPUT_PULLUP);
  pinMode2f(PIN_SIO1, INPUT_PULLUP);
  pinMode2f(PIN_SIO2, INPUT_PULLUP);
  pinMode2f(PIN_SIO3, INPUT_PULLUP);

  // digitalWrite2f(LED1, LOW);
}

inline __attribute__((always_inline))
word spi_receive_quad()         // Quad mode
{
  byte b = 0;

  // digitalWrite2f(LED2, HIGH);

  digitalWrite2f(PIN_SCK, HIGH);     
  b = (PINF & 0x0F) << 4;
  digitalWrite2f(PIN_SCK,LOW);
  digitalWrite2f(PIN_SCK,HIGH);
  b = b | (PINF & 0x0F);
  digitalWrite2f(PIN_SCK,LOW);

  // digitalWrite2f(LED2, LOW);

  return(b);
}


////////////////////////////////////////////////////////////////////
// Cache for SPI-RAM
////////////////////////////////////////////////////////////////////

byte cachePage[16];
byte cacheRAM[16][256];

inline __attribute__((always_inline))
byte cache_read_byte(word addr)           // 0x1234
{
//  byte p = (addr & 0xFF00) >> 8;          // p = 0x12
//  byte a = addr & 0x00FF;                 // a = 0x34
//  byte n = a >> 4;                        // n = 0x03
//  byte r = a & 0x0F;                      // r = 0x04

  byte a = (addr & 0xFF00) >> 8;            // a = 0x12
  byte p = a >> 4;                          // p = 0x01
  byte n = a & 0x0F;                        // n = 0x02
  byte r = (addr & 0x00FF);                 // r = 0x34
  
  // Serial.print("cache addr: "); Serial.print(addr, HEX);

  if (cachePage[n] == p)
  {
    // Cache Hit !!!
    return cacheRAM[n][r];
  }
  else
  {
    // Need to fill cache from SPI-RAM
    digitalWrite2f(LED2, HIGH);
    spi_read_byte_array_quad(0, addr & 0xFF00, 256, cacheRAM[n]);
    cachePage[n] = p;
    digitalWrite2f(LED2, LOW);
    return cacheRAM[n][r];
  }
}

inline __attribute__((always_inline))
void cache_write_byte(word addr, byte din)   // 0x1234
{
//  byte p = (addr & 0xFF00) >> 8;          // p = 0x12
//  byte a = addr & 0x00FF;                 // a = 0x34
//  byte n = a >> 4;                        // n = 0x03
//  byte r = a & 0x0f;                      // r = 0x04

  byte a = (addr & 0xFF00) >> 8;            // a = 0x12
  byte p = a >> 4;                          // p = 0x01
  byte n = a & 0x0F;                        // n = 0x02
  byte r = (addr & 0x00FF);                 // r = 0x34

  
  if (cachePage[n] == p)
  {
    // Cache Hit !!!
    cacheRAM[n][r] = din;
    spi_write_byte_quad(0, addr, din);        // Write-thru cache :)
    return;
  }
  else
  {
    // Need to fill cache from SPI-RAM
    digitalWrite2f(LED1, HIGH);
    spi_write_byte_quad(0, addr, din);
    spi_read_byte_array_quad(0, addr & 0xFF00, 256, cacheRAM[n]);
    cachePage[n] = p;
    digitalWrite2f(LED1, LOW);
    return;
  }
}

void cache_init()
{
  // Initialize cache from spi-ram
  for(int p=0; p<16; p++)
  {
    cachePage[p] = 0;
  }
  Serial.println("RAM Cache - Initialized.");

}

#endif


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
// 8031 DEFINITIONS
////////////////////////////////////////////////////////////////////

// 8031 HW CONSTRAINTS
// !!! TODO !!!
// 1- Clock input depends on IC used. See datasheet for details.
//

////////////////////////////////////////////////////////////////////
// MEMORY LAYOUT
////////////////////////////////////////////////////////////////////

#if (USE_SPI_RAM)
  // 2K MEMORY
  #define RAM_START   0x2000
  #define RAM_END     0x27FF
  byte    RAM[RAM_END-RAM_START+1];
#else
  // 6K MEMORY
  #define RAM_START   0x2000
  #define RAM_END     0x37FF
  byte    RAM[RAM_END-RAM_START+1];
#endif

// ROM(s) (Monitor)
#define ROM_START   0x0000
#define ROM_END     (ROM_START+sizeof(rom_bin)-1)

////////////////////////////////////////////////////////////////////
// 8031 Monitor by Frank Rudley
// File:   MONITORB_RS.asm
// MONITORA.ASM - Rev A Started 01/02/94
// MONITORB.ASM - Rev B Started 01/31/21 - Same as MONITORA
// ** MONITORB_RS.ASM - Rev B modified for Retroshield 25/12/2024
// ** converted to asm31-sdcc231-pj3 asm by kayto@github.com
// ** note some functionality currently missing 
// 
// ** Original Comments
// 8031 System #6
// 
// This program helps to develop a Monitor for the 8031 system.
// Runs at 9600 Baud
// 
// Allows the reading and writing to internal RAM. (R and W functions).
// Allows you to read and write to ROM stuff. (O and M functions)
// It also displays SFRs. (S funtion)
// It writes 256 byte blocks of ROM. (B Function)
// It write all internal Ram (D Function)
// Allow Upload of HEX file for Monitor Program Devel (H Function)
// Do Checksum between load memory and HEX file (C Function)
// Do a Jump to 0800h to run other programs. (J Function)
// Allow Upload of HEX File for Running at 0800h Memory (E Function)
// Do Checksum between load memory and HEX file at 0800 Mem (K Function)
// 
// Give a list of functions (Menu) (N Function)
//
////////////////////////////////////////////////////////////////////

PROGMEM const unsigned char rom_bin[] = {
// ROM code
0x75, 0x87, 0x80, 0x75, 0x89, 0x21, 0x75, 0x8D, 0xFF, 0x75, 0x8B, 0xFF,
0x75, 0x98, 0x52, 0xD2, 0x8E, 0x12, 0x07, 0x7F, 0x0A, 0x0D, 0x38, 0x30,
0x33, 0x31, 0x20, 0x4D, 0x4F, 0x4E, 0x49, 0x54, 0x4F, 0x52, 0x20, 0x52,
0x65, 0x76, 0x20, 0x42, 0x20, 0x62, 0x79, 0x20, 0x46, 0x72, 0x61, 0x6E,
0x6B, 0x20, 0x52, 0x75, 0x64, 0x6C, 0x65, 0x79, 0x0A, 0x0D, 0x0A, 0x0A,
0x0A, 0x0A, 0x1B, 0x12, 0x07, 0x7F, 0x0A, 0x38, 0x30, 0x33, 0x31, 0x3E,
0x1B, 0x12, 0x07, 0x95, 0x54, 0x5F, 0xB4, 0x52, 0x02, 0x01, 0x9E, 0xB4,
0x57, 0x02, 0x01, 0xB5, 0xB4, 0x4F, 0x02, 0x01, 0xCC, 0xB4, 0x4D, 0x02,
0x01, 0xE9, 0xB4, 0x53, 0x02, 0x21, 0x07, 0xB4, 0x42, 0x02, 0x21, 0xF6,
0xB4, 0x44, 0x02, 0x41, 0x89, 0xB4, 0x48, 0x02, 0x61, 0x0B, 0xB4, 0x43,
0x02, 0x61, 0x5E, 0xB4, 0x4A, 0x02, 0x81, 0x31, 0xB4, 0x45, 0x02, 0x81,
0x34, 0xB4, 0x4B, 0x02, 0x81, 0x86, 0xB4, 0x4E, 0x02, 0xA1, 0x56, 0xB4,
0x41, 0x02, 0xC1, 0xC9, 0xB4, 0x58, 0x02, 0xC1, 0xE8, 0xF1, 0xD8, 0x02,
0x00, 0x11, 0xF1, 0x7F, 0x2D, 0x52, 0x41, 0x4D, 0x3E, 0x1B, 0xF1, 0xE4,
0xF8, 0x74, 0x3A, 0xF1, 0xA1, 0xE6, 0xF1, 0xF0, 0xF1, 0xCF, 0x02, 0x00,
0x3F, 0xF1, 0x7F, 0x2D, 0x52, 0x41, 0x4D, 0x3E, 0x1B, 0xF1, 0xE4, 0xF8,
0x74, 0x3A, 0xF1, 0xA1, 0xF1, 0xE4, 0xF6, 0xF1, 0xCF, 0x02, 0x00, 0x3F,
0xF1, 0x7F, 0x2D, 0x52, 0x4F, 0x4D, 0x3E, 0x1B, 0xF1, 0xE4, 0xF5, 0x83,
0xF1, 0xE4, 0xF5, 0x82, 0x74, 0x3A, 0xF1, 0xA1, 0xE4, 0x93, 0xF1, 0xF0,
0xF1, 0xCF, 0x02, 0x00, 0x3F, 0xF1, 0x7F, 0x2D, 0x52, 0x4F, 0x4D, 0x3E,
0x1B, 0xF1, 0xE4, 0xF5, 0x83, 0xF1, 0xE4, 0xF5, 0x82, 0x74, 0x3A, 0xF1,
0xA1, 0xF1, 0xE4, 0xF0, 0xF1, 0xD8, 0xF1, 0xCF, 0x02, 0x00, 0x3F, 0xF1,
0x7F, 0x53, 0x46, 0x52, 0x73, 0x0A, 0x0A, 0x0A, 0x0D, 0x50, 0x30, 0x20,
0x20, 0x20, 0x3D, 0x20, 0x1B, 0xE5, 0x80, 0xF1, 0xF0, 0xF1, 0x7F, 0x20,
0x20, 0x20, 0x20, 0x50, 0x31, 0x20, 0x20, 0x20, 0x3D, 0x20, 0x1B, 0xE5,
0x90, 0xF1, 0xF0, 0xF1, 0x7F, 0x20, 0x20, 0x20, 0x20, 0x50, 0x32, 0x20,
0x20, 0x20, 0x3D, 0x20, 0x1B, 0xE5, 0xA0, 0xF1, 0xF0, 0xF1, 0x7F, 0x20,
0x20, 0x20, 0x20, 0x50, 0x33, 0x20, 0x20, 0x20, 0x3D, 0x20, 0x1B, 0xE5,
0xB0, 0xF1, 0xF0, 0xF1, 0x7F, 0x0A, 0x0D, 0x54, 0x4D, 0x4F, 0x44, 0x20,
0x3D, 0x20, 0x1B, 0xE5, 0x89, 0xF1, 0xF0, 0xF1, 0x7F, 0x20, 0x20, 0x20,
0x20, 0x54, 0x43, 0x4F, 0x4E, 0x20, 0x3D, 0x20, 0x1B, 0xE5, 0x88, 0xF1,
0xF0, 0xF1, 0x7F, 0x20, 0x20, 0x20, 0x20, 0x53, 0x43, 0x4F, 0x4E, 0x20,
0x3D, 0x20, 0x1B, 0xE5, 0x98, 0xF1, 0xF0, 0xF1, 0x7F, 0x20, 0x20, 0x20,
0x20, 0x50, 0x53, 0x57, 0x20, 0x20, 0x3D, 0x20, 0x1B, 0xE5, 0xD0, 0xF1,
0xF0, 0xF1, 0x7F, 0x0A, 0x0D, 0x50, 0x43, 0x4F, 0x4E, 0x20, 0x3D, 0x20,
0x1B, 0xE5, 0x87, 0xF1, 0xF0, 0xF1, 0x7F, 0x20, 0x20, 0x20, 0x20, 0x54,
0x48, 0x30, 0x20, 0x20, 0x3D, 0x20, 0x1B, 0xE5, 0x8C, 0xF1, 0xF0, 0xF1,
0x7F, 0x20, 0x20, 0x20, 0x20, 0x54, 0x4C, 0x30, 0x20, 0x20, 0x3D, 0x20,
0x1B, 0xE5, 0x8A, 0xF1, 0xF0, 0xF1, 0x7F, 0x20, 0x20, 0x20, 0x20, 0x54,
0x48, 0x31, 0x20, 0x20, 0x3D, 0x20, 0x1B, 0xE5, 0x8D, 0xF1, 0xF0, 0xF1,
0x7F, 0x20, 0x20, 0x20, 0x20, 0x54, 0x4C, 0x31, 0x20, 0x20, 0x3D, 0x20,
0x1B, 0xE5, 0x8B, 0xF1, 0xF0, 0xF1, 0xCF, 0x02, 0x00, 0x3F, 0xF1, 0x7F,
0x2D, 0x41, 0x20, 0x32, 0x35, 0x36, 0x20, 0x42, 0x79, 0x74, 0x65, 0x20,
0x42, 0x6C, 0x6F, 0x63, 0x6B, 0x20, 0x6F, 0x66, 0x20, 0x52, 0x6F, 0x6D,
0x0A, 0x0A, 0x0D, 0x42, 0x6C, 0x6F, 0x63, 0x6B, 0x3E, 0x1B, 0xF1, 0xE4,
0xF9, 0xF1, 0x7F, 0x0A, 0x0D, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x30,
0x30, 0x20, 0x30, 0x31, 0x20, 0x30, 0x32, 0x20, 0x30, 0x33, 0x20, 0x30,
0x34, 0x20, 0x30, 0x35, 0x20, 0x30, 0x36, 0x20, 0x30, 0x37, 0x20, 0x30,
0x38, 0x20, 0x30, 0x39, 0x20, 0x30, 0x41, 0x20, 0x30, 0x42, 0x20, 0x30,
0x43, 0x20, 0x30, 0x44, 0x20, 0x30, 0x45, 0x20, 0x30, 0x46, 0x0A, 0x0A,
0x0D, 0x1B, 0x89, 0x83, 0x78, 0x00, 0x88, 0x82, 0xF1, 0xCF, 0xE5, 0x83,
0xF1, 0xF0, 0xE5, 0x82, 0xF1, 0xF0, 0x74, 0x20, 0xF1, 0xA1, 0xF1, 0xA1,
0x88, 0x82, 0xE4, 0x93, 0xF1, 0xF0, 0x74, 0x20, 0xF1, 0xA1, 0x08, 0xE8,
0x54, 0x0F, 0xB4, 0x00, 0xEF, 0xB8, 0x00, 0xDA, 0xF1, 0xCF, 0x02, 0x00,
0x3F, 0xF1, 0x7F, 0x2D, 0x41, 0x20, 0x31, 0x32, 0x38, 0x20, 0x42, 0x79,
0x74, 0x65, 0x20, 0x42, 0x6C, 0x6F, 0x63, 0x6B, 0x20, 0x6F, 0x66, 0x20,
0x49, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x61, 0x6C, 0x20, 0x52, 0x61, 0x6D,
0x0A, 0x0A, 0x0D, 0x0A, 0x0D, 0x20, 0x20, 0x20, 0x20, 0x30, 0x30, 0x20,
0x30, 0x31, 0x20, 0x30, 0x32, 0x20, 0x30, 0x33, 0x20, 0x30, 0x34, 0x20,
0x30, 0x35, 0x20, 0x30, 0x36, 0x20, 0x30, 0x37, 0x20, 0x30, 0x38, 0x20,
0x30, 0x39, 0x20, 0x30, 0x41, 0x20, 0x30, 0x42, 0x20, 0x30, 0x43, 0x20,
0x30, 0x44, 0x20, 0x30, 0x45, 0x20, 0x30, 0x46, 0x0A, 0x0A, 0x0D, 0x1B,
0x78, 0x00, 0xF1, 0xCF, 0xE8, 0xF1, 0xF0, 0x74, 0x20, 0xF1, 0xA1, 0xF1,
0xA1, 0xE6, 0xF1, 0xF0, 0x74, 0x20, 0xF1, 0xA1, 0x08, 0xE8, 0x54, 0x0F,
0xB4, 0x00, 0xF2, 0xB8, 0x80, 0xE4, 0xF1, 0xCF, 0x02, 0x00, 0x3F, 0xF1,
0x7F, 0x2D, 0x55, 0x70, 0x6C, 0x6F, 0x61, 0x64, 0x20, 0x48, 0x65, 0x78,
0x20, 0x46, 0x69, 0x6C, 0x65, 0x0A, 0x0D, 0x1B, 0xF1, 0x95, 0xB4, 0x3A,
0x34, 0xF1, 0xE4, 0xF9, 0xF1, 0xE4, 0x24, 0x08, 0xF5, 0x83, 0xF1, 0xE4,
0xF5, 0x82, 0xF1, 0xE4, 0xB4, 0x00, 0x0E, 0xF1, 0xE4, 0xF0, 0xF1, 0xD8,
0xA3, 0xD9, 0xF8, 0xF1, 0xE4, 0xF1, 0xCF, 0x80, 0xDB, 0xF1, 0xE4, 0xF1,
0x7F, 0x0A, 0x0D, 0x44, 0x4F, 0x4E, 0x45, 0x20, 0x4C, 0x4F, 0x41, 0x44,
0x21, 0x21, 0x0A, 0x0D, 0x1B, 0xF1, 0xCF, 0x02, 0x00, 0x3F, 0xF1, 0x7F,
0x2D, 0x55, 0x70, 0x6C, 0x6F, 0x61, 0x64, 0x20, 0x48, 0x65, 0x78, 0x20,
0x46, 0x69, 0x6C, 0x65, 0x20, 0x46, 0x6F, 0x72, 0x20, 0x43, 0x6B, 0x65,
0x63, 0x6B, 0x73, 0x75, 0x6D, 0x20, 0x43, 0x68, 0x65, 0x63, 0x6B, 0x0A,
0x0D, 0x1B, 0x7B, 0x00, 0xF1, 0x95, 0xB4, 0x3A, 0x5F, 0x78, 0x00, 0xF1,
0xE4, 0xF9, 0xF8, 0xF1, 0xE4, 0xFA, 0x28, 0xF8, 0xEA, 0x24, 0x08, 0xF5,
0x83, 0xF1, 0xE4, 0xF5, 0x82, 0x28, 0xF8, 0xF1, 0xE4, 0xB4, 0x00, 0x46,
0xF1, 0xE4, 0xE4, 0x93, 0x28, 0xF8, 0xA3, 0xD9, 0xF7, 0x88, 0x10, 0xF1,
0xE4, 0xF4, 0x24, 0x01, 0xB5, 0x10, 0x18, 0xF1, 0x7F, 0x0A, 0x0D, 0x20,
0x47, 0x6F, 0x6F, 0x64, 0x20, 0x43, 0x68, 0x65, 0x63, 0x6B, 0x73, 0x75,
0x6D, 0x20, 0x0A, 0x0D, 0x1B, 0x80, 0xB5, 0xF1, 0x7F, 0x0A, 0x0D, 0x20,
0x42, 0x61, 0x64, 0x20, 0x43, 0x68, 0x65, 0x63, 0x6B, 0x73, 0x75, 0x6D,
0x20, 0x0A, 0x0D, 0x1B, 0x7B, 0x01, 0x80, 0x9C, 0x80, 0x3E, 0xF1, 0xE4,
0xBB, 0x00, 0x1E, 0xF1, 0x7F, 0x0A, 0x0D, 0x47, 0x4F, 0x4F, 0x44, 0x20,
0x43, 0x48, 0x45, 0x43, 0x4B, 0x53, 0x55, 0x4D, 0x20, 0x44, 0x4F, 0x4E,
0x45, 0x21, 0x21, 0x20, 0x0A, 0x0D, 0x1B, 0x80, 0x1B, 0xF1, 0x7F, 0x0A,
0x0D, 0x42, 0x41, 0x44, 0x20, 0x43, 0x48, 0x45, 0x43, 0x4B, 0x53, 0x55,
0x4D, 0x20, 0x44, 0x4F, 0x4E, 0x45, 0x21, 0x21, 0x20, 0x0A, 0x0D, 0x1B,
0xF1, 0xCF, 0x02, 0x00, 0x3F, 0x02, 0x20, 0x00, 0xF1, 0x7F, 0x2D, 0x55,
0x70, 0x6C, 0x6F, 0x61, 0x64, 0x20, 0x48, 0x65, 0x78, 0x20, 0x46, 0x69,
0x6C, 0x65, 0x0A, 0x0D, 0x1B, 0xF1, 0x95, 0xB4, 0x3A, 0x33, 0xF1, 0xE4,
0xF9, 0xF1, 0xE4, 0xF5, 0x83, 0xF1, 0xE4, 0xF5, 0x82, 0xF1, 0xE4, 0xB4,
0x00, 0x0E, 0xF1, 0xE4, 0xF0, 0xF1, 0xD8, 0xA3, 0xD9, 0xF8, 0xF1, 0xE4,
0xF1, 0xCF, 0x80, 0xDD, 0xF1, 0xE4, 0xF1, 0x7F, 0x0A, 0x0D, 0x44, 0x4F,
0x4E, 0x45, 0x20, 0x4C, 0x4F, 0x41, 0x44, 0x21, 0x21, 0x20, 0x0A, 0x0D,
0x1B, 0xF1, 0xCF, 0x02, 0x00, 0x3F, 0xF1, 0x7F, 0x2D, 0x55, 0x70, 0x6C,
0x6F, 0x61, 0x64, 0x20, 0x48, 0x65, 0x78, 0x20, 0x46, 0x69, 0x6C, 0x65,
0x20, 0x46, 0x6F, 0x72, 0x20, 0x43, 0x6B, 0x65, 0x63, 0x6B, 0x73, 0x75,
0x6D, 0x20, 0x43, 0x68, 0x65, 0x63, 0x6B, 0x0A, 0x0D, 0x1B, 0x7B, 0x00,
0xF1, 0x95, 0xB4, 0x3A, 0x5D, 0x78, 0x00, 0xF1, 0xE4, 0xF9, 0xF8, 0xF1,
0xE4, 0xFA, 0x28, 0xF8, 0xEA, 0xF5, 0x83, 0xF1, 0xE4, 0xF5, 0x82, 0x28,
0xF8, 0xF1, 0xE4, 0xB4, 0x00, 0x46, 0xF1, 0xE4, 0xE4, 0x93, 0x28, 0xF8,
0xA3, 0xD9, 0xF7, 0x88, 0x10, 0xF1, 0xE4, 0xF4, 0x24, 0x01, 0xB5, 0x10,
0x18, 0xF1, 0x7F, 0x0A, 0x0D, 0x20, 0x47, 0x6F, 0x6F, 0x64, 0x20, 0x43,
0x68, 0x65, 0x63, 0x6B, 0x73, 0x75, 0x6D, 0x20, 0x0A, 0x0D, 0x1B, 0x80,
0xB7, 0xF1, 0x7F, 0x0A, 0x0D, 0x20, 0x42, 0x61, 0x64, 0x20, 0x43, 0x68,
0x65, 0x63, 0x6B, 0x73, 0x75, 0x6D, 0x20, 0x0A, 0x0D, 0x1B, 0x7B, 0x01,
0x80, 0x9E, 0x80, 0x3D, 0xF1, 0xE4, 0xBB, 0x00, 0x1D, 0xF1, 0x7F, 0x0A,
0x0D, 0x47, 0x4F, 0x4F, 0x44, 0x20, 0x43, 0x48, 0x45, 0x43, 0x4B, 0x53,
0x55, 0x4D, 0x20, 0x44, 0x4F, 0x4E, 0x45, 0x21, 0x21, 0x0A, 0x0D, 0x1B,
0x80, 0x1B, 0xF1, 0x7F, 0x0A, 0x0D, 0x42, 0x41, 0x44, 0x20, 0x43, 0x48,
0x45, 0x43, 0x4B, 0x53, 0x55, 0x4D, 0x20, 0x44, 0x4F, 0x4E, 0x45, 0x21,
0x21, 0x20, 0x0A, 0x0D, 0x1B, 0xF1, 0xCF, 0x02, 0x00, 0x3F, 0xF1, 0x7F,
0x0A, 0x0D, 0x52, 0x20, 0x3D, 0x20, 0x52, 0x65, 0x61, 0x64, 0x20, 0x49,
0x6E, 0x74, 0x20, 0x52, 0x41, 0x4D, 0x0A, 0x0D, 0x57, 0x20, 0x3D, 0x20,
0x57, 0x72, 0x69, 0x74, 0x65, 0x20, 0x74, 0x6F, 0x20, 0x49, 0x6E, 0x74,
0x20, 0x52, 0x41, 0x4D, 0x0A, 0x0D, 0x4F, 0x20, 0x3D, 0x20, 0x52, 0x65,
0x61, 0x64, 0x20, 0x52, 0x4F, 0x4D, 0x0A, 0x0D, 0x4D, 0x20, 0x3D, 0x20,
0x57, 0x72, 0x69, 0x74, 0x65, 0x20, 0x52, 0x4F, 0x4D, 0x20, 0x61, 0x6E,
0x64, 0x20, 0x45, 0x78, 0x74, 0x20, 0x52, 0x61, 0x6D, 0x0A, 0x0D, 0x53,
0x20, 0x3D, 0x20, 0x44, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x20, 0x53,
0x46, 0x52, 0x73, 0x0A, 0x0D, 0x42, 0x20, 0x3D, 0x20, 0x32, 0x35, 0x36,
0x20, 0x62, 0x79, 0x74, 0x65, 0x73, 0x20, 0x6F, 0x66, 0x20, 0x52, 0x4F,
0x4D, 0x0A, 0x0D, 0x44, 0x20, 0x3D, 0x20, 0x31, 0x32, 0x38, 0x20, 0x62,
0x79, 0x74, 0x65, 0x73, 0x20, 0x6F, 0x66, 0x20, 0x49, 0x6E, 0x74, 0x20,
0x52, 0x41, 0x4D, 0x0A, 0x0D, 0x48, 0x20, 0x3D, 0x20, 0x4C, 0x6F, 0x61,
0x64, 0x20, 0x48, 0x45, 0x58, 0x20, 0x46, 0x69, 0x6C, 0x65, 0x20, 0x66,
0x6F, 0x72, 0x20, 0x4D, 0x4F, 0x4E, 0x49, 0x54, 0x4F, 0x52, 0x20, 0x50,
0x72, 0x6F, 0x67, 0x73, 0x0A, 0x0D, 0x43, 0x20, 0x3D, 0x20, 0x56, 0x65,
0x72, 0x69, 0x66, 0x79, 0x20, 0x43, 0x68, 0x65, 0x63, 0x6B, 0x73, 0x75,
0x6D, 0x73, 0x20, 0x4D, 0x4F, 0x4E, 0x49, 0x54, 0x4F, 0x52, 0x20, 0x50,
0x72, 0x6F, 0x67, 0x73, 0x0A, 0x0D, 0x4A, 0x20, 0x3D, 0x20, 0x4A, 0x75,
0x6D, 0x70, 0x20, 0x74, 0x6F, 0x20, 0x72, 0x75, 0x6E, 0x20, 0x50, 0x72,
0x6F, 0x67, 0x73, 0x0A, 0x0D, 0x45, 0x20, 0x3D, 0x20, 0x4C, 0x6F, 0x61,
0x64, 0x20, 0x48, 0x45, 0x58, 0x20, 0x46, 0x69, 0x6C, 0x65, 0x20, 0x66,
0x6F, 0x72, 0x20, 0x50, 0x72, 0x6F, 0x67, 0x73, 0x0A, 0x0D, 0x4B, 0x20,
0x3D, 0x20, 0x56, 0x65, 0x72, 0x69, 0x66, 0x79, 0x20, 0x43, 0x68, 0x65,
0x63, 0x6B, 0x73, 0x75, 0x6D, 0x73, 0x20, 0x66, 0x6F, 0x72, 0x20, 0x50,
0x72, 0x6F, 0x67, 0x73, 0x0A, 0x0D, 0x4E, 0x20, 0x3D, 0x20, 0x54, 0x68,
0x69, 0x73, 0x20, 0x4D, 0x65, 0x6E, 0x75, 0x0A, 0x0D, 0x41, 0x20, 0x3D,
0x20, 0x52, 0x65, 0x61, 0x64, 0x20, 0x45, 0x78, 0x74, 0x20, 0x52, 0x41,
0x4D, 0x0A, 0x0D, 0x58, 0x20, 0x3D, 0x20, 0x32, 0x35, 0x36, 0x20, 0x62,
0x79, 0x74, 0x65, 0x73, 0x20, 0x6F, 0x66, 0x20, 0x45, 0x78, 0x74, 0x20,
0x52, 0x41, 0x4D, 0x0A, 0x0D, 0x1B, 0x02, 0x00, 0x3F, 0xF1, 0x7F, 0x2D,
0x45, 0x58, 0x52, 0x41, 0x4D, 0x3E, 0x1B, 0xF1, 0xE4, 0xF5, 0x83, 0xF1,
0xE4, 0xF5, 0x82, 0x74, 0x3A, 0xF1, 0xA1, 0xE4, 0xE0, 0xF1, 0xF0, 0xF1,
0xCF, 0x02, 0x00, 0x3F, 0xF1, 0x7F, 0x2D, 0x41, 0x20, 0x32, 0x35, 0x36,
0x20, 0x42, 0x79, 0x74, 0x65, 0x20, 0x42, 0x6C, 0x6F, 0x63, 0x6B, 0x20,
0x6F, 0x66, 0x20, 0x45, 0x78, 0x74, 0x20, 0x52, 0x61, 0x6D, 0x0A, 0x0A,
0x0D, 0x42, 0x6C, 0x6F, 0x63, 0x6B, 0x3E, 0x1B, 0xF1, 0xE4, 0xF9, 0xF1,
0x7F, 0x0A, 0x0D, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x30, 0x30, 0x20,
0x30, 0x31, 0x20, 0x30, 0x32, 0x20, 0x30, 0x33, 0x20, 0x30, 0x34, 0x20,
0x30, 0x35, 0x20, 0x30, 0x36, 0x20, 0x30, 0x37, 0x20, 0x30, 0x38, 0x20,
0x30, 0x39, 0x20, 0x30, 0x41, 0x20, 0x30, 0x42, 0x20, 0x30, 0x43, 0x20,
0x30, 0x44, 0x20, 0x30, 0x45, 0x20, 0x30, 0x46, 0x0A, 0x0A, 0x0D, 0x1B,
0x89, 0x83, 0x78, 0x00, 0x88, 0x82, 0xF1, 0xCF, 0xE5, 0x83, 0xF1, 0xF0,
0xE5, 0x82, 0xF1, 0xF0, 0x74, 0x20, 0xF1, 0xA1, 0xF1, 0xA1, 0x88, 0x82,
0xE4, 0xE0, 0xF1, 0xF0, 0x74, 0x20, 0xF1, 0xA1, 0x08, 0xE8, 0x54, 0x0F,
0xB4, 0x00, 0xEF, 0xB8, 0x00, 0xDA, 0xF1, 0xCF, 0x02, 0x00, 0x3F, 0xD0,
0x83, 0xD0, 0x82, 0xE4, 0x93, 0x30, 0x99, 0xFD, 0xC2, 0x99, 0xF5, 0x99,
0xA3, 0xE4, 0x93, 0xB4, 0x1B, 0xF3, 0x74, 0x01, 0x73, 0x30, 0x98, 0xFD,
0xC2, 0x98, 0xE5, 0x99, 0x54, 0x7F, 0xF1, 0xA1, 0x22, 0x30, 0x99, 0xFD,
0xC2, 0x99, 0xF5, 0x99, 0x22, 0xC2, 0xD7, 0x94, 0x30, 0xF5, 0xF0, 0x94,
0x0A, 0x20, 0xD7, 0x06, 0xE5, 0xF0, 0x94, 0x07, 0xF5, 0xF0, 0xE5, 0xF0,
0x22, 0x54, 0x0F, 0xC2, 0xD7, 0xF5, 0xF0, 0x94, 0x0A, 0xE5, 0xF0, 0x20,
0xD7, 0x02, 0x24, 0x07, 0x24, 0x30, 0x22, 0x74, 0x0A, 0xF1, 0xA1, 0x74,
0x0D, 0xF1, 0xA1, 0x22, 0x74, 0x0A, 0x75, 0xF0, 0xFF, 0xD5, 0xF0, 0xFD,
0x14, 0x70, 0xF7, 0x22, 0xF1, 0x95, 0xF1, 0xA9, 0xC4, 0xFA, 0xF1, 0x95,
0xF1, 0xA9, 0x4A, 0x22, 0xFA, 0xC4, 0xF1, 0xBD, 0xF1, 0xA1, 0xEA, 0xF1,
0xBD, 0xF1, 0xA1, 0x22,
};

////////////////////////////////////////////////////////////////////
// 8251 Peripheral
// emulate just enough so keyboard/display works thru serial port.
////////////////////////////////////////////////////////////////////
// Left 8251 emulation in, incase somebody wants to use it.

#define ADDR_8251_DATA          0x00
#define ADDR_8251_MODCMD        0x01

#define STATE_8251_RESET        0x01
#define STATE_8251_INITIALIZED  0x00
#define CMD_8251_INTERNAL_RESET 0x40
#define CMD_8251_RTS            0x20
#define CMD_8251_DTR            0x02
#define STAT_8251_TxRDY         0x01
#define STAT_8251_RxRDY         0x02
#define STAT_8251_TxE           0x04
#define STAT_DSR                0x80

byte reg8251_STATE;      // register to keep track of 8251 state: reset or initialized
byte reg8251_MODE;
byte reg8251_COMMAND;
byte reg8251_STATUS;
byte reg8251_DATA;

////////////////////////////////////////////////////////////////////
// 8031 Processor Control
////////////////////////////////////////////////////////////////////
//

/* Digital Pin Assignments */
#define DATA_OUT (PORTL)
#define DATA_IN  (PINL)
#define ADDR_H   (PINC)
#define ADDR_L   (PINL)
// 8031 uses multiplexed Addr & Data
#define ADDR     ((unsigned int) (ADDR_H << 8 | ADDR_L))

#define uP_RESET    38
#define uP_ALE      39
#define uP_PSEN_N   40
#define uP_RD_N     51
#define uP_WR_N     50
#define uP_INT0_N   26
#define uP_INT1_N   27
#define uP_T0       28
#define uP_T1       29
#define uP_CLK1     52
#define uP_CLK2     53
#define uP_CLK      (uP_CLK2)
#define uP_GPIO     41

#define uP_TXD      25
#define uP_RXD      24

// Fast routines to drive clock signals high/low; faster than digitalWrite
// required to meet >100kHz clock
//
#define CLK_HIGH      (PORTB = PORTB | 0x01)
#define CLK_LOW       (PORTB = PORTB & 0xFE)
#define STATE_RD_N    (PINB & 0x04)
#define STATE_WR_N    (PINB & 0x08)
#define STATE_ALE     (PING & 0x04)
#define STATE_PSEN_N  (PING & 0x02)
#define STATE_TXD     (PINA & 0x08)

#define DIR_IN  0x00
#define DIR_OUT 0xFF
#define DATA_DIR   DDRL
#define ADDR_H_DIR DDRC
#define ADDR_L_DIR DDRL

unsigned long clock_cycle_count;
unsigned long clock_cycle_last;
unsigned long uP_start_millis;
unsigned long uP_stop_millis;
unsigned long uP_millis_last;
word uP_ADDR;
byte uP_DATA;

void uP_init()
{
  // Set directions
  DATA_DIR = DIR_IN;
  DATA_OUT = 0xFF;    // Enable Pull-ups
  
  ADDR_H_DIR = DIR_IN;
  ADDR_L_DIR = DIR_IN;
  
  pinMode(uP_RESET,   OUTPUT);
  pinMode(uP_WR_N,    INPUT_PULLUP);
  pinMode(uP_RD_N,    INPUT_PULLUP);
  pinMode(uP_ALE,     INPUT_PULLUP);
  pinMode(uP_PSEN_N,  INPUT_PULLUP);

  pinMode(uP_INT0_N,  INPUT_PULLUP);
  pinMode(uP_INT1_N,  INPUT_PULLUP);
  pinMode(uP_T0,      INPUT_PULLUP);
  pinMode(uP_T1,      INPUT_PULLUP);

  pinMode(uP_TXD,     INPUT_PULLUP);
  pinMode(uP_RXD,     INPUT_PULLUP);

  pinMode(uP_GPIO,    OUTPUT);
  
  pinMode(uP_CLK,     OUTPUT);
  pinMode(uP_CLK1,    OUTPUT);
  pinMode(uP_CLK2,    OUTPUT);

  uP_assert_reset();
  digitalWrite(uP_CLK, LOW);
  digitalWrite(uP_CLK1, LOW);
  digitalWrite(uP_CLK2, LOW);
  
  clock_cycle_count = 0;
  clock_cycle_last  = 0;
  uP_start_millis = millis();
  uP_millis_last = millis();

}

void intel8251_init()
{
  reg8251_STATE     = STATE_8251_RESET;
  reg8251_MODE      = 0b01001101;       // async mode: 1x baudrate, 8n1
  reg8251_COMMAND   = 0b00100111;       // enable tx/rx; assert DTR & RTS
  reg8251_STATUS    = 0b10000101;       // TxRDY, TxE, DSR (ready for operation). RxRDY=0
  reg8251_DATA      = 0x00;
}

void uP_assert_reset()
{
  // Drive RESET conditions
  digitalWrite(uP_RESET, HIGH);
  
  digitalWrite(uP_INT0_N, HIGH);
  digitalWrite(uP_INT1_N, HIGH);
  pinMode(uP_T0,          INPUT_PULLUP);
  pinMode(uP_T1,          INPUT_PULLUP);
  pinMode(uP_RXD,         INPUT_PULLUP);
}

void uP_release_reset()
{
  // Drive RESET conditions
  digitalWrite(uP_RESET, LOW);
}


////////////////////////////////////////////////////////////////////
// Processor Control Loop
////////////////////////////////////////////////////////////////////
// This is where the action is.
// it reads processor control signals and acts accordingly.
//
// 8031 takes multiple cycles (12 cycles, 6 stages).
// ALE=HIGH     -> latch A0..A7
// PSEN_N = LOW -> Enable ROM data output
// RD_N = LOW   -> Enable RAM data output
// WR_N = LOW   -> Enable RAM data input

word ADDR_latched  = 0;
byte DATA_latched = 0;
byte prevALE = 0;
byte prevPSEN = 0;
byte prevRD_N = 0;
byte prevWR_N = 0;

inline __attribute__((always_inline))
void cpu_tick()
{   
  CLK_HIGH;

  // 8031 has two types of bus activity: PSEN (Program Store) and RAM
  // PSEN asserted means 8031 wants to read from external ROM.
  // RD_N, WR_N asserted means 8031 wants to access external RAM.
  // Before any transaction, ALE is asserted to capture ADDR
  
  ////////////////////////////////////////////////////////////
  // ALE
  ////////////////////////////////////////////////////////////
  if (STATE_ALE)      // need to capture address bits when ALE is high.
  {
    uP_ADDR = ADDR;
  } 
  else
  ////////////////////////////////////////////////////////////
  // PSEN_N
  // Consider RAM for non-ROM locations, so you can write
  // programs and execute in Paulmon2.
  ////////////////////////////////////////////////////////////
  if (!STATE_PSEN_N)
  {
    // change DATA port to output to uP:
    DATA_DIR = DIR_OUT;

    // ROM?
    if ( (ROM_START <= uP_ADDR) && (uP_ADDR <= ROM_END) )
      DATA_OUT = pgm_read_byte_near(rom_bin + (uP_ADDR - ROM_START));
    else
    // Execute from RAM?
    if ( (RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END) )
      DATA_OUT = RAM[uP_ADDR - RAM_START];
#if (USE_SPI_RAM)
    else
    {
      //treat everywhere else as ram
      DATA_OUT = cache_read_byte(uP_ADDR);
    }
#else
    else
      DATA_OUT = 0x00;      // Dummy 0x00 out for unmapped memory locations
#endif
  } 
  else
  ////////////////////////////////////////////////////////////
  // RD_N Falling Edge
  // Note: We perform actual read operation once during falling
  // edge and then continue to output this value as long as
  // RD_N is low.  This is done to prevent multiple reads from
  // devices like FTDI (not used for 8031, but I like this
  // method for future use. 
  // Similar method is done for WR_N where we perform the actual
  // write on WR_N rising edge.
  ////////////////////////////////////////////////////////////
  if (!STATE_RD_N && prevRD_N)     // Falling edge of RD_N
  {
    // change DATA port to output to uP:
    DATA_DIR = DIR_OUT;

    // RAM?
    if ( (RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END) )
      DATA_latched = RAM[uP_ADDR - RAM_START];
#if (USE_SPI_RAM)
    else
    {
      //treat everywhere else as ram
      DATA_latched = cache_read_byte(uP_ADDR);
      // DATA_OUT = spi_read_byte_quad(0, uP_ADDR);
    }
#else
    else
      DATA_latched = 0x00;      // Dummy 0x00 out for unmapped memory locations
#endif

    DATA_OUT = DATA_latched;
  } 
  else
  ////////////////////////////////////////////////////////////
  // RD_N
  ////////////////////////////////////////////////////////////
  if (!STATE_RD_N)    // Continue to output data read on falling edge ^^^
  {
    // change DATA port to output to uP:
    DATA_DIR = DIR_OUT;

    DATA_OUT = DATA_latched;
  } 
  else
  ////////////////////////////////////////////////////////////
  // WR_N
  ////////////////////////////////////////////////////////////
  // Start capturing data_in but don't write it to destination yet
  if (!STATE_WR_N)
  {
    DATA_latched = DATA_IN;
  } 
  else
  ////////////////////////////////////////////////////////////
  // WR_N Rising Edge
  ////////////////////////////////////////////////////////////
  // Write data to destination when WR# goes high.
  if (STATE_WR_N && !prevWR_N)
  {
    // Memory Write
    if ( (RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END) )
      RAM[uP_ADDR - RAM_START] = DATA_latched;
#if (USE_SPI_RAM)
    else
    {
      // treat everywhere else as ram
      cache_write_byte(uP_ADDR, DATA_latched);
    }    
#endif
  }

  // Capture previous states for edge detection
  prevRD_N = STATE_RD_N;
  prevWR_N = STATE_WR_N;

  //////////////////////////////////////////////////////////////////////
  // start next cycle

  CLK_LOW;    // E goes low

  // turn databus to input if both PSEN or RD are deasserted.
  if (STATE_PSEN_N && STATE_RD_N)
  {
    DATA_DIR = DIR_IN;
    DATA_OUT = 0xFF;    // Enable Pull-ups
  }

#if (USE_LCD_KEYPAD)
  // one full cycle complete
  clock_cycle_count ++;
#endif

}

////////////////////////////////////////////////////////////////////
// Serial Event
////////////////////////////////////////////////////////////////////

/*
  SerialEvent occurs whenever a new data comes in the
 hardware serial RX.  This routine is run between each
 time loop() runs, so using delay inside loop can delay
 response. Note: Multiple bytes of data may be available.
 */

inline __attribute__((always_inline))
void serialEvent8251() 
{
  if (Serial.available())
  {
    // if (reg8251_STATUS & CMD_8251_RTS)  // read serial byte only if RTS is asserted
    {
      // RxRDY bit for cpu
      reg8251_STATUS = reg8251_STATUS | STAT_8251_RxRDY;
    }
  }
  return;
}


////////////////////////////////////////
// Soft-UART for 8031's Hard-UART
////////////////////////////////////////

#define k8031_UART_BAUD (16*12)
byte txd_8031;
word txd_delay = k8031_UART_BAUD*1.5;     // start capturing 1.5 bits later, middle
byte txd_bit = 0;

byte rxd_8031;
word rxd_delay = k8031_UART_BAUD;         // start output 1 bit at a time
byte rxd_bit = 0;

inline __attribute__((always_inline))
void serialEvent8031()
{
  // RXD
  if (rxd_bit == 0 && Serial.available())
  {
    rxd_bit = 9;
    rxd_8031 = Serial.read();
    rxd_delay = 192;

    pinMode2(uP_RXD, OUTPUT);
    digitalWrite2(uP_RXD, LOW);      // Start bit, low
  }
  else
  if (rxd_bit)
  {
    rxd_delay--;
    if (rxd_delay == 0)
    {
      digitalWrite2(uP_RXD, rxd_8031 & 0x01);
      rxd_8031 = (rxd_8031 >> 1);
      rxd_delay = 192;

      // are we done yet?  1bit left, which is stop bit
      rxd_bit--;
      if (rxd_bit == 0x01)
      {
        // set bit0 to output stop bit
        rxd_8031 = 0x01;
      }
      else
      if (rxd_bit == 0)
        pinMode2(uP_RXD, INPUT_PULLUP);
    }
  }

  // TXD  
  // Check for start bit
  
  if (txd_bit == 0 && !STATE_TXD)
  {
    txd_bit  = 9;   // need to receive 8(data)+1(stop) bits
    txd_8031 = 0;   // OR incoming bits to this.
    txd_delay = 288;
  }
  else
  if (txd_bit)
  {
    txd_delay--;
    if (txd_delay == 0)
    {
      txd_8031 = (txd_8031 >> 1) | (STATE_TXD << 4);
      txd_delay = 192;

      digitalWrite2(uP_GPIO, STATE_TXD);    // blink LED

      // are we done yet?  1bit left, which is stop bit
      if ((--txd_bit) == 0x01)
      {
        Serial.write(txd_8031);
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

// void btn_Pressed_Left()
// {
//   // Serial.println("Left.");
//   digitalWrite(uP_NMI_N, LOW);
// }

// void btn_Pressed_Right()
// {
//   // Serial.println("Right.");
//   digitalWrite(uP_NMI_N, HIGH);
// }

void btn_Pressed_Up()
{
  // Serial.println("Up.");
  
  // release uP_RESET
  digitalWrite(uP_RESET, HIGH);
}

void btn_Pressed_Down()
{
  // Serial.println("Down.");
  
  // assert uP_RESET
  digitalWrite(uP_RESET, LOW);
  
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
      // if (key == BTN_LEFT)   btn_Pressed_Left();
      // if (key == BTN_RIGHT)  btn_Pressed_Right();      
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
    lcd.print(freq);  lcd.print(" kHz  8031");
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
  Serial.print("LCD-DISP:   "); Serial.println(USE_LCD_KEYPAD, HEX); 
  Serial.print("SPI-RAM:    "); Serial.print(USE_SPI_RAM * 65536, DEC); Serial.println(" Bytes");
  Serial.print("SRAM Size:  "); Serial.print(RAM_END - RAM_START + 1, DEC); Serial.println(" Bytes");
  Serial.print("SRAM_START: 0x"); Serial.println(RAM_START, HEX); 
  Serial.print("SRAM_END:   0x"); Serial.println(RAM_END, HEX); 
  Serial.print("ROM Size:   "); Serial.print(ROM_END - ROM_START + 1, DEC); Serial.println(" Bytes");
  Serial.print("ROM_START:  0x"); Serial.println(ROM_START, HEX); 
  Serial.print("ROM_END:    0x"); Serial.println(ROM_END, HEX); 
  Serial.println("");
  Serial.println("=============================================");
  Serial.println("> 8031 Monitor by Frank Rudley");
  Serial.println("> This program helps to develop a Monitor ");
  Serial.println("> for the 8031 system.");
  Serial.println("> ");
  Serial.println("> Modified for Retroshield by kayto@github.com");
  Serial.println("> EXT RAM/ROM functionality currently missing.");
  Serial.println("> 'N' for Menu.");
  Serial.println("=============================================");
  Serial.println("");  
  Serial.print  ("==> Soft-UART {TxD, RxD}, Baud Rate: "); 
    Serial.print  (k8031_UART_BAUD, DEC);
    Serial.println(" cpu cycles/bit");
//  Serial.println("==> Please wait for monitor prompt.");
  if (outputDEBUG)
  {
  Serial.println("\nWARNING: DEBUG mode not supported");
  Serial.println("for 8031, due to min clock freq.");    
  }
  
#if (USE_LCD_KEYPAD)
  pinMode(LCD_BL, OUTPUT);
  analogWrite(LCD_BL, backlightSet);  
  lcd.begin(16, 2);
#endif

#if (USE_SPI_RAM)
  // Initialize memory subsystem
  spi_init();
  cache_init();
#endif

  // Initialize processor GPIO's
  uP_init();
  intel8251_init();


  // Reset processor
  //
  uP_assert_reset();
  
  for(int i=0;i<25;i++) cpu_tick();
  
  // Go, go, go
  uP_release_reset();

  Serial.println("\n");
}

////////////////////////////////////////////////////////////////////
// Loop()
//
////////////////////////////////////////////////////////////////////

void loop()
{
  word i = 0;
  word j = 0;
  
  // Loop forever
  //
  while(1)
  {    
    //////////////////////////////
    serialEvent8031();    
    cpu_tick();

  // execute lcdkeypad() when word i overflows (simple counter)
#if (USE_LCD_KEYPAD)
    if (i++ == 0) process_lcdkeypad();
#endif    
  }
}
