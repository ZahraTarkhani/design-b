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

		 best_move       : out std_logic_vector(15 downto 0);
		 done            : out std_logic);
end move_generator;

architecture Behavioral of move_generator is
	type generator_stream is (IDLE, WAIT_FOR_MOVE, PROCESS_MOVE);
	signal current_state : generator_stream := IDLE;

	signal sig_old_our_move   : std_logic := '0';
	signal sig_current_window : board_window_5;
	signal move_id            : integer   := 0;

	constant move_list_len : integer := 102;
	type possible_move is record
		bitmap   : std_logic_vector(24 downto 0);
		name     : std_logic_vector(4 downto 0);
		rotation : std_logic_vector(2 downto 0);
	end record;
	type possible_moves is array (move_list_len - 1 downto 0) of possible_move;
	signal move_list : possible_moves;

	signal current_best_move_id : integer := move_list_len + 1;

	signal sig_valid_move : std_logic;

	signal sig_cur_move_bitmap : std_logic_vector(24 downto 0);

	signal sig_stream_done   : std_logic;
	--signal sig_board_piece   : board_piece;
	signal sig_rst_stream    : std_logic;
	signal sig_next_stream   : std_logic := '0';
	signal sig_stream_window : board_window_5;
	signal sig_stream_ready  : std_logic;

	signal sig_stream_x : std_logic_vector(3 downto 0);
	signal sig_stream_y : std_logic_vector(3 downto 0);

begin
	process(clk, rst, our_move) is
	begin
		if rst = '1' then
			best_move      <= (others => '0');
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

				best_move            <= (others => '0');
				current_best_move_id <= move_list_len + 1;
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

							move_id       <= 0;
							current_state <= PROCESS_MOVE;
						end if;
					when PROCESS_MOVE =>
						if pieces_on_board(conv_integer(move_list(move_id).name)) = '0' then
							if sig_valid_move = '1' then
								best_move <= (sig_stream_x + 1) & (sig_stream_y + 1) & move_list(move_id).name & move_list(move_id).rotation;

								current_best_move_id <= move_id;

								if sig_stream_done = '1' or move_id = 0 then
									done          <= '1';
									current_state <= IDLE;
								elsif sig_stream_ready = '1' then
									sig_next_stream    <= '1';
									sig_current_window <= sig_stream_window;

									move_id       <= 0;
									current_state <= PROCESS_MOVE;
								else
									current_state <= WAIT_FOR_MOVE;
								end if;
							end if;
						end if;

						if move_id < move_list_len - 1 and move_id + 1 < current_best_move_id then
							move_id <= move_id + 1;
						else
							if sig_stream_done = '1' then
								done          <= '1';
								current_state <= IDLE;
							elsif sig_stream_ready = '1' then
								sig_next_stream    <= '1';
								sig_current_window <= sig_stream_window;

								move_id       <= 0;
								current_state <= PROCESS_MOVE;
							else
								current_state <= WAIT_FOR_MOVE;
							end if;
						end if;
				end case;
			end if;
		end if;
	end process;

	sig_cur_move_bitmap <= move_list(move_id).bitmap;
	move_checker : entity work.valid_place_5x5_window
		port map(
			window_5x5  => sig_current_window,
			piece_5x5   => sig_cur_move_bitmap,
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

	move_list <= (
			-- Piece A(0)
			("00000" & "00000" & "00100" & "00000" & "00000",
				"00000", "000"
			),

			-- Piece B(0)
			("00000" & "00000" & "00100" & "00100" & "00000",
				"00001", "000"
			),

			-- Piece B(2)
			("00000" & "00000" & "01100" & "00000" & "00000",
				"00001", "010"
			),

			-- Piece B(3)
			("00000" & "00000" & "00110" & "00000" & "00000",
				"00001", "011"
			),

			-- Piece B(4)
			("00000" & "00100" & "00100" & "00000" & "00000",
				"00001", "100"
			),

			-- Piece C(0)
			("00000" & "00100" & "00100" & "00100" & "00000",
				"00010", "000"
			),

			-- Piece C(2)
			("00000" & "00000" & "01110" & "00000" & "00000",
				"00010", "010"
			),

			-- Piece D(0)
			("00000" & "00100" & "00110" & "00000" & "00000",
				"00011", "000"
			),

			-- Piece D(1)
			("00000" & "00100" & "01100" & "00000" & "00000",
				"00011", "001"
			),

			-- Piece D(2)
			("00000" & "00000" & "00110" & "00100" & "00000",
				"00011", "010"
			),

			-- Piece D(3)
			("00000" & "00000" & "01100" & "00100" & "00000",
				"00011", "011"
			),

			-- Piece E(0)
			("00000" & "00100" & "00100" & "00100" & "00100",
				"00100", "000"
			),

			-- Piece E(2)
			("00000" & "00000" & "11110" & "00000" & "00000",
				"00100", "010"
			),

			-- Piece E(3)
			("00000" & "00000" & "01111" & "00000" & "00000",
				"00100", "011"
			),

			-- Piece E(4)
			("00100" & "00100" & "00100" & "00100" & "00000",
				"00100", "100"
			),

			-- Piece F(0)
			("00000" & "00100" & "00100" & "01100" & "00000",
				"00101", "000"
			),

			-- Piece F(1)
			("00000" & "00100" & "00100" & "00110" & "00000",
				"00101", "001"
			),

			-- Piece F(2)
			("00000" & "01000" & "01110" & "00000" & "00000",
				"00101", "010"
			),

			-- Piece F(3)
			("00000" & "00010" & "01110" & "00000" & "00000",
				"00101", "011"
			),

			-- Piece F(4)
			("00000" & "00110" & "00100" & "00100" & "00000",
				"00101", "100"
			),

			-- Piece F(5)
			("00000" & "01100" & "00100" & "00100" & "00000",
				"00101", "101"
			),

			-- Piece F(6)
			("00000" & "00000" & "01110" & "00010" & "00000",
				"00101", "110"
			),

			-- Piece F(7)
			("00000" & "00000" & "01110" & "01000" & "00000",
				"00101", "111"
			),

			-- Piece G(0)
			("00000" & "00100" & "00110" & "00100" & "00000",
				"00110", "000"
			),

			-- Piece G(1)
			("00000" & "00100" & "01100" & "00100" & "00000",
				"00110", "001"
			),

			-- Piece G(2)
			("00000" & "00000" & "01110" & "00100" & "00000",
				"00110", "010"
			),

			-- Piece G(6)
			("00000" & "00100" & "01110" & "00000" & "00000",
				"00110", "110"
			),

			-- Piece H(0)
			("00000" & "00000" & "00110" & "00110" & "00000",
				"00111", "000"
			),

			-- Piece H(1)
			("00000" & "00000" & "01100" & "01100" & "00000",
				"00111", "001"
			),

			-- Piece H(4)
			("00000" & "01100" & "01100" & "00000" & "00000",
				"00111", "100"
			),

			-- Piece H(5)
			("00000" & "00110" & "00110" & "00000" & "00000",
				"00111", "101"
			),

			-- Piece I(0)
			("00000" & "00000" & "01100" & "00110" & "00000",
				"01000", "000"
			),

			-- Piece I(1)
			("00000" & "00000" & "00110" & "01100" & "00000",
				"01000", "001"
			),

			-- Piece I(2)
			("00000" & "00100" & "01100" & "01000" & "00000",
				"01000", "010"
			),

			-- Piece I(3)
			("00000" & "00100" & "00110" & "00010" & "00000",
				"01000", "011"
			),

			-- Piece I(4)
			("00000" & "01100" & "00110" & "00000" & "00000",
				"01000", "100"
			),

			-- Piece I(5)
			("00000" & "00110" & "01100" & "00000" & "00000",
				"01000", "101"
			),

			-- Piece I(6)
			("00000" & "00010" & "00110" & "00100" & "00000",
				"01000", "110"
			),

			-- Piece I(7)
			("00000" & "01000" & "01100" & "00100" & "00000",
				"01000", "111"
			),

			-- Piece J(0)
			("00100" & "00100" & "00100" & "00100" & "00100",
				"01001", "000"
			),

			-- Piece J(2)
			("00000" & "00000" & "11111" & "00000" & "00000",
				"01001", "010"
			),

			-- Piece K(0)
			("00100" & "00100" & "00100" & "01100" & "00000",
				"01010", "000"
			),

			-- Piece K(1)
			("00100" & "00100" & "00100" & "00110" & "00000",
				"01010", "001"
			),

			-- Piece K(2)
			("00000" & "01000" & "01111" & "00000" & "00000",
				"01010", "010"
			),

			-- Piece K(3)
			("00000" & "00010" & "11110" & "00000" & "00000",
				"01010", "011"
			),

			-- Piece K(4)
			("00000" & "00110" & "00100" & "00100" & "00100",
				"01010", "100"
			),

			-- Piece K(5)
			("00000" & "01100" & "00100" & "00100" & "00100",
				"01010", "101"
			),

			-- Piece K(6)
			("00000" & "00000" & "11110" & "00010" & "00000",
				"01010", "110"
			),

			-- Piece K(7)
			("00000" & "00000" & "01111" & "01000" & "00000",
				"01010", "111"
			),

			-- Piece L(0)
			("00100" & "00100" & "01100" & "01000" & "00000",
				"01011", "000"
			),

			-- Piece L(1)
			("00100" & "00100" & "00110" & "00010" & "00000",
				"01011", "001"
			),

			-- Piece L(2)
			("00000" & "01100" & "00111" & "00000" & "00000",
				"01011", "010"
			),

			-- Piece L(3)
			("00000" & "00110" & "11100" & "00000" & "00000",
				"01011", "011"
			),

			-- Piece L(4)
			("00000" & "00010" & "00110" & "00100" & "00100",
				"01011", "100"
			),

			-- Piece L(5)
			("00000" & "01000" & "01100" & "00100" & "00100",
				"01011", "101"
			),

			-- Piece L(6)
			("00000" & "00000" & "11100" & "00110" & "00000",
				"01011", "110"
			),

			-- Piece L(7)
			("00000" & "00000" & "00111" & "01100" & "00000",
				"01011", "111"
			),

			-- Piece M(0)
			("00000" & "00100" & "01100" & "01100" & "00000",
				"01100", "000"
			),

			-- Piece M(1)
			("00000" & "00100" & "00110" & "00110" & "00000",
				"01100", "001"
			),

			-- Piece M(2)
			("00000" & "01100" & "01110" & "00000" & "00000",
				"01100", "010"
			),

			-- Piece M(3)
			("00000" & "00110" & "01110" & "00000" & "00000",
				"01100", "011"
			),

			-- Piece M(4)
			("00000" & "00110" & "00110" & "00100" & "00000",
				"01100", "100"
			),

			-- Piece M(5)
			("00000" & "01100" & "01100" & "00100" & "00000",
				"01100", "101"
			),

			-- Piece M(6)
			("00000" & "00000" & "01110" & "00110" & "00000",
				"01100", "110"
			),

			-- Piece M(7)
			("00000" & "00000" & "01110" & "01100" & "00000",
				"01100", "111"
			),

			-- Piece N(0)
			("00000" & "01100" & "00100" & "01100" & "00000",
				"01101", "000"
			),

			-- Piece N(1)
			("00000" & "00110" & "00100" & "00110" & "00000",
				"01101", "001"
			),

			-- Piece N(2)
			("00000" & "01010" & "01110" & "00000" & "00000",
				"01101", "010"
			),

			-- Piece N(6)
			("00000" & "00000" & "01110" & "01010" & "00000",
				"01101", "110"
			),

			-- Piece O(0)
			("00000" & "00100" & "00110" & "00100" & "00100",
				"01110", "000"
			),

			-- Piece O(1)
			("00000" & "00100" & "01100" & "00100" & "00100",
				"01110", "001"
			),

			-- Piece O(2)
			("00000" & "00000" & "11110" & "00100" & "00000",
				"01110", "010"
			),

			-- Piece O(3)
			("00000" & "00000" & "01111" & "00100" & "00000",
				"01110", "011"
			),

			-- Piece O(4)
			("00100" & "00100" & "01100" & "00100" & "00000",
				"01110", "100"
			),

			-- Piece O(5)
			("00100" & "00100" & "00110" & "00100" & "00000",
				"01110", "101"
			),

			-- Piece O(6)
			("00000" & "00100" & "01111" & "00000" & "00000",
				"01110", "110"
			),

			-- Piece O(7)
			("00000" & "00100" & "11110" & "00000" & "00000",
				"01110", "111"
			),

			-- Piece P(0)
			("00000" & "00100" & "00100" & "01110" & "00000",
				"01111", "000"
			),

			-- Piece P(2)
			("00000" & "01000" & "01110" & "01000" & "00000",
				"01111", "010"
			),

			-- Piece P(3)
			("00000" & "00010" & "01110" & "00010" & "00000",
				"01111", "011"
			),

			-- Piece P(4)
			("00000" & "01110" & "00100" & "00100" & "00000",
				"01111", "100"
			),

			-- Piece Q(0)
			("00100" & "00100" & "00111" & "00000" & "00000",
				"10000", "000"
			),

			-- Piece Q(1)
			("00100" & "00100" & "11100" & "00000" & "00000",
				"10000", "001"
			),

			-- Piece Q(2)
			("00000" & "00000" & "00111" & "00100" & "00100",
				"10000", "010"
			),

			-- Piece Q(3)
			("00000" & "00000" & "11100" & "00100" & "00100",
				"10000", "011"
			),

			-- Piece R(0)
			("00000" & "01100" & "00110" & "00010" & "00000",
				"10001", "000"
			),

			-- Piece R(1)
			("00000" & "00110" & "01100" & "01000" & "00000",
				"10001", "001"
			),

			-- Piece R(2)
			("00000" & "00010" & "00110" & "01100" & "00000",
				"10001", "010"
			),

			-- Piece R(3)
			("00000" & "01000" & "01100" & "00110" & "00000",
				"10001", "011"
			),

			-- Piece S(0)
			("00000" & "01000" & "01110" & "00010" & "00000",
				"10010", "000"
			),

			-- Piece S(1)
			("00000" & "00010" & "01110" & "01000" & "00000",
				"10010", "001"
			),

			-- Piece S(2)
			("00000" & "00110" & "00100" & "01100" & "00000",
				"10010", "010"
			),

			-- Piece S(3)
			("00000" & "01100" & "00100" & "00110" & "00000",
				"10010", "011"
			),

			-- Piece T(0)
			("00000" & "01000" & "01110" & "00100" & "00000",
				"10011", "000"
			),

			-- Piece T(1)
			("00000" & "00010" & "01110" & "00100" & "00000",
				"10011", "001"
			),

			-- Piece T(2)
			("00000" & "00110" & "01100" & "00100" & "00000",
				"10011", "010"
			),

			-- Piece T(3)
			("00000" & "01100" & "00110" & "00100" & "00000",
				"10011", "011"
			),

			-- Piece T(4)
			("00000" & "00100" & "01110" & "00010" & "00000",
				"10011", "100"
			),

			-- Piece T(5)
			("00000" & "00100" & "01110" & "01000" & "00000",
				"10011", "101"
			),

			-- Piece T(6)
			("00000" & "00100" & "00110" & "01100" & "00000",
				"10011", "110"
			),

			-- Piece T(7)
			("00000" & "00100" & "01100" & "00110" & "00000",
				"10011", "111"
			),

			-- Piece U(0)
			("00000" & "00100" & "01110" & "00100" & "00000",
				"10100", "000"
			));
end Behavioral;

