#ifndef _6551_H
#define _6551_H

////////////////////////////////////////////////////////////////////
// 6551 ACIA Peripheral
// Software-emulated 6551 for keyboard/display via USB Serial
// Address map:
//   $8400 = DATA (RX/TX)
//   $8401 = STATUS
//   $8402 = COMMAND
//   $8403 = CONTROL
////////////////////////////////////////////////////////////////////

// I/O addresses
#define ACIA_DATA     0x8400
#define ACIA_STATUS   0x8401
#define ACIA_COMMAND  0x8402
#define ACIA_CONTROL  0x8403

// Emulated registers
byte regACIA_DATA;       // RX/TX buffer
byte regACIA_STATUS;     // Status bits
byte regACIA_COMMAND;    // Command register
byte regACIA_CONTROL;    // Control register

// ----------------------------------------------------
// Initialize the 6551 state
// ----------------------------------------------------
void m6551_init()
{
  regACIA_DATA    = 0x00;
  // Bit 4 (0x10) = Transmit Data Register Empty
  // Bit 3 (0x08) = Receive Data Register Full
  regACIA_STATUS  = 0x10;   // TX empty at reset
  regACIA_COMMAND = 0x00;
  regACIA_CONTROL = 0x00;
}

// ----------------------------------------------------
// Poll host serial for received data
// Call this periodically from your main loop
// ----------------------------------------------------
inline void m6551_poll()
{
  if (Serial.available()) {
    regACIA_DATA = Serial.read();
    regACIA_STATUS |= 0x08;  // set RX full
  }
}

// ----------------------------------------------------
// Read handler
// ----------------------------------------------------
inline byte m6551_read(word addr)
{
  switch (addr) {
    case ACIA_DATA:
      // Reading clears RX full bit
      regACIA_STATUS &= ~0x08;
      return regACIA_DATA;
    case ACIA_STATUS:
      return regACIA_STATUS;
    case ACIA_COMMAND:
      return regACIA_COMMAND;
    case ACIA_CONTROL:
      return regACIA_CONTROL;
  }
  return 0xFF;
}

// ----------------------------------------------------
// Write handler
// ----------------------------------------------------
inline void m6551_write(word addr, byte value)
{
  switch (addr) {
    case ACIA_DATA:
      regACIA_DATA = value;
      // emulate immediate transmit
      Serial.write(value);
      // TX empty
      regACIA_STATUS |= 0x10;
      break;
    case ACIA_STATUS:
      // write to status is typically used for reset
      regACIA_STATUS = 0x10; // clear RX full, leave TX empty
      break;
    case ACIA_COMMAND:
      regACIA_COMMAND = value;
      break;
    case ACIA_CONTROL:
      regACIA_CONTROL = value;
      break;
  }
}

#endif // _6551_H
