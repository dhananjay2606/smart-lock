-- ============================================================
-- File     : seg7_driver.vhd
-- Project  : Smart Digital Lock System
-- Purpose  : Time-multiplexed 4-digit 7-segment display driver
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.lock_pkg.all;

entity seg7_driver is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    disp_mode : in  std_logic_vector(2 downto 0);
    digit0    : in  std_logic_vector(3 downto 0);
    seg       : out std_logic_vector(6 downto 0);
    anode     : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of seg7_driver is

  constant MUX_DIV : integer := 20_000;
  signal mux_cnt   : integer range 0 to MUX_DIV-1 := 0;
  signal digit_sel : integer range 0 to 3 := 0;
  signal seg_r     : std_logic_vector(6 downto 0);

begin

  -- Multiplexer timing
  process(clk, rst)
  begin
    if rst = '1' then
      mux_cnt   <= 0;
      digit_sel <= 0;
    elsif rising_edge(clk) then
      if mux_cnt = MUX_DIV - 1 then
        mux_cnt <= 0;
        if digit_sel = 3 then digit_sel <= 0;
        else digit_sel <= digit_sel + 1; end if;
      else
        mux_cnt <= mux_cnt + 1;
      end if;
    end if;
  end process;

  -- Anode selection (active LOW for common-anode display)
  process(digit_sel)
  begin
    case digit_sel is
      when 0 => anode <= "1110";
      when 1 => anode <= "1101";
      when 2 => anode <= "1011";
      when 3 => anode <= "0111";
      when others => anode <= "1111";
    end case;
  end process;

  -- Segment data from display mode
  process(disp_mode, digit_sel)
  begin
    case disp_mode is

      when "001" =>              -- "----"
        seg_r <= SEG_DASH;

      when "010" =>              -- "****" entry masking
        seg_r <= SEG_STAR;

      when "011" =>              -- "Err "
        case digit_sel is
          when 0 => seg_r <= SEG_LUT(14);  -- E
          when 1 => seg_r <= "0101111";    -- r
          when 2 => seg_r <= "0101111";    -- r
          when 3 => seg_r <= SEG_OFF;
          when others => seg_r <= SEG_OFF;
        end case;

      when "100" =>              -- "OPEn"
        case digit_sel is
          when 0 => seg_r <= SEG_LUT(0);   -- O
          when 1 => seg_r <= "0001100";    -- P
          when 2 => seg_r <= SEG_LUT(14);  -- E
          when 3 => seg_r <= "0101011";    -- n
          when others => seg_r <= SEG_OFF;
        end case;

      when "101" =>              -- "LOCK"
        case digit_sel is
          when 0 => seg_r <= "1000111";    -- L
          when 1 => seg_r <= SEG_LUT(0);   -- O
          when 2 => seg_r <= SEG_LUT(12);  -- C
          when 3 => seg_r <= "0001000";    -- K
          when others => seg_r <= SEG_OFF;
        end case;

      when others =>             -- blank
        seg_r <= SEG_OFF;

    end case;
  end process;

  seg <= seg_r;

end architecture;