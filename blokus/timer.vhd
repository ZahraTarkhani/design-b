----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:35:00 10/24/2012 
-- Design Name: 
-- Module Name:    timer - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity timer is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           time_int : out  integer;
           time_dec : out  integer;
			  test_leds: out std_logic_vector(7 downto 0)
			  );
end timer;

architecture Behavioral of timer is

signal counter_ns : integer range 0 to 127 := 0;
signal counter_us : integer range 0 to 1024 := 0;
signal counter_ms : integer range 0 to 127 := 0;
signal counter_ds : integer range 0 to 15 := 0;
signal counter_s : integer range 0 to 2047 := 0;

begin

process(clk, reset)
begin

	if clk = '1' and clk'event then
		if reset = '1' then
			counter_ns <= 0;
			counter_us <= 0;
			counter_ms <= 0;
			counter_ds <= 0;
			counter_s <= 0;
		else
			counter_ns <= counter_ns + 1;
			if counter_ns = 50 then 
				counter_us <= counter_us + 1;
				counter_ns <=0;
			end if;
			if counter_us = 1000 then
				counter_ms <= counter_ms + 1;
				counter_us <= 0;
			end if;
			if counter_ms = 100 then 
				counter_ds <= counter_ds + 1;
				counter_ms <= 0;
			end if;
			if counter_ds = 10 then
				counter_s <= counter_s +1;
				counter_ds <= 0;
			end if;
		end if;
	end if;
end process;

time_int <= counter_s;
time_dec <= counter_ds;

test_leds <= conv_std_logic_vector(counter_s, 4) & conv_std_logic_vector(counter_ds, 4);

end Behavioral;

