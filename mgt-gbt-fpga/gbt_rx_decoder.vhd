--Copyright (C) 2023 Komeil Majidi.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gbt_bank_package.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_banks_user_setup.all;

entity gbt_rx_decoder is
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
      RX_FRAMECLK_I                             : in  std_logic;
      RX_GEARBOX_READY_I                        : in  std_logic;
      READY_O                                   : out std_logic;
      RX_ISDATA_FLAG_ENABLE_I                   : in  std_logic;  
      RX_ISDATA_FLAG_O                          : out std_logic;  
		RX_ERROR_DETECTED									: out std_logic;
		RX_BIT_MODIFIED_CNTER							: out std_logic_vector(7 downto 0);
      RX_FRAME_I                                : in  std_logic_vector(119 downto 0);      
      RX_COMMON_FRAME_O                         : out std_logic_vector( 83 downto 0);
      RX_EXTRA_FRAME_WIDEBUS_O                  : out std_logic_vector( 31 downto 0)
      
   );
end gbt_rx_decoder;
architecture structural of gbt_rx_decoder is 

   signal rxFrame_from_deinterleaver            : std_logic_vector(119 downto 0);
   signal rxCommonFrame_from_reedSolomonDecoder : std_logic_vector( 87 downto 0); 

	signal error_cnter_lsb								: integer range 0 to 44;
	signal error_cnter_msb								: integer range 0 to 44;
	
	signal error_detected_lsb							: std_logic;
	signal error_detected_msb							: std_logic;

begin

   RX_ISDATA_FLAG_O  <= '1' when (RX_FRAME_I(119 downto 116) = DATA_HEADER_PATTERN) and (RX_ISDATA_FLAG_ENABLE_I = '1') else '0'; 

   gbtFrame_gen: if RX_ENCODING = GBT_FRAME generate
   
      deinterleaver: entity work.gbt_rx_decoder_gbtframe_deintlver
         port map (        
            RX_FRAME_I                          => RX_FRAME_I,
            RX_FRAME_O                          => rxFrame_from_deinterleaver
         );   
      
      reedSolomonDecoder60to119: entity work.gbt_rx_decoder_gbtframe_rsdec
         port map (
            RX_FRAMECLK_I                       => RX_FRAMECLK_I,
            RX_COMMON_FRAME_ENCODED_I           => rxFrame_from_deinterleaver(119 downto 60),
            RX_COMMON_FRAME_O                   => rxCommonFrame_from_reedSolomonDecoder(87 downto 44),
				MODIFIED_BIT_CNT_O						=> error_cnter_msb,
            ERROR_DETECT_O                      => error_detected_msb
         );   

      reedSolomonDecoder0to50: entity work.gbt_rx_decoder_gbtframe_rsdec
         port map(
            RX_FRAMECLK_I                       => RX_FRAMECLK_I,
            RX_COMMON_FRAME_ENCODED_I           => rxFrame_from_deinterleaver(59 downto 0),
            RX_COMMON_FRAME_O                   => rxCommonFrame_from_reedSolomonDecoder(43 downto 0),
				MODIFIED_BIT_CNT_O						=> error_cnter_lsb,
            ERROR_DETECT_O                      => error_detected_lsb 
         );    
      
      RX_COMMON_FRAME_O                         <= rxCommonFrame_from_reedSolomonDecoder(83 downto 0);  
		
		RX_ERROR_DETECTED 								<= error_detected_lsb or error_detected_msb;		
		RX_BIT_MODIFIED_CNTER							<= std_logic_vector(to_unsigned(error_cnter_lsb + error_cnter_msb, 8));
		
   end generate;

   wideBus_gen: if RX_ENCODING = WIDE_BUS generate
      
      RX_COMMON_FRAME_O                         <= RX_FRAME_I(115 downto 32);
      RX_EXTRA_FRAME_WIDEBUS_O                  <= RX_FRAME_I( 31 downto  0);     
		RX_ERROR_DETECTED 								<= '0';
		RX_BIT_MODIFIED_CNTER							<= x"00";

   end generate;

   widebus_no_gen: if RX_ENCODING /= WIDE_BUS generate
   
      RX_EXTRA_FRAME_WIDEBUS_O                  <= (others => '0');
   
   end generate;

   READY_O                                      <= RX_GEARBOX_READY_I;             

end structural;
