library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

use work.types.all;

entity cmd_hex_to_ascii is
	Port(    hex_command   : in  move;
		 flip_board    : in  std_logic;
		 ascii_command : out std_logic_vector(31 downto 0));
end cmd_hex_to_ascii;

architecture Behavioral of cmd_hex_to_ascii is
	signal hex_command_flipped : move;

	type possible_flips is array (0 to 7) of std_logic_vector(2 downto 0);
	constant flips : possible_flips := (
		"100",
		"101",
		"110",
		"111",
		"000",
		"001",
		"010",
		"011"
	);
begin
	process(hex_command, flip_board)
	begin
		if flip_board = '0' then
			hex_command_flipped <= hex_command;
		else
			hex_command_flipped.x        <= 15 - hex_command.x;
			hex_command_flipped.y        <= 15 - hex_command.y;
			hex_command_flipped.name     <= hex_command.name;
			hex_command_flipped.rotation <= flips(conv_integer(hex_command.rotation));
		end if;
	end process;

	process(hex_command_flipped)
	begin
		if hex_command.x = 0 and hex_command.y = 0 then
			-- pass (0000)
			ascii_command <= x"30303030";
		else
			-- x
			if hex_command_flipped.x <= 9 then
				ascii_command(31 downto 24) <= hex_command_flipped.x + x"30";
			else
				ascii_command(31 downto 24) <= hex_command_flipped.x + x"61" - 10;
			end if;

			-- y
			if hex_command_flipped.y <= 9 then
				ascii_command(23 downto 16) <= hex_command_flipped.y + x"30";
			else
				ascii_command(23 downto 16) <= hex_command_flipped.y + x"61" - 10;
			end if;

			-- piece_id
			ascii_command(15 downto 8) <= hex_command_flipped.name + x"61";

			-- rotation
			ascii_command(7 downto 0) <= hex_command_flipped.rotation + x"30";
		end if;

	end process;

end Behavioral;
