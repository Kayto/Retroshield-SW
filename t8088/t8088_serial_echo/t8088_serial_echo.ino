////////////////////////////////////////////////////////////////////
// RetroShield 80C88 for Teensy 3.5/3.6/4.1
//
// 2024/03/03
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

// Date         Comments                                            Author
// -----------------------------------------------------------------------------
// 03/03/2024   Bring-up on Teensy 4.1.                             Erturk
// 03/11/2024   Clean up for release.                               Erturk
// 09/07/2024   Reorg one code for Arduino + Teensy.                Erturk

////////////////////////////////////////////////////////////////////
// Options
//   outputDEBUG: Print memory access debugging messages.
////////////////////////////////////////////////////////////////////
#define outputDEBUG     0

////////////////////////////////////////////////////////////////////
// BOARD DEFINITIONS
////////////////////////////////////////////////////////////////////

#include "memorymap.h"      // Memory Map (ROM, RAM, PERIPHERALS)
#include "portmap.h"        // Pin mapping to cpu
#include "setuphold.h"      // Delays required to meet setup/hold
#include "buttons.h"        // Functions to read 2 buttons on teensy adapter board
#include "i8251.h"          // 8251 UART

void uP_assert_reset()
{
  // Drive RESET conditions
  digitalWriteFast( uP_RESET,  HIGH );
  digitalWriteFast( uP_CLK,    LOW );
  digitalWriteFast( uP_TEST_N, LOW );
  digitalWriteFast( uP_NMI,    LOW );   
  digitalWriteFast( uP_INTR,   LOW ); 
}

void uP_release_reset()
{
  digitalWriteFast(uP_RESET,  LOW);
}


void uP_init()
{
  pinMode( uP_RESET,  OUTPUT); digitalWrite(uP_RESET, HIGH );

  pinMode( uP_CLK,    OUTPUT); digitalWrite(uP_RESET, LOW  );
  pinMode( uP_TEST_N, OUTPUT); digitalWrite(uP_RESET, LOW  );
  pinMode( uP_NMI,    OUTPUT); digitalWrite(uP_RESET, LOW  );
  pinMode( uP_INTR,   OUTPUT); digitalWrite(uP_RESET, LOW  );

  pinMode( uP_INTA_N, INPUT);
  pinMode( uP_DEN_N,  INPUT);
  pinMode( uP_IO_M_N, INPUT);
  pinMode( uP_RD_N,   INPUT);  
  pinMode( uP_WR_N,   INPUT);  
  pinMode( uP_DT_R_N, INPUT);
  pinMode( uP_ALE,    INPUT);   

  // Set directions for ADDR & DATA Bus.
  configure_PINMODE_ADDR();
  configure_PINMODE_DATA();

  uP_assert_reset();

}

void board_init()
{
  // Initialize "hw" before cpu starts executing, such as
  // filling memory or modify vectors or modifying rom functions.

  // SCP monitor default user program is located at 0040:0000 (0x000400).
  // You can enter your custom program here.
  // This way you don't have to reenter it everytime.
  
  // Increment Mem: 
  const byte myprogram[] = {
    0x90,                       // NOP
    0xFE, 0x84, 0x00, 0x10,     // Increment adress 0x1000
    0xEB, 0xF9,                 // Go back to NOP
    0x00, 0x00, 0x00            // Dummy bytes.
  };

  for (int i=0; i<sizeof(myprogram); i++)
    RAM[0x400 + i] = myprogram[i];
  
  // Override divide-by-zero interrupt to restart monitor
  RAM[0x0000] = 0x00;
  RAM[0x0001] = 0x00;
  RAM[0x0002] = 0xFF;
  RAM[0x0003] = 0xFF;

  // Override NMI interrupt to restart monitor
  RAM[0x0008] = 0x00;
  RAM[0x0009] = 0x00;
  RAM[0x000a] = 0xFF;
  RAM[0x000b] = 0xFF;
}

////////////////////////////////////////////////////////////////////
// Processor Control Loop
////////////////////////////////////////////////////////////////////

unsigned long uP_ADDR;
byte          uP_DATA;

byte DATA_OUT = 0x00;
byte DATA_IN  = 0x00;
byte INT_PTR  = 0x00;

bool prev_RD_N    = true;
bool prev_WR_N    = true;
bool prev_INTA_N  = true;

char tmp[200];      // for debug sprintf buffer

inline __attribute__((always_inline))
void cpu_tick_debug()
{
  sprintf(tmp, " ADDR: \"%0.5lX\" ", uP_ADDR);  Serial.write(tmp);
  sprintf(tmp, " DATA: \"%0.2X\"", uP_DATA);    Serial.write(tmp);
  Serial.println(" *");
}


inline __attribute__((always_inline))
void cpu_tick_minimum_mode()
{    
  CLK_LOW();
  DELAY_FACTOR_L();

  ///////////////////////////////////////////
  // Address Latch
  ///////////////////////////////////////////
  if (digitalReadFast(uP_ALE))
  {
    uP_ADDR = ADDR();

    if (outputDEBUG)
    {      
      sprintf(tmp, " ADDR: \"%0.5lX\" ", uP_ADDR);    Serial.write(tmp);
      if (0) delay(200);
    }
  }
  else
  ///////////////////////////////////////////
  // MEMORY TRANSACTIONs
  ///////////////////////////////////////////
  if (!digitalReadFast(uP_DEN_N) && !digitalReadFast(uP_IO_M_N) )
  {

    ///////////////////////////////////////////
    // MEMORY READ
    ///////////////////////////////////////////

    if (!digitalReadFast(uP_RD_N))
    {
      xDATA_DIR_OUT();

      // RD# LOW
      if (outputDEBUG) { Serial.print(" MEM RD "); }

      // ROM?
      if ( (ROM_START <= uP_ADDR) && (uP_ADDR <= ROM_END) )
      { 
        DATA_OUT = pgm_read_byte_near(ROM + (uP_ADDR - ROM_START)); 
        if (outputDEBUG) { Serial.print("ROM "); }
      }
      else 
      // RAM?
      if ( (RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END) )
      { 
        DATA_OUT = RAM[uP_ADDR - RAM_START]; 
        if (outputDEBUG) { Serial.print("RAM "); }
      }
      else
      if ( (RESET_VECTOR_START <= uP_ADDR) && (uP_ADDR <= RESET_VECTOR_END) )
      {
        // Purposely checked after ROM/RAM for speed optimizations.
        DATA_OUT = pgm_read_byte_near(RESET_VECTOR + (uP_ADDR - RESET_VECTOR_START) ); 
        if (outputDEBUG) { Serial.print("RST "); }
      }
      else
      {
        DATA_OUT = 0x00;
        if (outputDEBUG) { Serial.print("UNK "); }
      }

      SET_DATA_OUT(DATA_OUT);
      DELAY_FOR_BUFFER();           // Let level shifter stabilize.        
      
      // for debug console
      uP_DATA = DATA_OUT;

      if (outputDEBUG)
      {
        sprintf(tmp, " DATA: \"%0.2X\" ", uP_DATA);
        Serial.write(tmp);
        Serial.println("*");
      }
    }
    else      
    ///////////////////////////////////////////
    // MEMORY WRITE
    ///////////////////////////////////////////    

    // Latch data while WR# is low.
    if (!digitalReadFast(uP_WR_N))
    {

      // WR# LOW
      xDATA_DIR_IN();

      if (false && outputDEBUG) { Serial.print(" MEM WR_N "); }

      DATA_IN = xDATA_IN();
      uP_DATA = DATA_IN;

      if (false && outputDEBUG)
      {
        sprintf(tmp, " DATA: \"%0.2X\"", uP_DATA);
        Serial.write(tmp);
        Serial.println("*");
      }    

    }
    else
    // process latched data when WR# goes high.
    if (digitalReadFast(uP_WR_N) && !prev_WR_N)
    {
      // WR# Rising edge
      if (outputDEBUG) { Serial.print(" MEM WR "); }

      // RAM
      if ( (RAM_START <= uP_ADDR) && (uP_ADDR <= RAM_END) )
      { 
        RAM[uP_ADDR - RAM_START] = DATA_IN; 
        if (outputDEBUG) { Serial.print("RAM "); }
      }
      else
      {
        if (outputDEBUG) { Serial.print("UNK "); }
      }

      if (outputDEBUG)
      {
        sprintf(tmp, " DATA: \"%0.2X\"", uP_DATA);    Serial.write(tmp);
        Serial.println("*");
      }      
    }
    else
    {
      // DEN# by itself.  Weird..
      xDATA_DIR_IN();
    }

    if (false && outputDEBUG)
    { 
      Serial.println("*"); 
    }  
  }
  else
  ///////////////////////////////////////////
  // I/O TRANSACTION
  ///////////////////////////////////////////
  if (!digitalReadFast(uP_DEN_N) && digitalReadFast(uP_IO_M_N) )
  {

    ///////////////////////////////////////////
    // I/O READ
    ///////////////////////////////////////////

    if (!digitalReadFast(uP_RD_N))
    {
      xDATA_DIR_OUT();

      // RD# LOW
      if (outputDEBUG) { Serial.print(" I/O RD "); }

      if ( uP_ADDR == ADDR_8251_DATA)
      {
        DATA_OUT = reg8251_DATA = toupper( Serial.read() );       // DATA register access
        reg8251_STATUS = reg8251_STATUS & (~STAT_8251_RxRDY);     // clear RxRDY bit in 8251
        // Serial.write("8251 serial read\n");
      }
      else
      if ( uP_ADDR == ADDR_8251_MODCMD )
      {
        if (reg8251_STATE == STATE_8251_RESET)                    // Mode/Command Register access
          DATA_OUT = reg8251_MODE;
        else
          DATA_OUT = reg8251_STATUS;
      }
      else
      {
        DATA_OUT = 0x00;
        if (outputDEBUG) { Serial.print("UNK "); }
      }

      SET_DATA_OUT(DATA_OUT);
      DELAY_FOR_BUFFER();           // Let level shifter stabilize.        

      // for debug console
      uP_DATA = DATA_OUT;

      if (outputDEBUG)
      {
        sprintf(tmp, " DATA: \"%0.2X\"", uP_DATA);
        Serial.write(tmp);
        Serial.println("*");
      }
    }
    else      
    ///////////////////////////////////////////
    // I/O WRITE
    /////////////////////////////////////////// 

    // Latch data while WR# is low.   
    if (!digitalReadFast(uP_WR_N))
    {

      // WR# LOW
      xDATA_DIR_IN();

      if (false && outputDEBUG) { Serial.print(" I/O WR_N "); }

      DATA_IN = xDATA_IN();
      uP_DATA = DATA_IN;

      if (false && outputDEBUG)
      {
        sprintf(tmp, " DATA: \"%0.2X\"", uP_DATA);
        Serial.write(tmp);
        Serial.println("*");
      }    

    }
    else
    // process latched data when WR# goes high.
    if (digitalReadFast(uP_WR_N) && !prev_WR_N)
    {
      // WR# Rising edge
      if (outputDEBUG) { Serial.print(" I/O WR "); }

      // 8251 access
      if (uP_ADDR == ADDR_8251_DATA)
      {
        
        reg8251_DATA = DATA_IN;                                   // write to DATA register
        Serial.write(reg8251_DATA);                               // Spit byte out to serial
      }
      else
      if ( uP_ADDR == ADDR_8251_MODCMD )
      {
        if (reg8251_STATE == STATE_8251_RESET)                    // write to Mode/Command Register
        {
          reg8251_STATE = STATE_8251_INITIALIZED;                 // 8251 changes from MODE to COMMAND
                                                                  // we ignore the mode command for now.
          // reg8251_MODE = DATA_IN
          // Serial.write("8251 reset\n");
        } else {
          reg8251_COMMAND = DATA_IN;                              // Write to 8251 command register
                                                                  // TODO: process command sent
        }
      }
      else
      {
        if (outputDEBUG) { Serial.print("UNK "); }
      }

      if (outputDEBUG)
      {
        sprintf(tmp, " DATA: \"%0.2X\"", uP_DATA);
        Serial.write(tmp);
        Serial.println("*");
      }      
    }
    else
    ///////////////////////////////////////////
    // IO INTA
    ///////////////////////////////////////////    

    // From 80C88 REN Datasheet:
    // 
    // The basic difference between the interrupt acknowledge cycle 
    // and a read cycle is that the interrupt acknowledge (INTA) signal is 
    // asserted in place of the read (RD) signal and the address bus is 
    // held at the last valid logic state by internal bus-hold devices (see 
    // Figure 6 on page 13. In the second of two successive INTA cycles, 
    // a byte of information is read from the data bus, as supplied by 
    // the interrupt system logic (i.e., 82C59A priority interrupt 
    // controller). This byte identifies the source (type) of the interrupt. 
    // It is multiplied by four and used as a pointer into the interrupt 
    // vector lookup table, as described earlier

    // 11. Two INTA cycles run back-to-back. The 80C88 local ADDR/DATA bus 
    // is floating during both INTA cycles. Control signals are shown for 
    // the second INTA cycle.

    // ERTURK - it should be ok to drive the databus w/ interrupt pointer
    //          in both INTA cycles. Supposedly the bus-hold circuits should
    //          be ok.

    INT_PTR  = 0x0C;

    // ^^^^
    // This interrupt pointer will be sent to 80c88 during interrupt cycle.
    // SCP v1.5 uses int #0C for uart break-in interrupt
    // For your custom hw design, you  can modify it.
    // On a PC XT architecture, it is sent by interrupt controller (8259). 
    

    if (!digitalReadFast(uP_INTA_N))
    {
      xDATA_DIR_OUT();

      // INTA cycle
      if (outputDEBUG) { Serial.print(" I/O INTA "); }
          
      SET_DATA_OUT(INT_PTR);
      DELAY_FOR_BUFFER();           // Let level shifter stabilize.        

      // for debug console
      uP_DATA = DATA_OUT;

      if (outputDEBUG)
      {
        sprintf(tmp, " INTA: \"%0.2X\"", uP_DATA);
        Serial.write(tmp);
        Serial.println("*");
      } 
    }
    else

    {
      // I/O + DEN# by itself.  Weird..
      xDATA_DIR_IN();
    }

    if (false && outputDEBUG)
    { 
      Serial.println("*"); 
    }  

  }
  else
  {
    // DEN_N by itself, tri-state to be sure.
    xDATA_DIR_IN();
  }

  // Save for edge detection
  prev_RD_N   = digitalReadFast(uP_RD_N);
  prev_WR_N   = digitalReadFast(uP_WR_N);
  prev_INTA_N = digitalReadFast(uP_INTA_N);

  CLK_HIGH();
  DELAY_FACTOR_H();
}


////////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////////

void setup() 
{
#if   (ARDUINO_AVR_MEGA2560)  
  Serial.begin(115200);
#elif (ARDUINO_TEENSY35 || ARDUINO_TEENSY36 || ARDUINO_TEENSY41) 
  Serial.begin(115200);
  while (!Serial);              // Wait for serial on Teensy.
#endif

  Serial.write(27);       // ESC command
  Serial.print("[2J");    // clear screen command
  Serial.write(27);
  Serial.print("[H");
  Serial.println("\n");
  Serial.println("Configuration:");
  Serial.println("==============");
  print_teensy_version();
  Serial.print("Debug:      ");   Serial.println(outputDEBUG, HEX);
  Serial.print("--------------"); Serial.println();
  Serial.print("ROM Size:   ");   Serial.print(ROM_END - ROM_START + 1, DEC); Serial.println(" Bytes");
  Serial.print("ROM_START:  0x"); Serial.println(ROM_START, HEX); 
  Serial.print("ROM_END:    0x"); Serial.println(ROM_END, HEX);
  Serial.print("--------------"); Serial.println(); 
  Serial.print("SRAM Size:  ");   Serial.print(RAM_END - RAM_START + 1, DEC); Serial.println(" Bytes");
  Serial.print("SRAM_START: 0x"); Serial.println(RAM_START, HEX); 
  Serial.print("SRAM_END:   0x"); Serial.println(RAM_END, HEX); 
  Serial.print("--------------"); Serial.println(); 
  Serial.println();
  Serial.println("=======================================================");
  Serial.println("; Standalone 80C88 Serial Echo program using");
  Serial.println("; SCP 8086 Monitor routines");
  Serial.println("; Original SCP Code by Tim Paterson");
  Serial.println("; Adapted by kayto@github");
  Serial.println("=======================================================");

  delay(1000);

  Serial.print("SRAM Size:  ");   Serial.print( (RAM_END - RAM_START + 1)/1024, DEC); Serial.print(" KBytes @ 0x"); Serial.println(RAM_START, HEX);

  uP_init();
  board_init();
  intel8251_init();

  Serial.print("RESET=1...");
  // Reset processor
  uP_assert_reset();
  for(int i=0;i<100;i++) {
    cpu_tick_minimum_mode();
  }
  uP_release_reset();
  Serial.println("RESET=0");
  Serial.println();
}

////////////////////////////////////////////////////////////////////
// Loop
////////////////////////////////////////////////////////////////////

void loop()
{
  byte i = 0;

  // Loop forever
  //  
  while(1)
  {
    cpu_tick_minimum_mode();

    i--;
    if (i == 0) serialEvent8251();    // Dont' check Serial.available() every cycle
    if (i == 0) Serial.flush();

    // Use Teensy buttons P & C to do something.
    // Warning - these impact performance a lot (buttons are read as ADC input).

    // Use button P on teensy to single-step 80c88.
    if (0) {
      cpu_tick_debug(); 
      use_button_P_to_single_step();
    }
    if (0) use_button_P_to_pulse_pin(uP_NMI,   LOW, HIGH);
    if (0) use_button_P_to_pulse_pin(uP_INTR,   LOW, HIGH);
    if (0) use_button_C_to_pulse_pin(uP_RESET, LOW, HIGH);

    if (outputDEBUG) {
      cpu_tick_debug(); 
      delay(200);
    }

  }
}


