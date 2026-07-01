-- ============================================================
-- File     : lock_pkg.vhd
-- Project  : Smart Digital Lock System
-- Purpose  : Shared constants, types, and lookup tables
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package lock_pkg is

  -- ── System Clock & Timing Constants ──────────────────────
  constant CLK_FREQ_HZ   : integer := 100_000_000; -- 100 MHz (Basys3)
  constant SCAN_DIV      : integer := 100_000;      -- 1 kHz keypad scan
  constant DEBOUNCE_MS   : integer := 20;           -- 20ms debounce window
  constant UNLOCK_SECS   : integer := 5;            -- door open duration
  constant ALARM_SECS    : integer := 30;           -- lockout duration
  constant MAX_ATTEMPTS  : integer := 3;            -- wrong tries before alarm
  constant PASS_LENGTH   : integer := 4;            -- PIN digit count

  -- ── Password Type & Default PIN (1-2-3-4) ────────────────
  type pass_array is array (0 to PASS_LENGTH-1) of std_logic_vector(3 downto 0);
  constant DEFAULT_PASS  : pass_array := (
    "0001",   -- digit 0 = '1'
    "0010",   -- digit 1 = '2'
    "0011",   -- digit 2 = '3'
    "0100"    -- digit 3 = '4'
  );

  -- ── FSM State Enumeration ─────────────────────────────────
  type lock_state_t is (
    INIT,
    WAIT_FOR_KEY,
    ENTER_PASS,
    CHECK_PASS,
    UNLOCKED,
    ERROR_STATE,
    ALARM
  );

  -- ── 7-Segment Display LUT (active LOW, segments: gfedcba) ─
  type seg_lut_t is array (0 to 15) of std_logic_vector(6 downto 0);
  constant SEG_LUT : seg_lut_t := (
    "1000000", -- 0
    "1111001", -- 1
    "0100100", -- 2
    "0110000", -- 3
    "0011001", -- 4
    "0010010", -- 5
    "0000010", -- 6
    "1111000", -- 7
    "0000000", -- 8
    "0010000", -- 9
    "0001000", -- A (10)
    "0000011", -- b (11)
    "1000110", -- C (12)
    "0100001", -- d (13)
    "0000110", -- E (14)
    "0001110"  -- F (15)
  );

  -- ── Special Segment Patterns ──────────────────────────────
  constant SEG_DASH : std_logic_vector(6 downto 0) := "0111111"; -- "-"
  constant SEG_STAR : std_logic_vector(6 downto 0) := "0011100"; -- "*" approx
  constant SEG_OFF  : std_logic_vector(6 downto 0) := "1111111"; -- blank

end package lock_pkg;