library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 

use work.vendor_specific_gbt_bank_package.all;
use work.gbt_banks_user_setup.all;

entity gbt_rx_descrambler is 
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
      RX_DECODER_READY_I                        : in  std_logic;        
      READY_O                                   : out std_logic;
      RX_ISDATA_FLAG_I                          : in  std_logic;
      RX_ISDATA_FLAG_O                          : out std_logic;
      RX_COMMON_FRAME_I                         : in  std_logic_vector(83 downto 0);
      RX_DATA_O                                 : out std_logic_vector(83 downto 0);
      RX_EXTRA_FRAME_WIDEBUS_I                  : in  std_logic_vector(31 downto 0);
      RX_EXTRA_DATA_WIDEBUS_O                   : out std_logic_vector(31 downto 0)
      
   );
end gbt_rx_descrambler;

architecture structural of gbt_rx_descrambler is 

begin

   regs: process(RX_FRAMECLK_I, RX_RESET_I)
   begin
      if RX_RESET_I = '1' then
         RX_ISDATA_FLAG_O                       <= '0';
         READY_O                                <= '0';
      elsif rising_edge(RX_FRAMECLK_I) then
         RX_ISDATA_FLAG_O                       <= RX_ISDATA_FLAG_I;
         READY_O                                <= RX_DECODER_READY_I;
      end if;
   end process;

   gbtFrameOrWideBus_gen: if    (RX_ENCODING = GBT_FRAME)
                             or (RX_ENCODING = WIDE_BUS) generate 

      gbtRxDescrambler84bit_gen: for i in 0 to 3 generate

         gbtRxDescrambler21bit: entity work.gbt_rx_descrambler_21bit
            port map(
               RX_RESET_I                       => RX_RESET_I,
               RX_FRAMECLK_I                    => RX_FRAMECLK_I,
               RX_COMMON_FRAME_I                => RX_COMMON_FRAME_I(((21*i)+20) downto (21*i)), 
               RX_DATA_O                        => RX_DATA_O(((21*i)+20) downto (21*i))
            );
            
      end generate;
      
   end generate;

    wideBus_gen: if RX_ENCODING = WIDE_BUS generate
      
      gbtRxDescrambler32bit_gen: for i in 0 to 1 generate

         gbtRxDescrambler16bit: entity work.gbt_rx_descrambler_16bit
            port map(
               RX_RESET_I                       => RX_RESET_I,
               RX_FRAMECLK_I                    => RX_FRAMECLK_I,
               RX_EXTRA_FRAME_WIDEBUS_I         => RX_EXTRA_FRAME_WIDEBUS_I(((16*i)+15) downto (16*i)),
               RX_EXTRA_DATA_WIDEBUS_O          => RX_EXTRA_DATA_WIDEBUS_O(((16*i)+15) downto (16*i))
            );
         
      end generate; 
     
   end generate;     
   
   wideBus_no_gen: if RX_ENCODING /= WIDE_BUS generate
   
      RX_EXTRA_DATA_WIDEBUS_O                   <= (others => '0');
   
   end generate;
end structural;
