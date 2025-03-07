#ifndef _PORTMAP_H
#define _PORTMAP_H

// This is a complicated header file.
// it defines port macros based on Arduino or Teeny and which
// version of teensy. Fastest port access are done using 
// direct access to ports.


// ##################################################
#if (ARDUINO_AVR_MEGA2560)
// ##################################################
// DIO2 library required on MEGA for fast GPIO access.
#include <avr/pgmspace.h>
#include "pins2_arduino.h"
#include <DIO2.h>

// DIO2 library uses ..2 instead of ..Fast
#define digitalWriteFast(PORT,DATA)  digitalWrite2(PORT,DATA)
#define digitalReadFast(PORT)        digitalRead2(PORT)
#endif

// ##################################################
#if (ARDUINO_AVR_MEGA2560)
// ##################################################

#define MEGA_PD7  (38)
#define MEGA_PG0  (41)
#define MEGA_PG1  (40)
#define MEGA_PG2  (39)
#define MEGA_PB0  (53)
#define MEGA_PB1  (52)
#define MEGA_PB2  (51)
#define MEGA_PB3  (50)

#define MEGA_PC7  (30)
#define MEGA_PC6  (31)
#define MEGA_PC5  (32)
#define MEGA_PC4  (33)
#define MEGA_PC3  (34)
#define MEGA_PC2  (35)
#define MEGA_PC1  (36)
#define MEGA_PC0  (37)

#define MEGA_PL7  (42)
#define MEGA_PL6  (43)
#define MEGA_PL5  (44)
#define MEGA_PL4  (45)
#define MEGA_PL3  (46)
#define MEGA_PL2  (47)
#define MEGA_PL1  (48)
#define MEGA_PL0  (49)

#define MEGA_PA7  (29)
#define MEGA_PA6  (28)
#define MEGA_PA5  (27)
#define MEGA_PA4  (26)
#define MEGA_PA3  (25)
#define MEGA_PA2  (24)
#define MEGA_PA1  (23)
#define MEGA_PA0  (22)

// ##################################################
#elif (ARDUINO_TEENSY35 || ARDUINO_TEENSY36 || ARDUINO_TEENSY41)
// ##################################################

#define MEGA_PD7  (24)
#define MEGA_PG0  (13)
#define MEGA_PG1  (16)
#define MEGA_PG2  (17)
#define MEGA_PB0  (28)
#define MEGA_PB1  (39)
#define MEGA_PB2  (29)
#define MEGA_PB3  (30)

#define MEGA_PC7  (27)
#define MEGA_PC6  (26)
#define MEGA_PC5  (4)
#define MEGA_PC4  (3)
#define MEGA_PC3  (38)
#define MEGA_PC2  (37)
#define MEGA_PC1  (36)
#define MEGA_PC0  (35)

#define MEGA_PL7  (5)
#define MEGA_PL6  (21)
#define MEGA_PL5  (20)
#define MEGA_PL4  (6)
#define MEGA_PL3  (8)
#define MEGA_PL2  (7)
#define MEGA_PL1  (14)
#define MEGA_PL0  (2)

#define MEGA_PA7  (12)
#define MEGA_PA6  (11)
#define MEGA_PA5  (25)
#define MEGA_PA4  (10)
#define MEGA_PA3  (9)
#define MEGA_PA2  (23)
#define MEGA_PA1  (22)
#define MEGA_PA0  (15)

#endif

////////////////////////////////////////////////////////////////////
// 80C88 Processor Control Pins
////////////////////////////////////////////////////////////////////

#define uP_RESET      MEGA_PB0
#define uP_INTA_N     MEGA_PB2
#define uP_CLK        MEGA_PG0
#define uP_DEN_N      MEGA_PG2
#define uP_IO_M_N     MEGA_PC4
#define uP_RD_N       MEGA_PC6
#define uP_TEST_N     MEGA_PC7
#define uP_WR_N       MEGA_PC5
#define uP_DT_R_N     MEGA_PD7
#define uP_ALE        MEGA_PG1
#define uP_NMI        MEGA_PB3
#define uP_INTR       MEGA_PB1


////////////////////////////////////////////////////////////////////
// MACROS
////////////////////////////////////////////////////////////////////

// #define NORMAL_CLK
#define INVERTED_CLK      // Rev A board inverts clock via U2.

#ifdef INVERTED_CLK
  #define CLK_HIGH()      digitalWriteFast(uP_CLK, LOW)
  #define CLK_LOW()       digitalWriteFast(uP_CLK, HIGH)
#else
  #define CLK_HIGH()      digitalWriteFast(uP_CLK, HIGH)
  #define CLK_LOW()       digitalWriteFast(uP_CLK, LOW)
#endif

byte ADDRpinTable[] = {
  // AD0..AD19
  MEGA_PL0,MEGA_PL1,MEGA_PL2,MEGA_PL3,MEGA_PL4,MEGA_PL5,MEGA_PL6,MEGA_PL7,
  MEGA_PA0,MEGA_PA1,MEGA_PA2,MEGA_PA3,MEGA_PA4,MEGA_PA5,MEGA_PA6,MEGA_PA7,
  MEGA_PC0,MEGA_PC1,MEGA_PC2,MEGA_PC3  
};

byte DATApinTable[] = {
  // AD0..AD7
  MEGA_PL0,MEGA_PL1,MEGA_PL2,MEGA_PL3,MEGA_PL4,MEGA_PL5,MEGA_PL6,MEGA_PL7
  // 80C86:  MEGA_PA0,MEGA_PA1,MEGA_PA2,MEGA_PA3,MEGA_PA4,MEGA_PA5,MEGA_PA6,MEGA_PA7,
};

void configure_PINMODE_ADDR()
{
  for (int i=0; i<sizeof(ADDRpinTable); i++)
  {
    pinMode(ADDRpinTable[i], INPUT);
  } 
}

void configure_PINMODE_DATA()
{
  for (int i=0; i<sizeof(DATApinTable); i++)
  {
    pinMode(DATApinTable[i], INPUT);
  } 
}

// ##################################################
#if (ARDUINO_AVR_MEGA2560)
// ##################################################

#define MEGA_DIR_IN  0x00
#define MEGA_DIR_OUT 0xFF

// Directions
#define MEGA_ADDR_A1916_DIR  DDRC   // Only low 4 bits.
#define MEGA_ADDR_A1508_DIR  DDRA
#define MEGA_ADDR_A0700_DIR  DDRL
#define MEGA_DATA_DIR        DDRL

// Data in/out
#define MEGA_ADDR_A1916      ((PINC) & 0x0fL)
#define MEGA_ADDR_A1508      ((PINA) & 0xFFL)
#define MEGA_ADDR_A0700      ((PINL) & 0xFFL)
#define MEGA_DATA_IN         ((byte) PINL)
#define MEGA_DATA_OUT        (PORTL)

// read bits raw
#define xDATA_DIR_IN()    (MEGA_DATA_DIR = MEGA_DIR_IN)
#define xDATA_DIR_OUT()   (MEGA_DATA_DIR = MEGA_DIR_OUT)
#define SET_DATA_OUT(D)   (MEGA_DATA_OUT = (byte) D)
#define xDATA_IN()        ((byte) MEGA_DATA_IN)

// build ADDR
#define ADDR()            ((MEGA_ADDR_A1916<<16)|(MEGA_ADDR_A1508<<8 )|(MEGA_ADDR_A0700))

// ##################################################
#elif (ARDUINO_TEENSY35 || ARDUINO_TEENSY36)
// ##################################################

// read bits raw
#define xDATA_DIR_IN()    (GPIOD_PDDR = (GPIOD_PDDR & 0xFFFFFF00))
#define xDATA_DIR_OUT()   (GPIOD_PDDR = (GPIOD_PDDR | 0x000000FF))
#define SET_DATA_OUT(D)   (GPIOD_PDOR = (GPIOD_PDOR & 0xFFFFFF00) | ( (byte) D))
#define xDATA_IN()        ((byte) (GPIOD_PDIR & 0xFF))

// Teensy has an LED on its digital pin13 (PTC5). which interferes w/
// level shifters.  So we instead pick-up A5 from PTA5 port and use
// PTC5 for PG0 purposes.
//
#define ADDR_HM_RAW       ((word) (GPIOC_PDIR & 0b0000111111011111))
#define ADDR_AD13_RAW     ((word) (GPIOA_PDIR & 0b0000000000100000))
#define ADDR_L_RAW        ((byte) (GPIOD_PDIR & 0xFF))

// build ADDR, ADDR_H, ADDR_L
#define ADDR()            ((unsigned long) ( ( (ADDR_HM_RAW | ADDR_AD13_RAW) << 8)  | ADDR_L_RAW))

// ##################################################
#elif (ARDUINO_TEENSY41)
// ##################################################

// Teensy 4.1 has different port/pin assignments compared to Teeny 3.5 & 3.6
// so we have to do bit shuffling to construct address and data buses.
// Teensy 4.1's 600Mhz seems to compensate by executing rest faster.

inline __attribute__((always_inline))
void xDATA_DIR_IN()
{
  for (int i=7; i>=0; i--)                    // <<== Hardcoded number
  {
    pinMode(DATApinTable[i],INPUT);
  } 
}


inline __attribute__((always_inline))
void xDATA_DIR_OUT()
{
  for (int i=7; i>=0; i--)                    // <<== Hardcoded number
  {
    pinMode(DATApinTable[i],OUTPUT);
  } 
}

inline __attribute__((always_inline))
void SET_DATA_OUT(byte b)
{
  // for (int i=0; i<8; i++)
  // {
  //   digitalWrite(DATApinTable[i], (b & 1));
  //   b = b >> 1;
  // } 

  digitalWriteFast(MEGA_PL0, (b & 1));
  b = b >> 1;
  digitalWriteFast(MEGA_PL1, (b & 1));
  b = b >> 1;
  digitalWriteFast(MEGA_PL2, (b & 1));
  b = b >> 1;
  digitalWriteFast(MEGA_PL3, (b & 1));
  b = b >> 1;
  digitalWriteFast(MEGA_PL4, (b & 1));
  b = b >> 1;
  digitalWriteFast(MEGA_PL5, (b & 1));
  b = b >> 1;
  digitalWriteFast(MEGA_PL6, (b & 1));
  b = b >> 1;
  digitalWriteFast(MEGA_PL7, (b & 1));  
}

inline __attribute__((always_inline))
byte xDATA_IN()
{
  byte b = 0;

  // for (int i=7; i>=0; i--)
  // {
  //   b = b << 1;
  //   b = b | digitalRead(DATApinTable[i]);
  // } 

  b = b | digitalReadFast(MEGA_PL7);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL6);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL5);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL4);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL3);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL2);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL1);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL0);

  return b;
}


inline __attribute__((always_inline))
unsigned long ADDR()
{
  unsigned long b = 0;

  // for (int i=19; i>=0; i--)
  // {
  //   b = b << 1;
  //   b = b | digitalRead(ADDRpinTable[i]);
  // } 

  b = b | digitalReadFast(MEGA_PC3);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PC2);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PC1);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PC0);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PA7);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PA6);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PA5);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PA4);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PA3);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PA2);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PA1);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PA0);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL7);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL6);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL5);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL4);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL3);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL2);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL1);
  b = b << 1;
  b = b | digitalReadFast(MEGA_PL0);

  return b;
}

// ##################################################
#endif
// ##################################################

void print_teensy_version()
{
#if (ARDUINO_AVR_MEGA2560)
  Serial.println("Arduino:    Mega2560");
#elif (ARDUINO_TEENSY35)
  Serial.println("Teensy:     3.5");
#elif (ARDUINO_TEENSY36)
  Serial.println("Teensy:     3.6");
#elif (ARDUINO_TEENSY36)
  Serial.println("Teensy:     4.1");
#endif
}

#endif    // _PORTMAP_H



// Reference
//
// #define GPIO?_PDOR    (*(volatile uint32_t *)0x400FF0C0) // Port Data Output Register
// #define GPIO?_PSOR    (*(volatile uint32_t *)0x400FF0C4) // Port Set Output Register
// #define GPIO?_PCOR    (*(volatile uint32_t *)0x400FF0C8) // Port Clear Output Register
// #define GPIO?_PTOR    (*(volatile uint32_t *)0x400FF0CC) // Port Toggle Output Register
// #define GPIO?_PDIR    (*(volatile uint32_t *)0x400FF0D0) // Port Data Input Register
// #define GPIO?_PDDR    (*(volatile uint32_t *)0x400FF0D4) // Port Data Direction Register
//