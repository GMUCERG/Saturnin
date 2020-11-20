--------------------------------------------------------------------------------
--! @file       SuperRound.vhd
--! @brief      SuperRound for Saturnin
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

entity SuperRound is
    port(
        clk : in std_logic;
        input : in std_logic_vector(CCW -1 downto 0);
        key : in std_logic_vector(4*CCW -1 downto 0);
        RC : in std_logic_vector(CCW -1 downto 0);
        sel_sigma : in std_logic;
        sel_SR : in std_logic;
        rot : in std_logic_vector(1 downto 0);
        rot_inv : in std_logic_vector(1 downto 0);
        sel_SR_inv : in std_logic;
        en_mds_in : in std_logic;
        en_sbox_r : in std_logic;
        en_mds_out : in std_logic;
        ld_round : in std_logic;
        add_key : in std_logic;
        rot_in : in std_logic;
        shift_mds : in std_logic;
        add_RC : in std_logic;
        output : out std_logic_vector(15 downto 0)
        );
end SuperRound;

-- TODO Change values to constants
architecture Behavioral of SuperRound is
    signal in_sr : std_logic_vector(255 downto 0);
    signal in_sr_out : std_logic_vector(63 downto 0);
    type sbox_arr is array(0 to 15) of std_logic_vector(3 downto 0);
    signal sbox_in : sbox_arr;
    signal sbox_out : sbox_arr;
    signal sbox_out_s : std_logic_vector(63 downto 0);
    
    signal sbox_rot_mux : std_logic_vector(63 downto 0);
    signal mds_in_r : std_logic_vector(255 downto 0);
    signal SR_out : std_logic_vector(63 downto 0);
    signal SR_inv_out : std_logic_vector(63 downto 0);
    signal SR_inv_in : std_logic_vector(63 downto 0);
    type mds_arr is array(0 to 15) of std_logic_vector(15 downto 0);
    signal mds_in : mds_arr;
    signal mds_out : mds_arr;
    signal mds_out_s, mds_out_r : std_logic_vector(255 downto 0);

    signal key_xor : std_logic_vector(4*CCW - 1 downto 0);
    signal RC_mux : std_logic_vector(4*CCW -1 downto 0);
begin

registers : process(clk)
  begin
    if rising_edge(clk) then
        if ld_round = '1' then
            in_sr <= input & in_sr(255 downto 16);
        elsif rot_in = '1' then
          in_sr <= RC_mux & in_sr(255 downto 64);
        end if;
        

        if en_mds_in = '1' then
            mds_in_r <= SR_out & mds_in_r(255 downto 64);
        end if;
        if en_mds_out = '1' then
            mds_out_r <= mds_out_s;
        end if;
        
        if shift_mds = '1' then
            mds_out_r <= (63 downto 0 => '0') & mds_out_r(255 downto 64);
        end if;
    end if;
  end process registers;
  
  
  in_sr_out <= in_sr(63 downto 0);
  sbox_gen : for i in 0 to 15 generate
    sbox_in(i) <= in_sr_out(48+i) & in_sr_out(32+i) & in_sr_out(16+i) & in_sr_out(i);
  i_sbox : entity work.Sbox
        port map(
          sel_sigma => sel_sigma,
          addr => sbox_in(i),
          dout => sbox_out(i)
        );
    sbox_out_s(i) <= sbox_out(i)(0);
    sbox_out_s(16+i) <= sbox_out(i)(1);
    sbox_out_s(32+i) <= sbox_out(i)(2);
    sbox_out_s(48+i) <= sbox_out(i)(3);
  end generate sbox_gen;
  
  
  i_SR : entity work.SR
    generic map(Inverse => 0)
    port map(
        A => sbox_out_s,
        rot => rot,
        sel_slice => sel_SR,
        B => SR_out
    );

  mds_gen : for i in 0 to 15 generate
    mds_in(i) <= mds_in_r(i) &
      mds_in_r(16+i) &
mds_in_r(32+i) &
mds_in_r(48+i) &
mds_in_r(64+i) &
mds_in_r(80+i) &
mds_in_r(96+i) &
mds_in_r(112+i) &
mds_in_r(128+i) &
mds_in_r(144+i) &
mds_in_r(160+i) &
mds_in_r(176+i) &
mds_in_r(192+i) &
mds_in_r(208+i) &
mds_in_r(224+i) &
mds_in_r(240+i);
      i_mds: entity work.MDS(behavioral)
        port map (
          input  => mds_in(i),
          output => mds_out(i));
    mds_out_s(i) <= mds_out(i)(15);
mds_out_s(16+i) <= mds_out(i)(14);
mds_out_s(32+i) <= mds_out(i)(13);
mds_out_s(48+i) <= mds_out(i)(12);
mds_out_s(64+i) <= mds_out(i)(11);
mds_out_s(80+i) <= mds_out(i)(10);
mds_out_s(96+i) <= mds_out(i)(9);
mds_out_s(112+i) <= mds_out(i)(8);
mds_out_s(128+i) <= mds_out(i)(7);
mds_out_s(144+i) <= mds_out(i)(6);
mds_out_s(160+i) <= mds_out(i)(5);
mds_out_s(176+i) <= mds_out(i)(4);
mds_out_s(192+i) <= mds_out(i)(3);
mds_out_s(208+i) <= mds_out(i)(2);
mds_out_s(224+i) <= mds_out(i)(1);
mds_out_s(240+i) <= mds_out(i)(0);
  end generate mds_gen;
  
  
  SR_inv_in <= mds_out_r(63 downto 0);
  
  
  i_SRinv : entity work.SR
    generic map(Inverse => 1)
    port map(
        A => SR_inv_in,
        rot => rot,
        sel_slice => sel_SR,
        B => SR_inv_out
    );

  key_xor <= SR_inv_out xor key when add_key = '1' else SR_inv_out;
  RC_mux <= key_xor(4*CCW -1 downto CCW) &
            (RC xor key_xor(CCW -1 downto 0)) when add_RC = '1' else key_xor;
    output <= in_sr(15 downto 0);
end Behavioral;
