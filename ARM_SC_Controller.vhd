----------------------------------------------------------------------------------
-- Company: 	   Binghamton University
-- Engineer(s):    Carl Betcher
-- 
-- Create Date:    23:13:36 11/13/2016 
-- Design Name: 
-- Module Name:    Controller - Behavioral 
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

entity controller is -- single cycle control decoder
  port(clk, reset:        in  STD_LOGIC;
       Instr:             in  STD_LOGIC_VECTOR(31 downto 12);
       ALUFlags:          in  STD_LOGIC_VECTOR(3 downto 0);
       en_ARM:            in  STD_LOGIC;
       RegSrc:            out STD_LOGIC_VECTOR(1 downto 0);
       RegWrite:          out STD_LOGIC;
       ImmSrc:            out STD_LOGIC_VECTOR(1 downto 0);
       --ALUSrc:            out STD_LOGIC;
       ALUControl:        out STD_LOGIC_VECTOR(2 downto 0);
       MemWrite:          out STD_LOGIC;
       --MemtoReg:          out STD_LOGIC;
       PCWrite:           out STD_LOGIC;
       AdrSrc:            out STD_LOGIC;
       IRWrite:           out STD_LOGIC;
       ALUSrcA:           out STD_LOGIC;
       ALUSrcB:           out STD_LOGIC_VECTOR(1 downto 0);
       ResultSrc:         out STD_LOGIC_VECTOR(1 downto 0);
       decode_state:      out STD_LOGIC
       );
end;
architecture Behavioral of Controller is

	COMPONENT Decoder
	PORT(
		clk, reset : IN STD_LOGIC;
		en_ARM : IN STD_LOGIC;
		Op : IN std_logic_vector(1 downto 0);
		Funct : IN std_logic_vector(5 downto 0);
		Rd : IN std_logic_vector(3 downto 0);
		FlagW : OUT std_logic_vector(1 downto 0);
		PCS : OUT std_logic;
		RegW : OUT std_logic;
		MemW : OUT std_logic;
		--MemtoReg : OUT std_logic;
		ALUSrcA : OUT std_logic;
		ALUSrcB : OUT std_logic_vector(1 downto 0);
		AdrSrc : OUT std_logic;
		ResultSrc : OUT std_logic_vector(1 downto 0);
		IRWrite : OUT std_logic;
		NextPC : OUT std_logic;
		ImmSrc : OUT std_logic_vector(1 downto 0);
		RegSrc : OUT std_logic_vector(1 downto 0);
		ALUControl : OUT std_logic_vector(2 downto 0);
		decode_state : OUT STD_LOGIC          
		);
	END COMPONENT;

	COMPONENT Cond_Logic
	PORT(
		clk : std_logic;
		reset : std_logic;
		Cond : IN std_logic_vector(3 downto 0);
		ALUFlags : IN std_logic_vector(3 downto 0);
		FlagW : IN std_logic_vector(1 downto 0);
		PCS : IN std_logic;
		RegW : IN std_logic;
		MemW : IN std_logic;
		NextPC : IN std_logic;          
		PCWrite : OUT std_logic;
		RegWrite : OUT std_logic;
		MemWrite : OUT std_logic
		);
	END COMPONENT;
	
	signal FlagW : std_logic_vector(1 downto 0);
	signal PCS  : std_logic;
	signal RegW : std_logic;
	signal MemW : std_logic;
    signal NextPCsig : std_logic;

begin

	-- Instantiate the Decoder Function of the Controller
	i_Decoder: Decoder PORT MAP(
	    clk => clk,
	    reset => reset,
		Op => Instr(27 downto 26),
		Funct => Instr(25 downto 20),
		Rd => Instr(15 downto 12),
		en_ARM => en_ARM,
		FlagW => FlagW,
		PCS => PCS,
		RegW => RegW,
		MemW => MemW,
		--MemtoReg => MemtoReg,
		ALUSrcA => ALUSrcA,
		ALUSrcB => ALUSrcB,
		AdrSrc => AdrSrc,
		ResultSrc => ResultSrc,
		NextPC => NextPCsig,
		IRWrite => IRWrite,
		ImmSrc => ImmSrc,
		RegSrc => RegSrc,
		ALUControl => ALUControl,
		decode_state => decode_state 
	);

	-- Instantiate the Conditional Logic Function of the Controller
	i_Cond_Logic: Cond_Logic PORT MAP(
		clk => clk,
		reset => reset,
		Cond => Instr(31 downto 28),
		ALUFlags => ALUFlags,
		FlagW => FlagW,
		PCS => PCS,
		RegW => RegW,
		MemW => MemW,
		NextPC => NextPCsig,
		PCWrite => PCWrite,
		RegWrite => RegWrite,
		MemWrite => MemWrite 
	);

end Behavioral;

