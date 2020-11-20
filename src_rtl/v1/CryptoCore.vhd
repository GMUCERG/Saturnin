--------------------------------------------------------------------------------
--! @file       CryptoCore.vhd
--! @brief      Top level file for Saturnin Cipher
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


library ieee;
use ieee.numeric_std.all;
use ieee.STD_LOGIC_1164.all;
use work.NIST_LWAPI_pkg.all;
use work.design_pkg.all;


entity CryptoCore is
    port (
        clk             : in   STD_LOGIC;
        rst             : in   STD_LOGIC;
        --PreProcessor===============================================
        ----!key----------------------------------------------------
        key             : in   STD_LOGIC_VECTOR (CCSW     -1 downto 0);
        key_valid       : in   STD_LOGIC;
        key_ready       : out  STD_LOGIC;
        ----!Data----------------------------------------------------
        bdi             : in   STD_LOGIC_VECTOR (CCW     -1 downto 0);
        bdi_valid       : in   STD_LOGIC;
        bdi_ready       : out  STD_LOGIC;
        bdi_pad_loc     : in   STD_LOGIC_VECTOR (CCWdiv8 -1 downto 0);
        bdi_valid_bytes : in   STD_LOGIC_VECTOR (CCWdiv8 -1 downto 0);
        bdi_size        : in   STD_LOGIC_VECTOR (3       -1 downto 0);
        bdi_eot         : in   STD_LOGIC;
        bdi_eoi         : in   STD_LOGIC;
        bdi_type        : in   STD_LOGIC_VECTOR (4       -1 downto 0);
        decrypt_in      : in   STD_LOGIC;
        key_update      : in   STD_LOGIC;
        hash_in         : in   std_logic;
        --!Post Processor=========================================
        bdo             : out  STD_LOGIC_VECTOR (CCW      -1 downto 0);
        bdo_valid       : out  STD_LOGIC;
        bdo_ready       : in   STD_LOGIC;
        bdo_type        : out  STD_LOGIC_VECTOR (4       -1 downto 0);
        bdo_valid_bytes : out  STD_LOGIC_VECTOR (CCWdiv8 -1 downto 0);
        end_of_block    : out  STD_LOGIC;
        msg_auth_valid  : out  STD_LOGIC;
        msg_auth_ready  : in   STD_LOGIC;
        msg_auth        : out  STD_LOGIC;

        -- 2 pass
        fdi_data         : in std_logic_vector(CCW-1 downto 0);
        fdi_valid        : in std_logic;
        fdi_ready        : out  std_logic;
        fdo_valid        : out std_logic;
        fdo_ready        : in  std_logic;
        fdo_data         : out std_logic_vector(CCW -1 downto 0);
        fdi_last : in std_logic

    );
end CryptoCore;

architecture behavioral of CryptoCore is

    --! Constant to check for empty hash
    
    -- State signals
  type state_t is (RESET,
                   IDLE,
                   STORE_KEY,
                   INIT_HASH,
                   ABSORB_NPUB,
                   CASCADE_AD,
                   WAIT_CASCADE_AD,
                   INIT_CASCADE,
                   END_CASCADE_AD,
                   PADD_AD,
                   LOAD_0_CASCADE_AD,
                   PADD_CT,
                   WRITE_0_FDO,
                   INIT_CASCADE_CT,
                   WAIT_CASCADE_CT,
                   CASCADE_CT,
                   CTR,
                   INIT_CTR,
                   WAIT_CTR,
                   VERIFY_TAG,
                   OUTPUT_TAG);
    signal n_state_s, state_s           : state_t;

  -- counters
  signal word_cnt_s, word_cnt_r : integer range 0 to DBLK_WORDS;
  signal cc_cnt_s, cc_cnt_r : integer range 0 to 2**MSG_CNT_WIDTH -1;
  signal cc_s : std_logic_vector(MSG_CNT_WIDTH -1 downto 0);
  -- registers
  signal N_r : std_logic_vector(NPUB_SIZE-1 downto 0);
  signal N_s : std_logic_vector(CCW -1 downto 0);
  signal en_N : std_logic;
  signal rot_N : std_logic;
  signal N_mux : std_logic_vector(CCW -1 downto 0);
  signal sel_N : std_logic_vector(1 downto 0);

  signal din_r : std_logic_vector(DBLK_SIZE -1 downto 0);
  signal shift_din : std_logic;

  signal sel_din : std_logic_vector(1 downto 0);
  signal din_mux : std_logic_vector(CCW -1 downto 0);
  signal pad_bit : std_logic;
  -- Concatenated length according to specification
  signal R         : std_logic_vector(4 downto 0);
  signal sel_R     : std_logic;
  signal D         : std_logic_vector(3 downto 0);
  signal din       : std_logic_vector(CCW -1 downto 0);
  signal dout      : std_logic_vector(CCW -1 downto 0);
  signal init      : std_logic;
  signal done_init : std_logic;
  signal start     : std_logic;
  signal done      : std_logic;
  signal din_valid : std_logic;
  signal dout_valid : std_logic;
  signal dout_state : std_logic_vector(CCW -1 downto 0);
  signal key_s : std_logic_vector(CCSW -1 downto 0);
  signal bdi_s : std_logic_vector(CCW -1 downto 0);

  signal key_r : std_logic_vector(DBLK_SIZE -1 downto 0);
  signal en_key, rot_key : std_logic;
  signal cascade_key : std_logic_vector(CCW -1 downto 0);
  signal mode : std_logic;
  signal dout_xor : std_logic_vector(CCW -1 downto 0);
  signal sel_xor : std_logic;

  signal key_valid_s : std_logic;
  signal ld_key : std_logic;
  signal sel_key : std_logic_vector(1 downto 0);

  signal sel_bdi : std_logic_vector(1 downto 0);
  signal bdi_eoi_r, bdi_eot_r : std_logic;
  signal en_bdi_eot, en_bdi_eoi : std_logic;

  signal shift_mi : std_logic;
  -- status register
  -- 2 EOI
  -- 1 EOT
  -- 0 MODE
  signal status_r, status : std_logic_vector(5 downto 0);
  signal clr_status, en_status : std_logic;
  signal clr_done : std_logic;
  signal tag_r : std_logic_vector(DBLK_SIZE -1 downto 0);
  signal en_tag : std_logic;
  signal sel_bdo : std_logic;
  signal en_bdi_info : std_logic;
  signal bdi_pad_loc_r : std_logic_vector(1 downto 0);
  signal bdi_valid_bytes_r : std_logic_vector(1 downto 0);
  signal bdo_s : std_logic_vector(CCW -1 downto 0);
  signal stop : std_logic;
  signal ld_new_key : std_logic;
  signal key_ready_s : std_logic;
  signal bdi_partial_r : std_logic;

  signal bdo_pad_loc_s : std_logic_vector(CCWdiv8 -1 downto 0);
  signal bdo_valid_bytes_s : std_logic_vector(CCWdiv8 -1 downto 0);

  signal dout_ready : std_logic;
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
    cc_cnt_s <= cc_cnt_r;
    init <= '0';
    start <= '0';
    din_valid <= '0';
    bdi_ready <= '0';
    en_N <= '0';
    rot_N <= '0';
    sel_din <= "00";
    pad_bit <= '0';
    D <= "0000";
    ld_key <= '0';
    sel_key <= "00";
    sel_xor <= '0';
    shift_din <= '0';
    mode <= '0';
    bdo_valid <= '0';
    en_bdi_eoi <= '0';
    en_bdi_eot <= '0';
    sel_bdi <= "00";
    en_tag <= '0';
    status <= status_r;
    en_status <= '0';
    shift_mi <= '0';
    en_key <= '0';
    rot_key <= '0';
    sel_bdo <= '0';
    end_of_block <= '0';
    stop <= '0';
    fdo_valid <= '0';
    ld_new_key <= '0';
    sel_R <= '0';
    fdi_ready <= '0';
    en_bdi_info <= '0';
    dout_ready <= '0';
    msg_auth_valid <= '0';
    bdo_valid_bytes_s <= (others => '0');
    bdo_pad_loc_s <= (others => '0');
    case state_s is
      when RESET =>
        n_state_s <= IDLE;
        status <= (others => '0');
      when IDLE =>
        word_cnt_s <= 0;
        if key_update = '1' then
          --init <= '1';
          en_key <= '1';
          ld_new_key <= '1';
          bdo_pad_loc_s <= (others => '1');
          bdo_valid_bytes_s <= (others => '1');
          n_state_s <= STORE_KEY;
        elsif bdi_valid = '1' and bdi_type = HDR_NPUB then
          start <= '1';
          mode <= '1';
          D <= "0010";
          n_state_s <= ABSORB_NPUB;
      --  elsif bdi_valid = '1' and (bdi_type = HDR_PT or bdi_type = HDR_CT) then
       --   init <= '1';
       --   ld_key <= '1';
       --   rot_key <= '1';
      --    sel_key <= "11";
      --    cc_cnt_s <= 1;
      --    n_state_s <= INIT_CTR;
        elsif hash_in = '1' then
          en_key <= '1';
          ld_new_key <= '1';
          bdo_pad_loc_s <= (others => '0');
          bdo_valid_bytes_s <= (others => '0');
          n_state_s <= INIT_HASH;
        end if;
      when INIT_HASH =>
        ld_new_key <= '1';
        bdo_pad_loc_s <= (others => '0');
        bdo_valid_bytes_s <= (others => '0');
        if word_cnt_r = DBLK_WORDS -1 then
          ld_new_key <= '0';
          word_cnt_s <= 0;
          mode <= '1';
          start <= '1';
          sel_R <= '1';
          n_state_s <= CASCADE_AD;
        else
          en_key <= '1';
          word_cnt_s <= word_cnt_r + 1;
        end if;
      when STORE_KEY =>
        ld_new_key <= '1';
        bdo_pad_loc_s <= (others => '1');
        bdo_valid_bytes_s <= (others => '1');
        if word_cnt_r = DBLK_WORDS -1 then
          ld_new_key <= '0';
          word_cnt_s <= 0;
          n_state_s <= IDLE;
        elsif key_valid = '1' then
          en_key <= '1';
          word_cnt_s <= word_cnt_r + 1;
        end if;
      when ABSORB_NPUB =>
        bdi_ready <= '1';
        if word_cnt_r = NPUB_WORDS then
          pad_bit <= '1';
          sel_din <= "11";
          bdi_ready <= '0';
          din_valid <= '1';
          shift_din <= '1';
          sel_key <= "11";
          rot_key <= '1';
          if bdi_eoi = '1' then
            status(2) <= '1';
          end if;
          mode <= '1'; -- CASCADE MODE
          n_state_s <= INIT_CASCADE;
        elsif bdi_valid = '1' then
          en_N <= '1';
          shift_din <= '1';
          din_valid <= '1';
          sel_key <= "11";
          rot_key <= '1';
          sel_din <= "00";
          word_cnt_s <= word_cnt_r + 1;
        end if;
      when INIT_CASCADE =>
        din_valid <= '1';
        mode <= '1';
        sel_key <= "11";
        D <= "0010";
        if word_cnt_r = DBLK_WORDS - 1 then
          if done = '1' then -- wait until done
            if status_r(2) = '1' or bdi_type /= HDR_AD then --npub EOI or no AD
              n_state_s <= PADD_AD;
            else
              n_state_s <= CASCADE_AD;
            end if;
            word_cnt_s <= 0;
            cc_cnt_s <= cc_cnt_r + 1;
          end if;
          din_valid <= '0';
        elsif word_cnt_r = (DBLK_WORDS - MSG_CNT_WORDS) -1 then
          sel_din <= "10";
          shift_din <= '1';
          rot_key <= '1';
          word_cnt_s <= word_cnt_r + 1;
        else
          rot_key <= '1';
          sel_din <= "11";
          shift_din <= '1';
          word_cnt_s <= word_cnt_r + 1;
        end if;

      when CASCADE_AD =>
        mode <= '1';
        sel_bdi <= "01";
        if bdi_valid = '1' then
          if word_cnt_r = DBLK_WORDS then
            word_cnt_s <= 0;
            n_state_s <= WAIT_CASCADE_AD;
            D <= "0010";
          elsif bdi_eot = '1' then
            if hash_in = '0' then
            sel_key <= "01";
            end if;
            din_valid <= '1';
            bdi_ready <= '1';
            sel_xor <= '1';
            shift_din <= '1';
            en_tag <= '1';
            status(1) <= '1';
            status(2) <= bdi_eoi;
            if word_cnt_r = DBLK_WORDS -1 and bdi_valid_bytes = "11" then
              word_cnt_s <= 0; --write empty to fifo
              if hash_in = '1' then
                D <= "0111";
                sel_R <= '1';
              else
                D <= "0010";
              end if;
              n_state_s <= WAIT_CASCADE_AD;
            elsif word_cnt_r = DBLK_WORDS -1 and bdi_valid_bytes /= "11" then
              word_cnt_s <= word_cnt_r + 1;
              if hash_in = '1' then
                D <= "1000";
                sel_R <= '1';
              else
                D <= "0011";
              end if;
              n_state_s <= LOAD_0_CASCADE_AD;
            elsif bdi_valid_bytes = "11" then
              word_cnt_s <= word_cnt_r + 1;
              n_state_s <= PADD_AD;
            else
              word_cnt_s <= word_cnt_r + 1;
              n_state_s <= LOAD_0_CASCADE_AD;
            end if;
          else
            if hash_in = '1' then
              D <= "0111";
              sel_R <= '1';
              rot_key <= '1';
            else
              sel_key <= "01";
            end if;
            din_valid <= '1';
            bdi_ready <= '1';
            sel_xor <= '1';
            shift_din <= '1';
            en_tag <= '1';
            word_cnt_s <= word_cnt_r + 1;
          end if;
        end if;
        -- if word_cnt_r = DBLK_WORDS then
        --   word_cnt_s <= 0;
        --   n_state_s <= WAIT_CASCADE_AD;
        --   bdi_ready <= '0';
        --   D <= "0010";
        -- elsif bdi_valid = '1' then
        --   if bdi_eot = '1' then
        --    -- D <= "0011";
        --     -- if last message is a complete packet
        --     if bdi_valid_bytes = "11" and word_cnt_r < DBLK_WORDS -1 then
        --       n_state_s <= PADD_AD; -- pad the next word
        --     else
        --       sel_bdi <= "01"; -- pad BDI
        --     end if;
        --     status(1) <= '1'; -- eot
        --     status(2) <= bdi_eoi;
        --   end if;
        --   din_valid <= '1';
        --   sel_key <= "01";
        --   sel_xor <= '1';
        --   shift_din <= '1';
        --   en_tag <= '1';
        --   word_cnt_s <= word_cnt_r + 1;
--        end if;
      when WAIT_CASCADE_AD =>
        mode <= '1';
        D <= "0010";
        if done = '1' then
          if status_r(1) = '1' then
            n_state_s <= PADD_AD; -- last AD with no partial block
          else
            n_state_s <= CASCADE_AD;
          end if;
        end if;
      when PADD_AD =>
        D <= "0011";
        status(0) <= '0'; --cascade mod end
        din_valid <= '1';
        pad_bit <= '1';
        sel_din <= "11";
        shift_din <= '1';
        if hash_in = '0' then
            sel_key <= "01";
        end if;
        en_tag <= '1';
        sel_xor <= '1';
        n_state_s <= LOAD_0_CASCADE_AD;
        word_cnt_s <= word_cnt_r + 1;
      when LOAD_0_CASCADE_AD =>
        if hash_in = '1' then
          D <= "1000";
          sel_R <= '1';
        else
          D <= "0011";
        end if;
        if word_cnt_r = DBLK_WORDS then
          if done = '1' then
            n_state_s <= END_CASCADE_AD;
            word_cnt_s <= 0;
          end if;
        else
          if hash_in = '0' then
            sel_key <= "01";
          end if;
          sel_xor <= '1';
          shift_din <= '1';
          en_tag <= '1';
          word_cnt_s <= word_cnt_r + 1;
          sel_din <= "11";
          din_valid <= '1';
        end if;
      when END_CASCADE_AD =>
        sel_xor <= '1';
        shift_din <= '1';
        mode <= '1';
        dout_ready <= '1';
        if hash_in = '1' then
          bdo_valid_bytes_s <= (others => '1');
          bdo_valid <= '1';
        end if;
        if word_cnt_r = DBLK_WORDS then
          if status_r(2) = '1' then -- if EOI
              n_state_s <= PADD_CT;
          else
            mode <= '1';
            start <= '1'; -- start CTR mode
            n_state_s <= INIT_CTR;
          end if;
          word_cnt_s <= 0;
        elsif hash_in = '1' and word_cnt_r = DBLK_WORDS -1 then
          n_state_s <= IDLE;
              bdo_valid_bytes_s <= (others => '1');
              bdo_valid <= '1';
              end_of_block <= '1';
              word_cnt_s <= 0;
              status <= (others => '0');
        else
          en_tag <= '1';
          word_cnt_s <= word_cnt_r + 1;
        end if;

      when PADD_CT =>
        bdo_valid_bytes_s <= (others => '0');
        bdo_pad_loc_s <= "10";
        fdo_valid <= '1';
        rot_key <= '1';
        word_cnt_s <= word_cnt_r + 1;
        n_state_s <= WRITE_0_FDO;
      when WRITE_0_FDO =>
        if word_cnt_r = DBLK_WORDS then
          n_state_s <= INIT_CASCADE_CT;
          start <= '1';
          word_cnt_s <= 0;
          mode <= '1'; --cascade mode
        else
          rot_key <= '1';
          bdo_valid_bytes_s <= (others => '0');
          bdo_pad_loc_s <= "00";
          fdo_valid <= '1';
          word_cnt_s <= word_cnt_r + 1;
        end if;
      when INIT_CTR =>
        rot_key <= '1';
        ld_key <= '1';
        sel_key <= "11";
        din_valid <= '1';
        D <= "0001";
        mode <= '1';
        if word_cnt_r = DBLK_WORDS then
          rot_key <= '0';
          ld_key <= '0';
          sel_key <= "00";
          din_valid <= '0';
          if done = '1' then
            word_cnt_s <= 0;
            cc_cnt_s <= cc_cnt_r + 1;
            n_state_s <= CTR;
          end if;
          din_valid <= '0';
        elsif word_cnt_r = (DBLK_WORDS - MSG_CNT_WORDS) then
          sel_din <= "10";
          word_cnt_s <= word_cnt_r + 1;
        elsif word_cnt_r > NPUB_WORDS then
          sel_din <= "11";
          word_cnt_s <= word_cnt_r + 1;
        elsif word_cnt_r = NPUB_WORDS then
          pad_bit <= '1';
          word_cnt_s <= word_cnt_r + 1;
          sel_din <= "11";
        elsif word_cnt_r < NPUB_WORDS then
          sel_din <= "01";
          rot_N <= '1';
          word_cnt_s <= word_cnt_r + 1;
        end if;
      when WAIT_CTR =>
        mode <= '1';
        if done = '1' then
          cc_cnt_s <= cc_cnt_r + 1;
          n_state_s <= CTR;
        end if;
      when CTR =>

        D <= "0001";
       -- if bdi_eot = '1' then
        -- stop <= '1';
         -- bdo_valid <= '1';
       --   bdo_valid_bytes_s <= bdi_valid_bytes;
        -- bdi_ready <= '1';
         --   if bdi_valid_bytes /= "11" then
          --    n_state_s <= WRITE_0_FDO;
          --  else
              -- complete partial packet, next work is pad word
            --  if word_cnt_r = DBLK_WORDS - 1 then
              --  word_cnt_s <= 0; -- if this is a complete block, next message
                                 -- is padded
             -- end if;
             -- n_state_s <= PADD_CT;
           -- end if;
           -- bdo_pad_loc_s <= bdi_pad_loc;
        if word_cnt_r = DBLK_WORDS then
          word_cnt_s <= 0;
          n_state_s <= WAIT_CTR;
        elsif dout_valid = '1' and bdo_ready = '1' and bdi_valid = '1' then
          rot_key <= '1';
          ld_key <= '1';
          sel_key <= "11";
          dout_ready <= '1';
          fdo_valid <= '1';
          bdi_ready <= '1';
          bdo_valid <= '1';
          din_valid <= '1';
          bdo_valid_bytes_s <= bdi_valid_bytes;
          bdo_pad_loc_s <= bdi_pad_loc;
          -- if word_cnt_r = DBLK_WORDS then
          --   fdo_valid <= '0';
          --   bdi_ready <= '0';
          --   bdo_valid <= '0';
          --   din_valid <= '0';
          -- --if done = '1' then
          --     word_cnt_s <= 0;
          --     n_state_s <= WAIT_CTR;
          --  -- end if;
          --   din_valid <= '0';
          if bdi_eot = '1' then
            stop <= '1';
            if word_cnt_r = DBLK_WORDS -1 and bdi_valid_bytes = "11" then
              word_cnt_s <= 0; --write empty to fifo
              n_state_s <= PADD_CT;
            elsif word_cnt_r = DBLK_WORDS -1 and bdi_valid_bytes /= "11" then
              word_cnt_s <= word_cnt_r + 1;
              n_state_s <= WRITE_0_FDO;
            elsif bdi_valid_bytes = "11" then
              word_cnt_s <= word_cnt_r + 1;
              n_state_s <= PADD_CT;
            else
              word_cnt_s <= word_cnt_r + 1;
              n_state_s <= WRITE_0_FDO;
            end if;
          elsif word_cnt_r = (DBLK_WORDS - MSG_CNT_WORDS) then
            sel_din <= "10";
            word_cnt_s <= word_cnt_r + 1;
          elsif word_cnt_r > NPUB_WORDS then
            sel_din <= "11";
            word_cnt_s <= word_cnt_r + 1;
          elsif word_cnt_r = NPUB_WORDS then
            pad_bit <= '1';
            word_cnt_s <= word_cnt_r + 1;
            sel_din <= "11";
          elsif word_cnt_r < NPUB_WORDS then
            sel_din <= "01";
            rot_N <= '1';
            word_cnt_s <= word_cnt_r + 1;
          end if;
        end if;
      when INIT_CASCADE_CT =>
        mode <= '1';
        --Load the tag as the key
        if word_cnt_r = DBLK_WORDS then
          n_state_s <= WAIT_CASCADE_CT;
          word_cnt_s <= 0;
          if fdi_last = '1' then
            D <= "0101";
          else
            D <= "0100";
          end if;
        elsif fdi_valid = '1' then
          fdi_ready <= '1';
          word_cnt_s <= word_cnt_r + 1;
          sel_key <= "10";
          sel_xor <= '1';
          shift_din <= '1';
          sel_bdi <= "10";
          en_tag <= '1';
          din_valid <= '1';
          dout_ready <= '1';
        end if;
      when WAIT_CASCADE_CT =>
        if fdi_last = '1' then
          mode <= '0';
          if done = '1' then
            if decrypt_in = '1' then
              n_state_s <= VERIFY_TAG;
            else
              n_state_s <= OUTPUT_TAG;
            end if;
          end if;
        else
          if done = '1' then
            n_state_s <= CASCADE_CT;
          end if;
          mode <= '1';
        end if;
      when CASCADE_CT =>
        mode <= '1';
        if word_cnt_r = DBLK_WORDS then
          n_state_s <= WAIT_CASCADE_CT;
          word_cnt_s <= 0;
          if fdi_last = '1' then
            D <= "0101";
          else
            D <= "0100";
          end if;
        elsif fdi_valid = '1' then
          fdi_ready <= '1';
          word_cnt_s <= word_cnt_r + 1;
          sel_key <= "01";
          sel_xor <= '1';
          shift_din <= '1';
          sel_bdi <= "10";
          en_tag <= '1';
          din_valid <= '1';
          dout_ready <= '1';
        end if;
      when VERIFY_TAG =>
        sel_xor <= '1';
        shift_din <= '1';
        bdi_ready <= '1';
        if word_cnt_r = DBLK_WORDS -1 then
          n_state_s <= IDLE;
          end_of_block <= '1';
          msg_auth_valid <= '1';
         -- msg_auth <= '1';
          cc_cnt_s <= 0;
          status <= (others => '0');
        else
          word_cnt_s <= word_cnt_r + 1;
          dout_ready <= '1';
          if msg_auth = '0' then
            n_state_s <= IDLE;
            msg_auth_valid <= '1';
            cc_cnt_s <= 0;
            status <= (others => '0');
            word_cnt_s <= 0;
          end if;
        end if;
      when OUTPUT_TAG =>
        bdo_valid <= '1';
        sel_xor <= '1';
        bdo_valid_bytes_s <= "11";
        shift_din <= '1';
        if word_cnt_r = DBLK_WORDS -1 then
          n_state_s <= IDLE;
          end_of_block <= '1';
          cc_cnt_s <= 0;
          status <= (others => '0');
        elsif bdo_ready = '1' then
          dout_ready <= '1';
          word_cnt_s <= word_cnt_r + 1;
        end if;
    end case;
  end process FSM_control_path;

  counters : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        word_cnt_r <= 0;
        cc_cnt_r <= 0;
      else
        cc_cnt_r <= cc_cnt_s;
        word_cnt_r <= word_cnt_s;
      end if;
    end if;
  end process counters;

  cc_s <= std_logic_vector(to_unsigned(cc_cnt_r, MSG_CNT_WIDTH));
  registers: process(clk)
  begin
    if rising_edge(clk) then
      if en_tag = '1' then
        tag_r <= cascade_key & tag_r(DBLK_SIZE -1 downto CCW);
      end if;
     -- if en_status = '1' then
        status_r <= status;
     -- end if;
      if en_key = '1' then
        key_r <= key_s & key_r(DBLK_SIZE -1 downto CCW);
      elsif rot_key = '1' then
        key_r <= key_r(CCW -1 downto 0) & key_r(DBLK_SIZE -1 downto CCW);
      end if;
      if en_bdi_eot = '1' then
        bdi_eot_r <= bdi_eot;
      end if;
      if en_bdi_eoi = '1' then
        bdi_eoi_r <= bdi_eoi;
      end if;
      if en_bdi_info = '1' then
        bdi_valid_bytes_r <= bdi_valid_bytes;
        bdi_pad_loc_r <= bdi_pad_loc;
      end if;
      if shift_din = '1' then
        din_r <= din_mux & din_r(din_r'length - 1 downto CCW);
      elsif shift_mi = '1' then
        din_r <= bdi_s & din_r(din_r'length -1 downto CCW);
      end if;
      if en_N = '1' then
        N_r <= bdi_s & N_r(N_r'length - 1 downto CCW);
      elsif rot_N = '1' then
        N_r <= N_r(CCW -1 downto 0) & N_r(N_r'length - 1 downto CCW);
      end if;
    end if;
  end process registers;
  with sel_key select key_s <=
    reverse_byte(padd(key, bdo_valid_bytes_s, bdo_pad_loc_s)) when "00",
    cascade_key when "01",
    tag_r(CCW -1 downto 0) when "10",
    key_r(CCW -1 downto 0) when others;

  with sel_bdi select bdi_s <=
    reverse_byte(bdi) when "00",
    reverse_byte(padd(bdi, bdi_valid_bytes, bdi_pad_loc)) when "01",
    reverse_byte(fdi_data) when "10",
    reverse_byte(padd(fdi_data, bdi_valid_bytes_r, bdi_pad_loc_r)) when others;



  N_s <= N_r(CCW -1 downto 0);

  with sel_din select din_mux <=
    bdi_s when "00",
    N_s when "01",
    reverse_byte(cc_s) when "10",
    (7 => pad_bit, others => '0') when others;

  --with sel_N select N_mux <=
   -- bdi_s when "00",
    --x"8000" when "01",
    --x"0000" when others;
  R <= "10000" when sel_R = '1' else "01010";

  key_valid_s <= key_valid or ld_key;

  dout_xor <= din_r(CCW-1 downto 0) when sel_xor = '1' else reverse_byte(bdi);
  cascade_key <= dout xor dout_xor;
  i_Saturnin: entity work.Saturnin
    port map (
      clk       => clk,
      rst       => rst,
      key       => key_s,
      R         => R,
      D         => D,
      din       => din_mux,
      din_valid => din_valid,
      dout_valid => dout_valid,
      dout      => dout,
      start     => start,
      mode   => mode,
      dout_ready => dout_ready,
      done      => done,
      stop => stop);

  bdo_valid_bytes <= bdo_valid_bytes_s;
  fdo_data <= padd(bdi, bdo_valid_bytes_s, bdo_pad_loc_s) when decrypt_in = '1' else
              padd(bdo_s, bdo_valid_bytes_s, bdo_pad_loc_s);
  key_ready <= ld_new_key;
	bdo_s <= reverse_byte(tag_r(CCW -1 downto 0)) when sel_bdo = '1' else reverse_byte(cascade_key);
  msg_auth <= '1' when (bdo_s = bdi) else '0';
  bdo <= bdo_s;
end behavioral;
