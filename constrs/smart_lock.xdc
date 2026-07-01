## File: smart_lock.xdc
## Target: Digilent Basys3 (XC7A35T)
## ─────────────────────────────────────────────────────────────────

## ── System Clock (100 MHz onboard oscillator) ───────────────────
set_property PACKAGE_PIN W5  [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 \
             -waveform {0 5} [get_ports clk]

## ── Reset Button (active HIGH, center button on Basys3) ─────────
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## ── Master Reset (right button) ─────────────────────────────────
set_property PACKAGE_PIN T18 [get_ports master_rst]
set_property IOSTANDARD LVCMOS33 [get_ports master_rst]

## ── Keypad Rows (inputs with pull-ups) ──────────────────────────
## Wire keypad ROW pins to PMOD header JA (pins 1-4)
set_property PACKAGE_PIN J1  [get_ports {row[0]}]
set_property PACKAGE_PIN L2  [get_ports {row[1]}]
set_property PACKAGE_PIN J2  [get_ports {row[2]}]
set_property PACKAGE_PIN G2  [get_ports {row[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {row[*]}]
## Enable internal pull-ups so unpressed rows read HIGH
set_property PULLUP true [get_ports {row[0]}]
set_property PULLUP true [get_ports {row[1]}]
set_property PULLUP true [get_ports {row[2]}]
set_property PULLUP true [get_ports {row[3]}]

## ── Keypad Columns (outputs, driven LOW to scan) ────────────────
## Wire to PMOD header JA (pins 7-10)
set_property PACKAGE_PIN H1  [get_ports {col[0]}]
set_property PACKAGE_PIN K2  [get_ports {col[1]}]
set_property PACKAGE_PIN H2  [get_ports {col[2]}]
set_property PACKAGE_PIN G3  [get_ports {col[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {col[*]}]
set_property DRIVE 4         [get_ports {col[*]}]
set_property SLEW  SLOW      [get_ports {col[*]}]

## ── 7-Segment Display: Segments (a-g, active LOW) ───────────────
## Basys3 onboard 4-digit 7-segment display
set_property PACKAGE_PIN W7  [get_ports {seg[0]}]  ;# segment a
set_property PACKAGE_PIN W6  [get_ports {seg[1]}]  ;# segment b
set_property PACKAGE_PIN U8  [get_ports {seg[2]}]  ;# segment c
set_property PACKAGE_PIN V8  [get_ports {seg[3]}]  ;# segment d
set_property PACKAGE_PIN U5  [get_ports {seg[4]}]  ;# segment e
set_property PACKAGE_PIN V5  [get_ports {seg[5]}]  ;# segment f
set_property PACKAGE_PIN U7  [get_ports {seg[6]}]  ;# segment g
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

## ── 7-Segment Display: Digit Anodes (active LOW) ────────────────
set_property PACKAGE_PIN U2  [get_ports {anode[0]}]
set_property PACKAGE_PIN U4  [get_ports {anode[1]}]
set_property PACKAGE_PIN V4  [get_ports {anode[2]}]
set_property PACKAGE_PIN W4  [get_ports {anode[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode[*]}]

## ── Status LEDs (onboard Basys3 LEDs) ───────────────────────────
set_property PACKAGE_PIN U16 [get_ports led_green]
set_property PACKAGE_PIN E19 [get_ports led_red]
set_property IOSTANDARD LVCMOS33 [get_ports led_green]
set_property IOSTANDARD LVCMOS33 [get_ports led_red]

## ── Relay Output (via PMOD JB pin 1) ────────────────────────────
## Add a 2N2222 transistor + flyback diode to drive a real relay coil
set_property PACKAGE_PIN A14 [get_ports relay_out]
set_property IOSTANDARD LVCMOS33 [get_ports relay_out]
set_property DRIVE 12       [get_ports relay_out]

## ── Buzzer Output (via PMOD JB pin 2) ───────────────────────────
## Passive buzzer driven through a transistor
set_property PACKAGE_PIN A16 [get_ports buzzer_out]
set_property IOSTANDARD LVCMOS33 [get_ports buzzer_out]

## ── Timing false paths (async reset, master reset buttons) ──────
set_false_path -from [get_ports rst]
set_false_path -from [get_ports master_rst]
set_false_path -from [get_ports {row[*]}]