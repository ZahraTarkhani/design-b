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
end types;
