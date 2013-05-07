--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package types is
	type board_piece is (EMPTY, ACTIVE, OCCUPIED);
	type board is array (0 to 13, 0 to 13) of board_piece;
	type board_window_5 is array (0 to 4, 0 to 4) of board_piece;
	type board_window_7 is array (0 to 6, 0 to 6) of board_piece;

	type move is record
		x        : std_logic_vector(3 downto 0);
		y        : std_logic_vector(3 downto 0);
		name     : std_logic_vector(4 downto 0);
		rotation : std_logic_vector(2 downto 0);
	end record;

	type possible_move is record
		bitmap   : std_logic_vector(24 downto 0);
		name     : std_logic_vector(4 downto 0);
		rotation : std_logic_vector(2 downto 0);
	end record;
end types;
