----------------------------------------------------------------------------------
-- Company: 	   Binghamton University
-- Engineer: 	   Christopher Fehrer, Dean Birbiglia
-- 
-- Create Date:    10:14:31 11/08/2016 
-- Design Name: 
-- Module Name:    Instruction_Memory - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
library std;
use std.textio.all;

entity Memory is
   Generic ( data_width : positive := 32; addr_width : positive := 9);
   Port ( clk : in STD_LOGIC; 
          WE  : in STD_LOGIC;
          A   : in  STD_LOGIC_VECTOR (addr_width-1 downto 0);
          WD  : in  STD_LOGIC_VECTOR (data_width-1 downto 0);
          RD  : out  STD_LOGIC_VECTOR (data_width-1 downto 0));
end Memory;

architecture Behavioral of Memory is

   -- Declare type for the memory
   type Mem_type is array(0 to 2**addr_width-1) 
	     	   of bit_vector(data_width-1 downto 0);
   
   -- Declare function for reading a file and returning 
   -- a data array of the initial memory contents with the program
   impure function init_ROM (file_name : in string) 
	  return Mem_type is  
          FILE     rom_file    : text is in file_name;                       
          variable instruction : line;                                 
          variable instr_ROM   : Mem_type;
          variable I           : natural;	
   begin 
      -- Loop for reading each line in the file
	  -- until end of file is reached
	  -- Then, fill in remaining instr_ROMory with zeros
	  I := 0;
	  while not endfile(rom_file) loop
          readline (rom_file, instruction);                             
          read (instruction, instr_ROM(I));
		  I := I + 1;	
      end loop;
	  for J in I to Mem_type'left loop
		  instr_ROM(J) := (others => '0');
	  end loop;
      return instr_ROM;
   end function;                                                

   -- Declare a constant for the instruction array read from the file
   signal MEM : Mem_type := 
   --init_ROM("../../program.txt"); -- Synthesis
   init_ROM("../../../../program.txt"); -- Simulation

begin
       -- Synchronous Write to Data Memory
    process (clk)                                                
    begin
      if rising_edge(clk) then 
         if WE = '1' then
            MEM(to_integer(unsigned(A))) <= to_bitvector(WD); 
         end if;
      end if;                                                       
    end process; 

	process (A)    -- Asynchronous Read                                            
	begin                                                        
		RD <= to_stdlogicvector(MEM(to_integer(unsigned(A))));      
	end process; 

end Behavioral;
