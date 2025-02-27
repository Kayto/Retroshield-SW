#ifndef I8251_H
#define I8251_H

////////////////////////////////////////////////////////////////////
// 8251 Peripheral
// emulate just enough so keyboard/display works thru serial port.
////////////////////////////////////////////////////////////////////

#define ADDR_8251_DATA          0xF6
#define ADDR_8251_MODCMD        0xF7

#define STATE_8251_RESET        0x01
#define STATE_8251_INITIALIZED  0x00
#define CMD_8251_INTERNAL_RESET 0x40
#define CMD_8251_RTS            0x20
#define CMD_8251_DTR            0x02
#define STAT_8251_TxRDY         0x02      // Swap bit w/ STAT_8251_RxRDY - read below
#define STAT_8251_RxRDY         0x01      // Swap bit w/ STAT_8251_TxRDY - read below
#define STAT_8251_TxE           0x04
#define STAT_DSR                0x80

byte reg8251_STATE;      // register to keep track of 8251 state: reset or initialized
byte reg8251_MODE;
byte reg8251_COMMAND;
byte reg8251_STATUS;
byte reg8251_DATA;


void intel8251_init()
{
#if (outputDEBUG)
  Serial.println("intel8251_init()\n");
#endif

  reg8251_STATE     = STATE_8251_INITIALIZED;     // SCP 1.5 mon does not initialize 8251 so override.
  reg8251_MODE      = 0b01001101;                 // async mode: 1x baudrate, 8n1
  reg8251_COMMAND   = 0b00100111;                 // enable tx/rx; assert DTR & RTS
  // reg8251_STATUS    = 0b10000101;              // From 8085: TxRDY, TxE, DSR (ready for operation). RxRDY=0
  reg8251_STATUS    = STAT_DSR | STAT_8251_TxE | STAT_8251_TxRDY;
  reg8251_DATA      = 0x00;
}

  // Hack 8251 registers to meet the following routoines from SCP 1.5

  // ; Seattle Computer Products 8086 Monitor version 1.5  3-19-82.
  // ;   by Tim Paterson
  // ; This software is not copyrighted.

  //         CPU     8086

  // BASE:   EQU     0F0H            ;CPU Support base port address
  // STAT:   EQU     BASE+7          ;UART status port
  // DATA:   EQU     BASE+6          ;UART data port
  // RDRF:   EQU     01h             ;UART data available bit
  // TDRE:   EQU     02h             ;UART transmitter ready bit

  // ;Character input routine

  // IN:
  //         CLI                     ;Poll, don't interrupt
  //         IN      AL, STAT
  //         TEST    AL, RDRF
  //         JZ      IN              ;Loop until ready
  //         IN      AL, DATA
  //         AND     AL,7FH          ;Only 7 bits
  //         STI                     ;Interrupts OK now
  //         RET

  // ;Console output of character in AL

  // OUT:
  //         PUSH    AX              ;Character to output on stack
  // OUT1:
  //         IN      AL,STAT
  //         AND     AL,TDRE
  //         JZ      OUT1            ;Wait until ready
  //         POP     AX
  //         OUT     DATA,AL
  //         RET

////////////////////////////////////////////////////////////////////
// Serial Event
////////////////////////////////////////////////////////////////////

inline __attribute__((always_inline))
void serialEvent8251() 
{
  const byte TRANSMIT_DELAY = 10;
  static byte tx_delay = TRANSMIT_DELAY;

  if (tx_delay > 0)
    tx_delay--;
  else
  if (Serial.available())
  {
    // if (reg8251_STATUS & CMD_8251_RTS)  // read serial byte only if RTS is asserted
    {
      // RxRDY bit for cpu
      reg8251_STATUS = reg8251_STATUS | STAT_8251_RxRDY;
    }

    tx_delay = TRANSMIT_DELAY;
  }
  return;
}



#endif