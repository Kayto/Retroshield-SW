////////////////////////////////////////////////////////////////////
// 6522 VIA (Versatile Interface Adapter) Emulation
// For RetroShield 6502 with Teensy 4.1
//
// This module emulates the MOS 6522 VIA chip for SMON's tracewalk
// functionality. It provides Timer 1 in one-shot mode with IRQ
// generation for single-step debugging.
//
// Features:
//   - Timer 1 one-shot and free-running modes
//   - IFR/IER interrupt flag and enable registers
//   - IRQ pin control for 65C02 CPU
//   - Tracewalk timing compensation (+3 cycles)
//
// Memory Map: $9000-$900F (configurable via VIA_BASE)
//
// Copyright (c) 2025 kayto@github.com
// Released under MIT License
//
// Based on MOS 6522 datasheet timing specifications
////////////////////////////////////////////////////////////////////

#ifndef _6522_H
#define _6522_H

// -------------------------------------------------------------------
// Enable/disable verbose VIA debug output
// -------------------------------------------------------------------
#define VIA_DEBUG 0  // Disable - causes timing issues
#define VIA_TRACE_ADDRS 0  // Disable tracewalk address tracking

// -------------------------------------------------------------------
// VIA base address for SMON
// -------------------------------------------------------------------
#define VIA_BASE    0x9000

#define VIA_DRB    (VIA_BASE + 0x0)
#define VIA_DRA    (VIA_BASE + 0x1)
#define VIA_DDRB   (VIA_BASE + 0x2)
#define VIA_DDRA   (VIA_BASE + 0x3)
#define VIA_T1CL   (VIA_BASE + 0x4)
#define VIA_T1CH   (VIA_BASE + 0x5)
#define VIA_T1LL   (VIA_BASE + 0x6)
#define VIA_T1LH   (VIA_BASE + 0x7)
#define VIA_T2CL   (VIA_BASE + 0x8)
#define VIA_T2CH   (VIA_BASE + 0x9)
#define VIA_SR     (VIA_BASE + 0xA)
#define VIA_ACR    (VIA_BASE + 0xB)
#define VIA_PCR    (VIA_BASE + 0xC)
#define VIA_IFR    (VIA_BASE + 0xD)
#define VIA_IER    (VIA_BASE + 0xE)
#define VIA_UNUSED (VIA_BASE + 0xF)

// -------------------------------------------------------------------
// Emulated registers
// -------------------------------------------------------------------
volatile byte regVIA_DRB, regVIA_DRA;
volatile byte regVIA_DDRB, regVIA_DDRA;
volatile byte regVIA_T1CL, regVIA_T1CH, regVIA_T1LL, regVIA_T1LH;
volatile byte regVIA_T2CL, regVIA_T2CH;
volatile byte regVIA_SR, regVIA_ACR, regVIA_PCR;
volatile byte regVIA_IFR, regVIA_IER;

// Internal timer counter, IRQ timeout, and IRQ pin state
volatile uint16_t via_t1_counter = 0;
volatile uint32_t via_irq_timeout = 0;
volatile bool via_irq_pin_is_low = false;
volatile bool via_t1_paused = false;
volatile bool trace_walk_active = false;

// External address bus from main sketch
extern word uP_ADDR;

// -------------------------------------------------------------------
// Init
// -------------------------------------------------------------------
inline void m6522_init() {
  regVIA_DRB = regVIA_DRA = 0;
  regVIA_DDRB = regVIA_DDRA = 0;
  regVIA_T1CL = regVIA_T1CH = regVIA_T1LL = regVIA_T1LH = 0;
  regVIA_T2CL = regVIA_T2CH = 0;
  regVIA_SR = 0;
  regVIA_ACR = 0;
  regVIA_PCR = 0;
  regVIA_IFR = 0;
  regVIA_IER = 0;
  via_t1_counter = 0;
  via_irq_timeout = 0;
  via_irq_pin_is_low = false;
  via_t1_paused = false;
  trace_walk_active = false;

  pinMode(uP_IRQ_N, INPUT_PULLUP);
#if VIA_DEBUG
  Serial.println(F("[VIA] init done"));
#endif
}

// -------------------------------------------------------------------
// Poll (called each cpu_tick)
// -------------------------------------------------------------------
inline void m6522_poll() {
  static uint16_t last_addr = 0;
  static uint32_t stall_counter = 0;

  if (via_t1_counter > 0 && !via_t1_paused) {
    via_t1_counter--;
#if VIA_DEBUG
    if (via_t1_counter < 10 || via_t1_counter % 10 == 0) {
      Serial.print(F("[VIA] T1="));
      Serial.println(via_t1_counter);
    }
#endif
    if (via_t1_counter == 0) {
      regVIA_IFR |= 0x40; // Timer1 interrupt flag
      regVIA_IFR |= 0x80; // Master interrupt flag
      via_irq_timeout = 0; // Disable timeout - let IRQ stay latched indefinitely
      // Reload Timer 1 in free-running mode (ACR bit 6 set)
      if (regVIA_ACR & 0x40) {
        uint16_t timer_value = ((uint16_t)regVIA_T1LH << 8) | regVIA_T1LL;
        via_t1_counter = timer_value;
      } else {
        // One-shot mode: timer stops until T1CH is written again
        via_t1_paused = true;
      }
    }
  }

  // Timeout handling
  if (via_irq_timeout > 0) {
    via_irq_timeout--;
#if VIA_DEBUG
    if (via_irq_timeout % 10000 == 0 && via_irq_timeout > 0) {
      Serial.print(F("[VIA] Timeout: "));
      Serial.println(via_irq_timeout);
    }
#endif
    if (via_irq_timeout == 0 && (regVIA_IFR & 0x40)) {
      regVIA_IFR &= ~0x40; // Clear Timer1 interrupt
      if ((regVIA_IFR & 0x7F) == 0) regVIA_IFR &= ~0x80; // Clear master interrupt
    }
  }

  // Handle IRQ line
  if ((regVIA_IFR & 0x40) && (regVIA_IER & 0x40)) {
    if (!via_irq_pin_is_low) {
      pinMode(uP_IRQ_N, OUTPUT);
      digitalWriteFast(uP_IRQ_N, LOW);
      via_irq_pin_is_low = true;
    }
  } 
  // Don't automatically release IRQ - only release when IFR is cleared
  // The 6502 needs IRQ to stay low for multiple cycles to detect it
  else {
    if (via_irq_pin_is_low && !(regVIA_IFR & 0x80)) {
      // Only release IRQ if IFR bit 7 is clear (no interrupts pending)
      digitalWriteFast(uP_IRQ_N, HIGH);  // Drive HIGH, not pullup
      via_irq_pin_is_low = false;
    }
  }

  // Track address changes after keypress to see if CPU is progressing
#if VIA_TRACE_ADDRS
  static bool keypress_detected = false;
  static uint32_t addr_change_count = 0;
  
  if (trace_walk_active) {
    if (regACIA_STATUS & 0x08) {  // Key was received
      keypress_detected = true;
    }
    
    if (keypress_detected && uP_ADDR != last_addr) {
      addr_change_count++;
      if (addr_change_count < 100) {  // Show first 100 address changes
        Serial.print(F("[VIA] $"));
        Serial.println(uP_ADDR, HEX);
      }
      if (addr_change_count == 100) {
        Serial.println(F("[VIA] Stopped tracking (100 addresses shown)"));
        keypress_detected = false;  // Stop tracking
      }
    }
  }
#endif
  last_addr = uP_ADDR;
}

// -------------------------------------------------------------------
// Read
// -------------------------------------------------------------------
inline byte m6522_read(word addr) {
#if VIA_DEBUG
  Serial.print(F("[VIA READ] $"));
  Serial.print(addr, HEX);
  Serial.print(F(" => $"));
#endif
  byte value;
  switch (addr) {
    case VIA_DRB: value = regVIA_DRB; break;
    case VIA_DRA: value = regVIA_DRA; break;
    case VIA_DDRB: value = regVIA_DDRB; break;
    case VIA_DDRA: value = regVIA_DDRA; break;
    case VIA_T1CL:
      regVIA_IFR &= ~0x40;
      if ((regVIA_IFR & 0x7F) == 0) regVIA_IFR &= ~0x80;
      if (via_irq_pin_is_low) {
        digitalWriteFast(uP_IRQ_N, HIGH);
        via_irq_pin_is_low = false;
      }
      // Don't auto-resume during tracewalk - wait for keypress
      if (!trace_walk_active) {
        via_t1_paused = false;
      }
      value = regVIA_T1CL;
      break;
    case VIA_T1CH: value = regVIA_T1CH; break;
    case VIA_T1LL: value = regVIA_T1LL; break;
    case VIA_T1LH: value = regVIA_T1LH; break;
    case VIA_T2CL: value = regVIA_T2CL; break;
    case VIA_T2CH: value = regVIA_T2CH; break;
    case VIA_SR:   value = regVIA_SR; break;
    case VIA_ACR:  value = regVIA_ACR; break;
    case VIA_PCR:  value = regVIA_PCR; break;
    case VIA_IFR:  
      value = regVIA_IFR;
      break;
    case VIA_IER:  value = regVIA_IER; break;
    default:       value = 0xFF; break;
  }
#if VIA_DEBUG
  Serial.println(value, HEX);
#endif
  return value;
}

// -------------------------------------------------------------------
// Write
// -------------------------------------------------------------------
inline void m6522_write(word addr, byte value) {
#if VIA_DEBUG
  Serial.print(F("[VIA WRITE] $"));
  Serial.print(addr, HEX);
  Serial.print(F(" <= $"));
  Serial.println(value, HEX);
#endif
  switch (addr) {
    case VIA_DRB:  regVIA_DRB = value; break;
    case VIA_DRA:  regVIA_DRA = value; break;
    case VIA_DDRB: regVIA_DDRB = value; break;
    case VIA_DDRA: regVIA_DDRA = value; break;
    case VIA_T1CL:
      regVIA_T1CL = value;
      break;
    case VIA_T1CH:
      regVIA_T1CH = value;
      regVIA_T1LH = value;  // Per 6522 datasheet: writing T1CH also writes T1LH
      // Per 6522 datasheet: writing T1CH transfers latches to counter and starts timer
      // +3 matches real 6522 behavior (N+1.5 cycles). First instruction executes during
      // RTI return before first IRQ - this is correct tracewalk behavior.
      via_t1_counter = ((uint16_t)regVIA_T1LH << 8) | regVIA_T1LL;
      via_t1_counter += 3;  // 6522 timer delay compensation
      // Writing T1CH starts/restarts the timer in both one-shot and free-run modes
      via_t1_paused = false;
      // T1 started
      regVIA_IFR &= ~0x40;
      if ((regVIA_IFR & 0x7F) == 0) regVIA_IFR &= ~0x80;
      if (via_irq_pin_is_low) {
        digitalWriteFast(uP_IRQ_N, HIGH);  // Drive HIGH, not pullup
        via_irq_pin_is_low = false;
      }
      break;
    case VIA_T1LL:
      regVIA_T1LL = value;
      break;
    case VIA_T1LH: regVIA_T1LH = value; break;
    case VIA_T2CL: regVIA_T2CL = value; break;
    case VIA_T2CH: regVIA_T2CH = value; break;
    case VIA_SR:   regVIA_SR = value; break;
    case VIA_ACR:
      regVIA_ACR = value;
      break;
    case VIA_PCR:  regVIA_PCR = value; break;
    case VIA_IFR:
      regVIA_IFR &= ~(value & 0x7F);
      if ((regVIA_IFR & 0x7F) == 0) regVIA_IFR &= ~0x80;
      if ((regVIA_IFR & 0x40) == 0 && via_irq_pin_is_low) {
        digitalWriteFast(uP_IRQ_N, HIGH);  // Drive HIGH, not pullup
        via_irq_pin_is_low = false;
      }
      break;
    case VIA_IER:
      if (value & 0x80)
        regVIA_IER |= (value & 0x7F);
      else
        regVIA_IER &= ~(value & 0x7F);
      
      // Only activate tracewalk flag once when Timer 1 interrupt is first enabled
      if (value == 0xC0 && !trace_walk_active) {
        trace_walk_active = true;
      }
      // Disable tracewalk when Timer 1 interrupt is disabled
      if (value == 0x40) {
        trace_walk_active = false;
      }
      break;
  }
}

#endif