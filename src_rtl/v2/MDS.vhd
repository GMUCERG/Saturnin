--------------------------------------------------------------------------------
--! @file       MDS.vhd
--! @brief      Implementation of MDS matrix
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
use IEEE.STD_LOGIC_1164.ALL;
use work.design_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MDS is
  Port ( input : in std_logic_vector(CCW -1 downto 0);
         output : out std_logic_vector(CCW -1 downto 0));
end MDS;

architecture Behavioral of MDS is
    signal a, b, c ,d : std_logic_vector(3 downto 0);
    signal a_alpha, a_alpha2 : std_logic_vector(3 downto 0);
    signal a_xor, a_alpha_xor : std_logic_vector(3 downto 0);
    
    signal b_alpha, b_alpha_xor, b_alpha_xor2 : std_logic_vector(3 downto 0);
    signal c_alpha, c_alpha2 : std_logic_vector(3 downto 0);
    signal c_xor, c_alpha_xor : std_logic_vector(3 downto 0);
    signal d_alpha, d_alpha_xor, d_alpha_xor2 : std_logic_vector(3 downto 0);
    

begin
    d <= input(3 downto 0);
    c <= input(7 downto 4);
    b <= input(11 downto 8);
    a <= input(15 downto 12);
    
    --a
    a_xor <= a xor b;
    
    
    i_a_alpha : entity work.alpha2
        port map(
            a_in => a_xor,
            a_out => a_alpha
        );
    
    a_alpha_xor <= a_alpha xor b_alpha_xor;
    
    output(15 downto 12) <=  a_alpha_xor;
    
    -- b
        i_b_alpha : entity work.alpha
        port map(
            a_in => b,
            a_out => b_alpha
        );
    
    b_alpha_xor <= b_alpha xor c_xor;
    b_alpha_xor2 <= c_alpha_xor xor b_alpha_xor;
    
    output(11 downto 8) <= b_alpha_xor2;
    
    -- c
    c_xor <= c xor d;
    
    
    i_c_alpha : entity work.alpha2
        port map(
            a_in => c_xor,
            a_out => c_alpha
        );
    
    c_alpha_xor <= c_alpha xor d_alpha_xor;
    
    output(7 downto 4) <=  c_alpha_xor;
    
    -- d
         i_d_alpha : entity work.alpha
        port map(
            a_in => d,
            a_out => d_alpha
        );
    
    d_alpha_xor <= d_alpha xor a_xor;
    d_alpha_xor2 <= a_alpha_xor xor d_alpha_xor;
    
    output(3 downto 0) <= d_alpha_xor2;
end Behavioral;
