library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

use work.types.all;

entity move_ranker is
	Port(
		our_window      : in  board_window_7;
		opponent_window : in  board_window_7;
		move_bitmap     : in  std_logic_vector(24 downto 0);

		rating          : out integer
	);
end entity move_ranker;

architecture structural of move_ranker is
	constant peice_count_weighting             : integer := 7;
	constant overlap_count_weighting           : integer := 7;
	constant our_active_squeres_weighting      : integer := 12;
	constant opp_active_squeres_weighting      : integer := 12;
	constant our_unblockable_squeres_weighting : integer := 24;
	constant opp_unblockable_squeres_weighting : integer := -24;

	signal peice_count             : integer range 0 to 5;
	signal overlap_count           : integer range 0 to 15;
	signal our_active_squeres      : integer range 0 to 8;
	signal opp_active_squeres      : integer range 0 to 5;
	signal our_unblockable_squeres : integer range 0 to 8;
	signal opp_unblockable_squeres : integer range 0 to 5;

	signal move_window_us  : board_window_7;
	signal move_window_opp : board_window_7;
begin
	rating <= (peice_count * peice_count_weighting) +
			(overlap_count * overlap_count_weighting) +
			(our_active_squeres * our_active_squeres_weighting) +
			(opp_active_squeres * opp_active_squeres_weighting) +
			(our_unblockable_squeres * our_unblockable_squeres_weighting) + 
			(opp_unblockable_squeres * opp_unblockable_squeres_weighting);

	-- count the number of blocks in a peice
	process(move_bitmap)
		variable count : integer := 0;
	begin
		count := 0;
		for i in move_bitmap'range loop
			if move_bitmap(i) = '1' then
				count := count + 1;
			end if;
		end loop;

		peice_count <= count;
	end process;
	
	-- count the amount of overlap our move has
	process(move_window_us, our_window)
		variable count : integer := 0;
	begin
		count := 0;
		for i in 0 to 6 loop
			for j in 0 to 6 loop
				if move_window_us(i, j) = OCCUPI and our_window(i, j) = OCCUPI then
					count := count + 1;
				end if;
			end loop;
		end loop;

		overlap_count <= count;
	end process;

	-- count the number of acive squres are created for us
	process(move_window_us, our_window)
		variable count : integer := 0;
	begin
		count := 0;
		for i in 0 to 6 loop
			for j in 0 to 6 loop
				if move_window_us(i, j) = ACTIVE and our_window(i, j) = EMPTY then
					count := count + 1;
--				elsif move_window_us(i, j) = OCCUPI and our_window(i, j) = ACTIVE then
--					count := count - 1;
				end if;
			end loop;
		end loop;

		our_active_squeres <= count;
	end process;


	-- count the number of active squeres our opponet looses
	process(move_window_opp, opponent_window)
		variable count : integer := 0;
	begin
		count := 0;
		for i in 0 to 6 loop
			for j in 0 to 6 loop
				if move_window_opp(i, j) = OCCUPI and opponent_window(i, j) = ACTIVE then
					count := count + 1;
				end if;
			end loop;
		end loop;

		opp_active_squeres <= count;
	end process;

	-- count the number of un-blockable squere we gain
	process(move_window_us, move_window_opp, our_window, opponent_window)
		variable count : integer := 0;
	begin
		count := 0;
		for i in 0 to 6 loop
			for j in 0 to 6 loop
				if move_window_us(i, j) = ACTIVE and opponent_window(i, j) = OCCUPI and our_window(i, j) = EMPTY then
					count := count + 1;
--				elsif move_window_us(i, j) = OCCUPI and opponent_window(i, j) = OCCUPI and our_window(i, j) = ACTIVE then
--					count := count - 1;
				end if;
			end loop;
		end loop;

		our_unblockable_squeres <= count;
	end process;

	-- count the number of unblockbale squeres the oponent looses
	process(move_window_us, move_window_opp, our_window, opponent_window)
		variable count : integer := 0;
	begin
		count := 0;
		for i in 0 to 6 loop
			for j in 0 to 6 loop
				if opponent_window(i, j) = ACTIVE and move_window_opp(i, j) /= OCCUPI and
						move_window_us(i, j) = OCCUPI and our_window(i, j) /= OCCUPI then
					count := count + 1;
				end if;
			end loop;
		end loop;

		opp_unblockable_squeres <= count;
	end process;

	marker : entity work.piece_bitmap_marker
		port map(piece_bitmap            => move_bitmap,
			     player                  => '0',
			     piece_bitmap_marker_us  => move_window_us,
			     piece_bitmap_marker_opp => move_window_opp);

end structural;


