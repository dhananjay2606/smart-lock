# Smart Digital Lock System — VHDL & FPGA

> A 4-digit PIN-based digital lock built entirely in VHDL and deployed on a Xilinx Basys3 FPGA board. This was my electronics engineering semester project — covering everything from the initial FSM design on paper all the way to a working bitstream.

---

## Why I Built This

I wanted a project that touched every part of the FPGA design flow — not just blinking LEDs. A digital lock made sense because it has real hardware inputs (keypad), real outputs (relay, display, buzzer), and a non-trivial control problem (state machine with timeouts, lockouts, and resets). It also maps cleanly onto things you'd actually see in embedded security products.

The goal was to go from a blank VHDL file to a fully verified, synthesis-ready design — and document every step along the way.

---

## What It Does

You press 4 digits on a matrix keypad. If the PIN matches, a relay clicks open and the display shows `OPEn`. Five seconds later it re-locks automatically. Press the wrong PIN three times in a row and the system locks out — buzzer pulsing, LEDs flashing, display showing `LOCK` — for 30 seconds. There's also a dedicated master reset button that clears everything instantly, regardless of state.

That's the user experience. Under the hood it's a 7-state FSM running at 100 MHz, with debounced keypad scanning, time-multiplexed display driving, and fully synchronous logic throughout.

---

## How It's Built

The design is split into six modules, each with a single responsibility:

```
smart_lock_top          ← top-level, just wires everything together
├── keypad_scanner      ← scans 4×4 keypad, debounces, outputs key code
├── lock_controller     ← the FSM — all the lock logic lives here
└── seg7_driver         ← drives the 4-digit 7-segment display
```

Plus two support files:
- `lock_pkg.vhd` — shared constants, types, and the 7-segment LUT
- `clock_divider.vhd` — scales 100 MHz down to 1 kHz for keypad scanning

I kept things modular deliberately. Each module can be simulated and tested independently, which made debugging much easier — especially the keypad debouncer, which took a few iterations to get right.

---

## The State Machine

This is the core of the project. Seven states, all synchronous, no latches:

```
INIT
 │  (system starts here, clears everything)
 ▼
WAIT_FOR_KEY
 │  (idle — display shows "----", waiting for first digit)
 │  digit pressed
 ▼
ENTER_PASS
 │  (collecting digits — display shows "****")
 │  4 digits entered
 ▼
CHECK_PASS
 │  (compare buffer against stored PIN)
 ├── match ──────────────────────────────▶ UNLOCKED
 │                                          relay ON, green LED,
 │                                          display "OPEn", 5s timer
 │                                          → auto-returns to INIT
 └── no match ──────────────────────────▶ ERROR_STATE
                                           red LED, display "Err",
                                           attempt_count++, 2s timer
                                           │
                                           ├── attempt_count < 3 → WAIT_FOR_KEY
                                           └── attempt_count = 3 → ALARM
                                                buzzer pulses, LEDs flash,
                                                display "LOCK", 30s timer
                                                → MASTER_RESET clears instantly
```

Master reset is asynchronous and overrides every state — it was one of the first things I designed because you need a way out of the alarm state without waiting 30 seconds during testing.

---

## The Tricky Part — Keypad Debouncing

Mechanical switches bounce. When you press a key, the contact doesn't cleanly go from open to closed — it bounces back and forth for anywhere from 50 µs to 5 ms. If you read the keypad naively, you'll register multiple keypresses from a single physical press.

My debouncer works in five phases:

```
1. DRIVE_COL   — pull one column LOW
2. SETTLE      — wait 10 µs for voltage to stabilize
3. READ_ROW    — sample all four rows
4. DEBOUNCE    — wait 20 ms, then re-sample to confirm still pressed
5. OUTPUT_KEY  — fire a single-cycle key_valid pulse, wait for release
```

The 20 ms window is the key — it's long enough to outlast any realistic bounce, short enough that it's imperceptible to a human pressing keys. The re-sample at the end of the debounce window is a guard against slow-rising signals being mistaken for a held key.

---

## Display Driver

The 7-segment display on the Basys3 has four digits sharing the same segment lines. You can only light one digit at a time, so you rotate through them fast enough that it looks like all four are on simultaneously — this is time multiplexing.

My driver cycles through all four digits at 1.25 kHz (well above the ~50 Hz threshold where flicker becomes visible). Each digit gets its segment pattern from a mode register set by the FSM:

| Mode | Display |
|------|---------|
| 001  | `----`  |
| 010  | `****`  |
| 011  | `Err ` |
| 100  | `OPEn`  |
| 101  | `LOCK`  |

This saves pins too — 11 total instead of 28 for direct drive.

---

## Simulation Results

I wrote a testbench that covers six scenarios without needing physical hardware:

| Test | What It Checks | Result |
|------|---------------|--------|
| 1 | System resets cleanly | ✅ Pass |
| 2 | Correct PIN (1-2-3-4) opens lock | ✅ Pass |
| 3 | Lock re-engages after 5 seconds | ✅ Pass |
| 4 | Three wrong PINs trigger alarm | ✅ Pass |
| 5 | Master reset clears alarm instantly | ✅ Pass |
| 6 | Lock works normally after reset | ✅ Pass |

The testbench drives `key_valid` and `key_code` directly, bypassing the hardware scanner — which is the right approach for FSM verification. You test the scanner separately against simulated row signals.

All assertions passed. The waveform clearly shows `relay_out` going high on correct PIN entry, `buzzer_out` toggling at 2 Hz during alarm, and `disp_mode` cycling through the correct values.

---

## Synthesis Numbers

Synthesized in AMD Vivado 2025.2 targeting the Basys3 (XC7A35T-CPG236-1):

| Resource | Used | Available | % |
|----------|------|-----------|---|
| Slice LUTs | 181 | 20,800 | 0.87% |
| Flip-Flops | 163 | 41,600 | 0.39% |
| Bonded IOB | 26 | 106 | 24.5% |
| BRAM | 0 | 50 | 0% |
| DSP | 0 | 90 | 0% |

Timing closed at 100 MHz with positive slack. No critical warnings.

The design is tiny — under 1% of the chip. There's plenty of room to add features (multi-user PINs, UART logging, etc.) without approaching any resource limits.

---

## Project Files

```
SmartLock-VHDL/
├── src/
│   ├── lock_pkg.vhd          constants, types, segment LUT
│   ├── clock_divider.vhd     100 MHz → 1 kHz tick generator
│   ├── keypad_scanner.vhd    matrix scan + 20ms debounce
│   ├── lock_controller.vhd   7-state FSM (main logic)
│   ├── seg7_driver.vhd       time-multiplexed display driver
│   └── smart_lock_top.vhd    structural top-level
│
├── sim/
│   └── tb_smart_lock.vhd     6-phase testbench
│
├── constrs/
│   └── smart_lock.xdc        pin assignments for Basys3
│
├── docs/
│   ├── ARCHITECTURE.md
│   └── HARDWARE_SETUP.md
│
└── images/
    ├── synthesis_results.png
    └── simulation_waveform.png
```

---

## Running This Yourself

You'll need AMD Vivado (free WebPACK edition works fine) and a Basys3 board. The design targets the XC7A35T-CPG236-1.

**Simulate:**
```
1. Open Vivado → Create Project → add all src/ and sim/ files
2. Set tb_smart_lock as simulation top
3. Run Behavioral Simulation
4. In TCL console: run 500us
5. Check waveform — relay_out should go HIGH after correct PIN sequence
```

**Synthesize & implement:**
```
Flow Navigator → Run Synthesis → Run Implementation
Check timing report: WNS must be positive
```

**Generate bitstream:**
```
Flow Navigator → Generate Bitstream
Output: SmartLock.runs/impl_1/smart_lock_top.bit
```

**Program the board:**
```
Hardware Manager → Open Target → Auto Connect
Right-click xc7a35t_0 → Program Device → select .bit file
```

---

## Hardware Wiring (Basys3 + Keypad)

Connect the 4×4 keypad to PMOD header JA:

```
Keypad    →    Basys3 Pin
ROW 0     →    JA1  (J1)
ROW 1     →    JA2  (L2)
ROW 2     →    JA3  (J2)
ROW 3     →    JA4  (G2)
COL 0     →    JA7  (H1)
COL 1     →    JA8  (K2)
COL 2     →    JA9  (H2)
COL 3     →    JA10 (G3)
GND       →    JA5
VCC 3.3V  →    JA6
```

The onboard 7-segment display, LEDs, and buttons are already wired via the XDC file.

For relay and buzzer: connect through a 2N2222 transistor on PMOD JB pins 1 and 2. Don't drive them directly from FPGA pins.

---

## Default PIN

The PIN is hardcoded in `lock_pkg.vhd`:

```vhdl
constant DEFAULT_PASS : pass_array := (
  "0001",  -- 1
  "0010",  -- 2
  "0011",  -- 3
  "0100"   -- 4
);
```

Change those four values to set a different PIN. Multi-user support is on the roadmap for v1.1.

---

## What I'd Do Differently

A few things I learned along the way:

- **Reduce simulation constants early.** The first time I ran simulation, it timed out because the 30-second alarm timeout at 100 MHz is 3 billion clock cycles — way too long for a testbench. I added simulation-mode constants to lock_pkg that shrink the timeouts.

- **Test the debouncer in isolation.** I initially tested it as part of the full system and had a hard time isolating whether bugs were in the scanner or the FSM. Separating them into independent testbenches made everything clearer.

- **The display driver needs its own clock domain check.** At 100 MHz the multiplexer counter rolls over fast. Worth verifying the refresh rate calculation independently before integrating.

---

## Planned Improvements

- **v1.1** — Multiple user PINs (up to 4), configurable via UART
- **v1.2** — Attempt logging to onboard BRAM
- **v2.0** — WiFi module integration for remote unlock
- **v3.0** — Biometric (fingerprint) as second factor

---

## License

MIT — do whatever you want with it, just keep the copyright notice.

---

## About

Built as part of an Electronics Engineering degree project.  
Tools: AMD Vivado 2025.2 | Language: VHDL | Target: Xilinx Basys3

If you use this for your own project or find a bug, open an issue — always happy to discuss hardware design.

