--------------------------------------------------------------------------------
--! @file       SheetRotator.vhd
--! @brief      State rotator
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

entity SheetRotator is
  generic (
    N : integer := 16;
    Inverse : integer := 0
   );
  Port (A : in std_logic_vector(N -1 downto 0);
        B : in std_logic_vector(1 downto 0);
        C : out std_logic_Vector(N-1 downto 0));
end SheetRotator;

architecture Behavioral of SheetRotator is
type array2 is array (0 to 2) of std_logic_vector(N-1 downto 0);
    signal Al : array2;
    signal Ar : array2;
begin



    Al(0) <= A;
    LEFT: if Inverse = 0 generate
        G:
        for i in 0 to 1 generate
            Ar(i) <= Al(i)((N-1)-4*((2**i)) downto 0) & Al(i)((N-1) downto (N-1)-(4*(2**i))+1);
            Al(i+1) <= Al(i) when B(i) = '0' else Ar(i);
        end generate G;
    end generate LEFT;
    RIGHT: if Inverse = 1 generate
        G:
        for i in 0 to 1 generate
            Ar(i) <=  Al(i)(4*(2**i)-1 downto 0) & Al(i)((N-1) downto 4*(2**i));
            Al(i+1) <= Al(i) when B(i) = '0' else Ar(i);
        end generate G;
    end generate RIGHT;
     C <= Al(2);
end Behavioral;
 
