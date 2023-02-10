--Copyright (C) 2023 Komeil Majidi.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gbt_bank_package.all;

entity gbt_rx_decoder_gbtframe_rs2errcor is
   port (

      S1_I                                      : in  std_logic_vector( 3 downto 0);
      S2_I                                      : in  std_logic_vector( 3 downto 0);
      XX0_I                                     : in  std_logic_vector( 3 downto 0);
      XX1_I                                     : in  std_logic_vector( 3 downto 0);
      REC_COEFFS_I                              : in  std_logic_vector(59 downto 0);
      DET_IS_ZERO_I                             : in  std_logic;
      COR_COEFFS_O                              : out std_logic_vector(59 downto 0)
      
   );
end gbt_rx_decoder_gbtframe_rs2errcor;

architecture behavioral of gbt_rx_decoder_gbtframe_rs2errcor is

   signal net                                   : rs2errcor_net_11x4bit_A;
   signal net20, net21                          : std_logic_vector( 3 downto 0);
   signal y1, y2, y1b                           : std_logic_vector( 3 downto 0);
   signal ermag1, ermag2, ermag3                : std_logic_vector(59 downto 0);
   signal temp                                  : rs2errcor_temp_6x60bit_A;

begin
   net(1)                                       <= gf16mult(S1_I, XX0_I);            
   net(3)                                       <= gf16mult(XX1_I, XX1_I);   
   net(4)                                       <= gf16mult(XX0_I, XX1_I);            
   y2                                           <= gf16mult(net(2), net(6));          
   net(8)                                       <= gf16mult(y2, XX1_I);            
   y1                                           <= gf16mult(net(9), net(10));
   net(10)                                      <= gf16invr(XX0_I);
   net( 6)                                      <= gf16invr(net(5));
   net(5)                                       <= gf16add(net(3), net(4));   
   net(9)                                       <= gf16add(net(8), S1_I);            
   net(2)                                       <= gf16add(S2_I, net(1));   
   y1b                                          <= gf16mult(S1_I, net(10));   
   net20                                        <= gf16loga(XX0_I);
   net21                                        <= gf16loga(XX1_I); 
   ermag1                                       <= x"00000000000000" & y1;   
   temp(1)                                      <= gf16shift(ermag1, net20);     
   ermag2                                       <= x"00000000000000" & y2;   
   temp(2)                                      <= gf16shift(ermag2, net21);   
   ermag3                                       <= x"00000000000000" & y1b;   
   temp(4)                                      <= gf16shift(ermag3, net20);
 
   adder60_1_gen: for i in 0 to 14 generate   
      temp(3)((4*i)+3 downto 4*i) <= gf16add(temp(1)((4*i)+3 downto 4*i), REC_COEFFS_I((4*i)+3 downto 4*i));         
   end generate;
   
   adder60_2_gen: for i in 0 to 14 generate
      temp(6)((4*i)+3 downto 4*i) <= gf16add(temp(3)((4*i)+3 downto 4*i), temp(2)((4*i)+3 downto 4*i));      
   end generate;
   
   adder60_3_gen: for i in 0 to 14 generate
      temp(5)((4*i)+3 downto 4*i) <= gf16add(temp(4)((4*i)+3 downto 4*i), REC_COEFFS_I((4*i)+3 downto 4*i));      
   end generate;
   COR_COEFFS_O                                 <= temp(6) when DET_IS_ZERO_I = '0' else temp(5);

end behavioral;
