-- ============================================================
-- File     : clock_divider.vhd
-- Project  : Smart Digital Lock System
-- Purpose  : Generates a single-cycle tick pulse from 100MHz
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.lock_pkg.all;

entity clock_divider is
  generic (
    DIVISOR : integer := SCAN_DIV
  );
  port (
    clk_in  : in  std_logic;
    rst     : in  std_logic;
    clk_out : out std_logic
  );
end entity;

architecture rtl of clock_divider is
  signal count : integer range 0 to DIVISOR-1 := 0;
begin

  process(clk_in, rst)
  begin
    if rst = '1' then
      count   <= 0;
      clk_out <= '0';
    elsif rising_edge(clk_in) then
      clk_out <= '0';
      if count = DIVISOR - 1 then
        count   <= 0;
        clk_out <= '1';   -- one-cycle high pulse
      else
        count <= count + 1;
      end if;
    end if;
  end process;

end architecture;