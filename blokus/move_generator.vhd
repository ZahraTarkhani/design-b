----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:17:02 04/12/2013 
-- Design Name: 
-- Module Name:    move_generator - Behavioral 
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

entity move_generator is
	Port(clk             : in  std_logic;
		 rst             : in  std_logic;
		 our_move        : in  std_logic;

		 board_x         : out std_logic_vector(3 downto 0);
		 board_y         : out std_logic_vector(3 downto 0);
		 board_value     : in  board_piece;
		 pieces_on_board : in  std_logic_vector(20 downto 0);

		 best_move       : out move;
		 done            : out std_logic);
end move_generator;

architecture Behavioral of move_generator is
	type generator_stream is (IDLE, WAIT_FOR_MOVE, PROCESS_MOVE);
	signal current_state : generator_stream := IDLE;

	signal sig_old_our_move   : std_logic := '0';
	signal sig_current_window : board_window_5;
	signal move_id            : integer   := 0;

	signal sig_move_list_len : integer;

	signal current_best_move_id : integer := -1;

	signal sig_valid_move : std_logic;

	signal sig_cur_move : possible_move;

	signal sig_stream_done   : std_logic;
	--signal sig_board_piece   : board_piece;
	signal sig_rst_stream    : std_logic;
	signal sig_next_stream   : std_logic := '0';
	signal sig_stream_window : board_window_5;
	signal sig_stream_ready  : std_logic;

	signal sig_stream_x     : std_logic_vector(3 downto 0);
	signal sig_stream_y     : std_logic_vector(3 downto 0);
	signal sig_stream_x_buf : std_logic_vector(3 downto 0);
	signal sig_stream_y_buf : std_logic_vector(3 downto 0);

begin
	process(clk, rst, our_move) is
	begin
		if rst = '1' then
			best_move      <= (x"0", x"0", "00000", "000");
			sig_rst_stream <= '1';
			done           <= '1';

			current_state <= IDLE;
		elsif rising_edge(clk) then
			if sig_old_our_move /= our_move then
				sig_old_our_move <= our_move;
			end if;

			if sig_old_our_move /= our_move and our_move = '1' then
				sig_rst_stream <= '1';
				current_state  <= WAIT_FOR_MOVE;
				done           <= '1';

				best_move            <= (x"0", x"0", "00000", "000");
				current_best_move_id <= sig_move_list_len + 1;
			else
				sig_rst_stream  <= '0';
				done            <= '0';
				sig_next_stream <= '0';

				case current_state is
					when IDLE =>
						done <= '1';

					when WAIT_FOR_MOVE =>
						if sig_stream_done = '1' then
							done          <= '1';
							current_state <= IDLE;
						elsif sig_stream_ready = '1' then
							sig_next_stream    <= '1';
							sig_current_window <= sig_stream_window;
							sig_stream_x_buf   <= sig_stream_x;
							sig_stream_y_buf   <= sig_stream_y;

							move_id       <= 0;
							current_state <= PROCESS_MOVE;
						end if;
					when PROCESS_MOVE =>
						if move_id < sig_move_list_len - 1 and move_id + 1 < current_best_move_id then
							move_id <= move_id + 1;
						else
							if sig_stream_done = '1' then
								done          <= '1';
								current_state <= IDLE;
							elsif sig_stream_ready = '1' then
								sig_next_stream    <= '1';
								sig_current_window <= sig_stream_window;

								sig_stream_x_buf <= sig_stream_x;
								sig_stream_y_buf <= sig_stream_y;

								move_id       <= 0;
								current_state <= PROCESS_MOVE;
							else
								current_state <= WAIT_FOR_MOVE;
							end if;
						end if;
						
						if pieces_on_board(conv_integer(sig_cur_move.name)) = '0' then
							if sig_valid_move = '1' then
								best_move.x          <= sig_stream_x_buf + 1;
								best_move.y          <= sig_stream_y_buf + 1;
								best_move.name       <= sig_cur_move.name;
								best_move.rotation   <= sig_cur_move.rotation;
								current_best_move_id <= move_id;

								if sig_stream_done = '1' or move_id = 0 then
									done          <= '1';
									current_state <= IDLE;
								elsif sig_stream_ready = '1' then
									sig_next_stream    <= '1';
									sig_current_window <= sig_stream_window;

									sig_stream_x_buf <= sig_stream_x;
									sig_stream_y_buf <= sig_stream_y;

									move_id       <= 0;
									current_state <= PROCESS_MOVE;
								else
									current_state <= WAIT_FOR_MOVE;
								end if;
							end if;
						end if;
				end case;
			end if;
		end if;
	end process;

	move_checker : entity work.valid_place_5x5_window
		port map(
			window_5x5  => sig_current_window,
			piece_5x5   => sig_cur_move.bitmap,
			valid_place => sig_valid_move
		);

	get_5x5_window : entity work.board_to_5x5
		port map(
			clk           => clk,
			rst           => rst,
			rst_stream    => sig_rst_stream,
			next_stream   => sig_next_stream,
			stream_window => sig_stream_window,
			stream_ready  => sig_stream_ready,
			stream_done   => sig_stream_done,
			stream_x      => sig_stream_x,
			stream_y      => sig_stream_y,
			board_x       => board_x,
			board_y       => board_y,
			board_value   => board_value
		);

	move_list : entity work.move_list
		port map(
			id            => move_id,
			move          => sig_cur_move,
			move_list_len => sig_move_list_len
		);
end Behavioral;

