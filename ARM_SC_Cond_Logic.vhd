----------------------------------------------------------------------------------
-- Company: 	   Binghamton University
-- Engineer: 	   Carl Betcher
-- 
-- Create Date:    22:32:43 11/16/2016 
-- Design Name:	   ARM Processor Conditional Logic 
-- Module Name:    Cond_Logic - Behavioral 
-- Project Name:   ARM_SingleCycle Processor
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

entity Cond_Logic is
    Port ( clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           Cond : in  STD_LOGIC_VECTOR (3 downto 0);
           ALUFlags : in  STD_LOGIC_VECTOR (3 downto 0);
           FlagW : in  STD_LOGIC_VECTOR (1 downto 0);
           PCS : in  STD_LOGIC;
           RegW : in  STD_LOGIC;
           MemW : in  STD_LOGIC;
           NextPC : in STD_LOGIC;
           PCWrite : out  STD_LOGIC;
           RegWrite : out  STD_LOGIC;
           MemWrite : out  STD_LOGIC);
end Cond_Logic;

architecture Behavioral of Cond_Logic is

	signal Flags : std_logic_vector(3 downto 0);
	signal CondEx : std_logic;
	signal N, Z, C, V : STD_LOGIC;
    signal CondExSync : std_logic := '0'; -- synchronized CondEx Signal
    signal PCSrc : std_logic; -- in between signal to create PCWrite

begin

	-- Conditional Logic checks if instruction should execute
	-- (if not, force PCSrc, RegWrite, and MemWrite to '0')
	-- and possibly updates the Status Register (Flags(3:0))
	
	-- Register for ALU flags 3 and 2
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				Flags(3 downto 2) <= (others => '0');
			elsif FlagW(1) = '1' and CondEx = '1' then
				Flags(3 downto 2) <= ALUFlags(3 downto 2);
			end if;	
		end if;
	end process;
	
	-- Register for ALU flags 1 and 0
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				Flags(1 downto 0) <= (others => '0');
			elsif FlagW(0) = '1' and CondEx = '1' then
				Flags(1 downto 0) <= ALUFlags(1 downto 0);
			end if;	
		end if;
	end process;
	
    -- Condition Checking Logic
    N <= Flags(3);  Z <= Flags(2);  C <= Flags(1);  V <= Flags(0);  
	process(Cond, N, Z, C, V) 
	begin
		case Cond is
			when "0000" => CondEx <= Z;						-- EQ
			when "0001" => CondEx <= not Z;					-- NE
			when "0010" => CondEx <= C;						-- CS/HS
			when "0011" => CondEx <= not C;					-- CC/LO
			when "0100" => CondEx <= N;						-- MI
			when "0101" => CondEx <= not N;					-- PL
			when "0110" => CondEx <= V;						-- VS
			when "0111" => CondEx <= not V;					-- VC
			when "1000" => CondEx <= not Z and C;			-- HI
			when "1001" => CondEx <= Z or not C;			-- LS
			when "1010" => CondEx <= not (N xor V);			-- GE
			when "1011" => CondEx <= N xor V;				-- LT
			when "1100" => CondEx <= not Z and not(N xor V);-- GT
			when "1101" => CondEx <= Z or (N xor V);		-- LE
			when "1110" => CondEx <= '1';					-- AL (or none)
			when others => CondEx <= '0';	
		end case;
	end process;
    
    --synchronize the CondEx signal
    process(clk)
        begin
        if rising_edge(clk) then
            CondExSync <= CondEx;
        end if;
    end process;
    
	-- Apply result of condition checking to control signals
	PCSrc    <= PCS  and CondExSync;
	PCWrite <= PCSrc or NextPC;
	RegWrite <= RegW and CondExSync;
	MemWrite <= MemW and CondExSync;
	
end Behavioral;

