#ifndef _BUTTONS_H
#define _BUTTONS_H

////////////////////////////////////////////////////////////
// These functions return real-time state (no debouncing)
////////////////////////////////////////////////////////////

#if (ARDUINO_TEENSY35 || ARDUINO_TEENSY36)

#define btn_P_state() (analogRead(A21) < 10 ? true : false)
#define btn_C_state() (analogRead(A22) < 10 ? true : false)

#elif (ARDUINO_TEENSY41)

#define btn_P_state() (analogRead(A16) < 10 ? true : false)
#define btn_C_state() (analogRead(A17) < 10 ? true : false)

#endif

////////////////////////////////////////////////////////////
// These functions are debounced.
////////////////////////////////////////////////////////////
long debounceDelay = 16;

bool btn_P_debounced() 
{
  static bool btn_P_prev_state = false;
  bool btn_P = btn_P_state();
  if ( btn_P != btn_P_prev_state )
  {
    delay(debounceDelay);
    return (btn_P_prev_state = btn_P_state());
  }
  return btn_P;
}

bool btn_C_debounced() 
{
  static bool btn_C_prev_state = false;
  bool btn_C = btn_C_state();
  if ( btn_C != btn_C_prev_state )
  {
    delay(debounceDelay);
    return (btn_C_prev_state = btn_C_state());
  }
  return btn_C;
}


void use_button_P_to_pulse_pin(int gpio, bool deasserted_value, bool asserted_value)
{
  const  byte PULSE_WIDTH         = 10;
  static byte num_clk_cycles      = 0;
  static bool pin_asserted        = false;
  static bool button_state        = false;
  static bool prev_button_state   = false;

  if (num_clk_cycles > 0)
  {
    num_clk_cycles--;
  }
  else
  {
    digitalWriteFast(gpio, deasserted_value);
    pin_asserted = false;
  }

  button_state = btn_P_debounced();
  if (button_state && !prev_button_state)     // pressed down edge
  {
    digitalWriteFast(gpio, asserted_value);
    num_clk_cycles = PULSE_WIDTH;
  }

  prev_button_state = button_state;
}


void use_button_C_to_pulse_pin(int gpio, bool deasserted_value, bool asserted_value)
{
  const  byte PULSE_WIDTH         = 10;
  static byte num_clk_cycles      = 0;
  static bool pin_asserted        = false;
  static bool button_state        = false;
  static bool prev_button_state   = false;

  if (num_clk_cycles > 0)
  {
    num_clk_cycles--;
  }
  else
  {
    digitalWriteFast(gpio, deasserted_value);
    pin_asserted = false;
  }

  button_state = btn_C_debounced();
  if (button_state && !prev_button_state)     // pressed down edge
  {
    digitalWriteFast(gpio, asserted_value);
    num_clk_cycles = PULSE_WIDTH;
  }

  prev_button_state = button_state;
}

void use_button_P_to_single_step()
{
  if (1 || outputDEBUG)
  {
    while(!btn_P_debounced());
    while(btn_P_debounced());
  }
}

#endif