////////////////////////////////////////////////////////////////////
// RetroShield 14500B for Arduino Mega 2560
//
// 2024/10/02
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
// 10/02/2024   Bring-up on Arduino Mega.                           Erturk


////////////////////////////////////////////////////////////////////
// Options
//   outputDEBUG: Print memory access debugging messages.
////////////////////////////////////////////////////////////////////
#define USE_RELAY_SHIELD  0         // Out ports C, D, E, F control relays 1,2,3,4
#define outputDEBUG       0         // Print lots of debug spew
bool    outputDEBUG_PAUSE = true;   // During debug: Press 's' to single-step. 'g' to run fast.

char    tmp[200];                   // for debug sprintf buffer

////////////////////////////////////////////////////////////////////
// BOARD DEFINITIONS
////////////////////////////////////////////////////////////////////
#include <Arduino.h>
#include "memorymap.h"      // Memory Map (ROM, RAM, PERIPHERALS)
#include "portmap.h"        // Pin mapping to cpu
#include "setuphold.h"      // Delays required to meet setup/hold
#include "relay.h"          // Relay shield (4 relays, pins 4-7-8-12)
#include "soft_uart.h"      // Soft UART
#include "retroshell.h"     // RetroShell for assembler/disassembler/memory editor

////////////////////////////////////////////////////////////////////
// HW EMULATION VARIABLES
////////////////////////////////////////////////////////////////////
#define uP_CLOCK_FREQ_HZ    (2000)     // 2kHz for killbit program.

word uP_ADDR;
byte uP_INSTRUCTION;
byte uP_IOADDR;

#if (!ARDUINO_AVR_MEGA2560)
#error "Sorry, MC14500B is only supported on Arduino Mega2560."
#error "Teensy requires extra circuitry for LEDs and buttons."
#error "That complicated the project, and increased cost."
#error "If you still want to use Teensy, please contact me."
#endif

////////////////////////////////////////////////////////////////////
void uP_assert_reset()
{
  // MC14500B Reset
  CLK_HIGH();
  digitalWriteFast( uP_RESET, HIGH );
  pinMode(uP_D0, INPUT_PULLUP);
  DELAY_UNIT_250NS();

  // System HW Reset
  uP_ADDR         = 0x0000;
  uP_INSTRUCTION  = 0b0000;
  uP_IOADDR       = 0b0000;
  
  for(unsigned i = MEMORY_START; i < MEMORY_END+1; i++)
    MEMORY[i] = 0;

  digitalWriteFast(uP_OUTP_D0, LOW);
  digitalWriteFast(uP_OUTP_D1, LOW);
  digitalWriteFast(uP_OUTP_D2, LOW);
  digitalWriteFast(uP_OUTP_D3, LOW);
  digitalWriteFast(uP_OUTP_D4, LOW);
  digitalWriteFast(uP_OUTP_D5, LOW);
  digitalWriteFast(uP_OUTP_D6, LOW);
  digitalWriteFast(uP_OUTP_D7, LOW);

}

void uP_release_reset()
{
  digitalWriteFast( uP_RESET, LOW );
}


void uP_init()
{
  pinMode( uP_RESET,      OUTPUT); digitalWrite( uP_RESET,  HIGH  );

  pinMode( uP_D0,         INPUT);
  pinMode( uP_WRITE,      INPUT);
  pinMode( uP_RR,         INPUT);
  pinMode( uP_JMP,        INPUT);
  pinMode( uP_RTN,        INPUT);
  pinMode( uP_FLAG_0,     INPUT);  
  pinMode( uP_FLAG_F,     INPUT);  

  pinMode( uP_CLK2,       OUTPUT); digitalWrite( uP_CLK2,   LOW  );
  pinMode( uP_I0,         OUTPUT); digitalWrite( uP_I0,     LOW  );
  pinMode( uP_I1,         OUTPUT); digitalWrite( uP_I1,     LOW  );
  pinMode( uP_I2,         OUTPUT); digitalWrite( uP_I2,     LOW  );
  pinMode( uP_I3,         OUTPUT); digitalWrite( uP_I3,     LOW  );


  // LED's
  pinMode( uP_OUTP_D0, OUTPUT );     digitalWrite( uP_OUTP_D0, HIGH );
  pinMode( uP_OUTP_D1, OUTPUT );     digitalWrite( uP_OUTP_D1, HIGH );
  pinMode( uP_OUTP_D2, OUTPUT );     digitalWrite( uP_OUTP_D2, HIGH );
  pinMode( uP_OUTP_D3, OUTPUT );     digitalWrite( uP_OUTP_D3, HIGH );
  pinMode( uP_OUTP_D4, OUTPUT );     digitalWrite( uP_OUTP_D4, HIGH );
  pinMode( uP_OUTP_D5, OUTPUT );     digitalWrite( uP_OUTP_D5, HIGH );
  pinMode( uP_OUTP_D6, OUTPUT );     digitalWrite( uP_OUTP_D6, HIGH );
  pinMode( uP_OUTP_D7, OUTPUT );     digitalWrite( uP_OUTP_D7, HIGH );

  pinMode( uP_KEY0,       INPUT_PULLUP);
  pinMode( uP_KEY1,       INPUT_PULLUP);
  pinMode( uP_KEY2,       INPUT_PULLUP);
  pinMode( uP_KEY3,       INPUT_PULLUP);
  pinMode( uP_KEY4,       INPUT_PULLUP);
  pinMode( uP_KEY5,       INPUT_PULLUP);
  pinMode( uP_KEY6,       INPUT_PULLUP);
  pinMode( uP_KEY7,       INPUT_PULLUP);
  pinMode( uP_KEY_RESET,  INPUT_PULLUP);

  uP_assert_reset();

}

////////////////////////////////////////////////////////////////////
// Simple Stack for JMP/RTN addresses.
////////////////////////////////////////////////////////////////////
#define ADDR_STACK_SIZE ((word) 32)
byte ADDR_STACK[ADDR_STACK_SIZE];
byte ADDR_STACK_PTR = 0;

inline __attribute__((always_inline))
void push_address(word addr)
{
  ADDR_STACK[ ADDR_STACK_PTR ] = addr;

  // Move pointer to next or wrap-around.
  if (ADDR_STACK_PTR == (ADDR_STACK_SIZE-1) )
    ADDR_STACK_PTR = 0;
  else
    ADDR_STACK_PTR++;
}

inline __attribute__((always_inline))
word pop_address()
{
  if (ADDR_STACK_PTR == 0)
    ADDR_STACK_PTR = (ADDR_STACK_SIZE-1);
  else
    ADDR_STACK_PTR--;

  return ADDR_STACK[ ADDR_STACK_PTR ];
}

void board_init()
{
  // Initialize "hw" before cpu starts executing, such as
  // filling memory or modify vectors or modifying rom functions.

  for(unsigned i = MEMORY_START; i < MEMORY_END+1; i++)
    MEMORY[i] = 0;

  // Set up the stack
  ADDR_STACK_PTR = 0;
}

////////////////////////////////////////////////////////////////////
// Processor Control Loop
////////////////////////////////////////////////////////////////////
inline __attribute__((always_inline))
void print_info()
{
  //
  if (IS_CLK_HIGH() )
    Serial.write("10  ");
  else
    Serial.write("01  ");
  // Instruction
  sprintf(tmp, "A=%04X OPR=%01X%01X", uP_ADDR, uP_INSTRUCTION, uP_IOADDR);  Serial.write(tmp);
  Serial.write(" [");
  switch(uP_INSTRUCTION)
  {
    case 0x0: Serial.write("NOP0"); break;
    case 0x1: Serial.write("LD  "); break;
    case 0x2: Serial.write("LDC "); break;
    case 0x3: Serial.write("AND "); break;
    case 0x4: Serial.write("ANDC"); break;
    case 0x5: Serial.write("OR  "); break;
    case 0x6: Serial.write("ORC "); break;
    case 0x7: Serial.write("XNOR"); break;
    case 0x8: Serial.write("STO "); break;
    case 0x9: Serial.write("STOC"); break;
    case 0xa: Serial.write("IEN "); break;
    case 0xb: Serial.write("OEN "); break;
    case 0xc: Serial.write("JMP "); break;
    case 0xd: Serial.write("RTN "); break;
    case 0xe: Serial.write("SKZ "); break;
    case 0xf: Serial.write("NOPF"); break;
  }
  Serial.write("] ");
  sprintf(tmp, "D=%01X RR=%01X", digitalReadFast(uP_D0), digitalReadFast(uP_RR));  Serial.write(tmp);
  if (digitalReadFast(uP_WRITE))
    Serial.write(" WR");
  else
    Serial.write("   ");
  Serial.write(" / ");
  sprintf(tmp, "F0=%01X FF=%01X", digitalReadFast(uP_FLAG_0), digitalReadFast(uP_FLAG_F)); Serial.write(tmp);
  Serial.write(" / ");
  sprintf(tmp, "JMP=%01X RTN=%01X", digitalReadFast(uP_JMP), digitalReadFast(uP_RTN)); Serial.write(tmp);
  Serial.write(" / ");
  // Scratch Memory
  Serial.write("MEM: "); 
    for(unsigned int i = MEMORY_END+1; i>MEMORY_START; i--)
    {
      sprintf(tmp, "%01X", MEMORY[i-1]); Serial.write(tmp);
    }

  // Outputs
  Serial.write(" OUTP: "); 
    sprintf(tmp, "%01X",    digitalReadFast(uP_OUTP_D7)); Serial.write(tmp);
    sprintf(tmp, "%01X",    digitalReadFast(uP_OUTP_D6)); Serial.write(tmp);
    sprintf(tmp, "%01X",    digitalReadFast(uP_OUTP_D5)); Serial.write(tmp);
    sprintf(tmp, "%01X",    digitalReadFast(uP_OUTP_D4)); Serial.write(tmp);
    sprintf(tmp, "%01X",    digitalReadFast(uP_OUTP_D3)); Serial.write(tmp);
    sprintf(tmp, "%01X",    digitalReadFast(uP_OUTP_D2)); Serial.write(tmp);
    sprintf(tmp, "%01X",    digitalReadFast(uP_OUTP_D1)); Serial.write(tmp);
    sprintf(tmp, "%01X",    digitalReadFast(uP_OUTP_D0)); Serial.write(tmp);
  
  // Inputs (keys)
  Serial.write(" INP: "); 
    sprintf(tmp, "%01X",    !digitalReadFast(uP_KEY7)); Serial.write(tmp);
    sprintf(tmp, "%01X",    !digitalReadFast(uP_KEY6)); Serial.write(tmp);
    sprintf(tmp, "%01X",    !digitalReadFast(uP_KEY5)); Serial.write(tmp);
    sprintf(tmp, "%01X",    !digitalReadFast(uP_KEY4)); Serial.write(tmp);
    sprintf(tmp, "%01X",    !digitalReadFast(uP_KEY3)); Serial.write(tmp);
    sprintf(tmp, "%01X",    !digitalReadFast(uP_KEY2)); Serial.write(tmp);
    sprintf(tmp, "%01X",    !digitalReadFast(uP_KEY1)); Serial.write(tmp);
    sprintf(tmp, "[K:%01X]",  !digitalReadFast(uP_KEY0)); Serial.write(tmp);
    sprintf(tmp, "[R:%01X]",     digitalReadFast(uP_RR)); Serial.write(tmp);    // Connected to RR instead of KEY0.
  
  Serial.println();
}

    // MEMORY MAP
    // 
    // Addr   Read    Write
    // ====   ====    ====
    // 0000   RAM0    RAM0
    // 0001   RAM1    RAM1
    // 0010   RAM2    RAM2
    // 0011   RAM3    RAM3
    // 0100   RAM4    RAM4
    // 0101   RAM5    RAM5
    // 0110   RAM6    RAM6
    // 0111   RAM7    RAM1
    // 1000   (RR)    OUT0
    // 1001   IN1     OUT1
    // 1010   IN2     OUT2
    // 1011   IN3     OUT3
    // 1100   IN4     OUT4
    // 1101   IN5     OUT5
    // 1110   IN6     OUT6
    // 1111   IN7     OUT7


byte port_read(word addr)
{
  byte data;

  switch(addr)
  {
    /* SCRATCH MEMORY, 8x1 bits */
    case 0b0000:  
    case 0b0001:
    case 0b0010:
    case 0b0011:
    case 0b0100:
    case 0b0101:
    case 0b0110:  
    case 0b0111:  data = MEMORY[addr] & 0x01; break;            // Catch all for memory
    /* INPUT Ports, 1-bit */
    case 0b1000:  data =  digitalReadFast(uP_RR  ); break;    // !!! Read back RR bit
    case 0b1001:  data = !digitalReadFast(uP_KEY1); break;
    case 0b1010:  data = !digitalReadFast(uP_KEY2); break;
    case 0b1011:  data = !digitalReadFast(uP_KEY3); break;
    case 0b1100:  data = !digitalReadFast(uP_KEY4); break;
    case 0b1101:  data = !digitalReadFast(uP_KEY5); break;
    case 0b1110:  data = !digitalReadFast(uP_KEY6); break;
    case 0b1111:  data = !digitalReadFast(uP_KEY7); break;
    default:
      data = 0x00;
      Serial.println("ERR: port read address out of range");
  }

  return data;      
}

void port_write(word addr, byte newValue)
{
  switch(addr)
  {
    /* SCRATCH MEMORY, 8x1 bits */
    case 0b0000:
    case 0b0001:
    case 0b0010:
    case 0b0011:
    case 0b0100:
    case 0b0101:
    case 0b0110:
    case 0b0111:  MEMORY[addr] = newValue & 0x01; break;
    /* OUTPUT Ports, 1-bit */
    case 0b1000:  digitalWriteFast(uP_OUTP_D0, newValue); break;
    case 0b1001:  digitalWriteFast(uP_OUTP_D1, newValue); break;
    case 0b1010:  digitalWriteFast(uP_OUTP_D2, newValue); break;
    case 0b1011:  digitalWriteFast(uP_OUTP_D3, newValue); break;
    case 0b1100:  digitalWriteFast(uP_OUTP_D4, newValue); relayshield_set(1, newValue); break;
    case 0b1101:  digitalWriteFast(uP_OUTP_D5, newValue); relayshield_set(2, newValue); break;
    case 0b1110:  digitalWriteFast(uP_OUTP_D6, newValue); relayshield_set(3, newValue); break;
    case 0b1111:  digitalWriteFast(uP_OUTP_D7, newValue); relayshield_set(4, newValue); break;
    default:
      Serial.println("ERR: port write address out of range");
  }      
}

inline __attribute__((always_inline))
void cpu_tick()
{ 
  bool jmp_executed = false;
  bool rtn_executed = false;

  if (digitalReadFast(uP_RESET))
  {
    uP_ADDR = 0x0000;
    
    Serial.print("CPU_TICK() called while in RESET");
    while(1);   // REMOVE to enable reset during normal operation.

    // Wait for asynch reset to release...
    return;
  }
  
  //////////////////////////////////////////////////
  // CLK should be HIGH, out of RESET
  //////////////////////////////////////////////////
  if (IS_CLK_LOW() )
  {
    Serial.println("ERROR - cpu_tick() expects CLK2 to be high.");
    while(1);
  }
  else
  {
    //////////////////////////////////////////////////    
    // Send instruction to MC14500B
    //////////////////////////////////////////////////    
    if ((ROM_START <= uP_ADDR) && (uP_ADDR <= ROM_END))
    {
      byte d = rom_read_byte(uP_ADDR);    // pgm_read_byte_near( ROM + (uP_ADDR - ROM_START) );

      uP_INSTRUCTION = (d & 0xF0) >> 4;
      uP_IOADDR      = (d & 0x0F);

      // sprintf(tmp, "* ADDR=%04X OPR=%01X OPA=%01X \n", uP_ADDR, uP_INSTRUCTION, uP_IOADDR);  Serial.write(tmp);
    }
    else
    {
      // Out of ROM bounds error - send NOP0
      uP_INSTRUCTION = 0b0000;
      uP_IOADDR      = 0b0000;

      Serial.println("OUT OF ADDR BOUNDS ERROR !");
      while(1);
    }

    // Output Instruction to 14500b
    digitalWriteFast(uP_I3, uP_INSTRUCTION & 0b1000);
    digitalWriteFast(uP_I2, uP_INSTRUCTION & 0b0100);
    digitalWriteFast(uP_I1, uP_INSTRUCTION & 0b0010);
    digitalWriteFast(uP_I0, uP_INSTRUCTION & 0b0001);

    DELAY_UNIT_250NS();

    // print_info();
    //////////////////////////////////////////////////
    CLK_LOW();
    //////////////////////////////////////////////////
    //
    // MC14500B receive the command on rising edge
    // and will execute it now.
    //
    DELAY_UNIT_250NS();

    //////////////////////////////////////////////////
    // OPTION: Reset System if NOP0
    //////////////////////////////////////////////////
    if ( 0 && (uP_INSTRUCTION == 0b0000))
    {
      uP_assert_reset();
      uP_release_reset();
      return;   // come back later
    }
    //////////////////////////////////////////////////
    // OPTION: Reset System if NOPF
    //////////////////////////////////////////////////
    if ( 0 && (uP_INSTRUCTION == 0b1111))
    {
      uP_assert_reset();
      uP_release_reset();
      return;   // come back later
    }

    //////////////////////////////////////////////////
    // OPTION: Reset System if NOPF
    //////////////////////////////////////////////////
    if (!digitalReadFast(uP_KEY_RESET))
    {
      uP_assert_reset();
      uP_release_reset();
      return;   // come back later      
    }


    //////////////////////////////////////////////////
    // WRITE
    //////////////////////////////////////////////////
    if (digitalReadFast(uP_WRITE))
    {
      // WRITE
      DATA_DIR_IN();

      port_write(uP_IOADDR, digitalReadFast(uP_D0));

      // switch(uP_IOADDR)
      // {
      //   /* SCRATCH MEMORY, 8x1 bits */
      //   case 0b0000:
      //   case 0b0001:
      //   case 0b0010:
      //   case 0b0011:
      //   case 0b0100:
      //   case 0b0101:
      //   case 0b0110:
      //   case 0b0111:  MEMORY[uP_IOADDR] = digitalReadFast(uP_D0); break;
      //   /* OUTPUT Ports, 1-bit */
      //   case 0b1000:  digitalWriteFast(uP_OUTP_D0, digitalReadFast(uP_D0)); break;
      //   case 0b1001:  digitalWriteFast(uP_OUTP_D1, digitalReadFast(uP_D0)); break;
      //   case 0b1010:  digitalWriteFast(uP_OUTP_D2, digitalReadFast(uP_D0)); break;
      //   case 0b1011:  digitalWriteFast(uP_OUTP_D3, digitalReadFast(uP_D0)); break;
      //   case 0b1100:  digitalWriteFast(uP_OUTP_D4, digitalReadFast(uP_D0)); relayshield_set(1, digitalReadFast(uP_D0)); break;
      //   case 0b1101:  digitalWriteFast(uP_OUTP_D5, digitalReadFast(uP_D0)); relayshield_set(2, digitalReadFast(uP_D0)); break;
      //   case 0b1110:  digitalWriteFast(uP_OUTP_D6, digitalReadFast(uP_D0)); relayshield_set(3, digitalReadFast(uP_D0)); break;
      //   case 0b1111:  digitalWriteFast(uP_OUTP_D7, digitalReadFast(uP_D0)); relayshield_set(4, digitalReadFast(uP_D0)); break;
      // }      
    }
    else
    //////////////////////////////////////////////////
    // READ
    //////////////////////////////////////////////////
    if (!digitalReadFast(uP_WRITE))
    {
      // READ
      DATA_DIR_OUT(); 

      digitalWriteFast(uP_D0, port_read(uP_IOADDR));

      // switch(uP_IOADDR)
      // {
      //   /* SCRATCH MEMORY, 8x1 bits */
      //   case 0b0000:  
      //   case 0b0001:
      //   case 0b0010:
      //   case 0b0011:
      //   case 0b0100:
      //   case 0b0101:
      //   case 0b0110:  
      //   case 0b0111:  digitalWriteFast(uP_D0, MEMORY[uP_IOADDR]); break;            // Catch all for memory
      //   /* INPUT Ports, 1-bit */
      //   case 0b1000:  digitalWriteFast(uP_D0,  digitalReadFast(uP_RR  )); break;    // !!! Read back RR bit
      //   case 0b1001:  digitalWriteFast(uP_D0, !digitalReadFast(uP_KEY1)); break;
      //   case 0b1010:  digitalWriteFast(uP_D0, !digitalReadFast(uP_KEY2)); break;
      //   case 0b1011:  digitalWriteFast(uP_D0, !digitalReadFast(uP_KEY3)); break;
      //   case 0b1100:  digitalWriteFast(uP_D0, !digitalReadFast(uP_KEY4)); break;
      //   case 0b1101:  digitalWriteFast(uP_D0, !digitalReadFast(uP_KEY5)); break;
      //   case 0b1110:  digitalWriteFast(uP_D0, !digitalReadFast(uP_KEY6)); break;
      //   case 0b1111:  digitalWriteFast(uP_D0, !digitalReadFast(uP_KEY7)); break;
      // }      
    }
    
    //////////////////////////////////////////////////
    // JMP
    //////////////////////////////////////////////////
    if (digitalReadFast(uP_JMP))
    {
      if (outputDEBUG) { Serial.write("JMP "); Serial.print(uP_IOADDR, HEX); Serial.println(); }
      push_address(uP_ADDR);
      uP_ADDR = uP_IOADDR;        // FIXME: This is only 4-bits. If a wider range desired, this needs to be updated.
      jmp_executed = true;
    }
    
    //////////////////////////////////////////////////
    // RTN
    //////////////////////////////////////////////////
    if (digitalReadFast(uP_RTN))
    {
      uP_ADDR = pop_address();
      if (outputDEBUG) { Serial.write("RTN "); Serial.print(uP_ADDR, HEX); Serial.println(); }
      rtn_executed = true;
    } 
    
    if (outputDEBUG)
    {
      print_info();

      if (outputDEBUG_PAUSE)
        while(!Serial.available());
      char c = Serial.read();
      if (c == 'g')
        outputDEBUG_PAUSE = false;
      else
      if (c == 's')
        outputDEBUG_PAUSE = true;
    }

    //////////////////////////////////////////////////
    CLK_HIGH();
    //////////////////////////////////////////////////

    DELAY_UNIT_250NS();      // HOLD TIME for reads.
    DATA_DIR_IN();

    // DELAY_UNIT_250NS();
    if (jmp_executed || rtn_executed)
      uP_ADDR = uP_ADDR;    // RTN goes back to the saved (JMP) address, which 14500 will skip. 
    else
    {
      uP_ADDR++; 

      // Wrap around if needed.
      if (uP_ADDR > ROM_END)
        uP_ADDR = ROM_START;
    }
  }
} // cpu_tick()


////////////////////////////////////////////////////////////////////
// Soft UART functions
////////////////////////////////////////////////////////////////////
bool read_uP_TXD_pin_mc14500()
{
  return digitalReadFast(uP_OUTP_D0);
}

void write_uP_RXD_pin_mc14500(bool value)
{
  digitalWriteFast(uP_OUTP_D7, value);

  // 14500 is very limited, I doubt one would read serial but 
  // here is how to receive :)
  // digitalWriteFast(uP_KEY0, value);
}

////////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////////

void setup() 
{
#if (ARDUINO_AVR_MEGA2560)  
  Serial.begin(115200);
#elif (ARDUINO_TEENSY35 || ARDUINO_TEENSY36 || ARDUINO_TEENSY41) 
  Serial.begin(0);
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
  Serial.println();
  Serial.println("=======================================================");
  Serial.println("; Motorola MC14500B");
  Serial.println("; ");
  Serial.println("; Simple Code Introduction");
  Serial.println(";   by kayto@github.com");   
  Serial.println(";");
  Serial.println("; Description");
  Serial.println(";   Bit-bangs 'hello world' to UART, which is");
  Serial.println(";   picked up by Arduino. With this demo, Yaroslav");
  Serial.println(";   shows all you need is 1-bit to do great things :)");
  Serial.println(";");
  Serial.println("; Reference");
  Serial.println(";   https://github.com/veremenko-y/mc14500-programs");
  Serial.println(";");
  Serial.println("=======================================================");

  uP_init();
  board_init();
  relayshield_init();   // for use with Arduino Relay Shield
  shell_setup("14500B");      

  // Enable soft UART
  soft_uart_setup(uP_CLOCK_FREQ_HZ, uP_CLOCK_FREQ_HZ, read_uP_TXD_pin_mc14500, write_uP_RXD_pin_mc14500, 1/1);    // Code sends every cpu clock; 1/1 sampling rate

  // Reset processor
  Serial.println("RESET");
  uP_assert_reset();
  uP_release_reset();
  Serial.println("RUNNING\n");


  if (outputDEBUG)
  {
    Serial.println("*** PRESS ENTER TO SINGLE-STEP:\n");
  }
}

////////////////////////////////////////////////////////////////////
// Loop
////////////////////////////////////////////////////////////////////

void loop()
{
  unsigned long prev_tick   = micros();
  bool          singleStep  = false;
  bool          runMode     = true;

  // Run processor until reset or Q is pressed.
  // then run shell for user to edit/load program.
  // user can type "exit" to return to cpu.

  Serial.println("Press '\\' to exit to shell.");

  while(1)
  {
    while(runMode)
    {
      cpu_tick();

      // Exit to shell on 'q' or 'Q'
      if (Serial.available())
      {
        char c = Serial.peek();
        if (c == '\\')
        {
          Serial.read();    // Remove q/Q
          runMode = false;
        }
      }

      // Reset processor on key press
      if (!digitalReadFast(uP_KEY_RESET))
      {
        delay(20);
        if (!digitalReadFast(uP_KEY_RESET)) 
        {
          // If you want to pause the processor instead of reset,
          // uncomment the following line:
          // runMode = false;
          if (runMode == true)
          {
            Serial.println("RESET");
            uP_assert_reset();
            uP_release_reset();
            Serial.println("RUNNING\n");
          } else {
            break;
          }
        }
      }

      // Soft UART
      // Uncomment to enable the soft UART. See hello world example.
      soft_uart_loop();

      // User wants to single step (from shell command)
      if (singleStep)
      {
        runMode = false;
        break;
      }

      // Inaccurate but good enough freq control
      while( (micros() - prev_tick) < (1000000/uP_CLOCK_FREQ_HZ));
      prev_tick = micros();

      // Additional delay for debugging
      if(0 || outputDEBUG)
        delayMicroseconds(500);
    }

    // if processor isn't running, switch to shell for user to edit/load program..
    // return value is true if user wants to execute one instruction and then return to shell.
    singleStep = shell_loop(uP_ADDR);

    // Exited the shell, run the processor again.
    runMode = true;
  }
}


