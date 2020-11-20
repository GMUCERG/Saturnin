--------------------------------------------------------------------------------
--! @file       Even.vhd
--! @brief      "Even" round part of the SuperRound
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
         shift_col : in std_logic_vector(1 downto 0);
         en_shift : in std_logic;
         sel_col : in std_logic_vector(1 downto 0);
         output     : out std_logic_vector(CCW -1 downto 0)
    );
end Even;

architecture behavioral of Even is
  signal col0_sr, col1_sr, col2_sr, col3_sr : std_logic_vector(4*CCW -1 downto 0);
  signal col_mux : std_logic_vector(CCW -1 downto 0);

  signal shift_col_s : std_logic_vector(3 downto 0);

  type sbox_arr is array(0 to 3) of std_logic_vector(3 downto 0);
  signal sbox_out : sbox_arr;
  signal mds_in : std_logic_vector(CCW -1 downto 0);
begin
-- TODO set 15 -> CCW and 63 -> constant
  registers : process(clk)
  begin
    if rising_edge(clk) then
      if shift_col_s = "0001" then
        col0_sr <= input & col0_sr(4*CCW -1 downto CCW);
      end if;
      if shift_col_s = "0010" then
        col1_sr <= input & col1_sr(4*CCW -1 downto CCW);
      end if;
      if shift_col_s = "0100" then
        col2_sr <= input & col2_sr(4*CCW -1 downto CCW);
      end if;
      if shift_col_s = "1000" then
        col3_sr <= input & col3_sr(4*CCW -1 downto CCW);
      end if;
    end if;
  end process registers;

  with (en_shift & shift_col) select shift_col_s <=
    "0001" when "100",
    "0010" when "101",
    "0100" when "110",
    "1000" when "111",
    "0000" when others;


  with sel_col select col_mux <=
    col0_sr(CCW -1 downto 0) when "00",
    col1_sr(CCW -1 downto 0) when "01",
    col2_sr(CCW -1 downto 0) when "10",
    col3_sr(CCW -1 downto 0) when others;

  sbox_gen : for i in 0 to 3 generate
    sigma_0: if i mod 2 = 0 generate
      i_sbox : entity work.Sbox
        generic map(
          sigma => 0
          )
        port map(
          addr => col_mux(4*(i+1)-1 downto 4*i),
          dout => sbox_out(i)
        );
    end generate sigma_0;
    sigma_1: if i mod 2 = 1 generate
      i_sbox : entity work.Sbox
        generic map(
          sigma => 1
          )
        port map(
          addr => col_mux(4*(i+1)-1 downto 4*i),
          dout => sbox_out(i)
        );
    end generate sigma_1;
  end generate sbox_gen;

  mds_in <= sbox_out(0) & sbox_out(1) & sbox_out(2) & sbox_out(3);

 i_mds: entity work.MDS(behavioral)
    port map (
      input  => mds_in,
      output => output);

end behavioral;
