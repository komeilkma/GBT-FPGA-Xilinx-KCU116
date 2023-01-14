--Copyright (C) 2023 Komeil Majidi.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vendor_specific_gbt_bank_package.all;

entity gbt_rx_framealigner is
   port (

      RX_RESET_I                                     : in  std_logic;
      RX_WORDCLK_I                                   : in  std_logic;
      RX_MGT_RDY_I                                   : in  std_logic;
      RX_HEADER_LOCKED_O                             : out std_logic;
      RX_HEADER_FLAG_O                               : out std_logic;       
      RX_BITSLIP_NBR_O                               : out std_logic_vector(GBTRX_BITSLIP_NBR_MSB downto 0);
      RX_WRITE_ADDRESS_O                             : out std_logic_vector(WORD_ADDR_MSB downto 0);            
      RX_WORD_I                                      : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      ALIGNED_RX_WORD_O                              : out std_logic_vector(WORD_WIDTH-1 downto 0)      
      
   );
end gbt_rx_framealigner;

architecture structural of gbt_rx_framealigner is

   signal rxPsWriteAddress_from_writeAddressCtrl     : std_logic_vector(WORD_ADDR_MSB downto 0);   
   signal rxBitSlipCmd_from_patternSearch            : std_logic;
   signal rxGbWriteAddressRst_from_patternSearch     : std_logic;
   signal rxBitslipOverflowCmd_from_rxBitSlipCounter : std_logic;
   signal rxBitSlipCount_from_rxBitSlipCounter       : std_logic_vector(GBTRX_BITSLIP_NBR_MSB downto 0);  
   signal ready_from_rightShifter                    : std_logic;
   signal shiftedRxWord_from_rightShifter            : std_logic_vector(WORD_WIDTH-1 downto 0);

begin
   writeAddressCtrl: entity work.gbt_rx_framealigner_wraddr
      port map (
         RX_RESET_I                                  => RX_RESET_I,
         RX_WORDCLK_I                                => RX_WORDCLK_I,
         RX_BITSLIP_OVERFLOW_CMD_I                   => rxBitslipOverflowCmd_from_rxBitSlipCounter,
         RX_PS_WRITE_ADDRESS_O                       => rxPsWriteAddress_from_writeAddressCtrl,
         RX_GB_WRITE_ADDRESS_RST_I                   => rxGbWriteAddressRst_from_patternSearch,
         RX_GB_WRITE_ADDRESS_O                       => RX_WRITE_ADDRESS_O  
      );  

   patternSearch: entity work.gbt_rx_framealigner_pattsearch
      port map (
         RX_RESET_I                                  => RX_RESET_I,
         RX_WORDCLK_I                                => RX_WORDCLK_I,  
         RIGHTSHIFTER_READY_I                        => ready_from_rightShifter,
         RX_WRITE_ADDRESS_I                          => rxPsWriteAddress_from_writeAddressCtrl,
         RX_BITSLIP_CMD_O                            => rxBitSlipCmd_from_patternSearch,
         RX_HEADER_LOCKED_O                          => RX_HEADER_LOCKED_O,
         RX_HEADER_FLAG_O                            => RX_HEADER_FLAG_O,
         RX_GB_WRITE_ADDRESS_RST_O                   => rxGbWriteAddressRst_from_patternSearch,
         RX_WORD_I                                   => shiftedRxWord_from_rightShifter,
         RX_WORD_O                                   => ALIGNED_RX_WORD_O
      );  

   rxBitSlipCounter: entity work.gbt_rx_framealigner_bscounter
      port map (
         RX_RESET_I                                  => RX_RESET_I,
         RX_WORDCLK_I                                => RX_WORDCLK_I,
         RX_BITSLIP_CMD_I                            => rxBitSlipCmd_from_patternSearch,
         RX_BITSLIP_OVERFLOW_CMD_O                   => rxBitslipOverflowCmd_from_rxBitSlipCounter,
         RX_BITSLIP_NBR_O                            => rxBitSlipCount_from_rxBitSlipCounter
      );      
     
   RX_BITSLIP_NBR_O                                  <= rxBitSlipCount_from_rxBitSlipCounter; 

   rightShifter: entity work.gbt_rx_framealigner_rightshift
      port map (
         RX_RESET_I                                  => RX_RESET_I,
         RX_WORDCLK_I                                => RX_WORDCLK_I,
         RX_MGT_RDY_I                                => RX_MGT_RDY_I,
         READY_O                                     => ready_from_rightShifter,
         RX_BITSLIP_COUNT_I                          => rxBitSlipCount_from_rxBitSlipCounter,
         RX_WORD_I                                   => RX_WORD_I,
         SHIFTED_RX_WORD_O                           => shiftedRxWord_from_rightShifter
      );  
end structural;
