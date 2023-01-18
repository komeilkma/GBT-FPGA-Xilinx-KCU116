library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity gbt_rx_decoder_gbtframe_deintlver is
   port (   

      RX_FRAME_I                                : in  std_logic_vector(119 downto 0);

      RX_FRAME_O                                : out std_logic_vector(119 downto 0)
   
   );   
end gbt_rx_decoder_gbtframe_deintlver;

architecture behavioral of gbt_rx_decoder_gbtframe_deintlver is

begin 

   gbtframedeinterleaving_gen:   for i in 0 to 14 generate
   
      RX_FRAME_O(119-(4*i) downto 116-(4*i))    <= RX_FRAME_I(119-(8*i) downto 116-(8*i));
      RX_FRAME_O( 59-(4*i) downto  56-(4*i))    <= RX_FRAME_I(115-(8*i) downto 112-(8*i));
      
   end generate;
   
end behavioral;
