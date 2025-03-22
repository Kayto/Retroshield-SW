#ifndef _PORTMAP_H
#define _PORTMAP_H

// ##################################################
#if (ARDUINO_AVR_MEGA2560)
// ##################################################
// DIO2 library required on MEGA for fast GPIO access.
#include <Arduino.h>
#include <avr/pgmspace.h>
#include "pins2_arduino.h"
#include <DIO2.h>

// DIO2 library uses ..2 instead of ..Fast (Teensy uses digitalWriteFast...)
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
// MC14500B Processor  Pins
////////////////////////////////////////////////////////////////////

//#define uP_CLK1     NOT_USED
#define uP_CLK2     MEGA_PG0
#define uP_RESET    MEGA_PB1
#define uP_D0       MEGA_PL4
#define uP_I3       MEGA_PL3
#define uP_I2       MEGA_PL2
#define uP_I1       MEGA_PL1
#define uP_I0       MEGA_PL0
#define uP_WRITE    MEGA_PL5
#define uP_RR       MEGA_PL7
#define uP_JMP      MEGA_PB3
#define uP_RTN      MEGA_PL6
#define uP_FLAG_0   MEGA_PB2
#define uP_FLAG_F   MEGA_PB0

#define uP_KEY0     MEGA_PC0
#define uP_KEY1     MEGA_PC1
#define uP_KEY2     MEGA_PC2
#define uP_KEY3     MEGA_PC3
#define uP_KEY4     MEGA_PC4
#define uP_KEY5     MEGA_PC5
#define uP_KEY6     MEGA_PC6
#define uP_KEY7     MEGA_PC7
#define uP_KEY_RESET  MEGA_PG1

#define uP_OUTP_D0  MEGA_PA0
#define uP_OUTP_D1  MEGA_PA1
#define uP_OUTP_D2  MEGA_PA2
#define uP_OUTP_D3  MEGA_PA3
#define uP_OUTP_D4  MEGA_PA4
#define uP_OUTP_D5  MEGA_PA5
#define uP_OUTP_D6  MEGA_PA6
#define uP_OUTP_D7  MEGA_PA7


////////////////////////////////////////////////////////////////////
// MACROS
////////////////////////////////////////////////////////////////////
#define CLK_HIGH()      digitalWriteFast(uP_CLK2, LOW)
#define CLK_LOW()       digitalWriteFast(uP_CLK2, HIGH)
#define IS_CLK_LOW()    (digitalReadFast(uP_CLK2))
#define IS_CLK_HIGH()   (!digitalReadFast(uP_CLK2))

// DIR_IN & DIR_OUT for DATA pin.
#if (ARDUINO_AVR_MEGA2560)
  #define DATA_DIR_IN()   (DDRL = DDRL & 0b11101111)
  #define DATA_DIR_OUT()  (DDRL = DDRL | 0b00010000)
#elif (ARDUINO_TEENSY35 || ARDUINO_TEENSY36)
 #define DATA_DIR_IN()   (GPIOD_PDDR = (GPIOD_PDDR & 0xFFFFFFEF))
 #define DATA_DIR_OUT()  (GPIOD_PDDR = (GPIOD_PDDR | 0x00000010))
#elif (ARDUINO_TEENSY41)
  #define DATA_DIR_IN()   (CORE_PIN6_DDRREG = CORE_PIN6_DDRREG & (~CORE_PIN6_BITMASK))
  #define DATA_DIR_OUT()  (CORE_PIN6_DDRREG = CORE_PIN6_DDRREG | ( CORE_PIN6_BITMASK))
#endif


////////////////////////////////////////////////////////////////////
void print_teensy_version()
{
#if (ARDUINO_AVR_MEGA2560)
  Serial.println("Arduino:    Mega2560");
#elif (ARDUINO_TEENSY35)
  Serial.println("Teensy:     3.5");
#elif (ARDUINO_TEENSY36)
  Serial.println("Teensy:     3.6");
#elif (ARDUINO_TEENSY41)
  Serial.println("Teensy:     4.1");
#endif
}

#endif    // _PORTMAP_H



// Reference 

// Teensy 3.5/3.6
//
// #define GPIO?_PDOR    (*(volatile uint32_t *)0x400FF0C0) // Port Data Output Register
// #define GPIO?_PSOR    (*(volatile uint32_t *)0x400FF0C4) // Port Set Output Register
// #define GPIO?_PCOR    (*(volatile uint32_t *)0x400FF0C8) // Port Clear Output Register
// #define GPIO?_PTOR    (*(volatile uint32_t *)0x400FF0CC) // Port Toggle Output Register
// #define GPIO?_PDIR    (*(volatile uint32_t *)0x400FF0D0) // Port Data Input Register
// #define GPIO?_PDDR    (*(volatile uint32_t *)0x400FF0D4) // Port Data Direction Register
//

// TEENSY4.1 
//
// CORE_PIN28_BIT
// CORE_PIN28_BITMASK
// CORE_PIN28_PORTREG
// CORE_PIN28_PORTSET
// CORE_PIN28_PORTCLEAR
// CORE_PIN28_PORTTOGGLE
// CORE_PIN28_DDRREG	(1=OUT, 0=IN)
// CORE_PIN28_PINREG

