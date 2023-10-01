----------------------------------------------------------------------------------
-- Company: 	   Binghamton University
-- Engineer(s):    Carl Betcher
-- 
-- Create Date:    23:13:36 11/13/2016 
-- Design Name:    ARM Processor Datapath
-- Module Name:    Datapath - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

entity datapath is  
  generic(IM_addr_width : positive := 9;
          DM_addr_width : positive := 9);
  port(clk, reset, en_ARM : in  STD_LOGIC;
       RegSrc       : in  STD_LOGIC_VECTOR(1 downto 0);
       RegWrite     : in  STD_LOGIC;
       ImmSrc       : in  STD_LOGIC_VECTOR(1 downto 0);
       ALUSrcA      : in  STD_LOGIC;
       ALUSrcB      : in  STD_LOGIC_VECTOR(1 downto 0);
       ALUControl   : in  STD_LOGIC_VECTOR(2 downto 0);
       --MemtoReg     : in  STD_LOGIC;
       ResultSrc   : in  STD_LOGIC_VECTOR(1 downto 0);
       PCWrite        : in  STD_LOGIC;
       AdrSrc        : in  STD_LOGIC;
       MemWrite        : in  STD_LOGIC;
       IRWrite        : in  STD_LOGIC;
       --DM_WE        : in  STD_LOGIC;
       --DM_Addr      : in  STD_LOGIC_VECTOR(DM_addr_width-1 downto 0);
       decode_state : in STD_LOGIC;
       SWITCH       : in std_logic_vector(7 downto 0); 
       ALUFlags     : out STD_LOGIC_VECTOR(3 downto 0);
       PC           : out STD_LOGIC_VECTOR(31 downto 0);
       Instr        : out STD_LOGIC_VECTOR(31 downto 0);
       ALUResult    : out STD_LOGIC_VECTOR(31 downto 0); 
       ReadData     : out STD_LOGIC_VECTOR(7 downto 0)
       );
end;

architecture Behavioral of Datapath is

	component Memory
    generic ( data_width : positive := 32; 
              addr_width : positive := 9);
	port(clk, WE :  in STD_LOGIC;
			  A  :  in STD_LOGIC_VECTOR(addr_width-1 downto 0);
			  WD :  in STD_LOGIC_VECTOR(data_width-1 downto 0);
			  RD :  out STD_LOGIC_VECTOR(data_width-1 downto 0));
	end component;
	
	COMPONENT Register_File
	GENERIC (data_size : natural := 32;
			 addr_size : natural := 4 );
	PORT(
		clk : IN std_logic;
		WE3 : IN std_logic;
		A1  : IN std_logic_vector(3 downto 0);
		A2  : IN std_logic_vector(3 downto 0);
		A3  : IN std_logic_vector(3 downto 0);
		WD3 : IN std_logic_vector(31 downto 0);
		R15 : IN std_logic_vector(31 downto 0);          
		RD1 : OUT std_logic_vector(31 downto 0);
		RD2 : OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	COMPONENT ALU
	PORT(
		A : IN std_logic_vector(31 downto 0);
		B : IN std_logic_vector(31 downto 0);
		shifter_carry : IN std_logic;
		ALUControl : IN std_logic_vector(2 downto 0);          
		Result : OUT std_logic_vector(31 downto 0);
		ALUFlags : OUT std_logic_vector(3 downto 0)
		);
	END COMPONENT;
    
    COMPONENT shifter
	GENERIC (data_size : natural := 32);
    Port ( input: in STD_LOGIC_VECTOR (data_size-1 downto 0);
           outputShifted: out STD_LOGIC_VECTOR (data_size-1 downto 0);
		   shamt5 : in STD_LOGIC_VECTOR (4 downto 0);
           sh : in  STD_LOGIC_VECTOR (1 downto 0);
           carryout : out  STD_LOGIC);
	END COMPONENT;
    
	signal InstrSig : std_logic_vector(31 downto 0);
	--signal PCmux : std_logic_vector(31 downto 0);
	signal PCsig : std_logic_vector(31 downto 0) := (others => '0');
	--signal PCplus4 : unsigned(31 downto 0);
	--signal PCplus8 : std_logic_vector(31 downto 0);
	signal ExtImm : std_logic_vector(31 downto 0);
	signal ShiftedImm24 : signed(31 downto 0);
	signal RA1mux : std_logic_vector(3 downto 0);
	signal RA2mux : std_logic_vector(3 downto 0);
	signal SrcA : std_logic_vector(31 downto 0);
	signal SrcB_preshift, SrcB_shifted : std_logic_vector(31 downto 0);
	signal ALUResultSig : std_logic_vector(31 downto 0);
	signal ReadDataSig : std_logic_vector(31 downto 0);
	signal WriteDataSig : std_logic_vector(31 downto 0);
	signal Result : std_logic_vector(31 downto 0);	
	
	signal ALUOut : std_logic_vector(31 downto 0);
	signal DataSig : std_logic_vector(31 downto 0);
	signal MemoryAddr : STD_LOGIC_VECTOR(DM_addr_width-1 downto 0);
	signal Asig : std_logic_vector(31 downto 0);
	signal RD1Sig : std_logic_vector(31 downto 0);
	signal RD2Sig : std_logic_vector(31 downto 0);
	
	signal RF_WE3 : std_logic;
    
    signal shtyp : std_logic_vector (1 downto 0);
    signal shamt5_step1, shamt5_step2, shamt5_final : std_logic_vector(4 downto 0);
    signal shifter_carry : std_logic;
    
begin
    
    -- Select to use DM_Addr or PCSig to access memory depending on AdrSrc
    MemoryAddr <= std_logic_vector(resize(unsigned(SWITCH),MemoryAddr'length)) when en_ARM = '0' AND reset = '0' AND decode_state = '1' 
        else Result(IM_addr_width+1 downto 2) when AdrSrc = '1' 
        else PCsig(IM_addr_width+1 downto 2);
	         	
	-- Instantiate the Memory
	i_mem: Memory 
	generic map (data_width => 32, 
	             addr_width => DM_addr_width)
	port map(clk => Clk, 
	          WE => MemWrite, 
	          A  => MemoryAddr, 
			  WD => WriteDataSig, 
			  RD => ReadDataSig);
			 
	-- Data Memory ReadData(7:0) to the toplevel for display
	ReadData <= ReadDataSig(7 downto 0); 		 
									       
	-- Output the instruction, only if IRWrite
    Process(clk) 
	begin 
		if rising_edge(clk) then
			if IRWrite = '1' then
				InstrSig <= ReadDataSig;
			else
				InstrSig <= InstrSig;
			end if;
		end if; 
	end process;
    Instr <= InstrSig;								       
									       
	-- Output the Program Counter
	PC <= PCsig;
	-- Output the ALUResult for the Data Memory Address
	ALUResult <= ALUResultSig;
	
	-- This Mux provides the data loaded into the PC
	-- When PCSrc = '1', the source of the PC in output of ALU or Data Memory
	--     Used for branching
	-- When PCSrc = '0', the source of the PC is PCPlus4
	--     Used when accessing the next consecutive instruction
	--PCmux <= Result when PCSrc = '1' else std_logic_vector(PCplus4);
	
	-- Program Counter
	-- reset clears it to 0
	-- en_ARM allows PC to be loaded from PCmux
	Process(clk) 
	begin 
		if rising_edge(clk) then
			if reset = '1' then
				PCsig <= (others => '0');
			elsif PCWrite = '1' then	--elsif en_ARM = '1' and PCWrite = '1' then	
				PCsig <= Result;
			else
				PCsig <= PCsig;
			end if;
		end if; 
	end process;
	
	-- ALUOut, Data Register
	Process(clk) 
	begin 
		if rising_edge(clk) then
            ALUOut <= ALUResultSig;
            DataSig <= ReadDataSig;
            ASig <= RD1Sig;
            WriteDataSig <= RD2Sig;
		end if; 
	end process;

	-- Adder adds 4 to the PC to produce PC+4
	--PCplus4 <= unsigned(PCsig) + 4;
	
	-- Adder adds 4 to PCplus4 to produce PC+8
	--PCplus8 <= std_logic_vector(PCplus4 + 4);
	
	-- Mux selects address for Port 1 of the Register File
	RA1mux <= InstrSig(19 downto 16) when RegSrc(0) = '0' else x"F";
	
	-- Mux selects address for Port 2 of the Register File
	RA2mux <= InstrSig(3 downto 0) when RegSrc(1) = '0' else InstrSig(15 downto 12);
	
	-- Write enable for Register File is gated by en_ARM
	RF_WE3 <= RegWrite; -- RF_WE3 <= RegWrite and en_ARM;
	
	-- Instantiate Register File (16 registers x 32 bits)
	i_Register_File: Register_File PORT MAP(
		clk => clk,
		WE3 => RF_WE3,
		A1 => RA1mux,
		A2 => RA2mux,
		A3 => InstrSig(15 downto 12),
		WD3 => Result,
		R15 => Result,
		RD1 => RD1Sig,
		RD2 => RD2Sig 
	);
	
	-- 24-bit Immediate Field sign extended and shifted left twice
	ShiftedImm24 <= resize(signed(InstrSig(23 downto 0)),30) & "00";
	
	-- Extend function for Immediate data
	with ImmSrc select
	ExtImm <= std_logic_vector(resize(unsigned(InstrSig(7 downto 0)),ExtImm'length))  when "00",
			  std_logic_vector(resize(unsigned(InstrSig(11 downto 0)),ExtImm'length)) when "01",
			  std_logic_vector(ShiftedImm24) when others;
	
	-- Selects Source of ALU input B
	-- When ALUSrc = '1', selects Extended Immediate Data
	-- When ALUSrc = '0', selects data from register file on Port 2
	--SrcB <= WriteDataSig when ALUSrc = '0' else ExtImm;
	
	--Deternube Shtype for barrel shifter
	-- Rot (11) when Immediate, else use Instr 6:5
	shtyp <= "11" when InstrSig(25) = '1' else InstrSig(6 downto 5);
	
	-- Determine Shamt5 for barrel shifter
	-- First determine Shift amount depending on whether immediate:
	shamt5_step1 <= (InstrSig(11 downto 8) & '0') when InstrSig(25) = '1' else InstrSig(11 downto 7);
	-- Now check to see if instruction is DP or memory/branch:
	shamt5_step2 <= shamt5_step1 when InstrSig(27 downto 26) = "00" else "00000";
	-- Now check to see if datapath is handling the program counter:
	shamt5_final <= "00000" when ALUSrcB = "10" else shamt5_step2;
	
	--SrcA Mux, controlled by ALUSrcA
	SrcA <= PCSig when ALUSrcA = '1' else ASig;
	
	--SrcB Mux, controlled by ALUSrcB
	with ALUSrcB  select
	SrcB_preshift <= WriteDataSig  when "00",
			ExtImm when "01",
			"00000000000000000000000000000100" when others;
	
	--Instantiate the Barrel Shifter
	i_shifter: shifter PORT MAP(
       input => SrcB_preshift,
       outputShifted => SrcB_shifted,
       shamt5 => shamt5_final,
       sh => shtyp,
       carryout => shifter_carry
    );
	
	-- Instantiate the ALU
	i_ALU: ALU PORT MAP(
		A => SrcA,
		B => SrcB_shifted,
		shifter_carry => shifter_carry,
		ALUControl => ALUControl,
		Result => ALUResultSig,
		ALUFlags => ALUFlags
	);	

	-- MUX "ReadData" from Data Memory and "ALUResult" from the ALU to produce "Result"
	-- Result is data written to the PC or the Register File
	with ResultSrc select
	Result <= ALUOut  when "00",
			  DataSig when "01",
			  ALUResultSig when others;
	--Result <= ALUResultSig when MemtoReg = '0' else ReadDataSig;
	
end Behavioral;

