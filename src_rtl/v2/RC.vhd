--------------------------------------------------------------------------------
--! @file       RC.vhd
--! @brief      Round Constant generation
--! @author     Rishub Nagpal <rnagpal2@gmu.edu>
--! @copyright  Copyright (c) 2020 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
--! @license    This project is released under the GNU Public License.
--!             The license and distribution terms for this file may be
--!             found in the file LICENSE in this distribution or at
--!             http://www.gnu.org/licenses/gpl-3.0.txt
--! @note       This is publicly available encryption source code that falls
--!             under the License Exception TSU (Technology and software-
--!             unrestricted)
-------------------------------------------------------------------------------- 
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.design_pkg.all;

entity RC is
  port (
    R : in std_logic_vector(4 downto 0);
    D : in std_logic_vector(3 downto 0);
    ld_RC : in std_logic;
    en_RC : in std_logic;
  --  sel_RC : in std_logic;
    clk : in std_logic;
    RC : out std_logic_vector(2*CCW -1 downto 0)
    );
end RC;

architecture Behavioral of RC is
  signal RC0_r, RC1_r : std_logic_vector(CCW -1 downto 0);
  signal RC0_dbl, RC1_dbl : std_logic_vector(CCW -1 downto 0);
  signal RC_mux : std_logic_vector(CCW -1 downto 0);
  signal init : std_logic_vector(CCW -1 downto 0); -- initial state of RC registers
  
  type RC_arr is array(0 to 16) of std_logic_vector(CCW -1 downto 0);
  signal RC0 : RC_arr;
  signal RC1 : RC_arr;
begin

  registers : process(clk)
  begin
    if rising_edge(clk) then
      if ld_RC = '1' then
        RC0_r <= init;
        RC1_r <= init;
      elsif en_RC = '1' then
        RC0_r <= RC0(16);
        RC1_r <= RC1(16);
      end if;
    end if;
  end process registers;

  init <= "1111111" & R & D;
  RC0(0) <= RC0_r;
  RC1(0) <= RC1_r;
  RC_gen : for i in 0 to 15 generate
  i_RC0: entity work.RC_DBL
    generic map (
      RC => 0)
    port map (
      x       => RC0(i),
      y => RC0(i+1));
  i_RC1: entity work.RC_DBL
    generic map (
      RC => 1)
    port map (
      x       => RC1(i),
      y => RC1(i+1));
  end generate RC_gen;

  RC <= RC1(16) & RC0(16);

end architecture Behavioral;
