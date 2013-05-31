library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

use work.types.all;

entity board_to_7x7 is
	port(
		clk               : in  std_logic;
		rst               : in  std_logic;

		rst_stream        : in  std_logic;
		next_stream       : in  std_logic;
		stream_window_us  : out board_window_7;
		stream_window_opp : out board_window_7;
		stream_ready      : out std_logic;
		stream_done       : out std_logic;

		stream_x          : out std_logic_vector(3 downto 0);
		stream_y          : out std_logic_vector(3 downto 0);

		board_x           : out std_logic_vector(3 downto 0);
		board_y           : out std_logic_vector(3 downto 0);
		board_value_us    : in  board_piece;
		board_value_opp   : in  board_piece
	);

end entity board_to_7x7;

architecture Behavioral of board_to_7x7 is
	signal stream_loc_x : integer := 0;
	signal stream_loc_y : integer := 0;

	type state_stream is (DONE, RESET, NEW_ROW, LOAD_CELL);
	signal current_state : state_stream := DONE;
	--signal next_state    : state_stream;

	signal sig_stream_ready : std_logic := '0';

	signal cell_x : integer := 0;
	signal cell_y : integer := 0;

	signal stream_window_sig_us     : board_window_7;
	signal stream_window_sig_opp    : board_window_7;
	signal sig_stream_window_active : std_logic := '0';

	type type_active_filter is array (0 to 6) of std_logic_vector(6 downto 0);
	constant active_filter : type_active_filter := (
		"0000000",
		"0001000",
		"0011100",
		"0111110",
		"0011100",
		"0001000",
		"0000000"
	);
begin
	process(clk, rst, rst_stream, next_stream) is
	begin
		if rst = '1' or rst_stream = '1' then
			stream_loc_x     <= 0;
			stream_loc_y     <= 0;
			sig_stream_ready <= '0';
			stream_done      <= '0';
			current_state    <= DONE;

			if rst_stream = '1' then
				current_state <= RESET;
			end if;
		elsif rising_edge(clk) then
			sig_stream_ready <= '0';
			stream_done      <= '0';

			case current_state is
				when DONE =>
					stream_done      <= '1';
					sig_stream_ready <= '1';

				when RESET =>
					stream_loc_x  <= 0;
					stream_loc_y  <= 0;
					current_state <= NEW_ROW;
					cell_x        <= 0;
					cell_y        <= 0;
				when NEW_ROW =>
					stream_window_sig_us(cell_y, cell_x)  <= board_value_us;
					stream_window_sig_opp(cell_y, cell_x) <= board_value_opp;

					if cell_x < 6 then
						cell_x <= cell_x + 1;
					else
						if cell_y < 6 then
							cell_x <= 0;
							cell_y <= cell_y + 1;
						else
							sig_stream_ready <= '1';

							if next_stream = '1' or sig_stream_window_active = '0' or stream_window_sig_us(3, 3) = OCCUPI then
								stream_loc_x <= stream_loc_x + 1;

								sig_stream_ready <= '0';

								current_state <= LOAD_CELL;
								cell_x        <= 6;
								cell_y        <= 0;
							end if;
						end if;
					end if;
				when LOAD_CELL =>
					if cell_y < 7 then
						-- do bitshift
						for i in 1 to 6 loop
							stream_window_sig_us(cell_y, i - 1)  <= stream_window_sig_us(cell_y, i);
							stream_window_sig_opp(cell_y, i - 1) <= stream_window_sig_opp(cell_y, i);
						end loop;

						stream_window_sig_us(cell_y, 6)  <= board_value_us;
						stream_window_sig_opp(cell_y, 6) <= board_value_opp;

						cell_y <= cell_y + 1;
					else
						sig_stream_ready <= '1';
						if next_stream = '1' or sig_stream_window_active = '0' or stream_window_sig_us(3, 3) = OCCUPI then
							cell_y <= 0;

							sig_stream_ready <= '0';

							if stream_loc_x = 13 and stream_loc_y = 13 then
								current_state <= DONE;
							elsif stream_loc_x = 13 then
								stream_loc_x <= 0;
								stream_loc_y <= stream_loc_y + 1;

								current_state <= NEW_ROW;
							else
								stream_loc_x <= stream_loc_x + 1;
							end if;
						end if;
					end if;
			end case;

		--current_state <= next_state;
		end if;

	end process;

	process(stream_window_sig_us) is
	begin
		sig_stream_window_active <= '0';

		for i in 0 to 6 loop
			for j in 0 to 6 loop
				if active_filter(i)(j) = '1' and stream_window_sig_us(i, j) = ACTIVE then
					sig_stream_window_active <= '1';
				end if;
			end loop;
		end loop;
	end process;

	board_x <= conv_std_logic_vector(cell_x + stream_loc_x - 3, 4);
	board_y <= conv_std_logic_vector(cell_y + stream_loc_y - 3, 4);

	stream_x <= conv_std_logic_vector(stream_loc_x, 4);
	stream_y <= conv_std_logic_vector(stream_loc_y, 4);

	stream_window_us  <= stream_window_sig_us;
	stream_window_opp <= stream_window_sig_opp;
	stream_ready      <= sig_stream_ready;

end architecture Behavioral;
