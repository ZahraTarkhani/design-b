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
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;


--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Rs232RefComp is
	Port(
		TXD   : out   std_logic := '1';
		RXD   : in    std_logic;
		CLK   : in    std_logic;        --Master Clock = 50MHz
		DBIN  : in    std_logic_vector(7 downto 0); --Data Bus in
		DBOUT : out   std_logic_vector(7 downto 0); --Data Bus out
		RDA   : inout std_logic;        --Read Data Available
		TBE   : inout std_logic := '1'; --Transfer Bus Empty
		RD    : in    std_logic;        --Read Strobe
		WR    : in    std_logic;        --Write Strobe
		PE    : out   std_logic;        --Parity Error Flag
		FE    : out   std_logic;        --Frame Error Flag
		OE    : out   std_logic;        --Overwrite Error Flag
		RSTW    : in  std_logic:='0';
		RST   : in    std_logic := '0'); --Master Reset
end Rs232RefComp;

architecture Behavioral of Rs232RefComp is


--entity rs232_receiver is
--  generic(system_speed, baudrate: integer);
--  port(
--    WR: in std_logic;
--    CLK: in std_logic;
--    DBOUT: out unsigned(7 downto 0);
--    RST: in std_logic;
--    RDA: out std_logic;
--    rx: in std_logic);
--end entity rs232_receiver;

  constant max_counter: natural := 434; --system_speed / baudrate;
  
  type state_type is (
    wait_for_rx_start, 
    wait_half_bit,
    receive_bits,
    wait_for_stop_bit);

  signal state: state_type := wait_for_rx_start;
  signal baudrate_counter: natural range 0 to max_counter := 0;
  signal bit_counter: natural range 0 to 7 := 0;
  signal shift_register: unsigned(7 downto 0) := (others => '0');

  type wstate_type is (
		winit,
    wait_for_strobe,
    send_start_bit,
    send_bits,
    send_stop_bit);

  signal wstate: wstate_type := wait_for_strobe;
  signal wbaudrate_counter: natural range 0 to max_counter := 0;
  signal wbit_counter: natural range 0 to 7 := 0;
  signal wshift_register: unsigned(7 downto 0) := (others => '0');
  signal data_sending_started: std_logic := '0';



begin

  update: process(CLK, RD)
  begin
    if rising_edge(CLK) then
      if RST = '1' then
        state <= wait_for_rx_start;
        DBOUT <= (others => '0');
        RDA <= '0';
      else
        case state is
          when wait_for_rx_start =>
            if RXD = '0' then
              -- start bit received, wait for a half bit time
              -- to sample bits in the middle of the signal
              state <= wait_half_bit;
              baudrate_counter <= max_counter / 2 - 1;
            end if;
          when wait_half_bit =>
            if baudrate_counter = 0 then
              -- now we are in the middle of the start bit,
              -- wait a full bit for the middle of the first bit
              state <= receive_bits;
              bit_counter <= 7;
              baudrate_counter <= max_counter - 1;
            else
              baudrate_counter <= baudrate_counter - 1;
            end if;
          when receive_bits =>
            -- sample a bit
            if baudrate_counter = 0 then
              shift_register <= RXD & shift_register(7 downto 1);
              if bit_counter = 0 then
                state <= wait_for_stop_bit;
              else
                bit_counter <= bit_counter - 1;
              end if;
              baudrate_counter <= max_counter - 1;
            else
              baudrate_counter <= baudrate_counter - 1;
            end if;
          when wait_for_stop_bit =>
            -- wait for the middle of the stop bit
            if baudrate_counter = 0 then
              state <= wait_for_rx_start;
--              if RXD = '1' then
                DBOUT <= std_logic_vector(shift_register);
                RDA <= '1';
                -- else: missing stop bit, ignore
--              end if;  
            else
              baudrate_counter <= baudrate_counter - 1;
            end if;
        end case;
      end if;
    end if;

    -- when acknowledged, reset strobe
    if RD = '1' then
      RDA <= '0';
    end if;
  end process;






--entity rs232_sender is
--  generic(
--    system_speed,  -- CLK speed, in hz
--    baudrate: integer);  -- baudrate, in bps
--  port(
--    TBE: out std_logic;  -- Wishbone ACK_O signal
--    CLK: in std_logic;  -- Wishbone CLK_i signal
--    DBIN: in unsigned(7 downto 0);  -- Wishbone DAT_i signal
--    RST: in std_logic;  -- Wishbone RST_i signal
--    WR: in std_logic;  -- Wishbone STB_i signal
--    TXD: out std_logic);  -- RS232 transmit pin
--end entity rs232_sender;


  -- acknowledge, when sending process was started
  TBE <= data_sending_started and WR;

  updatew: process(CLK, WR)
  begin
    if rising_edge(CLK) then
      if RSTW = '1' then
        TXD <= '1';
        data_sending_started <= '0';
        wstate <= wait_for_strobe;
      else
        case wstate is
          -- wait until the master asserts valid data
			 when winit =>
				  data_sending_started <= '0';
				  wstate <= wait_for_strobe;
				  TXD <= '1';
			 
          when wait_for_strobe =>
            if WR = '1' then
              wstate <= send_start_bit;
              wbaudrate_counter <= max_counter - 1;
              TXD <= '0';
              wshift_register <= unsigned(DBIN);
              data_sending_started <= '1';
            else
              TXD <= '1';
            end if;

          when send_start_bit =>
            if wbaudrate_counter = 0 then
              wstate <= send_bits;
              wbaudrate_counter <= max_counter - 1;
              TXD <= wshift_register(0);
              wbit_counter <= 7;
            else
              wbaudrate_counter <= wbaudrate_counter - 1;
            end if;

          when send_bits =>
            if wbaudrate_counter = 0 then
              if wbit_counter = 0 then
                wstate <= send_stop_bit;
                TXD <= '1';
              else
                TXD <= wshift_register(1);
                wshift_register <= shift_right(wshift_register,1);
                wbit_counter <= wbit_counter - 1;
              end if;
              wbaudrate_counter <= max_counter - 1;
            else
              wbaudrate_counter <= wbaudrate_counter - 1;
            end if;

          when send_stop_bit =>
            if wbaudrate_counter = 0 then
              wstate <= winit;
            else
              wbaudrate_counter <= wbaudrate_counter - 1;
            end if;
        end case;

        -- this resets acknowledge until all bits are sent
        if WR = '0' and data_sending_started = '1' then
          data_sending_started <= '0';
--			else
--			data_sending_started <= '1';
        end if;
      end if;
    end if;
  end process;











end Behavioral;