////////////////////////////////////////////////////////////////////
// RetroShield 2650 for Teensy
// 2020/01/25
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
// 01/25/2020   Initial Bring-up.                                   E. Kocalar
//
////////////////////////////////////////////////////////////////////
// Options
//   outputDEBUG: Print memory access debugging messages.
////////////////////////////////////////////////////////////////////
#define outputDEBUG     0

////////////////////////////////////////////////////////////////////
// 2650 DEFINITIONS
////////////////////////////////////////////////////////////////////
#include "t2650_pipbug_rom.h" 
#include "t2650_mwbasic_ram.h" 

// 2650 HW CONSTRAINTS
// !!! TODO !!!
//

////////////////////////////////////////////////////////////////////
// MEMORY LAYOUT
////////////////////////////////////////////////////////////////////

// 6K MEMORY
#define RAM_START   0x0400
#define RAM_END     0x6000
byte    RAM[RAM_END-RAM_START+1];

// ROM(s) (Monitor)
#define ROM_START   0x0000
#define ROM_END     (ROM_START+sizeof(rom_bin)-1)

////////////////////////////////////////////////////////////////////
// Arduino Port Mapping to Teensy GPIO Numbers.
////////////////////////////////////////////////////////////////////
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
#define MEGA_PC5  (04)
#define MEGA_PC4  (03)
#define MEGA_PC3  (38)
#define MEGA_PC2  (37)
#define MEGA_PC1  (36)
#define MEGA_PC0  (35)

#define MEGA_PL7  (05)
#define MEGA_PL6  (21)
#define MEGA_PL5  (20)
#define MEGA_PL4  (06)
#define MEGA_PL3  (08)
#define MEGA_PL2  (07)
#define MEGA_PL1  (14)
#define MEGA_PL0  (02)

#define MEGA_PA7  (12)
#define MEGA_PA6  (11)
#define MEGA_PA5  (25)
#define MEGA_PA4  (10)
#define MEGA_PA3  (09)
#define MEGA_PA2  (23)
#define MEGA_PA1  (22)
#define MEGA_PA0  (15)

////////////////////////////////////////////////////////////////////
// 2650 Processor Control
////////////////////////////////////////////////////////////////////
//
//
// #define GPIO?_PDOR    (*(volatile uint32_t *)0x400FF0C0) // Port Data Output Register
// #define GPIO?_PSOR    (*(volatile uint32_t *)0x400FF0C4) // Port Set Output Register
// #define GPIO?_PCOR    (*(volatile uint32_t *)0x400FF0C8) // Port Clear Output Register
// #define GPIO?_PTOR    (*(volatile uint32_t *)0x400FF0CC) // Port Toggle Output Register
// #define GPIO?_PDIR    (*(volatile uint32_t *)0x400FF0D0) // Port Data Input Register
// #define GPIO?_PDDR    (*(volatile uint32_t *)0x400FF0D4) // Port Data Direction Register

/* Digital Pin Assignments */

// read bits raw
#define xDATA_DIR_IN()    (GPIOD_PDDR = (GPIOD_PDDR & 0xFFFFFF00))
#define xDATA_DIR_OUT()   (GPIOD_PDDR = (GPIOD_PDDR | 0x000000FF))
#define SET_DATA_OUT(D)   (GPIOD_PDOR = (GPIOD_PDOR & 0xFFFFFF00) | ( (byte) D))
#define xDATA_IN          ((byte) (GPIOD_PDIR & 0xFF))

// Teensy has an LED on its digital pin13 (PTC5). which interferes w/
// level shifters.  So we instead pick-up A5 from PTA5 port and use
// PTC5 for PG0 purposes.
//
// k2650: AD15 not used.

#define ADDR_L1_RAW        ((word) (GPIOA_PDIR & 0b1111000000000000))
#define ADDR_L2_RAW        ((word) (GPIOC_PDIR & 0b0000111100000000))
#define ADDR_H1_RAW        ((word) (GPIOA_PDIR & 0b0000000000100000))
#define ADDR_H2_RAW        ((word) (GPIOC_PDIR & 0b0000000001011111))
#define ADDR_L_RAW         (ADDR_L1_RAW | ADDR_L2_RAW)
#define ADDR_H_RAW         (ADDR_H1_RAW | ADDR_H2_RAW)
// build ADDR, ADDR_H, ADDR_L
#define ADDR              ((word) ( (ADDR_H_RAW << 8)| (ADDR_L_RAW >> 8)))
#define ADDR_H            ((byte) ((ADDR & 0xFF00) >> 8))
#define ADDR_L            ((byte) (ADDR & 0x00FF))


/* Digital Pin Assignments */

#define uP_CLK      MEGA_PB1
#define uP_RESET    MEGA_PG1
#define uP_MIO_N    MEGA_PB0
#define uP_RW_N     MEGA_PB2
#define uP_OPREQ    MEGA_PB3
#define uP_INTREQ_N MEGA_PG0
#define uP_INTACK   MEGA_PG2
#define uP_FLAG     MEGA_PA7
#define uP_SENSE    MEGA_PD7

// Fast routines to drive clock signals high/low; faster than digitalWrite
// required to meet >100kHz clock
//
#define CLK_HIGH      ( GPIOA_PSOR = (1 << 17) )
#define CLK_LOW       ( GPIOA_PCOR = (1 << 17) )

#define STATE_MIO_N   ( (bool) (GPIOA_PDIR & (1 << 16)) )
// WATCHOUT: R is active-low and W is active high
#define STATE_RW_N    ( (bool) (GPIOB_PDIR & (1 << 18)) )
#define STATE_OPREQ   ( (bool) (GPIOB_PDIR & (1 << 19)) )
#define STATE_INTACK  ( (bool) (GPIOB_PDIR & (1 << 01)) )
#define STATE_FLAG    ( 1* (GPIOC_PDIR & (1 << 07)) )

// #define SENSE_HIGH    digitalWrite(uP_SENSE, true) 
// #define SENSE_LOW     digitalWrite(uP_SENSE, false) 
#define SENSE_HIGH    ( GPIOE_PSOR = (1 << 26) )
#define SENSE_LOW     ( GPIOE_PCOR = (1 << 26) )


unsigned long clock_cycle_count;

word uP_ADDR;
byte uP_DATA;

void uP_init()
{
  // Set directions for ADDR & DATA Bus.
  
  byte pinTable[] = {
    5,21,20,6,8,7,14,2,     // D7..D0
    27,26,4,3,38,37,36,35,  // A15..A8
    12,11,25,10,9,23,22,15  // A7..A0
  };
  for (int i=0; i<24; i++)
  {
    pinMode(pinTable[i],INPUT);
  } 

  pinMode(uP_CLK,       OUTPUT);
  pinMode(uP_RESET,     OUTPUT);
  pinMode(uP_INTREQ_N,  OUTPUT);
  pinMode(uP_SENSE,     OUTPUT);
    
  pinMode(uP_MIO_N,     INPUT);
  pinMode(uP_RW_N,      INPUT);
  pinMode(uP_OPREQ,     INPUT);
  pinMode(uP_INTACK,    INPUT);
  pinMode(uP_FLAG,      INPUT);

  digitalWrite(uP_CLK, LOW);
  uP_assert_reset();
  
  clock_cycle_count = 0;

}

void uP_assert_reset()
{
  digitalWrite(uP_INTREQ_N, HIGH);
  digitalWrite(uP_SENSE,    HIGH);     

  // Drive RESET conditions
  digitalWrite(uP_RESET, HIGH);
}

void uP_release_reset()
{
  // Drive RESET conditions
  digitalWrite(uP_RESET, LOW);
}

// Modified DLAY & DLY
// 0x3B, 0x06, 0x45, 0x7F, 0x01, 0x75, 0x18, 0x17, 0x20, 0x04, 0x20, 0xF8, 0x7E, 0xC0, 0xC0, 0x04, 
// 0x05, 0xF8, 0x7E, 0x17, 0x77, 0x10, 0x76, 0x40, 0xC2, 0x05, 0x08, 0x3B, 0x6B, 0x3B, 0x69, 0x74, 

// Modify pipbug ROM for super fast UART
// *** Not required for modified Pipbug rom ***
void k2650_pipbug_init()
{
  // Modify DLAY and DLY subroutines to count downto 0x20 and 0x05.
  // rom_bin[0x02A9 - 0x0000] = 0x04;    // LODI,R0 H'20'
  // rom_bin[0x02AA - 0x0000] = 0x20;
  
  // rom_bin[0x02AD - 0x0000] = 0xC0;    // NOP
  // rom_bin[0x02AE - 0x0000] = 0xC0;    // NOP

  // rom_bin[0x02AF - 0x0000] = 0x04;    // LODI,R0 H'05'
  // rom_bin[0x02B0 - 0x0000] = 0x05;
}
////////////////////////////////////////////////////////////////////
// Processor Control Loop
////////////////////////////////////////////////////////////////////
// This is where the action is.
// it reads processor control signals and acts accordingly.
//

bool currRD = 0;
bool prevRD = 0;
bool currWR_N = 1; 
bool prevWR_N = 1;
byte DATA_latched = 0;
word ADDR_latched = 0;

volatile byte DATA_OUT;
volatile byte DATA_IN;
#define DELAY_FACTOR() delayMicroseconds(1000)
#define DELAY_FACTOR_H() asm volatile("nop\nnop\nnop\nnop\n")
#define DELAY_FACTOR_L() asm volatile("nop\nnop\nnop\nnop\n")

inline __attribute__((always_inline))
void cpu_tick()
{   
  CLK_HIGH;
  
  uP_ADDR   = ADDR;

  currRD   = STATE_OPREQ && STATE_MIO_N && !STATE_RW_N;
  currWR_N = !(STATE_OPREQ && STATE_MIO_N && STATE_RW_N);
  
  if (outputDEBUG) 
  {    
    {
      char tmp[40];
      sprintf(tmp, "/ ADDR=%0.4X D=%0.2X", uP_ADDR, DATA_IN);
      Serial.write(tmp);
    }
    
    Serial.print(" OPREQ: ");
    Serial.print(STATE_OPREQ, HEX);
  
    Serial.print(" M/IO#: ");
    Serial.print(STATE_MIO_N, HEX);
  
    Serial.print(" RD: ");
    Serial.print(currRD, HEX);
    Serial.print(" WR_N: ");
    Serial.print(currWR_N, HEX);
  
    //Serial.print(" INTACK: ");
    //Serial.print(STATE_INTACK, HEX);
  
    //Serial.print(" FLAG: ");
    //Serial.print(STATE_FLAG, HEX);
    
    //Serial.print(" prevRD: ");
    //Serial.print(prevRD, HEX);
    //Serial.print(" prevWR_N: ");
    //Serial.print(prevWR_N, HEX);
  
    Serial.println(" ");
  }
  
  //////////////////////////////////////////////////////////////////////
  // Memory Access?
  //////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////
  // WR_N
  ////////////////////////////////////////////////////////////
  // Start capturing data_in but don't write it to destination yet
  if (!currWR_N)
  {
    // Serial.println("M: Data_latched");
    xDATA_DIR_IN();
    DATA_IN = xDATA_IN;
    
    DATA_latched = DATA_IN;
    ADDR_latched = uP_ADDR;
  } 
  else
  ////////////////////////////////////////////////////////////
  // WR_N Rising Edge
  ////////////////////////////////////////////////////////////
  // Write data to destination when WR# goes high.
  if (!prevWR_N && currWR_N)
  {
    // use ADDR_latched because ADDR may not be valid anymore.
    
    // Serial.println("M: Data_written");
    // Memory Write
    if ( (RAM_START <= ADDR_latched) && (ADDR_latched <= RAM_END) )
      //RAM[ADDR_latched - RAM_START] = DATA_latched;
      ram_bin [ADDR_latched - RAM_START] = DATA_latched;

#if outputDEBUG
    if ((0x0400 <= ADDR_latched) && (ADDR_latched <= 0x0435)) 
    {
      char tmp[20];
      sprintf(tmp, "WR A=%0.4X D=%0.2X\n", uP_ADDR, DATA_latched);
      Serial.write(tmp);
    }
#endif

  }      
  // else     // -- FIXME
  ////////////////////////////////////////////////////////////
  // RD Rising Edge
  ////////////////////////////////////////////////////////////
  if (!prevRD && currRD)     // Rising edge of RD
  {
    // Serial.println("READING...");
    
    // change DATA port to output to uP:
    xDATA_DIR_OUT();

    // ROM?
    if ( (ROM_START <= uP_ADDR) && (uP_ADDR <= ROM_END) )
      DATA_latched = rom_bin [(uP_ADDR - ROM_START)];
    else
    // Execute from RAM?
    if ( (RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END) )
//      DATA_latched = RAM[uP_ADDR - RAM_START];
        DATA_latched = ram_bin [uP_ADDR - RAM_START];
    else
      DATA_latched = 0xFF;

    DATA_OUT = DATA_latched;
    SET_DATA_OUT( DATA_OUT );
    
#if outputDEBUG
    if ((0x0400 <= uP_ADDR) && (uP_ADDR <= 0x0435)) 
    {
      char tmp[40];
      sprintf(tmp, "-- A=%0.4X D=%0.2X\n", uP_ADDR, DATA_latched);
      Serial.write(tmp);
    }
    if ((0x005B <= uP_ADDR) && (uP_ADDR <= 0x00A3)) 
    {
      char tmp[40];
      sprintf(tmp, "-- A=%0.4X D=%0.2X\n", uP_ADDR, DATA_latched);
      Serial.write(tmp);
    }
#endif
  } 
  else
  ////////////////////////////////////////////////////////////
  // RD_N
  ////////////////////////////////////////////////////////////
  if (currRD)    // Continue to output data read on falling edge ^^^
  {
    // Serial.println("Reading continue.");
    
    xDATA_DIR_OUT();

    DATA_OUT = DATA_latched;
    SET_DATA_OUT( DATA_OUT );
  } 

  else

  //////////////////////////////////////////////////////////////////////
  // IO Access?
  //////////////////////////////////////////////////////////////////////
  if (STATE_OPREQ && !STATE_MIO_N && false)
  {    
    ////////////////////////////////////////////////////////////
    // WR_N
    ////////////////////////////////////////////////////////////
    // Start capturing data_in but don't write it to destination yet
    if (!STATE_RW_N)
    {
      xDATA_DIR_IN();
      DATA_IN = xDATA_IN;
      
      DATA_latched = DATA_IN;
    } 
    else
    // IO Write?
    if (STATE_RW_N && !prevWR_N)      // perform write on rising edge
    {

#if (outputDEBUG)
      {
        char tmp[40];
        sprintf(tmp, "IORQ WR#=%0.1X A=%0.4X D=%0.2X\n", STATE_RW_N, uP_ADDR, DATA_latched);
        Serial.write(tmp);
      }
#endif
      
    } 
    else
    // IO Read?
    if (STATE_RW_N && !prevRD)    // perform actual read on rising edge
    {
      // change DATA port to output to uP:
      xDATA_DIR_OUT();

      DATA_latched = 0xFF;

      DATA_OUT = DATA_latched;
      SET_DATA_OUT( DATA_OUT );
      
#if (outputDEBUG)
      {
        char tmp[40];
        sprintf(tmp, "IORQ RD#=%0.1X A=%0.4X D=%0.2X\n", STATE_RW_N, uP_ADDR, DATA_latched);
        Serial.write(tmp);
      }
#endif
      
    } 
    else
    // continuing IO Read?
    if (STATE_RW_N)    // continue output same data
    {
      // change DATA port to output to uP:
      xDATA_DIR_OUT();

      DATA_OUT = DATA_latched;
      SET_DATA_OUT( DATA_OUT );
    } 

  }

  // Capture previous states for edge detection
  prevRD   = currRD;
  prevWR_N = currWR_N;

#if outputDEBUG
    delay(10);
#endif

  //////////////////////////////////////////////////////////////////////
  // start next cycle

  CLK_LOW;    // E goes low
  // DELAY_FACTOR_L();
  
  // turn databus to input if 2650 is not reading from ROM/RAM/IO.
  if (!STATE_OPREQ) // || !currWR_N)
  {
    xDATA_DIR_IN();
  }

  if (0)
  {
    {
      char tmp[40];
      sprintf(tmp, "\\ ADDR=%0.4X D=%0.2X", uP_ADDR, DATA_IN);
      Serial.write(tmp);
    }

    Serial.print(" OPREQ: ");
    Serial.print(STATE_OPREQ, HEX);
  
    Serial.print(" M/IO#: ");
    Serial.print(STATE_MIO_N, HEX);
  
    Serial.print(" RD: ");
    Serial.print(currRD, HEX);
    Serial.print(" WR_N: ");
    Serial.print(currWR_N, HEX);
  
    Serial.print(" INTACK: ");
    Serial.print(STATE_INTACK, HEX);
  
    Serial.print(" FLAG: ");
    Serial.print(STATE_FLAG, HEX);
    
    //Serial.print(" prevRD: ");
    //Serial.print(prevRD, HEX);
    //Serial.print(" prevWR_N: ");
    //Serial.print(prevWR_N, HEX);
  
    Serial.println(" ");
  }
  
#if outputDEBUG
    delay(300);
#endif
}

////////////////////////////////////////////////////////////////////
// Serial Event
////////////////////////////////////////////////////////////////////

////////////////////////////////////////
// Soft-UART for 2650's FLAG/SENSE
////////////////////////////////////////

// #define k2650_UART_BAUD (9045)
#define k2650_UART_BAUD (423)
byte txd_2650;
word txd_delay = k2650_UART_BAUD*1.5;     // start capturing 1.5 bits later, middle
byte txd_bit = 0;

byte rxd_2650;
word rxd_delay = k2650_UART_BAUD;         // start output 1 bit at a time
byte rxd_bit = 0;

inline __attribute__((always_inline))
void serialEvent2650()
{
  // RXD
  if (rxd_bit == 0 && Serial.available())
  {
    rxd_bit = 9;
    rxd_2650 = toupper( Serial.read() );
    if (rxd_2650 == '\\')
      rxd_2650 = 0x0A;
    rxd_delay = k2650_UART_BAUD;  // 192;

    pinMode(uP_SENSE, OUTPUT);
    digitalWrite(uP_SENSE, LOW);      // Start bit, low
  }
  else
  if (rxd_bit)
  {
    rxd_delay--;
    if (rxd_delay == 0)
    {
      digitalWrite(uP_SENSE, (rxd_2650 & 0x01));
      rxd_2650 = (rxd_2650 >> 1);
      rxd_delay = k2650_UART_BAUD;  // 192;

      // are we done yet?  1bit left, which is stop bit
      rxd_bit--;
      if (rxd_bit == 0x01)
      {
        // set bit0 to output stop bit
        rxd_2650 = 0x01;
      }
      else
      if (rxd_bit == 0)
        digitalWrite(uP_SENSE, HIGH);   
    }
  }

  // TXD
  // Check for start bit
  if (txd_bit == 0 && !STATE_FLAG)
  {
    // Serial.print(STATE_FLAG);
    txd_bit  = 9;   // need to receive 8(data)+1(stop) bits
    txd_2650 = 0;   // OR incoming bits to this.
    txd_delay = 1.5*k2650_UART_BAUD;  // 288
  }
  else
  if (txd_bit)
  {
    txd_delay--;
    if (txd_delay == 0)
    {
      // Serial.print(STATE_FLAG);
      // digitalWrite2(7, HIGH);
      txd_2650 = (txd_2650 >> 1) | (STATE_FLAG);
      // digitalWrite2(7, LOW);
      txd_delay = k2650_UART_BAUD;  // 192;

      // are we done yet?  1bit left, which is stop bit
      if ((--txd_bit) == 0x01)
      {
        Serial.write(txd_2650);
        // no more bits to receive.
        // stop bit will be ignored.
      }
    }
  }  
}


////////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////////

void setup() 
{

  Serial.begin(0);
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
  Serial.println("");
  Serial.println("=======================================================");
  Serial.println("> PIP BUG");
  Serial.println("> written by Signetics.");
  Serial.println("> downloaded from Craig Southeren's 18up5 repo");
  Serial.println("> https://bitbucket.org/postincrement/18up5-2650-remake/src/master/");
  Serial.println(">");
  Serial.println("> MicroWorld BASIC Interpreter for the 2650");
  Serial.println("> Written by Ian Binnie.");
  Serial.println("> Copyright MicroWorld, 1979");
  Serial.println("> Binary downloaded from Jim's repo");
  Serial.println("> https://github.com/jim11662418/Signetics-2650-SBC");
  Serial.println("=======================================================");
  Serial.println("");
  Serial.println("Enter \\ to send LF");
  Serial.println("Enter G0800 CR to enter MicroWorld BASIC. Type 'NEW' to start.");    
  // Initialize processor GPIO's
  uP_init();
  k2650_pipbug_init();

  Serial.println("\n");

  // Reset processor
  //
  Serial.println("RESET=1");
  uP_assert_reset();
  for(int i=0;i<25;i++)
    cpu_tick();
  
  // Go, go, go
  uP_release_reset();
  Serial.println("RESET=0");

}

////////////////////////////////////////////////////////////////////
// Loop()
////////////////////////////////////////////////////////////////////

void loop()
{
  word i = 500;
  word j = 0;
  
  // Loop forever
  //
  while(1)
  {    
    //////////////////////////////
    serialEvent2650();     // handles soft-uart on FLAGE/SENSE.
    cpu_tick();

    if (i-- == 0) {
      Serial.flush();
      i = 500;
    }
    
#define MEASURE_BAUD_RATE 0
#if MEASURE_BAUD_RATE
    if (STATE_FLAG)
    {
      if (j != 0)
      {
        Serial.print("BAUD = "); Serial.println(j);
        j = 0;
      }
    }
    else
    {
      j++;
    }
#endif
      
  }
}
