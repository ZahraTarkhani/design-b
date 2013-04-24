----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:43:00 04/17/2013 
-- Design Name: 
-- Module Name:    top - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.types.all;

entity top is
	Port(CLK  : in  STD_LOGIC;
		 RST  : in  STD_LOGIC;
		 TXD  : out STD_LOGIC;
		 RXD  : in  STD_LOGIC;
		 LEDS : out STD_LOGIC_VECTOR(7 downto 0);
		 SW   : in  STD_LOGIC_VECTOR(3 downto 0);
		 CONT : in  STD_LOGIC);
end top;

architecture Behavioral of top is
	type mainState is (stIdle, stPlayer, stPlayer2, stOurMove,  stWriteDown);

	signal stCur  : mainState := stIdle;
	signal stNext : mainState;

	signal sig_write       : std_logic                     := '0';
	signal sig_player      : std_logic                     := '0';
	signal sig_write_ready : std_logic;
	signal cmd_command     : std_logic_vector(15 downto 0) := (others => '0');

	signal sig_cmd1 : std_logic_vector(15 downto 0) := (others => '0');
	signal sig_cmd2 : std_logic_vector(15 downto 0) := (others => '0');

	signal sig_our_move            : std_logic                     := '0';
	signal sig_our_move_serial     : std_logic                     := '0';
	signal sig_best_move           : std_logic_vector(15 downto 0) := (others => '0');
	signal sig_move_generator_done : std_logic                     := '0';

	signal sig_move_in   : std_logic_vector(31 downto 0) := (others => '0');
	signal sig_opp_move  : std_logic_vector(31 downto 0) := (others => '0');
	signal sig_opp_move2 : std_logic_vector(31 downto 0) := (others => '0');
	signal sig_clk_half : std_logic:= '0';

begin
	cmdHtoA : entity work.cmd_hex_to_ascii
		port map(
			hex_command   => sig_best_move,
			ascii_command => sig_move_in
		);

	cmdAtoH : entity work.cmd_ascii_to_hex
		port map(
			ascii_command => sig_opp_move,
			hex_command   => sig_cmd1
		);

	cmdAtoH2 : entity work.cmd_ascii_to_hex
		port map(
			ascii_command => sig_opp_move2,
			hex_command   => sig_cmd2
		);

	blokus : entity work.blokus
		PORT MAP(
			reset                   => RST,
			clk                     => CLK,
			cmd_command             => cmd_command,
			sig_write               => sig_write,
			sig_player              => sig_player,
			sig_write_ready         => sig_write_ready,
			sig_our_move            => sig_our_move,
			sig_best_move           => sig_best_move,
			sig_move_generator_done => sig_move_generator_done
		);

	serial_control : entity work.DataCntrl
		port map(TXD           => TXD,
			     RXD           => RXD,
			     CLK           => CLK,
			     LEDS          => LEDS,
			     RST           => RST,
			     SW            => SW,
			     CONT          => CONT,

			     --interact with move generator
				  hex_debug => sig_best_move,
			     NET_MOVE_IN   => sig_move_in,
			     NET_CMD_OUT   => sig_opp_move,
			     NET_CMD_OUT_2 => sig_opp_move2,
			     OUR_MOVE      => sig_our_move_serial,
			     GEN_DONE      => sig_move_generator_done
		);

	process(CLK, RST)
	begin
		if (CLK = '1' and CLK'Event) then
			if RST = '1' then
				stCur <= stIdle;
			else
				sig_clk_half <= not sig_clk_half;
				if sig_clk_half = '1' then
					stCur <= stNext;
				end if;
			end if;
		end if;
	end process;

	process(stCur, sig_our_move_serial, sig_write_ready, sig_best_move, sig_move_generator_done, sig_cmd1, sig_opp_move2, sig_cmd2)
	begin
		case stCur is
			when stIdle =>
				sig_player   <= '0';
				sig_write    <= '0';
				cmd_command  <= (others => '0');
				sig_our_move <= '0';
				if sig_our_move_serial = '1' then
					stNext <= stPlayer;
				else
					stNext <= stIdle;
				end if;

			when stPlayer =>
				sig_player   <= '1';
				sig_write    <= '1';
				cmd_command  <= sig_cmd1;
				sig_our_move <= '0';
				if sig_write_ready = '1' then
					if sig_opp_move2 = "00000000000000000000000000000000" then
						stNext <= stOurMove;
					else
						stNext <= stPlayer2;
					end if;
				else
					stNext <= stPlayer;
				end if;
				
--				stNext       <= stPlayerIdle;
				

--			when stPlayerIdle =>
--				sig_player   <= '0';
--				sig_write    <= '0';
--				sig_our_move <= '0';
--				cmd_command  <= (others => '0');


			when stPlayer2 =>
				sig_player   <= '1';
				sig_write    <= '1';
				sig_our_move <= '0';
				cmd_command  <= sig_cmd2;
--c				stNext       <= stPlayerIdle2;
				if sig_write_ready = '1' then
					stNext <= stOurMove;
				else
					stNext <= stPlayer2;
				end if;

--			when stPlayerIdle2 =>
--				sig_player   <= '0';
--				sig_write    <= '0';
--				sig_our_move <= '0';
--				cmd_command  <= (others => '0');
--				if sig_write_ready = '1' then
--					stNext <= stOurMove;
--				else
--					stNext <= stPlayerIdle2;
--				end if;

			when stOurMove =>
				sig_player   <= '0';
				sig_write    <= '0';
				sig_our_move <= '1';
				cmd_command  <= (others => '0');
--				stNext       <= stOurMove2;
				if sig_move_generator_done = '1' then
					stNext <= stWriteDown;
				else
					stNext <= stOurMove;
				end if;


--			when stOurMove2 =>
--				sig_player   <= '0';
--				sig_write    <= '0';
--				sig_our_move <= '0';
--				cmd_command  <= (others => '0');
--				if sig_move_generator_done = '1' then
--					stNext <= stWriteDown;
--				else
--					stNext <= stOurMove2;
--				end if;

			when stWriteDown =>
				sig_player   <= '0';
				sig_write    <= '1';
				sig_our_move <= '0';
				cmd_command  <= sig_best_move;
--				stNext       <= stWriteDown2;
				if sig_write_ready = '1' then
					stNext <= stIdle;
				else
					stNext <= stWriteDown;
				end if;


--			when stWriteDown2 =>
--				sig_player   <= '0';
--				sig_write    <= '0';
--				sig_our_move <= '0';
--				cmd_command  <= (others => '0');
--				if sig_write_ready = '1' then
--					stNext <= stIdle;
--				else
--					stNext <= stWriteDown2;
--				end if;

		end case;
	end process;

end Behavioral;

