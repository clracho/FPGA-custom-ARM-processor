----------------------------------------------------------------------------------
-- Company: 	   Binghamton University
-- Engineer: 	   Christopher Fehrer
-- 
-- Create Date:     
-- Design Name:	   ARM Processor ALU 
-- Module Name:    ALU - Behavioral 
-- Project Name:   ARM_Processor
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
	Generic ( data_size : positive := 32 );
    Port ( A, B : in  STD_LOGIC_VECTOR (data_size-1 downto 0);
		   ALUControl : in STD_LOGIC_VECTOR (2 downto 0);
		   shifter_carry : in STD_LOGIC;
           Result : out  STD_LOGIC_VECTOR (data_size-1 downto 0);
           ALUFlags : out  STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    signal B_inverted, Mux1Out, SumOut, AorB, AandB, AxorB, AandnotB, notB, FinalMuxOut : STD_LOGIC_VECTOR(data_size-1 downto 0);
    signal Carryout, XNORouta, XNORoutb, XORout, ALUControl1_inverted : STD_LOGIC;
    signal Sum: unsigned(data_size downto 0);
	
begin
    B_inverted <= not B;
    Mux1Out <= B_inverted when ALUControl(0) = '1' else B;
    Sum <= resize(unsigned(A),data_size+1) + resize(unsigned(Mux1Out),data_size+1) when ALUControl(0) = '0' else
           resize(unsigned(A),data_size+1) + resize(unsigned(Mux1Out),data_size+1) + 1;
    SumOut <= std_logic_vector(Sum(data_size-1 downto 0));
    Carryout <= Sum(data_size);
    
    AorB <= A or B;
    AandB <= A and B;
    AxorB <= A xor B;
    AandnotB <= A and (not B);
    notB <= not B;
    
    -- ALU Controls:
    -- "000" - Add
    -- "001" - Subtract
    -- "010" - AND
    -- "011" - OR
    -- "100" - EOR
    -- "101" - BIC
    -- "110" - MVN
    -- "111" - MOV
    process(AorB, AandB, SumOut)
        begin
        case ALUControl is
            when "000" =>
                FinalMuxOut <= SumOut;
            when "001" =>
                FinalMuxOut <= SumOut;
            when "010" => 
                FinalMuxOut <= AandB;    
            when "011" =>
                FinalMuxOut <= AorB;
            when "100" =>
                FinalMuxOut <= AxorB;
            when "101" =>
                FinalMuxOut <= AandnotB;
            when "110" =>
                FinalMuxOut <= notB;
            when others =>
                FinalMuxOut <= B;
        end case;
    end process;
    
    XNORouta <= ALUControl(0) xor A(data_size-1) xor B(data_size-1);
    XNORoutb <= not XNORouta;
    XORout <= A(data_size-1) xor SumOut(data_size-1);
    ALUControl1_inverted <= not ALUControl(1);
    
    
    
    -- Assign final Result output
    Result <= FinalMuxOut;
    -- Assign ALUFlag for Zero to when final Result is 0.
    ALUFlags(2) <= '1' when resize(unsigned(FinalMuxOut),data_size) = 0 else '0';
    -- Assign ALUFlag for Negative to most significant FinalMuxOut bit
    ALUFlags(3) <= FinalMuxOut(data_size-1);
    -- Assign ALUFlag for Carry
    ALUFlags(1) <= (ALUControl1_inverted and Carryout) or shifter_carry;
    -- Assign ALUFlag for Overflow
    ALUFlags(0) <= XNORoutb and XORout and ALUControl1_inverted;
    
end Behavioral;