----------------------------------------------------------------------------------
-- Company: 		 Binghamton University
-- Engineer: 		 Christopher Fehrer and Dean Bribiglia 
-- 
-- Create Date:    11/7/2022
-- Design Name: 
-- Module Name:    Register_File - Behavioral 
-- Project Name:   ARM Processor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Register_File is
	generic (data_size : natural := 32;
			 addr_size : natural := 4 );
	port (clk, WE3   : in  std_logic;
		  A1, A2, A3 : in  std_logic_vector(addr_size-1 downto 0);
		  WD3, R15   : in  std_logic_vector(data_size-1 downto 0);
		  RD1, RD2   : out std_logic_vector(data_size-1 downto 0));
end Register_File;

architecture Behavioral of Register_File is
    type RegFile_type is array (0 to 2**addr_size -1) of std_logic_vector (data_size-1 downto 0);
    signal RegFile : RegFile_type := (others => (others => '0')); -- initialize to zeros
begin
    process(clk)
    begin
    -- Write synchronously to the RegFile on Port 3
        if rising_edge(clk) then
            if (WE3 = '1') then
                RegFile(to_integer(unsigned(A3))) <= WD3;
            end if;
        end if;
    end process;  
    -- Read from RegFile on Port 1
	-- When the address = 15, use data from the R15 input
	--   else use data from the RegFile array

	-- Read from RegFile on Port 2
	-- When the address = 15, use data from the R15 input
	--   else use data from the RegFile array
    RD1 <= R15 when A1 = "1111" else RegFile(to_integer(unsigned(A1)));
    RD2 <= R15 when A2 = "1111" else RegFile(to_integer(unsigned(A2)));
--        RD1 <= RegFile(to_integer(unsigned(A1)));
--        RD2 <= RegFile(to_integer(unsigned(A2)));
        
--        if (A1 = "1111") then
--            RD1 <= R15;
--        end if;
--        if (A2 = "1111") then
--            RD2 <= R15;
            
--        end if;
--    end process;

end Behavioral;
