------------------------------------------------------------------------
--  RS232RefCom.vhd
------------------------------------------------------------------------
-- Author:  Dan Pederson
--          Copyright 2004 Digilent, Inc.
------------------------------------------------------------------------
-- Description:  	This file defines a UART which tranfers data from 
--				serial form to parallel form and vice versa.			
------------------------------------------------------------------------
-- Revision History:
--  07/15/04 (Created) DanP
--	 02/25/08 (Created) ClaudiaG: made use of the baudDivide constant
--											in the Clock Dividing Processes
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Rs232 is
	Port(
		clk         : in  std_logic;
		rst         : in  std_logic;

		txd         : out std_logic;
		txd_do_send : in  std_logic;
		txd_buf     : in  std_logic_vector(7 downto 0);
		txd_done    : out std_logic;

		rxd_raw     : in  std_logic;
		rxd_ready   : out std_logic;
		rxd_buf     : out std_logic_vector(7 downto 0));
end Rs232;

architecture Behavioral of Rs232 is
	type rxd_states is (rxd_idle, rxd_find_center, rxd_sample, rxd_stop);
	signal rxd_state : rxd_states := rxd_idle;

	type txd_states is (txd_idle, txd_shift, txd_stop);
	signal txd_state : txd_states := txd_idle;

	signal rxd                : std_logic                     := '1';
	signal rxd_shift_register : std_logic_vector(31 downto 0) := (others => '1');

	constant clk_full_count : integer := 54;
	constant clk_half_count : integer := clk_full_count / 2;
begin
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rxd_shift_register = "11111111111111111111111111111111" then
				rxd <= '1';
			elsif rxd_shift_register = "0000000000000000000000000000000" then
				rxd <= '0';
			end if;
			rxd_shift_register <= rxd_shift_register(30 downto 0) & rxd_raw;
		end if;
	end process;

	rxd_process : process(clk, rst)
		variable clk_count : integer range 0 to clk_full_count := 0;
		variable bit_count : integer range 0 to 8              := 0;
		variable buf       : std_logic_vector(7 downto 0)      := (others => '0');

	begin
		if rst = '1' then
			rxd_state <= rxd_idle;
			rxd_ready <= '0';
			rxd_buf   <= (others => '0');

		elsif rising_edge(clk) then
			case rxd_state is
				when rxd_idle =>
					if (rxd = '0') then
						rxd_state <= rxd_find_center;
						rxd_ready <= '0';
						bit_count := 0;
					end if;
				when rxd_find_center =>
					if (rxd = '0') then
						if (clk_count = clk_half_count) then
							rxd_state <= rxd_sample;
							clk_count := 0;
						else
							clk_count := clk_count + 1;
						end if;
					else
						-- the bit ropped too early??? maybe it was just noise?
						rxd_state <= rxd_idle;
					end if;
				when rxd_sample =>
					if (clk_count = clk_full_count) then
						buf(bit_count) := rxd;
						bit_count      := bit_count + 1;

						if (bit_count = 8) then
							rxd_state <= rxd_stop;
							clk_count := 0;
							rxd_buf   <= buf;
							rxd_ready <= '1';
						end if;

						clk_count := 0;
					else
						clk_count := clk_count + 1;
					end if;
				when rxd_stop =>
					if (clk_count = clk_full_count) then
						rxd_state <= rxd_idle;
					else
						clk_count := clk_count + 1;
					end if;
			end case;
		end if;
	end process;

	txd_process : process(clk, rst)
		variable clk_count : integer range 0 to clk_full_count := 0;
		variable bit_count : integer range 0 to 8              := 0;

	begin
		if rst = '1' then
			txd_state <= txd_idle;
			txd       <= '1';
			txd_done  <= '1';

		elsif rising_edge(clk) then
			case txd_state is
				when txd_idle =>
					txd_done  <= '1';
					if (txd_do_send = '1') then
						txd_state <= txd_shift;
						txd_done  <= '0';
						clk_count := 0;

						-- we first must send a '0' bit
						txd <= '0';
					end if;
				when txd_shift =>
					if (clk_count = clk_full_count) then
						if (bit_count = 8) then
							txd_state <= txd_stop;
							bit_count := 0;

							-- stop bit
							txd <= '1';
						else
							txd       <= txd_buf(bit_count);
							bit_count := bit_count + 1;
						end if;
						clk_count := 0;
					else
						clk_count := clk_count + 1;
					end if;
				when txd_stop =>
					if (clk_count = clk_full_count) then
						if (txd_do_send = '0') then
							txd_state <= txd_idle;
							clk_count := 0;
						end if;
						txd_done <= '1';
					else
						clk_count := clk_count + 1;
					end if;
			end case;
		end if;
	end process;
end Behavioral;