--------------------------------------------------------------------------------
--! @file       Saturnin.vhd
--! @brief      Saturnin Block Cipher
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
use ieee.numeric_std.all;
use work.design_pkg.all;

entity Saturnin is
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- data signals
    key : in std_logic_vector(CCW -1 downto 0);
    R : in std_logic_vector(4 downto 0);
    D : in std_logic_vector(3 downto 0);
    din : in std_logic_vector(CCW -1 downto 0);
    dout : out std_logic_vector(CCW -1 downto 0);
   -- interface
    din_valid : in std_logic;
    mode : in std_logic;
    dout_valid : out std_logic;
    dout_ready : in std_logic;
    start : in std_logic;
    stop : in std_logic;
    done : out std_logic
    --rot_key : in std_logic;
    --din : in std_logic_vector(0 to CCW -1);
    --dout : out std_logic_vector(0 to CCW -1);
    --sel_din : in std_logic;
    --sel_key : in std_logic;

);
end Saturnin;
architecture Behavioral of Saturnin is
  --FSM
  type state_t is (RESET,
                   IDLE,
                   CASCADECTR,
                   ROUND,
                   OUTPUT_MSG);

  signal n_state_s, state_s : state_t;

  -- key signals
  signal key_r : std_logic_vector(DBLK_SIZE -1 downto 0);
  signal key_mux : std_logic_vector(CCW -1 downto 0);
  signal key_s : std_logic_vector(CCW -1 downto 0);
  signal key_s256 : std_logic_vector(16*CCW -1 downto 0);
  signal sel_key : std_logic;
  signal ld_key : std_logic;
  signal rot_key16 : std_logic;
  signal rot_key64 : std_logic;
  -- din
  signal sel_din : std_logic;
  signal din_mux : std_logic_vector(CCW -1 downto 0);
  -- RC signals
  signal ld_RC  : std_logic;
  signal en_RC  : std_logic;
  signal sel_RC : std_logic;
  signal add_RC : std_logic;
  signal RC     : std_logic_vector(2*CCW -1 downto 0);
  -- SuperRound signals
  --
  signal mi      : std_logic_vector(15 downto 0);
  signal sel_sigma  : std_logic;
  signal sel_SR     : std_logic;--_vector(1 downto 0);
  signal SR_rot        : std_logic_vector(1 downto 0);
  signal SR_rot_inv    : std_logic_vector(1 downto 0);
  signal sel_SR_inv : std_logic;
  signal en_mds_in  : std_logic;
  signal en_sbox_r  : std_logic;
  signal en_mds_out : std_logic;
  signal ld_round   : std_logic;
  signal rot_in     : std_logic;
  signal shift_mds_out  : std_logic;
  signal add_key    : std_logic;
  signal sel_out : std_logic;
  signal dout_s : std_logic_vector(CCW -1 downto 0);
  signal cascade_key : std_logic_vector(CCW -1 downto 0);
  signal sel_cascade : std_logic;
  signal co     : std_logic_vector(15 downto 0);
 -- counters
  signal word_cnt_r, word_cnt_s : integer range 0 to DBLK_WORDS ;
  signal round_cnt_r, round_cnt_s : integer range 0 to 16;
begin


  FSM_state_register : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state_s <= RESET;
      else
        state_s <= n_state_s;
      end if;
    end if;
  end process FSM_state_register;

  FSM_control_path : process(all)
  begin
    n_state_s <= state_s;
    word_cnt_s <= word_cnt_r;
    round_cnt_s <= round_cnt_r;
    ld_key <= '0';
    rot_key16 <= '0';
    ld_round <= '0';
    en_mds_in <= '0';
    en_mds_out <= '0';
    rot_in <= '0';
    shift_mds_out <= '0';
    sel_sigma <= '0';
    SR_rot <= "00";
    SR_rot_inv <= "00";
    sel_SR <= '0'; --<= "00";
    add_key <= '0';
    sel_key <= '0';
    add_RC <= '0';
    sel_RC <= '0';
    ld_RC <= '0';
    en_RC <= '0';
    done <= '0';
    dout_valid <= '0';
    rot_key64 <= '0';
    sel_cascade <= '0';
    case state_s is
      when RESET =>
        n_state_s <= IDLE;
      when IDLE =>
        word_cnt_s <= 0;
        if start = '1' then
          round_cnt_s <= to_integer(unsigned(R));
          ld_RC <= '1';
          if mode = '1' then
            n_state_s <= CASCADECTR;
          end if;
        end if;

    
      when CASCADECTR =>
        dout_valid <= '1';
        if word_cnt_r = DBLK_WORDS  then
          n_state_s <= ROUND;
          word_cnt_s <= 0;
          round_cnt_s <= to_integer(unsigned(R));
          ld_RC <= '1';
        elsif stop = '1' then
          n_state_s <= IDLE;
          word_cnt_s <= 0;
        elsif din_valid = '1' then
          ld_key <= '1';
          dout_valid <= '1';
          ld_round <= '1';
          sel_cascade <= '1';
          word_cnt_s <= word_cnt_r + 1;
        end if;
      when ROUND =>
        if round_cnt_r mod 2 = 1 then
            sel_SR <= '1';
        --    sel_out <= '1';
            sel_key <= '0';
          else
--            sel_out <= '1';
            sel_key <= '1';
        end if; 
        rot_in <= '1';
        if round_cnt_r = 1 then
            if mode = '1' then
              n_state_s <= CASCADECTR;
            elsif mode = '0' then
              n_state_s <= OUTPUT_MSG;
            end if;
            done <= '1';
            word_cnt_s <= 0;
          else
            en_RC <= '1';
            round_cnt_s <= round_cnt_r - 1;
          end if;
     -- when CTR =>
      --  if word_cnt_r = DBLK_WORDS then
       --   n_state_s <= HALF_EVEN;
        --  word_cnt_s <= 0;
         -- round_cnt_s <= to_integer(unsigned(R));
         -- ld_RC <= '1';
       -- elsif din_valid = '1' then
         -- ld_key <= '1';
          --ld_round <= '1';
          --sel_cascade <= '1';
          --word_cnt_s <= word_cnt_r + 1;
       -- end if;
      when OUTPUT_MSG =>
        dout_valid <= '1';
        if word_cnt_r = DBLK_WORDS -1 or stop = '1' then
         n_state_s <= IDLE;
          word_cnt_s <= 0;
        elsif dout_ready = '1' then
         ld_round <= '1';
         word_cnt_s <= word_cnt_r + 1;
        end if;
      end case;
  end process FSM_control_path;

  counters : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        word_cnt_r <= 0;
        round_cnt_r <= 0;
      else
        word_cnt_r <= word_cnt_s;
        round_cnt_r <= round_cnt_s;
      end if;
    end if;
  end process counters;

  registers: process(clk)
  begin
    if rising_edge(clk) then
      if ld_key = '1' then
        key_r <= key & key_r(DBLK_SIZE - 1 downto CCW);
      end if;
    end if;
  end process registers;





-- Round constants
  i_RC: entity work.RC(Behavioral)
    port map (
      R      => R,
      D      => D,
      ld_RC  => ld_RC,
      en_RC  => en_RC,
     -- sel_RC => sel_RC,
      clk    => clk,
      RC     => RC);


SuperRRound1 : entity work.SuperRound
    port map(
    clk => clk,
    input => mi,
    ld_round => ld_round,
    rot_in => rot_in,
    sel_sheet => sel_SR,
 --   rot_out, en_out : in std_logic;
     key => key_s256,
     RC => RC,
 --       sel_out => sel_out,
     output => co
     );

 
  key_s <= key_r(CCW -1 downto 0);
  key_s256 <= 
              key_r(16*CCW -12 downto 15*CCW) &
              key_r(16*CCW -1 downto 16*CCW -11) &
              key_r(15*CCW -12 downto 14*CCW) &
              key_r(15*CCW -1 downto 15*CCW -11) &
              key_r(14*CCW -12 downto 13*CCW) &
              key_r(14*CCW -1 downto 14*CCW -11) &
              key_r(13*CCW -12 downto 12*CCW) &
              key_r(13*CCW -1 downto 13*CCW -11) &
              key_r(12*CCW -12 downto 11*CCW) &
              key_r(12*CCW -1 downto 12*CCW -11) &
              key_r(11*CCW -12 downto 10*CCW) &
              key_r(11*CCW -1 downto 11*CCW -11) &
              key_r(10*CCW -12 downto 9*CCW) &
              key_r(10*CCW -1 downto 10*CCW -11) &
              key_r(9*CCW -12 downto 8*CCW) &
              key_r(9*CCW -1 downto 9*CCW -11) &
              key_r(8*CCW -12 downto 7*CCW) &
              key_r(8*CCW -1 downto 8*CCW -11) &
              key_r(7*CCW -12 downto 6*CCW) &
              key_r(7*CCW -1 downto 7*CCW -11) &
              key_r(6*CCW -12 downto 5*CCW) &
              key_r(6*CCW -1 downto 6*CCW -11) &
              key_r(5*CCW -12 downto 4*CCW) &
              key_r(5*CCW -1 downto 5*CCW -11) &
              key_r(4*CCW -12 downto 3*CCW) &
              key_r(4*CCW -1 downto 4*CCW -11) &
              key_r(3*CCW -12 downto 2*CCW) &
              key_r(3*CCW -1 downto 3*CCW -11) &
              key_r(2*CCW -12 downto 1*CCW) &
              key_r(2*CCW -1 downto 2*CCW -11) &
              key_r(1*CCW -12 downto 0) &
              key_r(1*CCW -1 downto 1*CCW -11)
              when sel_key = '1' else key_r;
  mi <= din xor key;-- when sel_cascade = '1' else din xor key_s; --when sel_din = '1' else din;
  dout <= co;
end architecture Behavioral;
