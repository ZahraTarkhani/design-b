--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:07:10 04/11/2013
-- Design Name:   
-- Module Name:   D:/andrewr/Blokus/blokus_testbench.vhd
-- Project Name:  Blokus
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: blokus
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use std.env.all;

use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY blokus_testbench IS
END blokus_testbench;

ARCHITECTURE behavior OF blokus_testbench IS

	--Inputs
	signal reset : std_logic := '1';
	signal clk   : std_logic := '0';

	-- Clock period definitions
	constant clk_period : time := 10 ns;

	signal sig_write       : std_logic := '0';
	signal sig_player      : std_logic := '0';
	signal sig_write_ready : std_logic;
	signal cmd_command     : move      := (x"0", x"0", "00000", "000");

	signal sig_our_move            : std_logic := '0';
	signal sig_best_move           : move;
	signal sig_move_generator_done : std_logic;
	
	signal fake_sw : std_logic_vector(3 downto 0);
	signal fake_cont : std_logic;
	signal fake_leds : std_logic_vector(7 downto 0);
	
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut : entity work.blokus PORT MAP(
			reset                   => reset,
			clk                     => clk,
			cmd_command             => cmd_command,
			sig_write               => sig_write,
			sig_player              => sig_player,
			CONT => fake_cont,
			SW =>fake_sw,
			LEDS => fake_leds,
			sig_write_ready         => sig_write_ready,
			sig_our_move            => sig_our_move,
			sig_best_move           => sig_best_move,
			sig_move_generator_done => sig_move_generator_done
		);

	-- Clock process definitions
	clk_process : process
	begin
		clk <= '1';
		wait for clk_period / 2;
		clk <= '0';
		wait for clk_period / 2;
	end process;

	-- Stimulus process
	stim_proc : process
	begin
		reset <= '1';
		wait for clk_period * 2;

		reset <= '0';
		
		wait for clk_period;
		cmd_command.x        <= x"5";
		cmd_command.y        <= x"3";
		cmd_command.name     <= "00100";
		cmd_command.rotation <= "000";

		sig_player <= '1';
		
		wait for clk_period;
		sig_write  <= '1';

		wait for clk_period * 2;
		cmd_command <= (x"0", x"0", "00000", "000");
		sig_player  <= '0';
		sig_write   <= '0';

		wait until sig_write_ready = '1';

		sig_our_move <= '1';

		wait for clk_period * 2;
		sig_our_move <= '0';

		wait until sig_move_generator_done = '1';
		
		
		wait for clk_period * 2;
		sig_our_move <= '1';

		wait for clk_period * 2;
		sig_our_move <= '0';

		wait until sig_move_generator_done = '1';
				
		cmd_command <= sig_best_move;
		sig_player  <= '0';
		sig_write   <= '1';

		wait for clk_period * 2;
		cmd_command <= (x"0", x"0", "00000", "000");
		sig_player  <= '0';
		sig_write   <= '0';

		wait until sig_write_ready = '1';

		wait for clk_period;
		cmd_command.x        <= x"2";
		cmd_command.y        <= x"1";
		cmd_command.name     <= "01010";
		cmd_command.rotation <= "111";

		sig_player <= '1';
		
		wait for clk_period;
		sig_write  <= '1';

		wait for clk_period * 2;
		cmd_command <= (x"0", x"0", "00000", "000");
		sig_player  <= '0';
		sig_write   <= '0';

		wait until sig_write_ready = '1';

		sig_our_move <= '1';

		wait for clk_period * 2;
		sig_our_move <= '0';

		wait until sig_move_generator_done = '1';

		cmd_command <= sig_best_move;
		sig_player  <= '0';
		sig_write   <= '1';

		wait for clk_period * 2;
		cmd_command <= (x"0", x"0", "00000", "000");
		sig_player  <= '0';
		sig_write   <= '0';

		wait until sig_write_ready = '1';
		
		wait for clk_period;
		cmd_command.x        <= x"6";
		cmd_command.y        <= x"1";
		cmd_command.name     <= "00000";
		cmd_command.rotation <= "000";

		sig_player <= '1';
		
		wait for clk_period;
		sig_write  <= '1';

		wait for clk_period * 2;
		cmd_command <= (x"0", x"0", "00000", "000");
		sig_player  <= '0';
		sig_write   <= '0';

		wait until sig_write_ready = '1';

		sig_our_move <= '1';

		wait for clk_period * 2;
		sig_our_move <= '0';

		wait until sig_move_generator_done = '1';

		cmd_command <= sig_best_move;
		sig_player  <= '0';
		sig_write   <= '1';

		wait for clk_period * 2;
		cmd_command <= (x"0", x"0", "00000", "000");
		sig_player  <= '0';
		sig_write   <= '0';

		wait until sig_write_ready = '1';
		
		wait for clk_period;
		cmd_command.x        <= x"7";
		cmd_command.y        <= x"2";
		cmd_command.name     <= "00001";
		cmd_command.rotation <= "000";

		sig_player <= '1';
		
		wait for clk_period;
		sig_write  <= '1';

		wait for clk_period * 2;
		cmd_command <= (x"0", x"0", "00000", "000");
		sig_player  <= '0';
		sig_write   <= '0';

		wait until sig_write_ready = '1';

		sig_our_move <= '1';

		wait for clk_period * 2;
		sig_our_move <= '0';

		wait until sig_move_generator_done = '1';

		cmd_command <= sig_best_move;
		sig_player  <= '0';
		sig_write   <= '1';

		wait for clk_period * 2;
		cmd_command <= (x"0", x"0", "00000", "000");
		sig_player  <= '0';
		sig_write   <= '0';

		wait until sig_write_ready = '1';

		wait for clk_period * 20;
		stop(2);

		wait;
	end process;

END;
