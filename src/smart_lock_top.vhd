-- ============================================================
-- File     : smart_lock_top.vhd
-- Project  : Smart Digital Lock System
-- Purpose  : Top-level structural entity — wires all modules
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.lock_pkg.all;

entity smart_lock_top is
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    master_rst : in  std_logic;
    row        : in  std_logic_vector(3 downto 0);
    col        : out std_logic_vector(3 downto 0);
    seg        : out std_logic_vector(6 downto 0);
    anode      : out std_logic_vector(3 downto 0);
    relay_out  : out std_logic;
    buzzer_out : out std_logic;
    led_green  : out std_logic;
    led_red    : out std_logic
  );
end entity;

architecture structural of smart_lock_top is

  signal key_valid_s : std_logic;
  signal key_code_s  : std_logic_vector(3 downto 0);
  signal disp_mode_s : std_logic_vector(2 downto 0);
  signal digit0_s    : std_logic_vector(3 downto 0);

begin

  U_KEYPAD : entity work.keypad_scanner
    port map (
      clk       => clk,
      rst       => rst,
      row       => row,
      col       => col,
      key_valid => key_valid_s,
      key_code  => key_code_s
    );

  U_FSM : entity work.lock_controller
    port map (
      clk         => clk,
      rst         => rst,
      master_rst  => master_rst,
      key_valid   => key_valid_s,
      key_code    => key_code_s,
      disp_digit0 => digit0_s,
      disp_digit1 => open,
      disp_digit2 => open,
      disp_digit3 => open,
      disp_mode   => disp_mode_s,
      relay_out   => relay_out,
      buzzer_out  => buzzer_out,
      led_green   => led_green,
      led_red     => led_red
    );

  U_DISPLAY : entity work.seg7_driver
    port map (
      clk       => clk,
      rst       => rst,
      disp_mode => disp_mode_s,
      digit0    => digit0_s,
      seg       => seg,
      anode     => anode
    );

end architecture;