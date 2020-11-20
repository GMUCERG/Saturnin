--------------------------------------------------------------------------------
--! @file       RC_DBL.vhd
--! @brief      DBL for RC generation
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
entity RC_DBL is
  generic(
    RC : integer
  );
  port (
    x : in std_logic_vector(CCW -1 downto 0);
    y : out std_logic_vector(CCW -1 downto 0)
);
end RC_DBL;

architecture Behavioral of RC_DBL is
  signal x_msb : std_logic;
begin
  x_msb <= x(CCW -1);
  RC0_gen : if RC = 0 generate
    y(CCW -1 downto 6) <= x(CCW -2 downto 5);
    y(5) <= x(4) xor x_msb;
    y(4) <= x(3);
    y(3) <= x(2) xor x_msb;
    y(2) <= x(1) xor x_msb;
    y(1) <= x(0);
    y(0) <= x_msb;
  end generate RC0_gen;
  RC1_gen : if RC = 1 generate
    y(CCW -1 downto 7) <= x(CCW -2 downto 6);
    y(6) <= x(5) xor x_msb;
    y(5) <= x(4);
    y(4) <= x(3) xor x_msb;
    y(3) <= x(2);
    y(2) <= x(1);
    y(1) <= x(0) xor x_msb;
    y(0) <= x_msb;
  end generate RC1_gen;

end architecture Behavioral;
