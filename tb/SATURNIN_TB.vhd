----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/27/2019 06:51:19 PM
-- Design Name: 
-- Module Name: SATURNIN_TB - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SATURNIN_TB is
--  Port ( );
end SATURNIN_TB;

architecture Behavioral of SATURNIN_TB is
Constant LOAD        : STD_LOGIC_VECTOR(3 downto 0) := "0001";
Constant XOR_KEY     : STD_LOGIC_VECTOR(3 downto 0) := "0010";
Constant SBOX        : STD_LOGIC_VECTOR(3 downto 0) := "0011";
Constant MDS         : STD_LOGIC_VECTOR(3 downto 0) := "0100";
Constant SRSHEET     : STD_LOGIC_VECTOR(3 downto 0) := "0101";
Constant SRSHEETINV  : STD_LOGIC_VECTOR(3 downto 0) := "0110";
Constant SRSLICE     : STD_LOGIC_VECTOR(3 downto 0) := "0111";
Constant SRSLICEINV  : STD_LOGIC_VECTOR(3 downto 0) := "1000";
Constant XOR_RC      : STD_LOGIC_VECTOR(3 downto 0) := "1001";
Constant OFFLOAD     : STD_LOGIC_VECTOR(3 downto 0) := "1010";
Constant W8          : STD_LOGIC_VECTOR(3 downto 0) := "1011";

type INST_ARRAY is array(0 to 17) of STD_LOGIC_VECTOR(3 downto 0);

Constant INST_ORDER  : INST_ARRAY := (LOAD,SBOX,MDS,SBOX,SRSHEET,MDS,SRSHEETINV,XOR_RC,XOR_KEY,SBOX,MDS,SBOX,SRSLICE,MDS,SRSLICEINV,XOR_RC,XOR_KEY,W8);

component SATURNIN 
    Generic( 
    DATA_WIDTH      : integer 
);
Port(
    Din             : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    Dout            : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    Dout_sel        : in STD_LOGIC_VECTOR(2 downto 0);
    Inst_Clk_Rst    : in STD_LOGIC;
    Inst_Mode       : in STD_LOGIC_VECTOR(3 downto 0);
    Inst_set_Done   : out STD_LOGIC;
    Inst_En         : in STD_LOGIC;
    clk             : in STD_LOGIC;
    RC_In           : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    KEY_In          : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0));
      
end component;    

SIGNAL reset        : STD_LOGIC;
SIGNAL TestClk      : STD_LOGIC := '0';
CONSTANT ClkPeriod  : TIME := 10ns;
Signal Inst_Mode_Tmp: STD_LOGIC_VECTOR(3 downto 0);
Signal Inst_en_Tmp  : STD_LOGIC;
Signal Inst_Set_Done_Tmp: STD_LOGIC;
Signal Inst_Clk_Rst_Tmp : STD_LOGIC;
Signal SBED_In      : STD_LOGIC_VECTOR(31 downto 0);
Signal SBED_Out     : STD_LOGIC_VECTOR(31 downto 0);
Signal SBED_Out_Sel : STD_LOGIC_VECTOR(2 downto 0);
Signal RC           : STD_LOGIC_VECTOR(31 downto 0);
Signal Key          : STD_LOGIC_VECTOR(31 downto 0);


begin

TestClk <= NOT TestClk AFTER ClkPeriod/2;

uut:  SATURNIN 
generic map (DATA_WIDTH => 32)
port map( Din => SBED_In,  RC_In => RC, Key_In => Key, Dout_Sel => SBED_Out_Sel, Inst_Clk_Rst => Inst_Clk_Rst_Tmp, Inst_Mode => Inst_Mode_Tmp, Inst_En => Inst_En_Tmp, --stim file
          Inst_Set_Done => Inst_Set_Done_Tmp, Dout => SBED_Out, --KAT
          clk => TestClk);
          
stimulus: PROCESS
    begin
-- load
        RC              <= x"98765432";
        Key             <= x"24354657";
        SBED_In         <= x"12345678";
--        Inst_Clk_Rst_tmp<= '1';
--        Inst_En_Tmp     <= '0';
--        wait for ClkPeriod*5;

--        Inst_Clk_Rst_tmp<= '0';   
--        wait for ClkPeriod;    

--        Inst_Mode_tmp   <= LOAD;
--        Inst_En_Tmp     <= '1';
--        wait until Inst_Set_Done_Tmp = '1';
        
--        Inst_En_Tmp     <= '0';
--        Inst_Clk_Rst_tmp<= '1';       
--        wait for ClkPeriod*5;

--        Inst_Clk_Rst_tmp<= '0';               
--        Inst_En_Tmp     <= '1';    
--        Inst_Mode_Tmp   <= SBOX;
--        wait until Inst_Set_Done_Tmp = '1';
        
--        Inst_En_Tmp     <= '0';
--        Inst_Clk_Rst_tmp<= '1';
--        wait for ClkPeriod*5;

--        Inst_Clk_Rst_tmp<= '0';       
--        Inst_Mode_Tmp   <= MDS;        
--        Inst_En_Tmp     <= '1'; 
--        wait until Inst_Set_Done_Tmp = '1';

--        Inst_En_Tmp     <= '0';
--        Inst_Clk_Rst_tmp<= '1';
    FOR INST_NUM in INST_ORDER'range loop
        Inst_Clk_Rst_Tmp    <= '1';
        Inst_En_Tmp         <= '0';
        Inst_Mode_Tmp       <= INST_ORDER(INST_NUM);
        wait for ClkPeriod;
        Inst_Clk_Rst_Tmp    <= '0';
        Inst_En_Tmp         <= '1';
        wait until Inst_Set_Done_Tmp = '1';
    end loop;        
        wait;
        
end process;


end Behavioral;
