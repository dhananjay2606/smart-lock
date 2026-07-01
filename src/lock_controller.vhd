-- ============================================================
-- File     : lock_controller.vhd
-- Project  : Smart Digital Lock System
-- Purpose  : Central FSM — password logic, alarm, master reset
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.lock_pkg.all;

entity lock_controller is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    master_rst  : in  std_logic;
    key_valid   : in  std_logic;
    key_code    : in  std_logic_vector(3 downto 0);
    disp_digit0 : out std_logic_vector(3 downto 0);
    disp_digit1 : out std_logic_vector(3 downto 0);
    disp_digit2 : out std_logic_vector(3 downto 0);
    disp_digit3 : out std_logic_vector(3 downto 0);
    disp_mode   : out std_logic_vector(2 downto 0);
    relay_out   : out std_logic;
    buzzer_out  : out std_logic;
    led_green   : out std_logic;
    led_red     : out std_logic
  );
end entity;

architecture rtl of lock_controller is

  signal state      : lock_state_t := INIT;
  signal attempts   : integer range 0 to MAX_ATTEMPTS := 0;
  signal digit_cnt  : integer range 0 to PASS_LENGTH  := 0;
  signal entered    : pass_array := (others => "0000");
  signal timeout : integer range 0 to 2_000_000_000 := 0;
  signal buzzer_tog : std_logic := '0';
 signal buz_cnt : integer range 0 to 25_000_000 := 0; 
 
  -- Compare entered PIN to stored PIN
  function pin_match(a, b : pass_array) return boolean is
  begin
    for i in 0 to PASS_LENGTH-1 loop
      if a(i) /= b(i) then return false; end if;
    end loop;
    return true;
  end function;

begin

  process(clk, rst)
  begin
    if rst = '1' then
      state      <= INIT;
      attempts   <= 0;
      digit_cnt  <= 0;
      timeout    <= 0;
      relay_out  <= '0';
      buzzer_out <= '0';
      led_green  <= '0';
      led_red    <= '0';

    elsif rising_edge(clk) then

      -- Master reset overrides everything
      if master_rst = '1' then
        state      <= INIT;
        attempts   <= 0;
        digit_cnt  <= 0;
        timeout    <= 0;
        relay_out  <= '0';
        buzzer_out <= '0';
        led_green  <= '0';
        led_red    <= '0';
        buzzer_tog <= '0';

      else
        -- Default de-assertion each cycle
        relay_out  <= '0';
        buzzer_out <= '0';
        led_green  <= '0';
        led_red    <= '0';

        case state is

          when INIT =>
            disp_mode <= "001";
            attempts  <= 0;
            digit_cnt <= 0;
            entered   <= (others => "0000");
            state     <= WAIT_FOR_KEY;

          when WAIT_FOR_KEY =>
            disp_mode <= "001";
            if key_valid = '1' then
              if unsigned(key_code) <= 9 then
                entered(0) <= key_code;
                digit_cnt  <= 1;
                state      <= ENTER_PASS;
              end if;
            end if;

          when ENTER_PASS =>
            disp_mode <= "010";
            if key_valid = '1' then
              if key_code = "1110" then
                digit_cnt <= 0;
                state     <= WAIT_FOR_KEY;
              elsif unsigned(key_code) <= 9 then
                entered(digit_cnt) <= key_code;
                if digit_cnt = PASS_LENGTH - 1 then
                  state     <= CHECK_PASS;
                  digit_cnt <= 0;
                else
                  digit_cnt <= digit_cnt + 1;
                end if;
              end if;
            end if;

          when CHECK_PASS =>
            if pin_match(entered, DEFAULT_PASS) then
              state   <= UNLOCKED;
              timeout <= 0;
            else
              attempts <= attempts + 1;
              state    <= ERROR_STATE;
              timeout  <= 0;
            end if;

          when UNLOCKED =>
            relay_out <= '1';
            led_green <= '1';
            disp_mode <= "100";
            timeout   <= timeout + 1;
            if timeout = CLK_FREQ_HZ * UNLOCK_SECS then
              state   <= INIT;
              timeout <= 0;
            end if;

          when ERROR_STATE =>
            led_red   <= '1';
            disp_mode <= "011";
            timeout   <= timeout + 1;
            if timeout = CLK_FREQ_HZ * 2 then
              timeout <= 0;
              entered <= (others => "0000");
              if attempts >= MAX_ATTEMPTS then
                state <= ALARM;
              else
                state <= WAIT_FOR_KEY;
              end if;
            end if;

          when ALARM =>
            disp_mode  <= "101";
            led_red    <= buzzer_tog;
            led_green  <= not buzzer_tog;
            buzzer_out <= buzzer_tog;

            if buz_cnt = CLK_FREQ_HZ/4 then
              buz_cnt    <= 0;
              buzzer_tog <= not buzzer_tog;
            else
              buz_cnt <= buz_cnt + 1;
            end if;

            timeout <= timeout + 1;
            if timeout = CLK_FREQ_HZ * ALARM_SECS then
              state      <= INIT;
              timeout    <= 0;
              attempts   <= 0;
              buzzer_tog <= '0';
            end if;

        end case;
      end if;
    end if;
  end process;

  -- Unused digit outputs (display driver uses disp_mode instead)
  disp_digit0 <= "0000";
  disp_digit1 <= "0000";
  disp_digit2 <= "0000";
  disp_digit3 <= "0000";

end architecture;