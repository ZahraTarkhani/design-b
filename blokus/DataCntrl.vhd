-------------------------------------------------------------------------
-- main.vhd
-------------------------------------------------------------------------
-- Author:  Dan Pederson
--          Copyright 2004 Digilent, Inc.
-------------------------------------------------------------------------
-- Description:  	This file tests the included UART component by 
--					sending data in serial form through the UART to
--					change it to parallel form, and then sending the
--					resultant data back through the UART to determine if
--					the signal is corrupted or not.  When the serial 
--					information is converted into parallel information, 
--					the data byte is displayed on the 8 LEDs on the 
--					system board.  
--
--					NOTE:  Not all mapped signals are used in this test.
--					The signals were mapped to ease the modification of
--					test program.			
-------------------------------------------------------------------------
-- Revision History:
--  	07/30/04 (DanP) Created
--		05/26/05 (DanP) Modified for Pegasus board/Updated commenting style
--		06/07/05	(DanP) LED scancode display added
-------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.types.all;

-------------------------------------------------------------------------
--
--Title:	Main entity
--
--Inputs:	3	:	RXD
--					CLK
--					RST
--
--Outputs:	1	:	TXD
--					LEDS					
--
--Description:	This describes the main entity that tests the included
--				UART component.   The LEDS signals are used to 
--				display the data byte on the LEDs, so it is set equal to 
--				the dbOutSig. Technically, the dbOutSig is the scan code 
--				backwards, which explains why the LEDs are mapped 
--				backwards to the dbOutSig.
--
-------------------------------------------------------------------------
entity DataCntrl is
	Port ( 	TXD		: out std_logic := '1'; -- UART transfer pin
				RXD		: in std_logic 	:= '1'; -- UART read pin
				CLK		: in std_logic; -- 50MHz Clk
				LEDS		: out std_logic_vector (7 downto 0); -- LEDS for debugging
				RST		: in std_logic	:= '0'; -- reset
				SW			: in std_logic_vector(3 downto 0); -- switches for debugging
				CONT 		: in std_logic := '0';
				
				--interact with move generator
				NET_MOVE_IN : in std_logic_vector(31 downto 0);
				NET_CMD_OUT : out std_logic_vector(31 downto 0);
				NET_CMD_OUT_2 : out std_logic_vector(31 downto 0);
				OUR_MOVE : out std_logic;
				GEN_DONE : in std_logic
				);
end DataCntrl;

architecture Behavioral of DataCntrl is

-------------------------------------------------------------------------
-- Local Component, Type, and Signal declarations.								
-------------------------------------------------------------------------

-------------------------------------------------------------------------
--
--Title:	Component Declarations
--
--Description:	This component is the UART that is to be tested.  
--				The UART code can be found in the included 
--				RS232RefComp.vhd file.
--
-------------------------------------------------------------------------
component RS232RefComp
   Port (  	TXD 	: out	std_logic :='1';--
				RXD 	: in	std_logic;					
				CLK 	: in	std_logic;							
				DBIN 	: in	std_logic_vector (7 downto 0);
				DBOUT 	: out	std_logic_vector (7 downto 0);
				RDA		: inout	std_logic;							
				TBE		: inout	std_logic 	:= '1';				
				RD		: in	std_logic;							
				WR		: in	std_logic;							
				PE		: out	std_logic;							
				FE		: out	std_logic;							
				OE		: out	std_logic;											
				RST		: in	std_logic	:= '0');				
end component;	

component timer is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           time_int : out  integer;
           time_dec : out  integer;
			  test_leds: out std_logic_vector(7 downto 0)
			  );
end component;


-------------------------------------------------------------------------
--
--Title:	Type Declarations
--
--Description:	There is one state machine used in this program, called 
--				the mainState state machine.  This state machine controls 
--				the flow of data around the UART; allowing for data to be
--				changed from serial to parallel, and then back to serial.
--
-------------------------------------------------------------------------
	type mainState is (
		--stInit,
		stReceive, stIdleReceive,
		stSend, stIdleSend,
		stAction);
-------------------------------------------------------------------------
--
--Title:  Local Signal Declarations
--
--Description:	The signals used by this entity are described below:
--
--				-dbInSig 	:  	This signal is the parallel data input  
--								for the UART
--				-dbOutSig	:	This signal is the parallel data output 
--								for the UART
--      		-rdaSig		:	This signal will get the RDA signal from 
--								the UART
--			 	-tbeSig		:	This signal will get the TBE signal from 
--								the UART
-- 				-rdSig		:	This signal is the RD signal for the UART
-- 				-wrSig		:	This signal is the WR signal for the UART
-- 				-peSig		:	This signal will get the PE signal from 
--								the UART
-- 				-feSig		:	This signal will get the FE signal from 
--								the UART
-- 				-oeSig		:	This signal will get the OE signal from 
--								the UART
--
--				The following signals are used by the main state machine
--				for state control:
--				
--				-stCur, stNext	
--	
-------------------------------------------------------------------------
	signal dbInSig	:	std_logic_vector(7 downto 0);
	signal dbOutSig	:	std_logic_vector(7 downto 0);
	signal rdaSig	:	std_logic;
	signal tbeSig	:	std_logic;
	signal rdSig	:	std_logic;
	signal wrSig	:	std_logic;
	signal peSig	:	std_logic;
	signal feSig	:	std_logic;
	signal oeSig	:	std_logic;
	
	signal stCur	:	mainState := stReceive;
	signal stNext	:	mainState;

	signal sig_int : integer;
	signal sig_dec : integer;
	signal sig_test_leds : std_logic_vector(7 downto 0);
	signal sig_uart_debug : std_logic_vector(7 downto 0);
	signal sig_state_debug : std_logic_vector(7 downto 0) := "00000000";
	signal sig_game_state : std_logic_vector (7 downto 0) := "00000000";
	signal sig_test_rda : std_logic := '0';
	signal sig_big_debug : std_logic := '0';

	signal sig_fake_txd : std_logic;

	type code_array is array(0 to 8) of std_logic_vector(7 downto 0);
	signal sig_code_array : code_array;
	signal sig_code_index : integer range 0 to 8 := 0;
	
	type move_array is array(0 to 3) of std_logic_vector(7 downto 0);
	signal sig_move_array : move_array;
	signal sig_move_index : integer range 0 to 3 := 0;
	
	
	signal sig_read_more : std_logic := '0';
	signal sig_write_more : std_logic := '0';
	--signal sig_make_move : std_logic := '0';
	signal sig_new_data_read : std_logic := '0';
	signal sig_new_data_written : std_logic := '0';
	signal sig_read_done : std_logic := '0';
	signal sig_action_done : std_logic := '0';

--to change, state machine states
	signal sig_cur_cmd : std_logic_vector(2 downto 0) := "000";
--Constants
	constant sig_init_game : std_logic_vector(2 downto 0) := "001";
	constant sig_set_init_pos : std_logic_vector(2 downto 0) := "010";
	constant sig_new_opp_move : std_logic_vector(2 downto 0) := "011";
	constant sig_new_opp_double_move : std_logic_vector(2 downto 0) := "100";
	constant sig_final_stop :std_logic_vector(2 downto 0) := "101";



--Team Code Hardcoded
	type team_array is array (0 to 2) of std_logic_vector(7 downto 0);
	constant sig_team_array : team_array :=  ( "00110001", "01010011", "01000010");
	
--Protocol Control Command BYTES
	constant sig_zero 	: std_logic_vector := "00110000"; --0
	constant sig_two 		: std_logic_vector := "00110010"; --2
	constant sig_three 	: std_logic_vector := "00110011"; --3
	constant sig_four 	: std_logic_vector := "00110100"; --4
	constant sig_nine 	: std_logic_vector := "00111001"; --9
	
------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

--direct signal assignments

--uart debug signals
sig_uart_debug <= sig_test_rda & rdaSig & tbeSig & rdSig & wrSig & peSig & feSig & oeSig;

sig_game_state <= sig_cur_cmd & "00" & sig_big_debug & sig_read_more & sig_write_more;

sig_move_array(0) <= NET_MOVE_IN(31 downto 24);
sig_move_array(1) <= NET_MOVE_IN(23 downto 16);
sig_move_array(2) <= NET_MOVE_IN(15 downto 8);
sig_move_array(3) <= NET_MOVE_IN(7 downto 0);

NET_CMD_OUT <= sig_code_array(1) & sig_code_array(2) & sig_code_array(3) & sig_code_array(4);
NET_CMD_OUT_2 <= sig_code_array(5) & sig_code_array(6) & sig_code_array(7) & sig_code_array(8);
-------------------------------------------------------------------------
--
--Title:		RS232RefComp map 
--
--Description:	This maps the signals and ports in main to the 
--				RS232RefComp.  The TXD, RXD, CLK, and RST of main are
--				directly tied to the TXD, RXD, CLK, and RST of the 
--				RS232RefComp.  The remaining RS232RefComp ports are 
--				mapped to internal signals in main.
--
-------------------------------------------------------------------------
	UART: RS232RefComp port map (	TXD 	=> TXD,--sig_fake_txd,-- 
									RXD 	=> RXD,
									CLK 	=> CLK,
									DBIN 	=> dbInSig,
									DBOUT	=> dbOutSig,
									RDA		=> rdaSig,
									TBE		=> tbeSig,	
									RD		=> rdSig,
									WR		=> wrSig,
									PE		=> peSig,
									FE		=> feSig,
									OE		=> oeSig,
									RST 	=> RST);

	--TXD <= RXD;

	MYTIMER: timer port map(
								clk => CLK,
								reset => RST, 
								time_int => sig_int,
								time_dec => sig_dec,
								test_leds => sig_test_leds
								);
	
	process (CLK, RST, sig_code_array(0), sig_code_index)
		begin
		if (CLK = '1' and CLK'Event) then
			if RST = '0' then
				if sig_code_array(0) = sig_zero then
					sig_read_more <= '0';
					if sig_move_index = 2 then
						sig_write_more <= '0';
					else
						sig_write_more <= '1';
					end if;
					sig_cur_cmd <= sig_init_game;
				elsif sig_code_array(0) = sig_nine then
					sig_read_more <= '0';
					sig_write_more <= '0';
					sig_cur_cmd <= sig_final_stop;
				elsif sig_code_array(0) = sig_two then
					--change
					--sig_write_more <= '0';
					if sig_move_index = 3 then
						sig_write_more <= '0';
					else
						sig_write_more <= '1';
					end if;
					if sig_code_index = 1 then
						sig_read_more <= '0';
					else 
						sig_read_more <= '1';
					end if;
					sig_cur_cmd <= sig_set_init_pos;
				elsif sig_code_array(0) = sig_three then
--					sig_write_more <= '0';
					if sig_move_index = 3 then
						sig_write_more <= '0';
					else
						sig_write_more <= '1';
					end if;
					if sig_code_index = 4 then
						sig_read_more <= '0';
					else 
						sig_read_more <= '1';
					end if;
					sig_cur_cmd <= sig_new_opp_move;
				elsif sig_code_array(0) = sig_four then
--					sig_write_more <= '0';
					if sig_move_index = 3 then
						sig_write_more <= '0';
					else
						sig_write_more <= '1';
					end if;
					if sig_code_index = 8 then
						sig_read_more <= '0';
					else 
						sig_read_more <= '1';
					end if;
					sig_cur_cmd <= sig_new_opp_double_move;	
				else
					sig_read_more <= '0';
					sig_write_more <= '0';
					sig_cur_cmd <= "000";	
			--		sig_big_debug <= '1';
				end if;
			else
					sig_read_more <= '0';
					sig_write_more <= '0';
					sig_cur_cmd <= "000";	
			end if;
		end if;
		end process;




	process (CLK, RST, sig_new_data_read,dbOutSig, sig_new_data_written, sig_action_done)
		begin
		--	
				if RST = '1' or sig_action_done = '1' then
--					sig_code_index <= 0;
					sig_code_array(0) <= "00000000";
					sig_code_array(1) <= "00000000";
					sig_code_array(2) <= "00000000";
					sig_code_array(3) <= "00000000";
					sig_code_array(4) <= "00000000";
					sig_code_array(5) <= "00000000";
					sig_code_array(6) <= "00000000";
					sig_code_array(7) <= "00000000";
					sig_code_array(8) <= "00000000";
				else
--					if (CLK = '1' and CLK'Event) then
						if sig_new_data_read = '1' and sig_new_data_read'Event then
							sig_code_array(sig_code_index) <= dbOutSig;
	--					else
	--						sig_code_array(sig_code_index) <= "00000000";
--						end if;
					end if;
				end if;
		end process;

	process(sig_new_data_read, sig_read_more, RST, sig_action_done, sig_read_done)
		begin
		if RST = '1' or sig_action_done = '1' or sig_read_done = '1' then 
			sig_code_index <= 0;
		else
			if sig_new_data_read = '0' and sig_new_data_read'Event then
				sig_code_index <= sig_code_index + 1;
			end if;
		end if;
		end process;

	process(sig_cur_cmd)
		begin
			case sig_cur_cmd is
			when sig_init_game =>
				dbInSig <= sig_team_array(sig_move_index);
				OUR_MOVE <= '0';
			when sig_final_stop =>
				dbInSig <= "00000000";		
				OUR_MOVE <= '0';				
			when others =>
				OUR_MOVE <= '1';
				dbInSig <= sig_move_array(sig_move_index);		
			end case;
		end process;

	process(sig_new_data_written, RST, sig_action_done)
		begin
		if RST = '1' or sig_action_done = '1' then 
			sig_move_index <= 0;
		else
			if sig_new_data_written = '0' and sig_new_data_written'Event then
				sig_move_index <= sig_move_index + 1;
			end if;
		end if;
		end process;

	
-------------------------------------------------------------------------
--
--Title: Main State Machine controller 
--
--Description:	This process takes care of the Main state machine 
--				movement.  It causes the next state to be evaluated on 
--				each rising edge of CLK.  If the RST signal is strobed, 
--				the state is changed to the default starting state, which 
--				is stReceive.
--
-------------------------------------------------------------------------
	process (CLK, RST)
		begin
			if (CLK = '1' and CLK'Event) then
				if RST = '1' then
					stCur <= stReceive;
				else
					stCur <= stNext;
				end if;
			end if;
		end process;
-------------------------------------------------------------------------
--
--Title: Main State Machine 
--
--Description:	This process defines the next state logic for the Main
--				state machine.  The main state machine controls the data
--				flow for this testing program in order to send and 
--				receive data.
--
-------------------------------------------------------------------------
	process (stCur, rdaSig, dbOutsig, tbeSig, CONT,
				sig_cur_cmd, sig_read_more, sig_write_more, GEN_DONE)
		begin
			case stCur is
-------------------------------------------------------------------------
--
--Title: stReceive state 
--
--Description:	This state waits for the UART to receive data.  While in
--				this state, the rdSig and wrSig are held low to keep the
--				UART from transmitting any data.  Once the rdaSig is set
--				high, data has been received, and is safe to transmit. At
--				this time, the stSend state is loaded, and the dbOutSig 
--				is copied to the dbInSig in order to transmit the newly
--				acquired parallel information.
--
-------------------------------------------------------------------------	
				when stReceive =>
					sig_state_debug <= "00000001";
					rdSig <= '0';
					wrSig <= '0';
					sig_new_data_written <= '0';
					sig_action_done <= '0';
					sig_read_done <= '0';
					if rdaSig = '1' then
						--sig_code_array(0) <= dbOutSig;
--						sig_code_temp <= dbOutSig;
						sig_new_data_read <= '1';
--						if CONT = '1' then
						stNext <= stIdleReceive;
--						else
--							stNext <= stReceive;
--						end if;
					else
						sig_new_data_read <= '0';
						stNext <= stReceive;
					end if;			
					
				when stIdleReceive =>
					sig_state_debug <= "00000011";
					--sig_code_index <= sig_code_index + 1;
					rdSig <= '1';
					wrSig <= '0';
					sig_new_data_written <= '0';
					sig_new_data_read <= '0';
					sig_action_done <= '0';
					sig_read_done <= '0';
					if rdaSig = '0' then
						if sig_read_more = '1' then
							stNext <= stReceive;
						else
							stNext <= stAction;
						end if;
						
						
					else
						stNext <= stIdleReceive;
					end if;
				
				when stAction =>
					rdSig <= '0';
					wrSig <= '0';
					sig_new_data_written <= '0';
					sig_new_data_read <= '0';
					sig_read_done <= '1';
					sig_state_debug <= "00011000";
					sig_action_done <= '0';
					
--					if CONT = '1' then
						if sig_write_more = '1' then 
							if GEN_DONE = '1' then
								stNext <= stSend;
							else
								stNext <= stAction;
							end if;
						else 
							stNext <= stReceive;
						end if;
--					else 
--						stNext <= stAction;
--					end if;
--					
--					if CONT = '1' then
--						stNext <= stReceive;
--						sig_action_done <= '1';
--					else 
--						stNext <= stAction;
--						sig_action_done <= '0';
--					end if;
-------------------------------------------------------------------------
--
--Title: stSend state 
--
--Description:	This state tells the UART to send the parallel 
--				information found in dbInSig.  It does this by strobing 
--				both the rdSig and wrSig signals high.  Once these 
--				signals have been strobed high, the stReceive state is 
--				loaded.
--
-------------------------------------------------------------------------
				when stSend =>
					sig_state_debug <= "10000000";
					rdSig <= '1'; 
					wrSig <= '1';
					sig_action_done <= '0';
					sig_read_done <= '0';
					sig_new_data_read <= '0';
					sig_new_data_written <= '0';

					if tbeSig = '0' then 
						stNext <= stIdleSend;
--						sig_new_data_written <= '1';
--						dbInSig <= "00110011";
						--dbIn <= data to write
					else
						stNext <= stSend;
					end if;
					
				when stIdleSend =>				
					sig_state_debug <= "11000000";
					rdSig <= '0';
					wrSig <= '0';
					
					sig_new_data_read <= '0';
					sig_new_data_written<= '1';
					sig_read_done <= '0';
					if tbeSig = '1' then 
						if sig_write_more = '1' then 
							stNext <= stSend;
							sig_action_done <= '0';
						else 
--							if CONT = '1' then
							stNext <= stReceive;
							sig_action_done <= '1';
--							else
--							stNext <= stIdleSend;
--							sig_action_done <= '0';
--							end if;
						end if;
					else 
						stNext <= stIdleSend;
						sig_action_done <= '0';
					end if;
				when others =>
					sig_state_debug <= "11111111";
					sig_new_data_read <= '0';
					sig_action_done <= '0';
					sig_new_data_written <= '0';
					sig_read_done <= '0';
					rdSig <= '0';
					wrSig <= '0';
					stNext <= stReceive;
			end case;
		end process;
		


-- led debugging
	process (SW, sig_uart_debug, sig_test_leds, dbInSig, dbOutSig, 
	sig_state_debug, sig_game_state, sig_code_array)
		begin
		case SW is
			when "0001" => LEDS <= sig_uart_debug; -- UART signals (see details above in signal assignments)
			when "0011" => LEDS <= sig_state_debug;
			when "0111" => LEDS <= conv_std_logic_vector(sig_code_index, 8);
			when "0010" => LEDS <= dbInSig;
			when "0100" => LEDS <= sig_test_leds;
			when "0101" => LEDS <= conv_std_logic_vector(sig_move_index, 8);
			when "1000" => LEDS <= sig_game_state;
			when "1001" => LEDS <= sig_code_array(0);
			when "1010" => LEDS <= sig_code_array(1);
			when "1100" => LEDS <= sig_code_array(2);
			when "1101" => LEDS <= sig_code_array(3);
			when "1110" => LEDS <= sig_code_array(4);

			when others => LEDS <= dbOutSig;
		end case;
	end process;	
		
end Behavioral;