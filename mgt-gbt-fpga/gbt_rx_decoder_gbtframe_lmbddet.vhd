library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gbt_bank_package.all;

entity gbt_rx_decoder_gbtframe_lmbddet is
   port (

      S1_I                                      : in  std_logic_vector(3 downto 0);
      S2_I                                      : in  std_logic_vector(3 downto 0);
      S3_I                                      : in  std_logic_vector(3 downto 0);
      DET_IS_ZERO_O                             : out std_logic
      
   );
end gbt_rx_decoder_gbtframe_lmbddet;

architecture behavioral of gbt_rx_decoder_gbtframe_lmbddet is

   signal mult1_out                             : std_logic_vector(3 downto 0);
   signal mult2_out                             : std_logic_vector(3 downto 0);

   signal add_out                               : std_logic_vector(3 downto 0);   

begin

   mult1_out                                    <= gf16mult(S2_I,S3_I);
   mult2_out                                    <= gf16mult(S1_I,S2_I);      
   add_out                                      <= gf16add(mult1_out, mult2_out);
   DET_IS_ZERO_O                                <= '1' when add_out = "0000" else '0'; 
   
end behavioral;
