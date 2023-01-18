library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gbt_bank_package.all;

entity gbt_rx_decoder_gbtframe_elpeval is
   port (    

      ALPHA_I                                   : in  std_logic_vector( 3 downto 0);
      ERRLOCPOLY_I                              : in  std_logic_vector(11 downto 0);
      ZERO_O                                    : out std_logic
      
   );
end gbt_rx_decoder_gbtframe_elpeval;
architecture behavioral of gbt_rx_decoder_gbtframe_elpeval is
   signal alpha2                                : std_logic_vector(3 downto 0);   
   signal alpha3                                : std_logic_vector(3 downto 0);  
   
   signal net1                                  : std_logic_vector(3 downto 0);
   signal net2                                  : std_logic_vector(3 downto 0);
   signal net3                                  : std_logic_vector(3 downto 0);
   signal net4                                  : std_logic_vector(3 downto 0);
   signal net5                                  : std_logic_vector(3 downto 0);   

begin
   alpha2                                       <= gf16mult(ALPHA_I, ALPHA_I);   
   alpha3                                       <= gf16mult( alpha2, ALPHA_I);
   net1                                         <= gf16mult(ERRLOCPOLY_I(11 downto 8), alpha3);   
   net2                                         <= gf16mult(ERRLOCPOLY_I( 7 downto 4), alpha2);   
   net3                                         <= gf16mult(ERRLOCPOLY_I( 3 downto 0), ALPHA_I);   
   net4                                         <= gf16add(net1, net2);   
   net5                                         <= gf16add(net3, net4);
   ZERO_O                                       <= '1' when net5 = x"0" else '0';

end behavioral;
