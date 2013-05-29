----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:23:42 04/04/2013 
-- Design Name: 
-- Module Name:    game_state - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.types.all;

entity game_state is
	Port(
		clk             : in  std_logic;
		rst             : in  std_logic;
		x               : in  std_logic_vector(3 downto 0);
		y               : in  std_logic_vector(3 downto 0);
		tile            : in  std_logic_vector(4 downto 0);
		player          : in  std_logic;
		pieces_on_board : out std_logic_vector(20 downto 0);

		piece_bitmap    : in  board_window_7;
		do_write        : in  std_logic;
		write_ready     : out std_logic;


--debug
		CONT : in std_logic;
		LEDS : out std_logic_vector(7 downto 0);
		SW : in std_logic_vector(3 downto 0);

		block_x         : in  std_logic_vector(3 downto 0);
		block_y         : in  std_logic_vector(3 downto 0);
		block_value     : out board_piece
	);

end game_state;
architecture Behavioral of game_state is
	signal curr_board : board := (others => (others => EMPTY));

	type memory_state is (IDLE, WRITING);
	signal current_state : memory_state := IDLE;

	signal sig_piece_bitmap : board_window_7               := (others => (others => EMPTY));
	signal sig_x            : std_logic_vector(3 downto 0) := (others => '0');
	signal sig_y            : std_logic_vector(3 downto 0) := (others => '0');

	signal sig_state : std_logic_vector(1 downto 0);

	signal i : integer := -3;
	signal j : integer := -3;
begin
	place_piece : process(clk, rst, x,y,tile,sig_x,sig_y, sig_state) is
	begin
		if rst = '1' then
			for reset_i in 0 to 13 loop
				for reset_j in 0 to 13 loop
					curr_board(reset_j, reset_i) <= EMPTY;
				end loop;
			end loop;
			curr_board(9, 9) <= ACTIVE;

			--curr_board      <= (others => (others => EMPTY));
			pieces_on_board <= (others => '0');
			write_ready     <= '0';

			i <= -3;
			j <= -3;
			sig_state <= "10";

			current_state <= IDLE;
		elsif rising_edge(clk) then
--			sig_state <= "00";
			case current_state is
				when IDLE =>
					write_ready <= '1';
					if do_write = '1'  then -- and CONT = '1'
						sig_state <= "01";

						if player = '0' then
							pieces_on_board(conv_integer(tile)) <= '1';
						end if;

						write_ready <= '0';

						sig_piece_bitmap <= piece_bitmap;
						sig_x            <= x;
						sig_y            <= y;

						current_state <= WRITING;
						i             <= -3;
						j             <= -3;

					end if;
				when WRITING =>
					if sig_y + i > 0 and sig_y + i <= 14 then
						if sig_x + j > 0 and sig_x + j <= 14 then
							if sig_piece_bitmap(i + 3, j + 3) > curr_board(conv_integer(sig_y + i - 1), conv_integer(sig_x + j - 1)) then
								curr_board(conv_integer(sig_y + i - 1), conv_integer(sig_x + j - 1)) <= sig_piece_bitmap(i + 3, j + 3);
							end if;
						end if;
					end if;


					if i < 3 then
						i <= i + 1;
					else
						if j < 3 then
							i <= -3;
							j <= j + 1;
						elsif do_write = '0' then --else --
							sig_state <= "10";
							current_state <= IDLE;
							write_ready   <= '1';
						end if;
					end if;
			end case;

		end if;
	end process;

	block_value <= curr_board(conv_integer(block_y), conv_integer(block_x)) when block_x >= 0 and block_x <= 13 and block_y >= 0 and block_y <= 13 else
		OCCUPIED;
		
		
	process(SW) is
	begin
	case(SW) is
		when "0000" =>
			LEDS <= "000000" & sig_state;	
		when "0001" => 
			LEDS <= x & y;
		when "0010" =>
			LEDS <= "000" & tile;
		when "0011" => 
			LEDS <= sig_x & sig_y;
		when others =>
			LEDS <= (others => '0');
	end case;
	end process;
		
	
		
end Behavioral;

