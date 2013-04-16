----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:30:58 04/12/2013 
-- Design Name: 
-- Module Name:    valide_place_5x5_window - Behavioral 
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

entity valid_place_5x5_window is
    Port ( window_5x5 : in  board_window_5;
           piece_5x5 : in  std_logic_vector(24 downto 0);
           valid_place : out  STD_LOGIC);
end valid_place_5x5_window;

architecture Behavioral of valid_place_5x5_window is
signal sig_valid : std_logic;
signal sig_active : std_logic;
begin
   process(window_5x5, piece_5x5) is
   begin
      sig_active <= '0';
      sig_valid <= '1';
      
      for i in 0 to 4 loop
         for j in 0 to 4 loop
            if piece_5x5(i + 5*j) = '1' then
               if window_5x5(j, i) = OCCUPIED then
                  sig_valid <= '0';
               elsif window_5x5(j, i) =  ACTIVE then
                  sig_active <= '1';
               end if;
             end if;
         end loop;
      end loop;
   end process;
   
   valid_place <= sig_valid and sig_active;
end Behavioral;

