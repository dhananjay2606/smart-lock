# Hardware Setup Guide

## Components Required

| Component         | Quantity        | Notes                    |
|-------------------|-----------------|--------------------------|
| Digilent Basys3   |        1        | XC7A35T-CPG236-1         |
| 4x4 Matrix Keypad |        1        | Membrane type            |
| Jumper wires M-F  |        10       | For PMOD connection      |
| USB-A to Micro-USB|        1        | Comes with Basys3        |
| 2N2222 transistor |        2        | For relay & buzzer       |
| 1N4007 diode      |        1        | Flyback for relay coil   |
| 1kΩ resistor      |        2        | Transistor base resistor |
| 5V Relay module   |        1        | Optional                 |
| Passive buzzer    |        1        | Optional                 |
|----------------------------------------------------------------|


## Keypad Wiring (PMOD JA

KEYPAD PIN BASYS3 PMOD JA FPGA PIN
──────────────────────────────────────────
ROW 0 ──▶ JA Pin 1 J1
ROW 1 ──▶ JA Pin 2 L2
ROW 2 ──▶ JA Pin 3 J2
ROW 3 ──▶ JA Pin 4 G2
GND ──▶ JA Pin 5 GND
COL 0 ──▶ JA Pin 7 H1
COL 1 ──▶ JA Pin 8 K2
COL 2 ──▶ JA Pin 9 H2
COL 3 ──▶ JA Pin 10 G3
VCC 3.3V ──▶ JA Pin 6 VCC


## Testing Sequence After Programming

STEP 1 — Power On
Expected: Display shows "----"

STEP 2 — Enter Correct PIN (1, 2, 3, 4)
Press keys one at a time
Expected: Display shows "****" per digit
Then "OPEn" after 4th digit
Green LED lights up
Relay clicks (if connected)
Auto-relocks after 5 seconds

STEP 3 — Enter Wrong PIN 3 Times
Press: 1 1 1 1 (three times)
Expected: Display shows "Err" after each
After 3rd wrong: "LOCK"
Buzzer pulses (if connected)
LEDs flash alternately

STEP 4 — Master Reset
Press RIGHT button (BTNR)
Expected: Instantly returns to "----"
All outputs go LOW
Attempt counter resets

---

## Common Issues & Fixes

|       Problem           |     Likely Cause     |            Fix            |
|-------------------------|----------------------|---------------------------|
| Display not showing     | Wrong anode polarity | Check common-anode wiring |
| Keypad not responding   | Missing pull-ups     | Check XDC PULLUP property |
| Multiple keys per press | Debounce too short   | Increase DEBOUNCE_CYC     |
| Relay not clicking      | No transistor driver | Add 2N2222 circuit        |
| DONE LED doesn't light  | Wrong bitstream      | Re-generate and re-flash  |