#ifndef _SETUPHOLD_H
#define _SETUPHOLD_H

// ##################################################
// Adjust setup/hold times based on Teensy
// Teensy 3.5 = 120Mhz  (1x)
// Teensy 3.6 = 180Mhz  (1.5x)
// Teensy 4.1 = 600Mhz  (5x)
// ##################################################
#if (ARDUINO_TEENSY35)

  #define DELAY_UNIT()        asm volatile("nop\nnop\nnop\nnop\nnop\nnop\n")
  #define DELAY_FACTOR_H()    {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); } // DELAY_UNIT(); }
  #define DELAY_FACTOR_L()    {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); } // DELAY_UNIT(); }

  #define DELAY_FOR_BUFFER()  {DELAY_UNIT(); DELAY_UNIT(); }

#elif (ARDUINO_TEENSY36)

  #define DELAY_UNIT()        asm volatile("nop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\n")
  #define DELAY_FACTOR_H()    {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); } // DELAY_UNIT(); }
  #define DELAY_FACTOR_L()    {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); } // DELAY_UNIT(); }

  #define DELAY_FOR_BUFFER()  {DELAY_UNIT(); DELAY_UNIT(); }

#elif (ARDUINO_TEENSY41)

  #define DELAY_UNIT()        asm volatile("nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n" \
                                           "nop\nnop\nnop\nnop\nnop\nnop\n")      // ~ 50ns


  #define DELAY_FACTOR_H()    {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }
  #define DELAY_FACTOR_L()    {DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); DELAY_UNIT(); }

  #define DELAY_FOR_BUFFER()  {DELAY_UNIT(); DELAY_UNIT(); } // add more time for READ SETUP TIME. asm volatile("nop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\nnop\n");

#endif

// 
// These following routines provide a more accurate clock timing.
// instead of dummy nop's, we can tell teensy to wait until a
// certain timing is met.
//

// Usage:
// accurate_delay_init()                        // initialize before loop()
// accurate_delay(NS_TO_TEENSY_CYCLE(400))      // wait until timer hits +400ns

// ##################################################
#if ((ARDUINO_TEENSY35) || (ARDUINO_TEENSY36) || (ARDUINO_TEENSY41))
// ##################################################

  #define TEENSY_PERIOD_NS          (1e9/F_CPU)                   // ns duration
  #define NS_TO_TEENSY_CYCLE(N)     ((N)/TEENSY_PERIOD_NS)        // Convert ns to #cpu cycle
  uint32_t next_edge_offset = 13;   // Fine-tune knob for freq accuracy.   set_clock_frequency_kHz()


// ##################################################
  inline __attribute__((always_inline))
  void accurate_delay_init()
  {
    ARM_DWT_CYCCNT = 0; /* reset counter */
  }

// ##################################################
  inline __attribute__((always_inline))
  void accurate_delay(uint32_t next_time)
  {
    while(ARM_DWT_CYCCNT < next_time);
    ARM_DWT_CYCCNT = next_edge_offset;   /* reset counter with compensation */
    return;
  }
#endif  // 
// ##################################################

#endif  // _SETUPHOLD_H