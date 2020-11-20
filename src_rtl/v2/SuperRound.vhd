--------------------------------------------------------------------------------
--! @file       SuperRound.vhd
--! @brief      Saturnin SupherRound
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SuperRound is
    port (
    clk : std_logic;
    input : std_logic_vector(CCW -1 downto 0);
    ld_round : in std_logic;
    rot_in : in std_logic;
 --   rot_out, en_out : in std_logic;
     key : in std_logic_vector(16*CCW -1 downto 0);
     RC : in std_logic_vector(2*CCW -1 downto 0);
        sel_sheet : in std_logic;
     output : out std_logic_vector(CCW-1 downto 0)
     );
end SuperRound;

architecture Behavioral of SuperRound is
    signal input_sr, output_sr : std_logic_vector(16*CCW -1 downto 0);
    type sbox_arr is array(0 to 63) of std_logic_vector(3 downto 0);
    signal even_sbox_in, even_sbox_out, odd_sbox_in, odd_sbox_out : sbox_arr; 
    signal even_sbox_out_s, odd_sbox_out_s : std_logic_vector(16*CCW -1 downto 0);
    type mds_arr is array(0 to 15) of std_logic_vector(15 downto 0);
    signal even_mds_in, odd_mds_in : mds_arr;
    signal even_mds_out, odd_mds_out : mds_arr;
    signal even_mds_out_s, odd_mds_out_s, odd_mds_in_s : std_logic_vector(255 downto 0);
     
    signal slice_s, inv_slice_s, inv_s, out_s : std_logic_Vector(255 downto 0);
    signal sheet_s, inv_sheet_s : std_logic_vector(255 downto 0);
    
    signal RC_out : std_logic_vector(255 downto 0);
begin
registers : process(clk)
  begin
    if rising_edge(clk) then
         if ld_round = '1' then
            input_sr <= input & input_sr(255 downto 16);
        elsif rot_in = '1' then
          input_sr <= out_s;
        end if;
        
     -- if en_out = '1' then
     --       output_sr <= odd_sbox_out_s;
    --    elsif rot_out = '1' then
  --          output_sr <= x"0000" & output_sr(255 downto 16);
        
        end if;
   -- end if;
  end process registers;
  -- probably should do this in a better way 
  even_sbox_row : for j in 0 to 3 generate
  even_sbox_gen : for i in 0 to 15 generate
     
     sigma0_gen1 : if (j = 0) generate 
     even_sbox_in(16*j+i)  <= input_sr(48+i) & input_sr(32+i) & input_sr(16+i) & input_sr(i);
     i_sbox : entity work.Sbox
        generic map(
            sigma => 0
        )
        port map(
          addr => even_sbox_in(16*j+i) ,
          dout => even_sbox_out(16*j+i) 
        );
        even_sbox_out_s(i) <= even_sbox_out(16*j+i) (0);
        even_sbox_out_s(16+i) <= even_sbox_out(16*j+i) (1);
        even_sbox_out_s(32+i) <= even_sbox_out(16*j+i) (2);
        even_sbox_out_s(48+i) <= even_sbox_out(16*j+i) (3);
     end generate sigma0_gen1;
     
     sigma1_gen1 : if (j = 1)  generate 
     even_sbox_in(16*j+i) <= input_sr(112+i) & input_sr(96+i) & input_sr(80+i) & input_sr(64+i);
     i_sbox : entity work.Sbox
        generic map(
            sigma => 1
        )
        port map(
          addr => even_sbox_in(16*j+i),
          dout => even_sbox_out(16*j+i) 
        );
        even_sbox_out_s(64+i) <= even_sbox_out(16*j+i) (0);
        even_sbox_out_s(80+i) <= even_sbox_out(16*j+i) (1);
        even_sbox_out_s(96+i) <= even_sbox_out(16*j+i) (2);
        even_sbox_out_s(112+i) <= even_sbox_out(16*j+i) (3);
      end generate sigma1_gen1;



sigma0_gen2 : if (j = 2) generate 
     even_sbox_in(16*j+i)  <= input_sr(176+i) & input_sr(160+i) & input_sr(144+i) & input_sr(128+i);
     i_sbox : entity work.Sbox
        generic map(
            sigma => 0
        )
        port map(
          addr => even_sbox_in(16*j+i) ,
          dout => even_sbox_out(16*j+i) 
        );
        even_sbox_out_s(128+i) <= even_sbox_out(16*j+i) (0);
        even_sbox_out_s(144+i) <= even_sbox_out(16*j+i) (1);
        even_sbox_out_s(160+i) <= even_sbox_out(16*j+i) (2);
        even_sbox_out_s(176+i) <= even_sbox_out(16*j+i) (3);
     end generate sigma0_gen2;
     
     sigma1_gen2 : if (j = 3)  generate 
     even_sbox_in(16*j+i)  <= input_sr(240+i) & input_sr(224+i) & input_sr(208+i) & input_sr(192+i);
     i_sbox : entity work.Sbox
        generic map(
            sigma => 1
        )
        port map(
          addr => even_sbox_in(16*j+i) ,
          dout => even_sbox_out(16*j+i) 
        );
        even_sbox_out_s(192+i) <= even_sbox_out(16*j+i) (0);
        even_sbox_out_s(208+i) <= even_sbox_out(16*j+i) (1);
        even_sbox_out_s(224+i) <= even_sbox_out(16*j+i) (2);
        even_sbox_out_s(240+i) <= even_sbox_out(16*j+i) (3);
      end generate sigma1_gen2;
    
 end generate even_sbox_gen;
 end generate even_sbox_row;
 
 
  mds_gen : for i in 0 to 15 generate
    even_mds_in(i) <= even_sbox_out_s(i) &
      even_sbox_out_s(16+i) &
even_sbox_out_s(32+i) &
even_sbox_out_s(48+i) &
even_sbox_out_s(64+i) &
even_sbox_out_s(80+i) &
even_sbox_out_s(96+i) &
even_sbox_out_s(112+i) &
even_sbox_out_s(128+i) &
even_sbox_out_s(144+i) &
even_sbox_out_s(160+i) &
even_sbox_out_s(176+i) &
even_sbox_out_s(192+i) &
even_sbox_out_s(208+i) &
even_sbox_out_s(224+i) &
even_sbox_out_s(240+i);
      i_mds: entity work.MDS(behavioral)
        port map (
          input  => even_mds_in(i),
          output => even_mds_out(i));
    even_mds_out_s(i) <= even_mds_out(i)(15);
even_mds_out_s(16+i) <= even_mds_out(i)(14);
even_mds_out_s(32+i) <= even_mds_out(i)(13);
even_mds_out_s(48+i) <= even_mds_out(i)(12);
even_mds_out_s(64+i) <= even_mds_out(i)(11);
even_mds_out_s(80+i) <= even_mds_out(i)(10);
even_mds_out_s(96+i) <= even_mds_out(i)(9);
even_mds_out_s(112+i) <= even_mds_out(i)(8);
even_mds_out_s(128+i) <= even_mds_out(i)(7);
even_mds_out_s(144+i) <= even_mds_out(i)(6);
even_mds_out_s(160+i) <= even_mds_out(i)(5);
even_mds_out_s(176+i) <= even_mds_out(i)(4);
even_mds_out_s(192+i) <= even_mds_out(i)(3);
even_mds_out_s(208+i) <= even_mds_out(i)(2);
even_mds_out_s(224+i) <= even_mds_out(i)(1);
even_mds_out_s(240+i) <= even_mds_out(i)(0);
  end generate mds_gen;
   odd_sbox_row : for j in 0 to 3 generate

   odd_sbox_gen : for i in 0 to 15 generate
     
     sigma0_gen1 : if (j = 0) generate 
     odd_sbox_in(16*j+i)  <= even_mds_out_s(48+i) & even_mds_out_s(32+i) & even_mds_out_s(16+i) & even_mds_out_s(i);
     i_sbox : entity work.Sbox
        generic map(
            sigma => 0
        )
        port map(
          addr => odd_sbox_in(16*j+i) ,
          dout => odd_sbox_out(16*j+i) 
        );
        odd_sbox_out_s(i) <= odd_sbox_out(16*j+i) (0);
        odd_sbox_out_s(16+i) <= odd_sbox_out(16*j+i) (1);
        odd_sbox_out_s(32+i) <= odd_sbox_out(16*j+i) (2);
        odd_sbox_out_s(48+i) <= odd_sbox_out(16*j+i) (3);
     end generate sigma0_gen1;
     
     sigma1_gen1 : if (j = 1)  generate 
     odd_sbox_in(16*j+i)  <= even_mds_out_s(112+i) & even_mds_out_s(96+i) & even_mds_out_s(80+i) & even_mds_out_s(64+i);
     i_sbox : entity work.Sbox
        generic map(
            sigma => 1
        )
        port map(
          addr => odd_sbox_in(16*j+i) ,
          dout => odd_sbox_out(16*j+i) 
        );
        odd_sbox_out_s(64+i) <= odd_sbox_out(16*j+i) (0);
        odd_sbox_out_s(80+i) <= odd_sbox_out(16*j+i) (1);
        odd_sbox_out_s(96+i) <= odd_sbox_out(16*j+i) (2);
        odd_sbox_out_s(112+i) <= odd_sbox_out(16*j+i) (3);
      end generate sigma1_gen1;
 
     sigma0_gen2 : if (j = 2) generate 
     odd_sbox_in(16*j+i)  <= even_mds_out_s(176+i) & even_mds_out_s(160+i) & even_mds_out_s(144+i) & even_mds_out_s(128+i);
     i_sbox : entity work.Sbox
        generic map(
            sigma => 0
        )
        port map(
          addr => odd_sbox_in(16*j+i) ,
          dout => odd_sbox_out(16*j+i) 
        );
        odd_sbox_out_s(128+i) <= odd_sbox_out(16*j+i) (0);
        odd_sbox_out_s(144+i) <= odd_sbox_out(16*j+i) (1);
        odd_sbox_out_s(160+i) <= odd_sbox_out(16*j+i) (2);
        odd_sbox_out_s(176+i) <= odd_sbox_out(16*j+i) (3);
     end generate sigma0_gen2;
     
     sigma1_gen2 : if (j = 3)  generate 
     odd_sbox_in(16*j+i)  <= even_mds_out_s(240+i) & even_mds_out_s(224+i) & even_mds_out_s(208+i) & even_mds_out_s(192+i);
     i_sbox : entity work.Sbox
        generic map(
            sigma => 1
        )
        port map(
          addr => odd_sbox_in(16*j+i) ,
          dout => odd_sbox_out(16*j+i) 
        );
        odd_sbox_out_s(192+i) <= odd_sbox_out(16*j+i) (0);
        odd_sbox_out_s(208+i) <= odd_sbox_out(16*j+i) (1);
        odd_sbox_out_s(224+i) <= odd_sbox_out(16*j+i) (2);
        odd_sbox_out_s(240+i) <= odd_sbox_out(16*j+i) (3);
      end generate sigma1_gen2;
 end generate odd_sbox_gen;
 end generate odd_sbox_row;

    Sheet_gen : for j in 0 to 15 generate
        first: if j >= 0 and j < 4 generate
           sheet_s((j+1)*CCW -1 downto j*CCW) <= odd_sbox_out_s((j+1)*CCW -1 downto j*CCW);  
        end generate first;
        second: if j >= 4 and j < 8 generate
            sheet_s((j+1)*CCW -1 downto j*CCW) <= odd_sbox_out_s(((j+1)*CCW -1)-4 downto j*CCW) & odd_sbox_out_s(((j+1)*CCW -1) downto ((j+1)*CCW -1)-4+1);
        end generate second;
        third: if j >= 8 and j <12 generate
            sheet_s((j+1)*CCW -1 downto j*CCW) <= odd_sbox_out_s(((j+1)*CCW -1)-8 downto j*CCW) & odd_sbox_out_s(((j+1)*CCW -1) downto ((j+1)*CCW -1)-8+1);
        end generate third;
        fourth: if j >= 12 and j < 16 generate
            sheet_s((j+1)*CCW -1 downto j*CCW) <= odd_sbox_out_s(((j+1)*CCW -1)-12 downto j*CCW) & odd_sbox_out_s(((j+1)*CCW -1) downto ((j+1)*CCW -1)-12+1);
        end generate fourth;
    end generate Sheet_gen;
    
    slice_gen : for i in 0 to 3 generate
        inner : for j in 0 to 15 generate
            first: if j >= 0 and j < 4 generate
                slice_s((4*i)+(16*j)+3 downto (4*i)+(16*j)) <= odd_sbox_out_s((4*i)+(16*j)+3 downto (4*i)+(16*j));
            end generate first;
            second: if j >= 4 and j < 8 generate
                slice_s((4*i)+(16*j)+3 downto (4*i)+(16*j)) <= odd_sbox_out_s((4*i)+(16*j)+3 -1 downto (4*i)+(16*j)) & odd_sbox_out_s((4*i)+(16*j)+3 downto (4*i)+(16*j)+3);
            end generate second;
            third: if j >= 8 and j <12 generate
                slice_s((4*i)+(16*j)+3 downto (4*i)+(16*j)) <= odd_sbox_out_s((4*i)+(16*j)+3-2 downto (4*i)+(16*j)) & odd_sbox_out_s((4*i)+(16*j)+3 downto (4*i)+(16*j)+3 -2 +1);
            end generate third;
            fourth: if j >= 12 and j < 16 generate
                slice_s((4*i)+(16*j)+3 downto (4*i)+(16*j)) <= odd_sbox_out_s((4*i)+(16*j)+3-3 downto (4*i)+(16*j)) & odd_sbox_out_s((4*i)+(16*j)+3 downto (4*i)+(16*j)+3 -3 +1);
            end generate fourth;
       end generate inner;
   end generate slice_gen;
   
   odd_mds_in_s <= sheet_s when sel_sheet = '1' else slice_s;
   odd_mds_gen : for i in 0 to 15 generate
    odd_mds_in(i) <= odd_mds_in_s(i) &
      odd_mds_in_s(16+i) &
odd_mds_in_s(32+i) &
odd_mds_in_s(48+i) &
odd_mds_in_s(64+i) &
odd_mds_in_s(80+i) &
odd_mds_in_s(96+i) &
odd_mds_in_s(112+i) &
odd_mds_in_s(128+i) &
odd_mds_in_s(144+i) &
odd_mds_in_s(160+i) &
odd_mds_in_s(176+i) &
odd_mds_in_s(192+i) &
odd_mds_in_s(208+i) &
odd_mds_in_s(224+i) &
odd_mds_in_s(240+i);
      i_mds: entity work.MDS(behavioral)
        port map (
          input  => odd_mds_in(i),
          output => odd_mds_out(i));
    odd_mds_out_s(i) <= odd_mds_out(i)(15);
odd_mds_out_s(16+i) <= odd_mds_out(i)(14);
odd_mds_out_s(32+i) <= odd_mds_out(i)(13);
odd_mds_out_s(48+i) <= odd_mds_out(i)(12);
odd_mds_out_s(64+i) <= odd_mds_out(i)(11);
odd_mds_out_s(80+i) <= odd_mds_out(i)(10);
odd_mds_out_s(96+i) <= odd_mds_out(i)(9);
odd_mds_out_s(112+i) <= odd_mds_out(i)(8);
odd_mds_out_s(128+i) <= odd_mds_out(i)(7);
odd_mds_out_s(144+i) <= odd_mds_out(i)(6);
odd_mds_out_s(160+i) <= odd_mds_out(i)(5);
odd_mds_out_s(176+i) <= odd_mds_out(i)(4);
odd_mds_out_s(192+i) <= odd_mds_out(i)(3);
odd_mds_out_s(208+i) <= odd_mds_out(i)(2);
odd_mds_out_s(224+i) <= odd_mds_out(i)(1);
odd_mds_out_s(240+i) <= odd_mds_out(i)(0);
  end generate odd_mds_gen;
  --(4*(2**i)-1 downto 0) & Al(i)((N-1) downto 4*(2**i)
  inv_Sheet_gen : for j in 0 to 15 generate
        first: if j >= 0 and j < 4 generate
           inv_sheet_s((j+1)*CCW -1 downto j*CCW) <= odd_mds_out_s((j+1)*CCW -1 downto j*CCW);  
        end generate first;
        second: if j >= 4 and j < 8 generate
            inv_sheet_s((j+1)*CCW -1 downto j*CCW) <= odd_mds_out_s((j*CCW+4-1) downto j*CCW) & odd_mds_out_s(((j+1)*CCW -1) downto j*CCW+4);
        end generate second;
        third: if j >= 8 and j <12 generate
            inv_sheet_s((j+1)*CCW -1 downto j*CCW) <= odd_mds_out_s((j*CCW+8-1) downto j*CCW) & odd_mds_out_s(((j+1)*CCW -1) downto j*CCW+8);
        end generate third;
        fourth: if j >= 12 and j < 16 generate
            inv_sheet_s((j+1)*CCW -1 downto j*CCW) <= odd_mds_out_s((j*CCW+12-1) downto j*CCW) & odd_mds_out_s(((j+1)*CCW -1) downto j*CCW+12);
        end generate fourth;
    end generate inv_Sheet_gen;
    
    inv_slice_gen : for i in 0 to 3 generate
        inner : for j in 0 to 15 generate
            first: if j >= 0 and j < 4 generate
                inv_slice_s((4*i)+(16*j)+3 downto (4*i)+(16*j)) <= odd_mds_out_s((4*i)+(16*j)+3 downto (4*i)+(16*j));
            end generate first;
            second: if j >= 4 and j < 8 generate
                inv_slice_s((4*i)+(16*j)+3 downto (4*i)+(16*j)) <= odd_mds_out_s((4*i)+(16*j) downto (4*i)+(16*j)) & odd_mds_out_s((4*i)+(16*j)+3 downto (4*i)+(16*j)+1);
            end generate second;
            third: if j >= 8 and j <12 generate
                inv_slice_s((4*i)+(16*j)+3 downto (4*i)+(16*j)) <= odd_mds_out_s((4*i)+(16*j)+2-1 downto (4*i)+(16*j)) & odd_mds_out_s((4*i)+(16*j)+3 downto (4*i)+(16*j)+2);
            end generate third;
            fourth: if j >= 12 and j < 16 generate
                inv_slice_s((4*i)+(16*j)+3 downto (4*i)+(16*j)) <= odd_mds_out_s((4*i)+(16*j)+3-1 downto (4*i)+(16*j)) & odd_mds_out_s((4*i)+(16*j)+3 downto (4*i)+(16*j)+3);
            end generate fourth;
       end generate inner;
   end generate inv_slice_gen;
   
   inv_s <= inv_sheet_s when sel_sheet = '1' else inv_slice_s;
   RC_out(127 downto 16) <= inv_s(127 downto 16);
   RC_out(15 downto 0) <= inv_s(15 downto 0) xor RC(15 downto 0);
   RC_out(143 downto 128) <= inv_s(143 downto 128) xor RC(31 downto 16);
   RC_out(255 downto 144) <= inv_s(255 downto 144);
    out_s <= RC_out xor key;
 output <= input_sr(CCW -1 downto 0); --output_sr(CCW -1 downto 0);

end Behavioral;
