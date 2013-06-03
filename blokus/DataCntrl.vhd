library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DataCntrl is
	Port(
		txd           : out std_logic := '1'; -- UART transfer pin
		rxd           : in  std_logic := '1'; -- UART read pin
		clk           : in  std_logic;  -- 50MHz Clk
		rst           : in  std_logic := '0'; -- reset

		--interact with move generator
		net_move_in   : in  std_logic_vector(31 downto 0);

		net_big_reset : out std_logic;
		net_cmd_out   : out std_logic_vector(31 downto 0);
		net_cmd_out_2 : out std_logic_vector(31 downto 0);

		big_recv      : out std_logic;
		small_recv    : out std_logic;
		our_move      : out std_logic;

		do_send_move  : in  std_logic;

		flip_board    : out std_logic;

		state_debug   : out std_logic_vector(7 downto 0)
	);
end DataCntrl;

architecture Behavioral of DataCntrl is
	-- rs232 signals
	signal sig_txd_do_send : std_logic;
	signal sig_txd_buf     : std_logic_vector(7 downto 0);
	signal sig_txd_done    : std_logic;
	signal sig_rxd_ready   : std_logic;
	signal sig_rxd_buf     : std_logic_vector(7 downto 0);

	type code_array is array (0 to 8) of std_logic_vector(7 downto 0);
	signal sig_code_array : code_array;

	signal sig_big_recv   : std_logic := '0';
	signal sig_small_recv : std_logic := '0';
	signal sig_our_move   : std_logic := '0';

	signal sig_init_rst : std_logic := '0';

	signal sig_send_team_code : std_logic := '0';
	--Team Code Hardcoded
	type team_array is array (0 to 2) of std_logic_vector(7 downto 0);
	constant sig_team_array : team_array := ("00110001", "01010011", "01000010");

	--Protocol Control Command BYTES
	constant sig_zero  : std_logic_vector := "00110000"; --0
	constant sig_two   : std_logic_vector := "00110010"; --2
	constant sig_three : std_logic_vector := "00110011"; --3
	constant sig_four  : std_logic_vector := "00110100"; --4
	constant sig_five  : std_logic_vector := "00110101"; --5
	constant sig_nine  : std_logic_vector := "00111001"; --9


	type recv_states is (recv_idle, recv_wait, recv_read);
	signal recv_state : recv_states := recv_idle;

	type send_states is (send_idle, send_team_code, send_team_code_wait, send_team_code_done, send_move, send_move_wait, send_move_done);
	signal send_state : send_states := send_idle;


begin
	big_recv   <= sig_big_recv;
	small_recv <= sig_small_recv;
	our_move   <= sig_our_move;

	net_cmd_out   <= sig_code_array(1) & sig_code_array(2) & sig_code_array(3) & sig_code_array(4);
	net_cmd_out_2 <= sig_code_array(5) & sig_code_array(6) & sig_code_array(7) & sig_code_array(8);

	net_big_reset <= sig_init_rst;

	rs232module : entity work.Rs232
		port map(
			clk         => clk,
			rst         => rst,
			txd         => txd,
			txd_do_send => sig_txd_do_send,
			txd_buf     => sig_txd_buf,
			txd_done    => sig_txd_done,
			rxd_raw     => rxd,
			rxd_ready   => sig_rxd_ready,
			rxd_buf     => sig_rxd_buf);
	
--	process(recv_state, send_state) 
--		variable recv_int : std_logic_vector(1 downto 0);
--		variable send_int : std_logic_vector(2 downto 0);
--	begin
--		if recv_state = recv_idle then
--			recv_int := "00";
--		elsif recv_state = recv_wait then
--			recv_int := "01";
--		else
--			recv_int := "10";
--		end if;
--		
--		if send_state = send_idle then
--			send_int := "000";
--		elsif send_state = send_team_code then
--			send_int := "001";
--		elsif send_state = send_team_code_wait then
--			send_int := "010";
--		elsif send_state = send_team_code_done then
--			send_int := "011";
--		elsif send_state = send_move then
--			send_int := "100";
--		elsif send_state = send_move_wait then
--			send_int := "101";
--		else
--			send_int := "110";
--		end if;
--		 _int & send_int & "000";
--	end process;

	state_debug <= sig_rxd_buf;

	process(clk, rst)
		variable num_bytes_to_recive : integer range 0 to 9;
		variable num_bytes_recived   : integer range 0 to 9;
	begin
		if rst = '1' then
			recv_state     <= recv_idle;
			flip_board     <= '0';
			sig_our_move   <= '0';
			sig_big_recv   <= '0';
			sig_small_recv <= '0';
			sig_code_array <= (others => (others => '0'));
		elsif rising_edge(clk) then
			case recv_state is
				when recv_idle =>
					if sig_rxd_ready = '1' then
						sig_our_move       <= '0';
						sig_big_recv       <= '0';
						sig_small_recv     <= '0';
						sig_send_team_code <= '0';
						sig_code_array     <= (others => (others => '0'));

						case sig_rxd_buf is
							when sig_zero =>
								num_bytes_to_recive := 1;
								sig_init_rst        <= '1';
								sig_send_team_code  <= '1';
								flip_board          <= '0';
							when sig_two =>
								num_bytes_to_recive := 2;
							when sig_three =>
								num_bytes_to_recive := 5;
							when sig_four =>
								num_bytes_to_recive := 9;
							when sig_nine =>
								num_bytes_to_recive := 1;
								sig_init_rst        <= '1';
							when others =>
								num_bytes_to_recive := 1;
						end case;

						sig_code_array(0) <= sig_rxd_buf;
						num_bytes_recived := 1;

						recv_state <= recv_wait;
					end if;
				when recv_wait =>
					if sig_rxd_ready = '0' then
						if num_bytes_recived /= num_bytes_to_recive then
							recv_state <= recv_read;
						else
							recv_state <= recv_idle;
						end if;
					end if;
				when recv_read =>
					if sig_rxd_ready = '1' then
						sig_code_array(num_bytes_recived) <= sig_rxd_buf;

						num_bytes_recived := num_bytes_recived + 1;

						if num_bytes_recived = num_bytes_to_recive then
							case sig_code_array(0) is
								when sig_two =>
									if sig_rxd_buf = sig_five then
										flip_board <= '1';
									else
										flip_board <= '0';
									end if;
									sig_our_move <= '1';
								when sig_three =>
									sig_our_move   <= '1';
									sig_small_recv <= '1';
								when sig_four =>
									sig_our_move <= '1';
									sig_big_recv <= '1';
								when others =>
							end case;
						end if;
						recv_state <= recv_wait;
					end if;
			end case;
		end if;
	end process;

	process(clk, rst)
		variable send_code_count : integer range 0 to 4 := 0;
	begin
		if rst = '1' then
			send_state <= send_idle;
			sig_txd_do_send <= '0';
		elsif rising_edge(clk) then
			case send_state is
				when send_idle =>
					sig_txd_do_send <= '0';
					if sig_send_team_code = '1' then
						send_state      <= send_team_code;
						send_code_count := 0;
					elsif do_send_move = '1' then
						send_state      <= send_move;
						send_code_count := 0;
					end if;
				when send_team_code =>
					if sig_txd_done = '1' then
						sig_txd_buf     <= sig_team_array(send_code_count);
						sig_txd_do_send <= '1';

						send_code_count := send_code_count + 1;
						send_state      <= send_team_code_wait;
					end if;
				when send_team_code_wait =>
					if sig_txd_done = '0' then
						sig_txd_do_send <= '0';

						if send_code_count = 3 then
							send_state <= send_team_code_done;
						else
							send_state <= send_team_code;
						end if;
					end if;
				when send_team_code_done =>
					if sig_send_team_code = '0' then
						send_state <= send_idle;
					end if;
				when send_move =>
					if sig_txd_done = '1' then
						case send_code_count is
							when 0 =>
								sig_txd_buf <= net_move_in(31 downto 24);
							when 1 =>
								sig_txd_buf <= net_move_in(23 downto 16);
							when 2 =>
								sig_txd_buf <= net_move_in(15 downto 8);
							when others =>
								sig_txd_buf <= net_move_in(7 downto 0);
						end case;
	
						sig_txd_do_send <= '1';
	
						send_code_count := send_code_count + 1;
						send_state      <= send_move_wait;
					end if;
				when send_move_wait =>
					if sig_txd_done = '0' then
						sig_txd_do_send <= '0';

						if send_code_count = 4 then
							send_state <= send_move_done;
						else
							send_state <= send_move;
						end if;
					end if;
				when send_move_done =>
					if do_send_move = '0' then
						send_state <= send_idle;
					end if;
			end case;
		end if;
	end process;

end Behavioral;