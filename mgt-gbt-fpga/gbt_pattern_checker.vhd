--Copyright (C) 2022 Komeil Majidi.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity gbt_pattern_checker is
   port(
      RESET_I                                                    : in  std_logic;
      RX_FRAMECLK_I                                              : in  std_logic;     
      RX_DATA_I                                                  : in  std_logic_vector(83 downto 0);      
      RX_EXTRA_DATA_WIDEBUS_I                                    : in  std_logic_vector(31 downto 0);   
      GBT_RX_READY_I                                             : in std_logic;      
      RX_ENCODING_SEL_I                                          : in  std_logic_vector( 1 downto 0);
      TEST_PATTERN_SEL_I                                         : in  std_logic_vector( 1 downto 0);
      STATIC_PATTERN_SCEC_I                                      : in  std_logic_vector( 1 downto 0);
      STATIC_PATTERN_DATA_I                                      : in  std_logic_vector(79 downto 0);
      STATIC_PATTERN_EXTRADATA_WIDEBUS_I                         : in  std_logic_vector(31 downto 0);
      RESET_GBTRXREADY_LOST_FLAG_I                               : in  std_logic;      
      RESET_DATA_ERRORSEEN_FLAG_I                                : in  std_logic;
      GBTRXREADY_LOST_FLAG_O                                     : out std_logic;
      RXDATA_ERRORSEEN_FLAG_O                                    : out std_logic;
      RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O                       : out std_logic;
      RXDATA_ERROR_CNT                                           : out std_logic_vector(63 downto 0);
      RXDATA_WORD_CNT                                            : out std_logic_vector(63 downto 0)
   );
end gbt_pattern_checker;
architecture behavioral of gbt_pattern_checker is    
    signal RXDATA_ERROR_CNT_s: unsigned(63 downto 0);
    signal RXDATA_WORD_CNT_s: unsigned(63 downto 0);  
begin
   main: process(RESET_I, RX_FRAMECLK_I)    
      constant LATENCY_DLY                                       : integer := 200;                              
      type state_T                                               is (s0_idle, s1_delay, s2_test);
      variable state                                             : state_T;   
      variable timer                                             : integer range 0 to LATENCY_DLY;
      variable previousScEc                                      : unsigned( 1 downto 0);
      variable previousWord                                      : unsigned(19 downto 0);
      variable previousWidebusWord                               : unsigned(15 downto 0);     
   begin                                                      
      if RESET_I = '1' then                                                  
         state                                                   := s0_idle;
         timer                                                   :=  0 ;
         previousScEc                                            := (others => '0');
         previousWord                                            := (others => '0');
         previousWidebusWord                                     := (others => '0'); 
         GBTRXREADY_LOST_FLAG_O                                  <= '0';   
         RXDATA_ERRORSEEN_FLAG_O                                 <= '0';
         RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O                    <= '0';      
      elsif rising_edge(RX_FRAMECLK_I) then
         case state is   
         
            when s0_idle =>
               if GBT_RX_READY_I = '1' then  
                  RXDATA_WORD_CNT_s <= (others => '0');
                  RXDATA_ERROR_CNT_s <= (others => '0');
                  state                                          := s1_delay;               
               end if;   
               
            when s1_delay =>                                                                                                  
               if timer = LATENCY_DLY then                 
                  state                                          := s2_test;
                  timer                                          := 0;
               else                   
                  timer                                          := timer + 1;
               end if;  
               
            when s2_test =>

               RXDATA_WORD_CNT_s <= RXDATA_WORD_CNT_s+ 1;
                              
               case TEST_PATTERN_SEL_I is 
                  when "01" =>
                     if
                           RX_DATA_I(83 downto 82)               /= "11"            
                        or RX_DATA_I(81 downto 80)               /= std_logic_vector(previousScEc + 1):
                        or RX_DATA_I(79 downto 60)               /= std_logic_vector(previousWord + 1)
                        or RX_DATA_I(79 downto 60)               /= RX_DATA_I(59 downto 40)
                        or RX_DATA_I(79 downto 60)               /= RX_DATA_I(39 downto 20)
                        or RX_DATA_I(79 downto 60)               /= RX_DATA_I(19 downto 0) 
                     then               
                        RXDATA_ERRORSEEN_FLAG_O                  <= '1';
                        RXDATA_ERROR_CNT_s                       <= RXDATA_ERROR_CNT_s + 1;
                     end if;
                     if RX_ENCODING_SEL_I = "01" then
                        if std_logic_vector(previousWidebusWord + 1) /= RX_EXTRA_DATA_WIDEBUS_I(31 downto 16)
                           or RX_EXTRA_DATA_WIDEBUS_I(31 downto 16)  /= RX_EXTRA_DATA_WIDEBUS_I(15 downto  0)
                        then               
                           RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O  <= '1';
                           RXDATA_ERROR_CNT_s                    <= RXDATA_ERROR_CNT_s+ 1;
                        end if;
                     else
                        RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O     <= '0';
                     end if;  
                     
                  when "10" =>
                     if
                           RX_DATA_I(83 downto 82)               /= "11"   
                        or RX_DATA_I(81 downto 80)               /= STATIC_PATTERN_SCEC_I
                        or RX_DATA_I(79 downto  0)               /= STATIC_PATTERN_DATA_I 
                     then
                        RXDATA_ERRORSEEN_FLAG_O                  <= '1';
                        RXDATA_ERROR_CNT_s                       <= RXDATA_ERROR_CNT_s + 1;
                     end if;
                     if RX_ENCODING_SEL_I = "01" then
                        if RX_EXTRA_DATA_WIDEBUS_I /= STATIC_PATTERN_EXTRADATA_WIDEBUS_I then
                           RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O  <= '1';
                           RXDATA_ERROR_CNT_s                    <= RXDATA_ERROR_CNT_s + 1;
                        end if;
                     else
                        RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O     <= '0';
                     end if; 
                  when others =>                      
                     RXDATA_ERRORSEEN_FLAG_O                     <= '0';                     
                     RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O        <= '0';
               end case;              
               if GBT_RX_READY_I = '0' then   
                  GBTRXREADY_LOST_FLAG_O                         <= '1';
               end if;               
         end case; 
         previousScEc                                            := unsigned(RX_DATA_I(81 downto 80));  
         previousWord                                            := unsigned(RX_DATA_I(79 downto 60));                
         previousWidebusWord                                     := unsigned(RX_EXTRA_DATA_WIDEBUS_I(31 downto 16));        
         if RESET_DATA_ERRORSEEN_FLAG_I = '1' then     
            RXDATA_ERRORSEEN_FLAG_O                              <= '0';
            RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O                 <= '0';
         end if;
         if RESET_GBTRXREADY_LOST_FLAG_I = '1' then   
            GBTRXREADY_LOST_FLAG_O                               <= '0';  
         end if;
      end if;
   end process;

   RXDATA_WORD_CNT <= std_logic_vector(RXDATA_WORD_CNT_s);
   RXDATA_ERROR_CNT <= std_logic_vector(RXDATA_ERROR_CNT_s);
end behavioral;
