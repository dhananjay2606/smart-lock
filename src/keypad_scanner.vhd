-- ============================================================
-- File     : keypad_scanner.vhd
-- Project  : Smart Digital Lock System
-- Purpose  : Scans 4x4 matrix keypad, debounces, outputs key
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.lock_pkg.all;

entity keypad_scanner is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    row       : in  std_logic_vector(3 downto 0);
    col       : out std_logic_vector(3 downto 0);
    key_valid : out std_logic;
    key_code  : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of keypad_scanner is

  type scan_state_t is (DRIVE_COL, SETTLE, READ_ROW, DEBOUNCE_KEY, OUTPUT_KEY);
  signal scan_state : scan_state_t := DRIVE_COL;

  signal col_idx    : integer range 0 to 3 := 0;
  signal col_drive  : std_logic_vector(3 downto 0) := "1110";
  signal row_sample : std_logic_vector(3 downto 0);

  constant SETTLE_CYC   : integer := 1000;
  constant DEBOUNCE_CYC : integer := 2_000_000;

  signal timer        : integer range 0 to DEBOUNCE_CYC := 0;
  signal raw_key      : std_logic_vector(3 downto 0) := "1111";
  signal key_detected : std_logic := '0';
  signal stable_key   : std_logic_vector(3 downto 0) := "1111";
  signal debounce_cnt : integer range 0 to DEBOUNCE_CYC := 0;
  signal key_valid_r  : std_logic := '0';

begin

  col <= col_drive;

  -- Column driver
  process(col_idx)
  begin
    case col_idx is
      when 0 => col_drive <= "1110";
      when 1 => col_drive <= "1101";
      when 2 => col_drive <= "1011";
      when 3 => col_drive <= "0111";
      when others => col_drive <= "1111";
    end case;
  end process;

  -- Main scan FSM
  process(clk, rst)
    variable decoded : std_logic_vector(3 downto 0);
  begin
    if rst = '1' then
      scan_state   <= DRIVE_COL;
      col_idx      <= 0;
      timer        <= 0;
      debounce_cnt <= 0;
      key_valid_r  <= '0';
      key_detected <= '0';

    elsif rising_edge(clk) then
      key_valid_r <= '0';

      case scan_state is

        when DRIVE_COL =>
          timer      <= 0;
          scan_state <= SETTLE;

        when SETTLE =>
          if timer = SETTLE_CYC - 1 then
            row_sample <= row;
            timer      <= 0;
            scan_state <= READ_ROW;
          else
            timer <= timer + 1;
          end if;

        when READ_ROW =>
          key_detected <= '0';
          decoded      := "1111";

          if    row_sample(0) = '0' then
            decoded      := std_logic_vector(to_unsigned(col_idx * 4 + 0, 4));
            key_detected <= '1';
          elsif row_sample(1) = '0' then
            decoded      := std_logic_vector(to_unsigned(col_idx * 4 + 4, 4));
            key_detected <= '1';
          elsif row_sample(2) = '0' then
            decoded      := std_logic_vector(to_unsigned(col_idx * 4 + 8, 4));
            key_detected <= '1';
          elsif row_sample(3) = '0' then
            decoded      := std_logic_vector(to_unsigned(col_idx * 4 + 12, 4));
            key_detected <= '1';
          end if;

          raw_key <= decoded;

          if key_detected = '1' then
            scan_state   <= DEBOUNCE_KEY;
            debounce_cnt <= 0;
          else
            if col_idx = 3 then col_idx <= 0;
            else col_idx <= col_idx + 1; end if;
            scan_state <= DRIVE_COL;
          end if;

        when DEBOUNCE_KEY =>
          if debounce_cnt = DEBOUNCE_CYC - 1 then
            if row(0) = '0' or row(1) = '0' or
               row(2) = '0' or row(3) = '0' then
              stable_key <= raw_key;
              scan_state <= OUTPUT_KEY;
            else
              scan_state <= DRIVE_COL;
            end if;
            debounce_cnt <= 0;
          else
            debounce_cnt <= debounce_cnt + 1;
          end if;

        when OUTPUT_KEY =>
          key_valid_r <= '1';
          if row = "1111" then
            if col_idx = 3 then col_idx <= 0;
            else col_idx <= col_idx + 1; end if;
            scan_state <= DRIVE_COL;
          end if;

      end case;
    end if;
  end process;

  -- Key decode: scan position → BCD digit
  process(stable_key)
  begin
    case stable_key is
      when "0000" => key_code <= "0001"; -- 1
      when "0001" => key_code <= "0100"; -- 4
      when "0010" => key_code <= "0111"; -- 7
      when "0011" => key_code <= "1110"; -- * (cancel)
      when "0100" => key_code <= "0010"; -- 2
      when "0101" => key_code <= "0101"; -- 5
      when "0110" => key_code <= "1000"; -- 8
      when "0111" => key_code <= "0000"; -- 0
      when "1000" => key_code <= "0011"; -- 3
      when "1001" => key_code <= "0110"; -- 6
      when "1010" => key_code <= "1001"; -- 9
      when "1011" => key_code <= "1111"; -- # (confirm)
      when others => key_code <= "1010"; -- A/B/C/D
    end case;
  end process;

  key_valid <= key_valid_r;

end architecture;