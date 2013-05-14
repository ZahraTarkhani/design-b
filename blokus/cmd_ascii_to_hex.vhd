----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:52:07 04/16/2013 
-- Design Name: 
-- Module Name:    cmd_ascii_to_hex - Behavioral 
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

entity cmd_ascii_to_hex is
	Port(ascii_command       : in  std_logic_vector(31 downto 0);
		 flip_board          : in  std_logic;
		 hex_command_flipped : out move);
end cmd_ascii_to_hex;

architecture Behavioral of cmd_ascii_to_hex is
	signal hex_command : move;

	type possible_flips is array (0 to 7) of std_logic_vector(2 downto 0);
	constant flips : possible_flips := (
		"111",
		"010",
		"001",
		"100",
		"011",
		"110",
		"101",
		"000"
	);
begin
	process(hex_command, flip_board)
	begin
		if flip_board = '0' then
			hex_command_flipped <= hex_command;
		else
			hex_command_flipped.x        <= 14 - hex_command.x;
			hex_command_flipped.y        <= 14 - hex_command.y;
			hex_command_flipped.name     <= hex_command.name;
			hex_command_flipped.rotation <= flips(conv_integer(hex_command.rotation));
		end if;
	end process;

	process(ascii_command)
	begin
		if ascii_command = x"30303030" then
			-- pass
			hex_command.x        <= x"0";
			hex_command.y        <= x"0";
			hex_command.name     <= "00000";
			hex_command.rotation <= "000";
		else
			-- x
			if ascii_command(31 downto 24) <= x"39" then
				hex_command.x <= ascii_command(27 downto 24);
			else
				hex_command.x <= ascii_command(27 downto 24) + 9;
			end if;

			-- y
			if ascii_command(23 downto 16) <= x"39" then
				hex_command.y <= ascii_command(19 downto 16);
			else
				hex_command.y <= ascii_command(19 downto 16) + 9;
			end if;

			-- piece id
			hex_command.name <= ascii_command(12 downto 8) - 1;

			-- rotation
			hex_command.rotation <= ascii_command(2 downto 0);
		end if;

	end process;

end Behavioral;

