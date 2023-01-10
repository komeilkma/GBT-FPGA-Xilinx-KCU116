--Copyright (C) 2022 Komeil Majidi.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity gbt_pattern_generator is  
   port (   
      RESET_I                                        : in  std_logic; 

      TX_FRAMECLK_I                                  : in  std_logic; 

      TX_ENCODING_SEL_I                              : in  std_logic_vector( 1 downto 0);

      TEST_PATTERN_SEL_I                             : in  std_logic_vector( 1 downto 0);
      STATIC_PATTERN_SCEC_I                          : in  std_logic_vector( 1 downto 0);
      STATIC_PATTERN_DATA_I                          : in  std_logic_vector(79 downto 0);
      STATIC_PATTERN_EXTRADATA_WIDEBUS_I             : in  std_logic_vector(31 downto 0);         
      TX_DATA_O                                     : out std_logic_vector(83 downto 0);      
      TX_EXTRA_DATA_WIDEBUS_O                        : out std_logic_vector(31 downto 0)  
   );
end gbt_pattern_generator;
architecture behavioral of gbt_pattern_generator is
begin
   main: process(RESET_I, TX_FRAMECLK_I) 
      constant SCECCOUNTER_OVERFLOW                  : integer := 2**2;
      constant COMMONWORDCOUNTER_OVERFLOW            : integer := 2**20;
      constant WIDEBUSWORDCOUNTER_OVERFLOW           : integer := 2**16;
      variable scEcWordCounter                       : unsigned( 1 downto 0);
      variable commonWordCounter                     : unsigned(19 downto 0);
      variable widebusWordCounter                    : unsigned(15 downto 0);
   begin                                      
      if RESET_I = '1' then                          
         scEcWordCounter                             := (others => '0');
         commonWordCounter                           := (others => '0');      
         widebusWordCounter                          := (others => '0');      
         TX_DATA_O                                   <= (others => '0');
         TX_EXTRA_DATA_WIDEBUS_O                     <= (others => '0');     
      elsif rising_edge(TX_FRAMECLK_I) then 
         TX_DATA_O(83 downto 82)                     <= "11";  
         case TEST_PATTERN_SEL_I is 
            when "01" =>    
               TX_DATA_O(81 downto 80)               <= std_logic_vector(scEcWordCounter);
               if commonWordCounter = SCECCOUNTER_OVERFLOW-1 then 
                  scEcWordCounter                    := (others => '0');
               else 
                  scEcWordCounter                    := scEcWordCounter + 1;
               end if;
               for i in 0 to 3 loop
                  TX_DATA_O((20*i)+19 downto (20*i)) <= std_logic_vector(commonWordCounter);   
               end loop;              
               if commonWordCounter = COMMONWORDCOUNTER_OVERFLOW-1 then 
                  commonWordCounter                  := (others => '0');
               else                             
                  commonWordCounter                  := commonWordCounter + 1;
               end if;                              
               if TX_ENCODING_SEL_I = "01" then
                  for i in 0 to 1 loop
                     TX_EXTRA_DATA_WIDEBUS_O((16*i)+15 downto (16*i)) <= std_logic_vector(widebusWordCounter);   
                  end loop;              
                  if widebusWordCounter = WIDEBUSWORDCOUNTER_OVERFLOW-1 then 
                     widebusWordCounter              := (others => '0');
                  else                          
                     widebusWordCounter              := widebusWordCounter + 1;
                  end if; 
               else
                  TX_EXTRA_DATA_WIDEBUS_O            <= (others => '0');
               end if;
            when "10" =>
               TX_DATA_O(81 downto 80)               <= STATIC_PATTERN_SCEC_I;                            
               TX_DATA_O(79 downto 0)                <= STATIC_PATTERN_DATA_I;                             
               if TX_ENCODING_SEL_I = "01" then
                  TX_EXTRA_DATA_WIDEBUS_O            <= STATIC_PATTERN_EXTRADATA_WIDEBUS_I;  
                else
                  TX_EXTRA_DATA_WIDEBUS_O            <= (others => '0');
               end if;
            when others => 
               TX_DATA_O(81 downto 0)           <= (others => '0');               
               TX_EXTRA_DATA_WIDEBUS_O          <= (others => '0'); 
               
         end case;
         
      end if;
   end process;
end behavioral;