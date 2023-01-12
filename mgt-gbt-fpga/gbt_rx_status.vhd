--Copyright (C) 2023 Komeil Majidi.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gbt_bank_package.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_banks_user_setup.all;
entity gbt_rx_status is
   generic (   
      GBT_BANK_ID                               : integer := 1;
		NUM_LINKS											: integer := 1;
		TX_OPTIMIZATION									: integer range 0 to 1 := STANDARD;
		RX_OPTIMIZATION									: integer range 0 to 1 := STANDARD;
		TX_ENCODING											: integer range 0 to 1 := GBT_FRAME;
		RX_ENCODING											: integer range 0 to 1 := GBT_FRAME    
   );
   port (
      RX_RESET_I                                : in  std_logic;
      RX_FRAMECLK_READY_I                       : in  std_logic; 
      RX_FRAMECLK_I                             : in  std_logic;                
      RX_DESCRAMBLER_READY_I                    : in  std_logic;  
      RX_WORDCLK_READY_I                        : in  std_logic; 
      RX_READY_O                                : out std_logic   
      
   );
end gbt_rx_status;
architecture behavioral of gbt_rx_status is
   signal rxDescramblerReady_r                  : std_logic;
   signal rxWordClkAligned_r2                   : std_logic;
   signal rxWordClkAligned_r                    : std_logic;

begin 
   statusStd_gen: if RX_OPTIMIZATION = STANDARD generate
   
      statusStd: process(RX_RESET_I, RX_FRAMECLK_READY_I, RX_FRAMECLK_I)   
      begin                                                
         if (RX_RESET_I = '1') or (RX_FRAMECLK_READY_I = '0') then
            rxDescramblerReady_r                <= '0';
            RX_READY_O                          <= '0';
         elsif rising_edge(RX_FRAMECLK_I) then       

            RX_READY_O                          <= rxDescramblerReady_r;                          
            rxDescramblerReady_r                <= RX_DESCRAMBLER_READY_I;                        

         end if;
      end process;
      
   end generate;

   statusLatOpt_gen: if RX_OPTIMIZATION = LATENCY_OPTIMIZED generate
   
      statusLatOpt: process(RX_RESET_I, RX_FRAMECLK_READY_I, RX_FRAMECLK_I)   
         variable state                         : rxReadyFsmStateLatOpt_T;
         variable timer                         : integer range 0 to GBT_READY_DLY-1;
      begin                                                
         if (RX_RESET_I = '1') or (RX_FRAMECLK_READY_I = '0') then
            state                               := s0_idle;
            timer                               := 0;
            rxWordClkAligned_r2                 <= '0';
            rxWordClkAligned_r                  <= '0';
            RX_READY_O                          <= '0';
         elsif rising_edge(RX_FRAMECLK_I) then 
            case state is 
               when s0_idle => 
                  if RX_DESCRAMBLER_READY_I = '1' then 
                     state                      := s1_rxWordClkCheck;                    
                  end if;
               when s1_rxWordClkCheck =>
                  if rxWordClkAligned_r2 = '1' then
                     if timer = GBT_READY_DLY-1 then
                        state                   := s2_gbtRxReadyMonitoring;
                        timer                   := 0;
                     else
                        timer                   := timer + 1;
                     end if;
                  end if;
               when s2_gbtRxReadyMonitoring =>
                  if (RX_DESCRAMBLER_READY_I = '1') and (rxWordClkAligned_r2 = '1') then
                     RX_READY_O                 <= '1';
                  else         
                     state                      := s0_idle;
                     RX_READY_O                 <= '0';              
                  end if;       
            end case;
            rxWordClkAligned_r2                 <= rxWordClkAligned_r;
            rxWordClkAligned_r                  <= RX_WORDCLK_READY_I;           

         end if;
      end process;
      
   end generate;
   
end behavioral;
