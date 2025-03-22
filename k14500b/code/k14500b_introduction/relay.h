#ifndef _RELAY_H
#define _RELAY_H

#include <Arduino.h>

// Extra functions for Relay Shield
// ...to make some noise...

#define RELAY_1 (4)
#define RELAY_2 (7)
#define RELAY_3 (8)
#define RELAY_4 (12)

void relayshield_init()
{
  if (!USE_RELAY_SHIELD) return;

  Serial.print("Arduino Relay Shield enabled (pins: ");
  Serial.println(String(RELAY_1) + ", " + String(RELAY_2) + ", " + String(RELAY_3) + ", " + String(RELAY_4) + ")");

  pinMode(RELAY_1, OUTPUT); digitalWriteFast(RELAY_1, LOW);
  pinMode(RELAY_2, OUTPUT); digitalWriteFast(RELAY_2, LOW);
  pinMode(RELAY_3, OUTPUT); digitalWriteFast(RELAY_3, LOW);
  pinMode(RELAY_4, OUTPUT); digitalWriteFast(RELAY_4, LOW);
}

void relayshield_turn_on(byte relay)
{
  if (!USE_RELAY_SHIELD) return;

  switch(relay)
  {
    case 1: digitalWriteFast(RELAY_1, HIGH); break;
    case 2: digitalWriteFast(RELAY_2, HIGH); break;
    case 3: digitalWriteFast(RELAY_3, HIGH); break;
    case 4: digitalWriteFast(RELAY_4, HIGH); break;
    default:
      break;
  }
}

void relayshield_turn_off(byte relay)
{
  if (!USE_RELAY_SHIELD) return;

  switch(relay)
  {
    case 1: digitalWriteFast(RELAY_1, LOW); break;
    case 2: digitalWriteFast(RELAY_2, LOW); break;
    case 3: digitalWriteFast(RELAY_3, LOW); break;
    case 4: digitalWriteFast(RELAY_4, LOW); break;
    default:
      break;
  }
}

void relayshield_set(byte relay, bool turnon)
{
  if (turnon)
    relayshield_turn_on(relay);
  else
    relayshield_turn_off(relay);
}
#endif
