----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:10:01 04/10/2013 
-- Design Name: 
-- Module Name:    blokus - Behavioral 
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

use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity blokus is
	Port(clk                     : in  std_logic;
		 reset                   : in  std_logic;
		 cmd_command             : in  move;
		 sig_write               : in  std_logic;
		 sig_player              : in  std_logic;
		 sig_write_ready         : out std_logic;

		 --debug
		 CONT                    : in  std_logic;
		 LEDS                    : out std_logic_vector(7 downto 0);
		 SW                      : in  std_logic_vector(3 downto 0);

		 sig_our_move            : in  std_logic;
		 sig_best_move           : out move;
		 sig_state_debug : in std_logic_vector (7 downto 0);
		 sig_move_generator_done : out std_logic);
end blokus;

architecture structural of blokus is
	signal cmd_piece_bitmap : std_logic_vector(24 downto 0);

	signal marker_board_window_7     : board_window_7;
	signal marker_board_opp_window_7 : board_window_7;

	signal sig_block_x         : std_logic_vector(3 downto 0);
	signal sig_block_y         : std_logic_vector(3 downto 0);
	signal sig_board_piece_us  : board_piece;
	signal sig_board_piece_opp : board_piece;

	signal sig_pieces_on_board : std_logic_vector(20 downto 0);
	
	signal sig_best_move_debug : move;

begin
	--cmd_command <= "0101010110010000";  --55r0
	cmd : entity work.command_converter
		port map(command      => cmd_command,
			     piece_bitmap => cmd_piece_bitmap);

	marker : entity work.piece_bitmap_marker
		port map(piece_bitmap            => cmd_piece_bitmap,
			     player                  => sig_player,
			     piece_bitmap_marker_us  => marker_board_window_7,
			     piece_bitmap_marker_opp => marker_board_opp_window_7);

	gstate : entity work.game_state
		port map(
			clk              => clk,
			rst              => reset,
			x                => cmd_command.x,
			y                => cmd_command.y,
			tile             => cmd_command.name,
			player           => sig_player,
			pieces_on_board  => sig_pieces_on_board,
			piece_bitmap     => marker_board_window_7,
			piece_bitmap_opp => marker_board_opp_window_7,
			CONT             => CONT,
			LEDS             => LEDS,
			SW               => SW,
			do_write         => sig_write,
			write_ready      => sig_write_ready,
			block_x          => sig_block_x,
			block_y          => sig_block_y,
			block_value_us   => sig_board_piece_us,
			sig_state_debug => sig_state_debug,
			best_move => sig_best_move_debug,
			block_value_opp  => sig_board_piece_opp);

	sig_best_move <= sig_best_move_debug;

	move_generator : entity work.move_generator
		port map(
			clk             => clk,
			rst             => reset,
			our_move        => sig_our_move,
			board_x         => sig_block_x,
			board_y         => sig_block_y,
			board_value_us  => sig_board_piece_us,
			board_value_opp => sig_board_piece_opp,
			pieces_on_board => sig_pieces_on_board,
			best_move       => sig_best_move_debug,
			done            => sig_move_generator_done);

end structural;

