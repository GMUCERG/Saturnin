--------------------------------------------------------------------------------
--! @file       Alpha2.vhd
--! @brief      Alpha-squared
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity alpha2 is
  Port ( a_in : in std_logic_vector(3 downto 0);
         a_out : out std_logic_vector(3 downto 0));
end alpha2;

architecture Behavioral of alpha2 is
    signal alpha1_out : std_logic_vector(3 downto 0);
begin

    i_a_alpha : entity work.alpha
    port map(
        a_in => a_in,
        a_out => alpha1_out
    );
    
   i_a_alpha2 : entity work.alpha
        port map(
            a_in => alpha1_out,
            a_out => a_out
        ); 

end Behavioral;
