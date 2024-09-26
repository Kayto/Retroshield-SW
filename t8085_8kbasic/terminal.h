#ifndef _TERMINAL_H
#define _TERMINAL_H

////////////////////////////////////////////////////////////////////
// 8251 Peripheral
// emulate just enough so keyboard/display works thru serial port.
////////////////////////////////////////////////////////////////////
// Left 8251 emulation in, incase somebody wants to use it.

#define ADDR_8251_DATA          0x08
#define ADDR_8251_MODCMD        0x09

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


void intel8251_init()
{
#if outputDEBUG
  Serial.println("intel8251_init()\n");
#endif

  reg8251_STATE     = STATE_8251_RESET;
  reg8251_MODE      = 0b01001101;       // async mode: 1x baudrate, 8n1
  reg8251_COMMAND   = 0b00100111;       // enable tx/rx; assert DTR & RTS
  reg8251_STATUS    = 0b10000101;       // TxRDY, TxE, DSR (ready for operation). RxRDY=0
  reg8251_DATA      = 0x00;
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
// Soft-UART for 8085's Hard-UART
// 
// Note: Untested because not used by MON85.
////////////////////////////////////////

#define k8085_UART_BAUD (16*12)
byte txd_8085;
word txd_delay = k8085_UART_BAUD*1.5;     // start capturing 1.5 bits later, middle
byte txd_bit = 0;

byte rxd_8085;
word rxd_delay = k8085_UART_BAUD;         // start output 1 bit at a time
byte rxd_bit = 0;

inline __attribute__((always_inline))
void serialEvent8085()
{
  // RXD
  if (rxd_bit == 0 && Serial.available())
  {
    rxd_bit = 9;
    rxd_8085 = Serial.read();
    rxd_delay = k8085_UART_BAUD;

    pinMode(uP_SID, OUTPUT);
    digitalWrite(uP_SID, LOW);      // Start bit, low
  }
  else
  if (rxd_bit)
  {
    rxd_delay--;
    if (rxd_delay == 0)
    {
      digitalWrite(uP_SID, rxd_8085 & 0x01);
      rxd_8085 = (rxd_8085 >> 1);
      rxd_delay = k8085_UART_BAUD;

      // are we done yet?  1bit left, which is stop bit
      rxd_bit--;
      if (rxd_bit == 0x01)
      {
        // set bit0 to output stop bit
        rxd_8085 = 0x01;
      }
      else
      if (rxd_bit == 0)
        digitalWrite(uP_SID, HIGH);       // Park high due to pull-ups on TXB0108
    }
  }

  // TXD
  // Check for start bit
  if (txd_bit == 0 && !STATE_SOD)
  {
    txd_bit  = 9;   // need to receive 8(data)+1(stop) bits
    txd_8085 = 0;   // OR incoming bits to this.
    txd_delay = k8085_UART_BAUD*1.5;
  }
  else
  if (txd_bit)
  {
    txd_delay--;
    if (txd_delay == 0)
    {
      // Push incoming bit from left.
      // STATE_SOD: PB2=PTB18
      txd_8085 = (txd_8085 >> 1) | (STATE_SOD >> 11);
      txd_delay = k8085_UART_BAUD;

      // are we done yet?  1bit left, which is stop bit
      if ((--txd_bit) == 0x01)
      {
        Serial.write(txd_8085);
        // no more bits to receive.
        // stop bit will be ignored.
      }
    }
  }  
}


#endif // _TERMINAL_H