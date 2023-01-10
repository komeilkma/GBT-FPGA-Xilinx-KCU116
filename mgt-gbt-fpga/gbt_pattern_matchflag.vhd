library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity gbt_pattern_matchflag is
   generic (    
      MATCH_PATTERN                             : std_logic_vector(7 downto 0) := x"FF"             
   );                
   port (               
      RESET_I                                   : in  std_logic; 
      CLK_I                                     : in  std_logic; 
      DATA_I                                    : in  std_logic_vector(83 downto 0);
      MATCHFLAG_O                               : out std_logic
      
   );
end gbt_pattern_matchflag;
architecture structural of gbt_pattern_matchflag is 
begin 
   main: process(RESET_I, CLK_I)
   begin
      if RESET_I = '1' then
         MATCHFLAG_O                            <= '0';      
      elsif rising_edge(CLK_I) then    
         MATCHFLAG_O                            <= '0';
         if DATA_I(7 downto 0) = MATCH_PATTERN then
            MATCHFLAG_O                         <= '1';         
         end if;   
      end if;   
   end process;  
end structural;
