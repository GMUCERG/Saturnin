--------------------------------------------------------------------------------
--! @file       Sbox.vhd
--! @brief      Sbox primitive
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
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Sbox is
  generic (
    sigma : integer
);
port (
        addr : in  std_logic_vector(3 downto 0);
        dout : out std_logic_vector(3 downto 0)
    );
end Sbox;

architecture Behavioral of Sbox is

type rom_type is array(0 to 2**4 - 1) of std_logic_vector(3 downto 0);
    signal ROM : rom_type;              -- :=

    attribute rom_style        : string;
    attribute rom_style of ROM : signal is "distributed";

begin

  sigma0ROM : if sigma = 0 generate
    ROM <= (
        -- sigma_0 sbox
        x"0", x"6", x"e", x"1",
        x"f", x"4", x"7", x"d",
        x"9", x"8", x"c", x"5",
        x"2", x"a", x"3", x"b"
        );
  end generate sigma0ROM;

  sigma1ROM : if sigma = 1 generate
    ROM <= (
        -- sigma_1 sbox
        x"0", x"9", x"d", x"2",
        x"f", x"1", x"b", x"7",
        x"6", x"4", x"5", x"3",
        x"8", x"c", x"a", x"e"
        );
  end generate sigma1ROM;
 
    dout <= ROM(to_integer(unsigned(addr)));  -- async read


end Behavioral;
