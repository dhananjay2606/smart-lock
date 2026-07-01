library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.lock_pkg.all;

entity tb_smart_lock is
end entity tb_smart_lock;

architecture sim of tb_smart_lock is

  signal clk        : std_logic := '0';
  signal rst        : std_logic := '1';
  signal master_rst : std_logic := '0';
  signal key_valid  : std_logic := '0';
  signal key_code   : std_logic_vector(3 downto 0) := "0000";
  signal disp_mode  : std_logic_vector(2 downto 0);
  signal disp_d0    : std_logic_vector(3 downto 0);
  signal disp_d1    : std_logic_vector(3 downto 0);
  signal disp_d2    : std_logic_vector(3 downto 0);
  signal disp_d3    : std_logic_vector(3 downto 0);
  signal relay_out  : std_logic;
  signal buzzer_out : std_logic;
  signal led_green  : std_logic;
  signal led_red    : std_logic;

  constant CLK_PERIOD : time := 10 ns;

begin

  -- Clock generation
  clk <= not clk after CLK_PERIOD / 2;

  -- DUT instantiation
  DUT : entity work.lock_controller
    port map (
      clk         => clk,
      rst         => rst,
      master_rst  => master_rst,
      key_valid   => key_valid,
      key_code    => key_code,
      disp_digit0 => disp_d0,
      disp_digit1 => disp_d1,
      disp_digit2 => disp_d2,
      disp_digit3 => disp_d3,
      disp_mode   => disp_mode,
      relay_out   => relay_out,
      buzzer_out  => buzzer_out,
      led_green   => led_green,
      led_red     => led_red
    );

  -- Stimulus process
  process
  begin

    -- PHASE 1: Reset
    rst <= '1';
    wait for 50 ns;
    rst <= '0';
    wait for 30 ns;

    -- PHASE 2: Correct PIN 1-2-3-4
    -- Press 1
    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    -- Press 2
    key_code  <= "0010";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    -- Press 3
    key_code  <= "0011";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    -- Press 4
    key_code  <= "0100";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 100 ns;

    -- Wait for FSM to process
    wait for 200 ns;

    -- Check relay
    assert relay_out = '1'
      report "FAIL: Relay should be ON after correct PIN"
      severity error;

    -- PHASE 3: Wait for auto relock
    -- (reduced timeout for simulation)
    wait for 1 us;

    -- PHASE 4: Wrong PIN 3 times
    -- Attempt 1: PIN 1-1-1-1
    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 500 ns;

    -- Attempt 2
    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 500 ns;

    -- Attempt 3
    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 500 ns;

    -- PHASE 5: Master Reset
    master_rst <= '1';
    wait for 30 ns;
    master_rst <= '0';
    wait for 100 ns;

    -- Check alarm cleared
    assert relay_out = '0'
      report "FAIL: Relay should be OFF after master reset"
      severity error;

    assert buzzer_out = '0'
      report "FAIL: Buzzer should be OFF after master reset"
      severity error;

    -- PHASE 6: Correct PIN again after reset
    key_code  <= "0001";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0010";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0011";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 50 ns;

    key_code  <= "0100";
    key_valid <= '1';
    wait for CLK_PERIOD;
    key_valid <= '0';
    wait for 200 ns;

    assert relay_out = '1'
      report "FAIL: Lock should open after reset and correct PIN"
      severity error;

    report "ALL SIMULATION TESTS COMPLETE" severity note;

    wait;
  end process;

end architecture sim;