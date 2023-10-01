----------------------------------------------------------------------------------
-- Company: 	   Binghamton University
-- Engineer: 	   Christopher Fehrer, Dean Birbiglia
-- 
-- Create Date:    22:20:32 11/16/2016 
-- Design Name:	   ARM Processor Decoder 
-- Module Name:    Decoder - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

entity Decoder is
    Port ( clk, reset : in STD_LOGIC;
           Op : in  STD_LOGIC_VECTOR (1 downto 0);
           Funct : in  STD_LOGIC_VECTOR (5 downto 0);
           Rd : in  STD_LOGIC_VECTOR (3 downto 0);
           en_ARM : in std_logic;
           FlagW : out  STD_LOGIC_VECTOR (1 downto 0);
           PCS : out  STD_LOGIC;
           RegW : out  STD_LOGIC;
           MemW : out  STD_LOGIC;
           --MemtoReg : out  STD_LOGIC;
           ALUSrcA : out  STD_LOGIC;
           ALUSrcB : out  STD_LOGIC_VECTOR (1 downto 0);
           AdrSrc : out STD_LOGIC;
           ResultSrc : out STD_LOGIC_VECTOR (1 downto 0);
           IRWrite : out STD_LOGIC;
           NextPC : out STD_LOGIC;
           ImmSrc : out  STD_LOGIC_VECTOR (1 downto 0);
           RegSrc : out  STD_LOGIC_VECTOR (1 downto 0);
           ALUControl : out  STD_LOGIC_VECTOR (2 downto 0);
           decode_state : out std_logic);
end Decoder;

architecture Behavioral of Decoder is

	alias cmd : std_logic_vector(3 downto 0) 
								   is Funct(4 downto 1); -- Instruction Command
														 -- ADD: cmd="0100"
														 -- SUB: cmd="0010"
	alias I   : std_logic is Funct(5); -- I-bit = '0' --> Src2 is a register
									   --       = '1' --> Src2 is an immediate
	alias S   : std_logic is Funct(0); -- S-bit = '1' --> set condition flags
	
	signal MainDecOp : std_logic_vector(3 downto 0);
	signal Controls  : std_logic_vector(9 downto 0);
	
	signal ALUDecOp : std_logic_vector(5 downto 0);

	signal RegWsig : std_logic;
	signal Branch : std_logic;
	signal ALUOp : std_logic;	

    type state_type is (Fetch, Decode, MemAdr, MemRead, MemWB, MemWrite, ExecuteR, ExecuteI, ALUWB, BranchState);
    signal state : state_type := Fetch;
    signal next_state : state_type;

begin

	-- PC LOGIC
	-- PCS = 1 if PC is written by an instruction or branch (B)
	PCS <= '1' when (Rd = x"F" and RegWsig = '1') or Branch = '1' else '0';
	
	-- MAIN DECODER
	MainDecOp <= Op & Funct(5) & Funct(0);
	
	with MainDecOp select
	Controls <= "0000001001" when "0000" | "0001",  -- DP Reg
				"0001001001" when "0010" | "0011",  -- DP Imm
				"0011010100" when "0100" | "0110",  -- STR
				"0101011000" when "0101" | "0111",  -- LDR
				"1001100010" when others;			-- B
	
	--Branch <= Controls(9);				-- Branch Instruction
	--MemtoReg <= Controls(8);			-- LDR, Data Mem to RF
	--MemW <= Controls(7);				-- STR, Data Mem WE
	--ALUSrc <= Controls(6);				-- ExtImm to ALU SrcB
	ImmSrc <= Controls(5 downto 4);     -- Extend control
	--RegWsig <= Controls(3);				-- To Condition Logic
	RegSrc <= Controls(2 downto 1);     -- RegSrc(0): RA1 Source
										-- RegSrc(1): RA2 Source
	--ALUOp <= Controls(0);				-- DP Instruction
	
	-- When CMP RegW should be '0', otherwise RegWsig
	RegW <= '0' when (Funct(4 downto 1) = "1010") else RegWsig; -- RegW output

	-- ALU DECODER
	ALUDecOp <= ALUOp & Funct(4 downto 1) & Funct(0);
	
    -- ALUControl sets the operation to be performed by ALU
    -- ALU Controls:
    -- "000" - Add
    -- "001" - Subtract
    -- "010" - AND
    -- "011" - OR
    -- "100" - EOR
    -- "101" - BIC
    -- "110" - MVN
    -- "111" - MOV
	with ALUDecOp select
	ALUControl <=   "000" when "101000" | "101001",  -- ADD
					"001" when "100100" | "100101",  -- SUB
					"001" when "110100" | "110101",  -- CMP
					"010" when "100000" | "100001",  -- AND
					"011" when "111000" | "111001",  -- ORR
					"100" when "100010" | "100011",  -- EOR
					"101" when "111100" | "111101",  -- BIC
					"110" when "111110" | "111111",  -- MVN
					"111" when "111010" | "111011",  -- MOV
					"000" when others;               -- Not DP

	-- FlagW: Flag Write Signal
	-- Asserted when ALUFlags should be saved
	-- FlagW(0) = '1' --> save NZ flags (ALUFlags(3:2))
	-- FlagW(1) = '1' --> save CV flags (ALUFlags(1:0))
	with ALUDecOp select								
	FlagW <=  "00" when "101000",  -- ADD     
			  "11" when "101001",  -- ADD     
			  "00" when "100100",  -- SUB     
			  "11" when "100101",  -- SUB
			  "11" when "110100",  -- CMP    
			  "11" when "110101",  -- CMP
			  "00" when "100000",  -- AND
			  "10" when "100001",  -- AND
			  "00" when "111000",  -- ORR
			  "10" when "111001",  -- ORR
			  "00" when "100010",  -- EOR
			  "10" when "100011",  -- EOR
			  "00" when "111100",  -- BIC
			  "10" when "111101",  -- BIC
			  "00" when "111110",  -- MVN
			  "11" when "111111",  -- MVN
			  "00" when "111010",  -- MOV
			  "11" when "111011",  -- MOV
			  "00" when others;    -- Not DP
	
	    -- FSM state register
        -- clock input is "clk", 
    process(clk)
        begin
        if rising_edge(clk) then
            if reset = '1' then
--                RegWsig <= '0';
--                MemW <= '0';
--                --MemtoReg <= '0';
--                ALUSrcA <= '0';
--                ALUSrcB <= "00";
--                AdrSrc <= '0';
--                ResultSrc <= "00";
--                IRWrite <= '0';
--                NextPC <= '0';
--                ImmSrc <= "00";
--                RegSrc <= "00";
--                ALUControl <= "00";
--                Branch <= '0';
                state <= Fetch;
            else
                state <= next_state;
            end if;
        end if;
    end process;
			  
	-- FSM Logic		  
    process (clk)
    begin
    case state is
        when Fetch =>
            RegWsig <= '0';
            MemW <= '0';
            --MemtoReg <= '0';
            AdrSrc <= '0';
            ALUSrcA <= '1';
            ALUSrcB <= "10";
            ALUOp <= '0';
            ResultSrc <= "10";
            IRWrite <= '1';
            NextPC <= '1';
            Branch <= '0';
            decode_state <= '0';
            next_state <= Decode;
        when Decode =>
            ALUSrcA <= '1';
            ALUSrcB <= "10";
            ALUOp <= '0';
            ResultSrc <= "10";
            -- reset past signals to 1
            NextPC <= '0';
            IRWrite <= '0';
            decode_state <= '1';
            if en_ARM = '0' then
                next_state <= Decode;
            elsif Op = "01" then
                next_state <= MemAdr;
            elsif Op = "00" then
                if Funct(5) = '0' then
                    next_state <= ExecuteR;
                else
                    next_state <= ExecuteI;
                end if;
            else
                next_state <= BranchState;
            end if;
        when MemAdr =>
            ALUSrcA <= '0';
            ALUSrcB <= "01";
            ALUOp <= '0';
            decode_state <= '0';
            if Funct(0) = '1' then
                next_state <= MemRead;
            else
                next_state <= MemWrite;
            end if;
        when MemRead =>
            decode_state <= '0';
            ResultSrc <= "00";
            AdrSrc <= '1';
            next_state <= MemWB;
        when MemWB =>
            decode_state <= '0';
            ResultSrc <= "01";
            RegWsig <= '1';
            next_state <= Fetch;
        when MemWrite =>
            decode_state <= '0';
            ResultSrc <= "00";
            AdrSrc <= '1';
            MemW <= '1';
            next_state <= Fetch;
        when ExecuteR =>
            decode_state <= '0';
            ALUSrcA <= '0';
            ALUSrcB <= "00";
            ALUOp <= '1';
            next_state <= ALUWB;
        when ExecuteI=>
            decode_state <= '0';
            ALUSrcA <= '0';
            ALUSrcB <= "01";
            ALUOp <= '1';
            next_state <= ALUWB;
        when ALUWB =>
            decode_state <= '0';
            ResultSrc <= "00";
            RegWsig <= '1';
            next_state <= Fetch;
        when BranchState =>
            decode_state <= '0';
            ALUSrcA <= '0';
            ALUSrcB <= "01";
            ALUOp <= '0';
            ResultSrc <= "10";
            Branch <= '1';
            next_state <= Fetch;
        end case;
    end process;
end Behavioral;

