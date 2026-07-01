# System Architecture

## Overview

The Smart Digital Lock System is built around a central
Finite State Machine that coordinates four hardware
interfaces: a matrix keypad for input, a 7-segment
display for feedback, a relay for door control, and
a buzzer/LED system for alerts.

The design follows a strict synchronous philosophy —
every signal changes only on the rising edge of the
100 MHz system clock. There are no latches anywhere
in the design.

---

## Module Breakdown

### lock_pkg.vhd
Shared package used by all other modules.
Contains:
- Timing constants (CLK_FREQ_HZ, DEBOUNCE_MS)
- FSM state enumeration (lock_state_t)
- Password type definition (pass_array)
- 7-segment display lookup table (SEG_LUT)
- Default PIN: 1-2-3-4

### clock_divider.vhd
Converts the 100 MHz system clock into a 1 kHz
single-cycle tick pulse used by the keypad scanner.
Generic DIVISOR parameter makes it reusable.

### keypad_scanner.vhd
Drives the 4x4 matrix keypad using column scanning:
- Rotates active-LOW signal through 4 columns
- Samples 4 row inputs after 10us settle time
- Applies 20ms debounce filter
- Outputs single-cycle key_valid pulse + key_code

### lock_controller.vhd
The heart of the system. A 7-state synchronous FSM:
- INIT          : Clear all registers
- WAIT_FOR_KEY  : Idle, display shows "----"
- ENTER_PASS    : Collecting digits, display "****"
- CHECK_PASS    : Compare buffer to stored PIN
- UNLOCKED      : Relay ON, display "OPEn", 5s timer
- ERROR_STATE   : Wrong PIN, red LED, 2s timer
- ALARM         : 3 failures, buzzer pulses, 30s timer

Master reset is asynchronous — overrides all states.

### seg7_driver.vhd
Time-multiplexed display driver:
- Cycles through 4 digits at 1.25 kHz
- Active-LOW segments and anodes (common anode display)
- Mode-based output (no individual digit control needed)
- Display modes: dash, star, Err, OPEn, LOCK

### smart_lock_top.vhd
Structural top-level entity.
Simply connects all modules together via internal signals.
No logic here — just port maps.

---
---

## Timing Summary

| Signal | Frequency | Period |
|--------|-----------|--------|
| System clock | 100 MHz | 10 ns |
| Keypad scan | 1 kHz | 1 ms |
| Display refresh | 1.25 kHz | 800 us |
| Debounce window | — | 20 ms |
| Unlock timeout | — | 5 sec |
| Alarm timeout | — | 30 sec |
| Buzzer pulse | 2 Hz | 500 ms |

---

## Design Decisions

**Why synchronous reset for FSM, async for master reset?**
The FSM uses synchronous reset for clean state transitions.
Master reset is asynchronous because it needs to work
instantly — even if the clock is somehow stalled.

**Why time-multiplexed display?**
Direct drive needs 4 x 8 = 32 pins.
Multiplexed needs only 7 + 4 = 11 pins.
Saves 21 FPGA I/O pins for future expansion.

**Why separate debounce from scan?**
Mixing them makes testing harder. The scanner handles
column rotation; the debouncer handles signal quality.
Each can be verified independently.