library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gbt_bank_package.all;

entity gbt_rx_decoder_gbtframe_syndrom is
   port (

      POLY_COEFFS_I                             : in  std_logic_vector(59 downto 0);
      S1_O                                      : out std_logic_vector( 3 downto 0);
      S2_O                                      : out std_logic_vector( 3 downto 0);
      S3_O                                      : out std_logic_vector( 3 downto 0);
      S4_O                                      : out std_logic_vector( 3 downto 0)
      
   );
end gbt_rx_decoder_gbtframe_syndrom;

architecture behavioral of gbt_rx_decoder_gbtframe_syndrom is

   signal net1                                  : syndromes_net1_4x15x4bit_A; 
   signal net2                                  : syndromes_net2_4x7x4bit_A;
   signal net3                                  : syndromes_net3_4x4x4bit_A;
   signal net4                                  : syndromes_net4_4x2x4bit_A; 
   signal syndrome_from_syndromeEvaluator       : syndromes_syndrome_4x4bit_A;

begin

   syndromeEvaluator_gen: for i in 1 to 4 generate   
   
      net1_gen: for j in 0 to 14 generate
         net1(i,j)                              <= gf16mult(POLY_COEFFS_I(59-(4*j) downto 56-(4*j)),ALPHAPOWER_S(i)(59-(4*j) downto 56-(4*j)));      
      end generate;
      
      net2_gen: for j in 0 to 6 generate
         net2(i,j)                              <= gf16add(net1(i,((2*j)+1)),net1(i,(2*j)));         
      end generate;
      
      net3_gen: for j in 0 to 2 generate
         net3(i,j)                              <= gf16add(net2(i,((2*j)+1)),net2(i,(2*j)));
      end generate;
      
      net3(i,3)                                 <= gf16add(net1(i,14),net2(i,6));
        
      net4_gen: for j in 0 to 1 generate
         net4(i,j)                              <= gf16add(net3(i,((2*j)+1)),net3(i,(2*j)));        
      end generate;
      
      syndrome_from_syndromeEvaluator(i)        <=  gf16add(net4(i,1),net4(i,0)); 

   end generate;
   S1_O                                         <= syndrome_from_syndromeEvaluator(1);
   S2_O                                         <= syndrome_from_syndromeEvaluator(2);
   S3_O                                         <= syndrome_from_syndromeEvaluator(3);
   S4_O                                         <= syndrome_from_syndromeEvaluator(4);

end behavioral;
