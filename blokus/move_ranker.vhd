library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.types.all;

entity move_ranker is
	Port(
		our_window      : in  board_window_7;
		opponent_window : in  board_window_7;
		move_window     : in  std_logic_vector(24 downto 0);

		raiting         : out std_logic_vector(31 downto 0)
	);
end entity move_ranker;

architecture structural of move_ranker is

begin


end structural;
