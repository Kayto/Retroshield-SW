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

// External variable from 6522.h
extern volatile bool trace_walk_active;

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
bool regACIA_DATA_READ;  // Track if current data has been consumed

// Debug control
#define ACIA_DEBUG 0  // Disable to avoid spam

// -------------------------------------------------------------------
// Initialize the 6551 state
// -------------------------------------------------------------------
void m6551_init()
{
  regACIA_DATA = 0x00;
  regACIA_STATUS = 0x10;   // TX empty at reset
  regACIA_COMMAND = 0x00;
  regACIA_CONTROL = 0x00;
  regACIA_DATA_READ = true; // No unread data at init
  
  // Initialize SMON special RAM locations
  extern byte RAM[];
  RAM[0x91] = 0x00;  // STOP flag - 0x7F=pressed, 0x00=not pressed
  RAM[0x02BC] = 0x00;  // Tracewalk control flag - should be 0 after first keypress
}

// -------------------------------------------------------------------
// Poll host serial for received data
// Call this periodically from your main loop
// -------------------------------------------------------------------
inline void m6551_poll()
{
  // Only receive new data if previous data was consumed
  if (Serial.available() && regACIA_DATA_READ) {
    regACIA_DATA = Serial.read();
    regACIA_STATUS |= 0x08;  // Set RX full
    regACIA_DATA_READ = false; // Mark as unread
    // Character received
  }
}

// -------------------------------------------------------------------
// Read handler
// -------------------------------------------------------------------
inline byte m6551_read(word addr)
{
  byte value = 0xFF;
  switch (addr) {
    case ACIA_DATA:
      value = regACIA_DATA;
      // Reading data marks it as consumed and clears RX full bit
      if (!regACIA_DATA_READ) {
        regACIA_DATA_READ = true;
        regACIA_STATUS &= ~0x08;  // Clear RX full only after first read
      }
      // Don't resume timer here - let SMON do it by writing T1CH
      // This ensures the timer counter is reloaded before unpausing
      break;
    case ACIA_STATUS:
      value = regACIA_STATUS;
      // Don't clear RX full on status read - only on data read
#if ACIA_DEBUG
      if (trace_walk_active && (value & 0x08)) {
        Serial.print(F("[ACIA] Status read: 0x"));
        Serial.println(value, HEX);
      }
#endif
      break;
    case ACIA_COMMAND:
      value = regACIA_COMMAND;
      break;
    case ACIA_CONTROL:
      value = regACIA_CONTROL;
      break;
  }
  return value;
}

// -------------------------------------------------------------------
// Write handler
// -------------------------------------------------------------------
inline void m6551_write(word addr, byte value)
{
  switch (addr) {
    case ACIA_DATA:
      regACIA_DATA = value;
#if ACIA_DEBUG
      // Only debug during tracewalk to reduce spam
      if (trace_walk_active) {
        Serial.print(F("[ACIA] TX: 0x"));
        Serial.print(value, HEX);
        Serial.print(F(" '"));
        if (value >= 32 && value < 127) {
          Serial.write(value);
        } else if (value == 13) {
          Serial.print(F("CR"));
        } else if (value == 10) {
          Serial.print(F("LF"));
        } else {
          Serial.print(F("."));
        }
        Serial.println(F("'"));
      }
#endif
      // Emulate immediate transmit
      Serial.write(value);
      // TX empty
      regACIA_STATUS |= 0x10;
      break;
    case ACIA_STATUS:
      // Write to status is typically used for reset
      regACIA_STATUS = 0x10; // Clear RX full, leave TX empty
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