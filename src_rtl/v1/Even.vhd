--------------------------------------------------------------------------------
--! @file       Even.vhd
--! @brief      "Even" part of the SuperRound
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

entity Even is
  Port (
         clk : in std_logic;
         input       : in  std_logic_vector(CCW -1 downto 0);
         shift_in : in std_logic;
         output     : out std_logic_vector(4*CCW -1 downto 0)
    );
end Even;

architecture behavioral of Even is
  signal sr : std_logic_vector(4*CCW -1 downto 0);
  signal col_mux : std_logic_vector(CCW -1 downto 0);

  signal shift_col_s : std_logic_vector(3 downto 0);
  
  type reg_arr is array(0 to 3) of std_logic_Vector(15 downto 0);
  type sbox_arr is array(0 to 15) of std_logic_vector(3 downto 0);
  signal sbox_out : sbox_arr;
  signal sr_out : reg_arr;
  signal mds_in,mds_out : reg_arr;-- std_logic_vector(CCW -1 downto 0);
begin
-- TODO set 15 -> CCW and 63 -> constant
  registers : process(clk)
  begin
    if rising_edge(clk) then
      if shift_in = '1' then
        sr <= input & sr(4*CCW -1 downto CCW);
      end if;
    end if;
  end process registers;



  sbox_gen : for i in 0 to 15 generate
    sigma_0: if i mod 2 = 0 generate
        
      i_sbox : entity work.Sbox
        generic map(
          sigma => 0
          )
        port map(
          addr => sr(4*(i+1)-1 downto 4*i),
          dout => sbox_out(i)
        );
    end generate sigma_0;
    sigma_1: if i mod 2 = 1 generate
      i_sbox : entity work.Sbox
        generic map(
          sigma => 1
          )
        port map(
          addr => sr(4*(i+1)-1 downto 4*i),
          dout => sbox_out(i)
        );
    end generate sigma_1;
  end generate sbox_gen;
  
  mds_gen : for i in 0 to 3 generate
    mds_in(i) <= (sbox_out(4*i+0) & sbox_out(4*i+1) & sbox_out(4*i+2) & sbox_out(4*i+3));
      i_mds: entity work.MDS(behavioral)
        port map (
          input  => mds_in(i),
          output => mds_out(i));
  end generate mds_gen;

  output <= mds_out(0) & mds_out(1) & mds_out(2) & mds_out(3);

end behavioral;
