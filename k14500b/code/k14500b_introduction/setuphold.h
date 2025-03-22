#ifndef _SETUPHOLD_H
#define _SETUPHOLD_H

#include <Arduino.h>

// ##################################################
// Adjust setup/hold times based on board
// Arduino Mega 2560  = 16Mhz   (0x)
// Teensy 3.5         = 120Mhz  (1x)
// Teensy 3.6         = 180Mhz  (1.5x)
// Teensy 4.1         = 600Mhz  (5x)
// ##################################################


// ##################################################
#if (ARDUINO_AVR_MEGA2560)
// ##################################################

  // 1 NOP = 250ns delay.
  #define DELAY_UNIT_250NS()    asm volatile("nop\nnop\nnop\nnop\n") 
  #define DELAY_UNIT()          asm volatile("nop\nnop\nnop\nnop\nnop\n")
  #define DELAY_FACTOR_H()      {DELAY_UNIT();} // DELAY_UNIT(); DELAY_UNIT();} // DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }
  #define DELAY_FACTOR_L()      {DELAY_UNIT();} // DELAY_UNIT(); DELAY_UNIT();} // DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }

  #define DELAY_FOR_BUFFER()    asm volatile("nop")   // N/A for Mega (Delay for level shifters (teensy) to pass data out)

// ##################################################
#elif (ARDUINO_TEENSY35)
// ##################################################

  #define DELAY_UNIT()      asm volatile("nop\nnop\nnop\nnop\nnop\nnop\n")
  #define DELAY_FACTOR_H() {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }
  #define DELAY_FACTOR_L() {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }

  // Add about (8.5+5.1ns = 13.6 ~ 20ns) delay for TXB0108's to stabilize.
  // 1/120MHz * 4 = 32ns  
  #define DELAY_FOR_BUFFER()  asm volatile("nop\nnop\nnop\nnop\n");

// ##################################################
#elif (ARDUINO_TEENSY36)
// ##################################################

  #define DELAY_UNIT()      asm volatile("nop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\n")
  #define DELAY_FACTOR_H() {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }
  #define DELAY_FACTOR_L() {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }

  // Add about (8.5+5.1ns = 13.6 ~ 20ns) delay for TXB0108's to stabilize.
  // 1/180MHz * 5 = 16ns
  #define DELAY_FOR_BUFFER()  asm volatile("nop\nnop\nnop\nnop\nnop\n");

// ##################################################
#elif (ARDUINO_TEENSY41)
// ##################################################

  #define DELAY_UNIT_25NS() asm volatile("nop\nnop\nnop\nnop\nnop\nnop\n" \
                                         "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                         "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                         "nop\nnop\nnop\n" \
                                         "nop\nnop\nnop\nnop\nnop\nnop\n")
  #define DELAY_UNIT()      asm volatile("nop\nnop\nnop\nnop\nnop\nnop\n" \
                                         "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                         "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                         "nop\nnop\nnop\n" \
                                         "nop\nnop\nnop\nnop\nnop\nnop\n")
  #define DELAY_FACTOR_1HL() delayNanoseconds(250) //{DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }
  #define DELAY_FACTOR_1LL() delayNanoseconds(150) //{DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }
  #define DELAY_FACTOR_2LH() delayNanoseconds(150) //{DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }
  #define DELAY_FACTOR_2LL() delayNanoseconds(150) //{DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }

  // delayMicroseconds(1) // 
  // Add about (8.5+5.1ns = 13.6 ~ 20ns) delay for TXB0108's to stabilize.
  // 1/600MHz * 10 = 16ns
  #define DELAY_FOR_BUFFER()  asm volatile("nop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\n");

  inline __attribute__((always_inline))
  void DELAY_UNIT_250NS() 
  {
    /* 100ns */ DELAY_UNIT_25NS(); DELAY_UNIT_25NS(); DELAY_UNIT_25NS(); DELAY_UNIT_25NS();
    /* 100ns */ DELAY_UNIT_25NS(); DELAY_UNIT_25NS(); DELAY_UNIT_25NS(); DELAY_UNIT_25NS();
    /*  50ns */ DELAY_UNIT_25NS(); DELAY_UNIT_25NS();
  }

#endif

#endif  // _SETUPHOLD_H