----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Christohher Fehrer, Dean Birbiglia
-- 
-- Create Date: 12/03/2022 03:07:41 PM
-- Design Name: 
-- Module Name: shifter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

entity shifter is
    Generic ( data_size : positive := 32 );
    Port ( input: in STD_LOGIC_VECTOR (data_size-1 downto 0);
           outputShifted: out STD_LOGIC_VECTOR (data_size-1 downto 0);
		   shamt5 : in STD_LOGIC_VECTOR (4 downto 0);
           sh : in  STD_LOGIC_VECTOR (1 downto 0);
           carryout : out  STD_LOGIC);
end shifter;

architecture Behavioral of shifter is
    signal stage16, stage8, stage4, stage2, stage1: std_logic_vector(data_size-1 downto 0);
    signal stage16_sh, stage8_sh, stage4_sh, stage2_sh, stage1_sh: std_logic_vector(data_size-1 downto 0);
    signal carryoutSig16, carryoutSig8, carryoutSig4, carryoutSig2, carryoutSig1: std_logic := '0';
begin

-- Shift by 16?
with sh select
stage16_sh <= (input(15 downto 0) & "0000000000000000") when "00",  -- LSL
           ("0000000000000000" & input(31 downto 16)) when "01",  -- LSR
           ((31 downto 16 => input(31)) & input(31 downto 16)) when "10", -- ASR
           (input(15 downto 0) & input(31 downto 16)) when others; -- ROR
stage16 <= stage16_sh when shamt5(4) = '1' else input;
carryoutSig16 <= input(16) when(shamt5(4) = '1' AND sh = "00") else '0';

-- Shift by 8?
with sh select
stage8_sh <= stage16(23 downto 0) & "00000000" when "00",  -- LSL
           "00000000" & stage16(31 downto 8) when "01",  -- LSR
           ((31 downto 24 => stage16(31)) & stage16(31 downto 8)) when "10", -- ASR
           (stage16(7 downto 0) & stage16(31 downto 8)) when others; -- ROR
stage8 <= stage8_sh when shamt5(3) = '1' else stage16;
carryoutSig8 <= input(8) when(shamt5(3) = '1' AND sh = "00") else carryoutSig16;

-- Shift by 4?
with sh select
stage4_sh <= (stage8(27 downto 0) & "0000") when "00",  -- LSL
           ("0000" & stage8(31 downto 4)) when "01",  -- LSR
           ((31 downto 24 => stage16(31)) & stage16(31 downto 8)) when "10", -- ASR
           (stage16(7 downto 0) & stage16(31 downto 8)) when others; -- ROR
stage4 <= stage4_sh when shamt5(2) = '1' else stage8;
carryoutSig4 <= input(4) when(shamt5(2) = '1' AND sh = "00") else carryoutSig8;

-- Shift by 2?
with sh select
stage2_sh <= (stage4(29 downto 0) & "00") when "00",  -- LSL
           ("00" & stage4(31 downto 2)) when "01",  -- LSR
           ((31 downto 30 => stage4(31)) & stage4(31 downto 2)) when "10", -- ASR
           (stage4(1 downto 0) & stage4(31 downto 2)) when others; -- ROR
stage2 <= stage2_sh when shamt5(1) = '1' else stage4;
carryoutSig2 <= input(2) when(shamt5(1) = '1' AND sh = "00") else carryoutSig4;

-- Shift by 1?
with sh select
stage1_sh <= (stage2(30 downto 0) & '0') when "00",  -- LSL
           ('0' & stage2(31 downto 1)) when "01",  -- LSR
           (stage2(31) & stage2(31 downto 1)) when "10", -- ASR
           (stage2(0) & stage2(31 downto 1)) when others; -- ROR
stage1 <= stage1_sh when shamt5(0) = '1' else stage2;
carryoutSig1 <= input(1) when(shamt5(0) = '1' AND sh = "00") else carryoutSig2;

outputShifted <= stage1;
carryout <= carryoutSig1;

end Behavioral;
