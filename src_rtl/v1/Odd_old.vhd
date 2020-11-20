--------------------------------------------------------------------------------
--! @file       Odd_old.vhd
--! @brief      "Odd" part of SuperRound
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


entity Odd is

  port (
    input  : in  std_logic_vector(CCW -1 downto 0);
    output : out std_logic_vector(CCW -1 downto 0);
    clk : in std_logic;
    srr_rot : in std_logic;
    srr_ld : in std_logic;
    en_col : in std_logic_vector(1 downto 0);
    sel_col : in std_logic_vector(1 downto 0);
    sel_output : in std_logic_vector(1 downto 0)
    );

end entity Odd;

architecture behavioral of Odd is

  type sbox_arr is array(0 to 3) of std_logic_vector(3 downto 0);
  signal sbox_out : sbox_arr;
  signal sbox_out_s : std_logic_vector(CCW -1 downto 0);
  signal srr_mux : std_logic_vector(CCW -1 downto 0);
  signal srr_r : std_logic_vector(4*CCW -1 downto 0);
  signal mds_in : std_logic_vector(CCW -1 downto 0);
  signal mds_out :  std_logic_vector(CCW -1 downto 0);
  signal shift_mux : std_logic_vector(CCW -1 downto 0);
  signal col0_r, col1_r, col2_r, col3_r : std_logic_vector(CCW -1 downto 0);
  signal col0, col1, col2, col3 : std_logic_vector(3 downto 0);
begin  -- architecture behavioral

  registers : process(clk)
  begin
    if rising_edge(clk) then
      if srr_ld = '1' then
        srr_r <= srr_r(CCW to 4*CCW -1) & sbox_out_s;
      elsif srr_rot = '1' then
        srr_r <= srr_r(CCW to 4*CCW -1) & srr_r(CCW -1 downto 0);
      end if;
      if en_col = "0001" then
        col0_r <= col0_r(4 to CCW -1) & shift_mux(3 downto 0);
      end if;
      if en_col = "0010" then
        col1_r <= col1_r(4 to CCW -1) & shift_mux(7 downto 4);
      end if;
      if en_col = "0100" then
        col2_r <= col2_r(4 to CCW -1) & shift_mux(11 downto 8);
      end if;
      if en_col = "1000" then
        col3_r <= col3_r(4 to CCW -1) & shift_mux(15 downto 12);
      end if;
    end if;
  end process registers;

  sbox_gen : for i in 0 to 3 generate
    sigma_0: if i mod 2 = 0 generate
      i_sbox : entity work.Sbox
        generic map(
          sigma => 0
          )
        port map(
          addr => input(4*(i+1)-1 downto 4*i),
          dout => sbox_out(i)
        );
    end generate sigma_0;
    sigma_1: if i mod 2 = 1 generate
      i_sbox : entity work.Sbox
        generic map(
          sigma => 1
          )
        port map(
          addr => input(4*(i+1)-1 downto 4*i),
          dout => sbox_out(i)
        );
    end generate sigma_1;
  end generate sbox_gen;

  sbox_out_s <= sbox_out(0) & sbox_out(1) & sbox_out(2) & sbox_out(3);

  col0 <= srr_r(3 downto 0);
  col1 <= srr_r(31 downto 28);
  col2 <= srr_r(43 downto 40);
  col3 <= srr_r(55 downto 52);
  mds_in <= col0 & col1 & col2 & col3;

  i_mds: entity work.MDS(behavioral)
    port map (
      input  => mds_in,
      output => mds_out);

  with sel_col select shift_mux <=
    mds_out when "00",
    mds_out(CCW -1 downto 4) & mds_out(3 downto 0) when "01",
    mds_out(CCW -1 downto 8) & mds_out(7 downto 0) when "10",
    mds_out(CCW -1 downto 12) & mds_out(11 downto 0) when others;

  with sel_output select output <=
    col0_r when "00",
    col1_r when "01",
    col2_r when "10",
    col3_r when others;
end architecture behavioral;
