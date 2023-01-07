--Copyright (C) 2022 Komeil Majidi.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity gbt_bank_reset is   
   generic ( 
   
      RX_INIT_FIRST                                : boolean := false;
      INITIAL_DELAY                                : natural := 1   * 40e6;    
      TIME_N                                       : natural := 1   * 40e5; 
      GAP_DELAY                                    : natural := 3   * 40e6 

   );    
   port (       
      CLK_I                                        : in  std_logic;
      GENERAL_RESET_I                              : in  std_logic;   
      MANUAL_RESET_TX_I                            : in  std_logic;
      MANUAL_RESET_RX_I                            : in  std_logic;
      MGT_TX_RESET_O                               : out std_logic;       
      MGT_RX_RESET_O                               : out std_logic;    
      GBT_TX_RESET_O                               : out std_logic;   
      GBT_RX_RESET_O                               : out std_logic;         
      BUSY_O                                       : out std_logic;   
      DONE_O                                       : out std_logic 

   );
end gbt_bank_reset;
architecture behavioral of gbt_bank_reset is      
   signal mgtResetTx_from_generalRstFsm         : std_logic; 
   signal gbtResetTx_from_generalRstFsm         : std_logic; 
   
   signal gbtResetTx_from_txRstFsm              : std_logic;
   signal mgtResetTx_from_txRstFsm              : std_logic;
   signal manual_reset_tx_r2                    : std_logic;
   signal manual_reset_tx_r                     : std_logic;
   signal mgtResetRx_from_generalRstFsm         : std_logic; 
   signal gbtResetRx_from_generalRstFsm         : std_logic; 
   
   signal gbtResetRx_from_rxRstFsm              : std_logic;
   signal mgtResetRx_from_rxRstFsm              : std_logic;
   signal manual_reset_rx_r2                    : std_logic;
   signal manual_reset_rx_r                     : std_logic;   
begin  
   generalRstCtrlFsm: process(GENERAL_RESET_I, CLK_I)   
      type general_stateT                          is (s0_idle, s1_firstResetDeassert, s2_secondResetDeassert,
                                                       s3_thirdResetDeassert, s4_fourthResetDeassert, s5_done);
      variable general_state                       : general_stateT;      
      variable general_timer                       : integer range 0 to (INITIAL_DELAY + GAP_DELAY);  
      type tx_stateT                               is (s0_idle, s1_assertTxResets, s2_deassertGbtTxReset, s3_deassertMgtTxReset);
      variable tx_state                            : tx_stateT;      
      variable tx_timer                            : integer range 0 to TIME_N;   
      type rx_stateT                               is (s0_idle, s1_assertRxResets, s2_deassertMgtRxReset, s3_deassertGbtRxReset);
      variable rx_state                            : rx_stateT;      
      variable rx_timer                            : integer range 0 to TIME_N;   
  begin 
      if GENERAL_RESET_I = '1' then   
         general_state                             := s0_idle;
         general_timer                             := 0;   
         mgtResetTx_from_generalRstFsm             <= '1';         
         gbtResetTx_from_generalRstFsm             <= '1';   
         mgtResetRx_from_generalRstFsm             <= '1';         
         gbtResetRx_from_generalRstFsm             <= '1';   
         BUSY_O                                    <= '0';
         DONE_O                                    <= '0';
         tx_state                                  := s0_idle;
         tx_timer                                  := 0;   
         gbtResetTx_from_txRstFsm                  <= '0';
         mgtResetTx_from_txRstFsm                  <= '0';
         rx_state                                  := s0_idle;
         rx_timer                                  := 0;   
         gbtResetRx_from_rxRstFsm                  <= '0';
         mgtResetRx_from_rxRstFsm                  <= '0';
         manual_reset_tx_r2                        <= '0';
         manual_reset_tx_r                         <= '0';
         manual_reset_rx_r2                        <= '0';
         manual_reset_rx_r                         <= '0';
      elsif rising_edge(CLK_I) then       
         case general_state is  
            when s0_idle =>                                                     
               BUSY_O                              <= '1';                   
               if general_timer = INITIAL_DELAY-1 then                    
                  general_state                    := s1_firstResetDeassert;
                  general_timer                    := 0; 
                  if RX_INIT_FIRST = true then
                     mgtResetRx_from_generalRstFsm <= '0';  
                  else
                     gbtResetTx_from_generalRstFsm <= '0';
                  end if;
               else      
                  general_timer                    := general_timer + 1;
               end if;   
            when s1_firstResetDeassert =>         
               if general_timer = TIME_N then                            
                  general_state                    := s2_secondResetDeassert;
                  general_timer                    := 0;
                  if RX_INIT_FIRST = true then
                     gbtResetRx_from_generalRstFsm <= '0';   
                  else
                     mgtResetTx_from_generalRstFsm <= '0';
                  end if;                  
               else
                  general_timer                    := general_timer + 1;
               end if;              
            when s2_secondResetDeassert =>                                         
               if general_timer = GAP_DELAY then                                    
                  general_state                    := s3_thirdResetDeassert;   
                  general_timer                    := 0;                
                  if RX_INIT_FIRST = true then
                     gbtResetTx_from_generalRstFsm <= '0';    
                  else
                     mgtResetRx_from_generalRstFsm <= '0';    
                  end if;
               else        
                  general_timer                    := general_timer + 1;
               end if;                                
            when s3_thirdResetDeassert =>      
               if general_timer = TIME_N then                                       
                  general_state                    := s4_fourthResetDeassert; 
                  general_timer                     := 0;                              
                  if RX_INIT_FIRST = true then
                     mgtResetTx_from_generalRstFsm <= '0';     
                  else
                     gbtResetRx_from_generalRstFsm <= '0';   
                  end if;
               else
                  general_timer                    := general_timer + 1;
               end if;  
            when s4_fourthResetDeassert =>            
                  general_state                    := s5_done; 
                  BUSY_O                           <= '0';
                  DONE_O                           <= '1';
            when s5_done =>         
               null;                                             
         end case;
         case tx_state is
            when s0_idle =>
               if (manual_reset_tx_r2 = '0') and (manual_reset_tx_r = '1') then
                  tx_state                         := s1_assertTxResets;
                  gbtResetTx_from_txRstFsm         <= '1';
                  mgtResetTx_from_txRstFsm         <= '1';
               end if;
            when s1_assertTxResets =>
               if (manual_reset_tx_r2 = '1') and (manual_reset_tx_r = '0') then
                  tx_state                         := s2_deassertGbtTxReset;
               end if;
            when s2_deassertGbtTxReset => 
               if tx_timer = TIME_N then
                  tx_state                         := s3_deassertMgtTxReset;
                  tx_timer                         := 0;
                  gbtResetTx_from_txRstFsm         <= '0';
               else
                  tx_timer                         := tx_timer + 1;
               end if;
            when s3_deassertMgtTxReset => 
               if tx_timer = TIME_N then
                  tx_state                         := s0_idle;
                  tx_timer                         := 0;
                  mgtResetTx_from_txRstFsm         <= '0';
               else
                  tx_timer                         := tx_timer + 1;
               end if;
         end case;
         case rx_state is
            when s0_idle =>
               if (manual_reset_rx_r2 = '0') and (manual_reset_rx_r = '1') then
                  rx_state                         := s1_assertRxResets;
                  mgtResetRx_from_rxRstFsm         <= '1';
                  gbtResetRx_from_rxRstFsm         <= '1';
               end if;
             when s1_assertRxResets =>
               if (manual_reset_rx_r2 = '1') and (manual_reset_rx_r = '0') then
                  rx_state                         := s2_deassertMgtRxReset;
               end if;
            when s2_deassertMgtRxReset => 
               if rx_timer = TIME_N then
                  rx_state                         := s3_deassertGbtRxReset;
                  rx_timer                         := 0;
                  mgtResetRx_from_rxRstFsm         <= '0';
               else
                  rx_timer                         := rx_timer + 1;
               end if;
            when s3_deassertGbtRxReset => 
               if rx_timer = TIME_N then
                  rx_state                         := s0_idle;
                  rx_timer                         := 0;
                  gbtResetRx_from_rxRstFsm         <= '0';
               else
                  rx_timer                         := rx_timer + 1;
               end if;
         end case;

         manual_reset_tx_r2                        <= manual_reset_tx_r;
         manual_reset_tx_r                         <= MANUAL_RESET_TX_I;
         manual_reset_rx_r2                        <= manual_reset_rx_r;
         manual_reset_rx_r                         <= MANUAL_RESET_RX_I;
         
      end if;
   end process;      
   MGT_TX_RESET_O                                  <= mgtResetTx_from_generalRstFsm or mgtResetTx_from_txRstFsm;
   GBT_TX_RESET_O                                  <= gbtResetTx_from_generalRstFsm or gbtResetTx_from_txRstFsm;
   MGT_RX_RESET_O                                  <= mgtResetRx_from_generalRstFsm or mgtResetRx_from_rxRstFsm;
   GBT_RX_RESET_O                                  <= gbtResetRx_from_generalRstFsm or gbtResetRx_from_rxRstFsm;
   end behavioral;
