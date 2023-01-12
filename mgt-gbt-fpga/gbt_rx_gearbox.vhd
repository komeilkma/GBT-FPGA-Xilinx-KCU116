--Copyright (C) 2023 Komeil Majidi.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_banks_user_setup.all;
entity gbt_rx_gearbox is
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
      RX_WORDCLK_I                              : in  std_logic;
      RX_FRAMECLK_I                             : in  std_logic;
      RX_HEADER_LOCKED_I                        : in  std_logic;
      RX_WRITE_ADDRESS_I                        : in  std_logic_vector(WORD_ADDR_MSB downto 0);
      READY_O                                   : out std_logic;
      RX_WORD_I                                 : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      RX_FRAME_O                                : out std_logic_vector(119 downto 0)      
      
   );   
end gbt_rx_gearbox;
architecture structural of gbt_rx_gearbox is
   

begin 
   rxGearboxStd_gen: if RX_OPTIMIZATION = STANDARD generate
   
      rxGearboxStd: entity work.gbt_rx_gearbox_std
         port map (      
            RX_RESET_I                          => RX_RESET_I,     
            RX_WORDCLK_I                        => RX_WORDCLK_I, 
            RX_FRAMECLK_I                       => RX_FRAMECLK_I, 
            RX_HEADER_LOCKED_I                  => RX_HEADER_LOCKED_I,
            RX_WRITE_ADDRESS_I                  => RX_WRITE_ADDRESS_I,
            READY_O                             => READY_O,
            RX_WORD_I                           => RX_WORD_I,
            RX_FRAME_O                          => RX_FRAME_O      
         );   
      
   end generate;   
   rxGearboxLatOpt_gen: if RX_OPTIMIZATION = LATENCY_OPTIMIZED generate   
   
      rxGearboxLatOpt: entity work.gbt_rx_gearbox_latopt
         port map (
            RX_RESET_I                          => RX_RESET_I,     
            RX_WORDCLK_I                        => RX_WORDCLK_I, 
            RX_FRAMECLK_I                       => RX_FRAMECLK_I, 
            RX_HEADER_LOCKED_I                  => RX_HEADER_LOCKED_I,
            RX_WRITE_ADDRESS_I                  => RX_WRITE_ADDRESS_I,
            READY_O                             => READY_O,
            RX_WORD_I                           => RX_WORD_I,
            RX_FRAME_O                          => RX_FRAME_O      
         );   
      
   end generate;  
end structural;
