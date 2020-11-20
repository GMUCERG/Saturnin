--------------------------------------------------------------------------------
--! @file       Odd.vhd
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
    input  : in  std_logic_vector(4*CCW -1 downto 0);
    output : out std_logic_vector(CCW -1 downto 0);
    clk : in std_logic;
    load : in std_logic; 
    sel_output : in std_logic_vector(1 downto 0)
    );

end entity Odd;

architecture behavioral of Odd is

  type mds_arr is array(0 to 3) of std_logic_vector(15 downto 0);
  type sbox_arr is array(0 to 15) of std_logic_vector(3 downto 0);
  signal sbox_out_s : sbox_arr;
  signal sbox_out_r : mds_arr;
  signal srr_mux : std_logic_vector(CCW -1 downto 0);
  signal sbox_r: std_logic_vector(4*CCW -1 downto 0);
  signal mds_in : mds_arr;--std_logic_vector(4*CCW -1 downto 0);
  signal mds_out :  mds_arr;--std_logic_vector(4*CCW -1 downto 0);
  signal shift_mux : std_logic_vector(CCW -1 downto 0);
  signal col0_r, col1_r, col2_r, col3_r : std_logic_vector(CCW -1 downto 0);
  signal col0, col1, col2, col3 : std_logic_vector(15 downto 0);
begin  -- architecture behavioral

  registers : process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        for i in 0 to 3 loop
            sbox_out_r(i) <= sbox_out_s(4*i) & sbox_out_s(4*i+1) & sbox_out_s(4*i+2) & sbox_out_s(4*i+3);
        end loop;
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
          addr => input(4*(i+1)-1 downto 4*i),
          dout => sbox_out_s(i)
        );
    end generate sigma_0;
    sigma_1: if i mod 2 = 1 generate
      i_sbox : entity work.Sbox
        generic map(
          sigma => 1
          )
        port map(
          addr => input(4*(i+1)-1 downto 4*i),
          dout => sbox_out_s(i)
        );
    end generate sigma_1;
  end generate sbox_gen;

  mds_in(0) <= sbox_out_r(0)(15 downto 12) & sbox_out_r(1)(11 downto 8) & sbox_out_r(2)(7 downto 4) & sbox_out_r(3)(3 downto 0); 
  mds_in(1) <= sbox_out_r(3)(15 downto 12) & sbox_out_r(0)(11 downto 8) & sbox_out_r(1)(7 downto 4) & sbox_out_r(2)(3 downto 0);
  mds_in(2) <= sbox_out_r(2)(15 downto 12) & sbox_out_r(3)(11 downto 8) & sbox_out_r(0)(7 downto 4) & sbox_out_r(1)(3 downto 0);
  mds_in(3) <= sbox_out_r(1)(15 downto 12) & sbox_out_r(2)(11 downto 8) & sbox_out_r(3)(7 downto 4) & sbox_out_r(0)(3 downto 0);

    mds_gen : for i in 0 to 3 generate
      i_mds: entity work.MDS(behavioral)
        port map (
          input  => mds_in(i),
          output => mds_out(i));
  end generate mds_gen;

  with sel_output select output <=
    mds_out(0)(15 downto 12) & mds_out(1)(11 downto 8) & mds_out(2)(7 downto 4) & mds_out(3)(3 downto 0) when "00",
    mds_out(3)(15 downto 12) & mds_out(0)(11 downto 8) & mds_out(1)(7 downto 4) & mds_out(2)(3 downto 0) when "01",
    mds_out(2)(15 downto 12) & mds_out(3)(11 downto 8) & mds_out(0)(7 downto 4) & mds_out(1)(3 downto 0) when "10",
    mds_out(1)(15 downto 12) & mds_out(2)(11 downto 8) & mds_out(3)(7 downto 4) & mds_out(0)(3 downto 0) when others;


end architecture behavioral;
