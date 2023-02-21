library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity gbt_rx_descrambler_21bit is
   port (

      RX_RESET_I                                : in  std_logic;
      RX_FRAMECLK_I                             : in  std_logic;
      RX_COMMON_FRAME_I                         : in  std_logic_vector(20 downto 0);
      RX_DATA_O                                 : out std_logic_vector(20 downto 0)
      
   );
end gbt_rx_descrambler_21bit;

architecture behavioral of gbt_rx_descrambler_21bit is 

   signal feedbackRegister                      : std_logic_vector(20 downto 0);

begin

   descrambler21bit: process(RX_RESET_I, RX_FRAMECLK_I)
   begin
      if RX_RESET_I = '1' then
         feedbackRegister                       <= (others => '0');
      elsif RISING_EDGE(RX_FRAMECLK_I) then

         RX_DATA_O( 0) <= RX_COMMON_FRAME_I( 0) xor feedbackRegister( 0) xor feedbackRegister ( 2);
         RX_DATA_O( 1) <= RX_COMMON_FRAME_I( 1) xor feedbackRegister( 1) xor feedbackRegister ( 3);
         RX_DATA_O( 2) <= RX_COMMON_FRAME_I( 2) xor feedbackRegister( 2) xor feedbackRegister ( 4);
         RX_DATA_O( 3) <= RX_COMMON_FRAME_I( 3) xor feedbackRegister( 3) xor feedbackRegister ( 5);
         RX_DATA_O( 4) <= RX_COMMON_FRAME_I( 4) xor feedbackRegister( 4) xor feedbackRegister ( 6);
         RX_DATA_O( 5) <= RX_COMMON_FRAME_I( 5) xor feedbackRegister( 5) xor feedbackRegister ( 7);
         RX_DATA_O( 6) <= RX_COMMON_FRAME_I( 6) xor feedbackRegister( 6) xor feedbackRegister ( 8);
         RX_DATA_O( 7) <= RX_COMMON_FRAME_I( 7) xor feedbackRegister( 7) xor feedbackRegister ( 9);
         RX_DATA_O( 8) <= RX_COMMON_FRAME_I( 8) xor feedbackRegister( 8) xor feedbackRegister (10);
         RX_DATA_O( 9) <= RX_COMMON_FRAME_I( 9) xor feedbackRegister( 9) xor feedbackRegister (11);
         RX_DATA_O(10) <= RX_COMMON_FRAME_I(10) xor feedbackRegister(10) xor feedbackRegister (12);
         RX_DATA_O(11) <= RX_COMMON_FRAME_I(11) xor feedbackRegister(11) xor feedbackRegister (13);
         RX_DATA_O(12) <= RX_COMMON_FRAME_I(12) xor feedbackRegister(12) xor feedbackRegister (14);
         RX_DATA_O(13) <= RX_COMMON_FRAME_I(13) xor feedbackRegister(13) xor feedbackRegister (15);
         RX_DATA_O(14) <= RX_COMMON_FRAME_I(14) xor feedbackRegister(14) xor feedbackRegister (16);
         RX_DATA_O(15) <= RX_COMMON_FRAME_I(15) xor feedbackRegister(15) xor feedbackRegister (17);
         RX_DATA_O(16) <= RX_COMMON_FRAME_I(16) xor feedbackRegister(16) xor feedbackRegister (18);
         RX_DATA_O(17) <= RX_COMMON_FRAME_I(17) xor feedbackRegister(17) xor feedbackRegister (19);
         RX_DATA_O(18) <= RX_COMMON_FRAME_I(18) xor feedbackRegister(18) xor feedbackRegister (20);
         RX_DATA_O(19) <= RX_COMMON_FRAME_I(19) xor feedbackRegister(19) xor RX_COMMON_FRAME_I( 0);
         RX_DATA_O(20) <= RX_COMMON_FRAME_I(20) xor feedbackRegister(20) xor RX_COMMON_FRAME_I( 1);
         feedbackRegister                       <= RX_COMMON_FRAME_I;      
         
      end if;
   end process;
  
end behavioral;
