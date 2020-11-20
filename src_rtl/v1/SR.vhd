--------------------------------------------------------------------------------
--! @file       SR.vhd
--! @brief      Sheet/slice rotator
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

entity SR is
  generic(Inverse : integer := 0);
  Port ( A : in std_logic_Vector(63 downto 0);
         sel_slice : std_logic;
         rot : std_logic_vector(1 downto 0);
         B : out std_logic_Vector(63 downto 0));
end SR;

architecture Behavioral of SR is
    type sheet_arr is array(0 to 3) of std_logic_vector(15 downto 0);
    type slice_arr is array(0 to 15) of std_logic_vector(3 downto 0);
    signal sheet_in, sheet_out : sheet_arr;
    signal slice_in, slice_out : slice_arr;
    signal slice_out_s, sheet_out_s : std_logic_Vector(63 downto 0);
begin
    sheet: for i in 0 to 3 generate
        sheet_in(i) <= A(16*(i+1)-1 downto 16*i);
      i_Sheet : entity work.SheetRotator
        generic map( N => 16, Inverse => Inverse)
        port map(
            A =>  sheet_in(i),
            B => rot,
            C => sheet_out(i)
        );
     sheet_out_s(16*(i+1)-1 downto 16*i) <= sheet_out(i);
    end generate sheet;
    
    slice: for i in 0 to 15 generate
        slice_in(i) <= A(4*(i+1)-1 downto 4*i);
      i_slice : entity work.VariableRotator
        generic map( N => 4, Inverse => Inverse)
        port map(
            A =>  slice_in(i),
            B => rot,
            C => slice_out(i)
        );
        slice_out_s(4*(i+1)-1 downto 4*i) <= slice_out(i);
    end generate slice;
    
    B <= slice_out_s when sel_slice = '0' else sheet_out_s;
    
end Behavioral;
 
