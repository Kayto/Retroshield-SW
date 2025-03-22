#ifndef _SOFT_UART_H
#define _SOFT_UART_H

#include <Arduino.h>

////////////////////////////////////////
// Soft-UART
//
// Requires 2 GPIO's.
// - TXD pin from the processor
// - RXD pin to the processor
////////////////////////////////////////
bool (*read_uP_TXD_pin)();              // function pointer to read processor's TXD pin
void (*write_uP_RXD_pin)(bool value);     // function pointer to write to processor's RXD pin

// Example usage:
//   void function1(void (*function)())
//   {
//       (*function)();
//   }

int SOFT_UART_CPU_CYCLES_PER_BAUD = (1000000/300);        // example: 1MHz CPU, 300 baud = 3333 cpu cycles per baud
int SOFT_UART_PIN_SAMPLING_RATE   = (1/1);                // example (1/2) sampling rate means we sample tx/rd pins every 2 cpu cycles.

// Delays for sampling the TXD/RXD pins.
int SOFT_UART_SAMPLE_DELAY        = (SOFT_UART_CPU_CYCLES_PER_BAUD);
int SOFT_UART_SAMPLE_DELAY_START  = (SOFT_UART_CPU_CYCLES_PER_BAUD * 1.5);        // start capturing 1.5 bits later, middle

// Inter-character delay.
int SOFT_UART_CHAR_DELAY          = (SOFT_UART_CPU_CYCLES_PER_BAUD * 40);         // wait this long between characters.


//////////////////////////////////////////////////
// Transmit function
//////////////////////////////////////////////////

inline __attribute__((always_inline))
void soft_uart_txd_to_processor( void (*set_proc_RXD_pin)(bool value) )
{
  static word txd_char_delay = SOFT_UART_CHAR_DELAY;   
  static word txd_bit_delay  = SOFT_UART_SAMPLE_DELAY_START;  
  static byte txd_bit        = 0;
  static byte txd_data;

  if (txd_char_delay > 0)
    txd_char_delay--;                                   // Delay between sending characters to processor.
  
  // Check if we waited enough to send a new character.
  if ((txd_char_delay == 0) && (txd_bit == 0))
  {
    if (Serial.available())      // Get ready to transmit if idle and new char from Arduino
    {
      // TODO: process the key if needed.  i.e. strip bit7 for Apple-I.
      txd_data = toupper( Serial.read() );
      txd_bit = 9;        // 8n1 = 1bit start + 8bit data + 1bit stop
      txd_bit_delay = SOFT_UART_SAMPLE_DELAY;
  
      (*set_proc_RXD_pin)(0);      // Start bit, low
    } 
  }
  else
  // Character is being sent.
  if ((txd_char_delay == 0) && (txd_bit > 0))
  {
    if (txd_bit_delay > 0)
      txd_bit_delay--;
    else
    {
      (*set_proc_RXD_pin)(txd_data & 0x01);
      
      txd_data      = (txd_data >> 1);
      txd_bit_delay = SOFT_UART_SAMPLE_DELAY;

      txd_bit--;
      if (txd_bit == 0x01)                // is it time to send stop bit?
      {
        txd_data = 0x01;                  // transmit stop bit
      }
      else
      if (txd_bit == 0)
      {
        txd_char_delay = SOFT_UART_CHAR_DELAY; // inter-character delay
      }
    }
  }
}


//////////////////////////////////////////////////
// Receive function
//////////////////////////////////////////////////

inline __attribute__((always_inline))
void soft_uart_rxd_from_processor(bool (*read_proc_TXD_pin)())
{
  static byte prev_RXD          = 1;
  static byte rxd_bit_counter   = 0;
  static byte rxd_byte          = 0;
  static word sample_delay      = SOFT_UART_SAMPLE_DELAY_START;

  // Check for start bit
  if ((rxd_bit_counter == 0) && !(*read_proc_TXD_pin)() && prev_RXD)
  {
    rxd_bit_counter = 9;                    // need to receive 1(start)+7(data)+1(stop) bits
    rxd_byte        = 0;                    // OR incoming bits to this.
    sample_delay    = SOFT_UART_SAMPLE_DELAY_START;
    // Serial.println("Serial.start");
  }
  else
  if (rxd_bit_counter)
  {
    sample_delay--;
    if (sample_delay == 0)
    {
      // Shift in from leftmost bit.
      rxd_byte = (rxd_byte >> 1) | ((*read_proc_TXD_pin)() << 7);  
      
      sample_delay = SOFT_UART_SAMPLE_DELAY;

      // are we almost done yet?
      rxd_bit_counter--;
      if (rxd_bit_counter == 0x01)        // 1bit left, which is stop bit  
      {
        rxd_byte = (rxd_byte & 0x7F);     // Receive 7bits into 8bit.
        Serial.write(rxd_byte);

        // wait for stop bit to be done before accepting next character.
      }
    }
  } 
  
  prev_RXD = (*read_proc_TXD_pin)();
}


//////////////////////////////////////////////////
// Soft UART loop
//////////////////////////////////////////////////

inline __attribute__((always_inline))
void soft_uart_loop()
{
  static byte flush_counter       = 0;
  static byte uart_sample_counter = SOFT_UART_PIN_SAMPLING_RATE;

  if (++flush_counter == 0)            // every 256
    Serial.flush();

  if (--uart_sample_counter == 0)
  {
    soft_uart_rxd_from_processor(read_uP_TXD_pin);
    soft_uart_txd_to_processor(write_uP_RXD_pin);
    uart_sample_counter = SOFT_UART_PIN_SAMPLING_RATE;
  }
}

void soft_uart_setup(int baud_rate, int cpu_frequency, bool (*board_read_proc_TXD_pin)(), void (*board_set_proc_RXD_pin)(bool value), int default_sampling_rate)
{
  SOFT_UART_CPU_CYCLES_PER_BAUD     = (cpu_frequency / baud_rate);
  SOFT_UART_SAMPLE_DELAY            = SOFT_UART_CPU_CYCLES_PER_BAUD;
  SOFT_UART_SAMPLE_DELAY_START      = SOFT_UART_CPU_CYCLES_PER_BAUD * 1.5;    // 1.5x lands us in the  middle of the bit.
  SOFT_UART_CHAR_DELAY              = SOFT_UART_CPU_CYCLES_PER_BAUD * 40;     // wait this long before transmitting next character.

  // Set function pointers to read/write to processor's TXD/RXD pins.
  read_uP_TXD_pin = board_read_proc_TXD_pin;
  write_uP_RXD_pin  = board_set_proc_RXD_pin;

  // Set sampling rate.
  SOFT_UART_PIN_SAMPLING_RATE       = default_sampling_rate;  

  Serial.println("Soft UART configuration:");
  Serial.print("  baud_rate:           ");   Serial.println(baud_rate);
  Serial.print("  cpu_frequency:       ");   Serial.println(cpu_frequency);
  Serial.print("  CPU Cycles/BAUD:     ");   Serial.print(SOFT_UART_CPU_CYCLES_PER_BAUD);   Serial.println("/cpu ticks");
  Serial.print("  Bit0 Start Delay:    ");   Serial.print(SOFT_UART_SAMPLE_DELAY_START);    Serial.println("/cpu ticks");
  Serial.print("  BitX Sample Delay:   ");   Serial.print(SOFT_UART_SAMPLE_DELAY);          Serial.println("/cpu ticks");
  Serial.print("  Char Delay:          ");   Serial.print(SOFT_UART_CHAR_DELAY);            Serial.println("/cpu ticks");
  Serial.print("  Sample Rate (/loop): ");   Serial.print(SOFT_UART_PIN_SAMPLING_RATE);     Serial.println("/loop");
} 

void soft_uart_detect_baud_rate()
{
  static int baud_rate = 0;
  static bool txd_pin_state_prev = 1;

  if (txd_pin_state_prev != read_uP_TXD_pin())
  {
    Serial.print("  Baud Rate: "); Serial.print(baud_rate); Serial.println(" baud/cpu ticks");
    baud_rate = 0;
  }
  else
  {
    baud_rate++;
  }  

  txd_pin_state_prev = read_uP_TXD_pin();
}

#endif