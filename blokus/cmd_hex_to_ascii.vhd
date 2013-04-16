----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:39:15 04/16/2013 
-- Design Name: 
-- Module Name:    cmd_hex_to_ascii - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.types.all;

entity cmd_hex_to_ascii is
	Port(hex_command   : in  std_logic_vector(15 downto 0);
		  ascii_command : out std_logic_vector(31 downto 0));
end cmd_hex_to_ascii;

architecture Behavioral of cmd_hex_to_ascii is

begin
	process(hex_command)
	begin
		
		-- x
		if hex_command(15 downto 12) <= 9 then
			ascii_command(31 downto 24) <= hex_command(15 downto 12) + x"30";
		else
			ascii_command(31 downto 24) <= hex_command(15 downto 12) + x"61" - 10;
		end if;
		
		-- y
		if hex_command(11 downto 8) <= 9 then
			ascii_command(23 downto 16) <= hex_command(11 downto 8) + x"30";
		else
			ascii_command(23 downto 16) <= hex_command(11 downto 8) + x"61" - 10;
		end if;
		
		-- piece_id
		ascii_command(15 downto 8) <= hex_command(7 downto 3) + x"61";
		
		-- rotation
		ascii_command(7 downto 0) <= hex_command(2 downto 0) + x"30";
				
	end process;

end Behavioral;
