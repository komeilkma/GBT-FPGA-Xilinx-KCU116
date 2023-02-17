library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.vendor_specific_gbt_bank_package.all;

entity gbt_rx_gearbox_latopt is
   port (    

      RX_RESET_I                                : in  std_logic;

      RX_WORDCLK_I                              : in  std_logic;
      RX_FRAMECLK_I                             : in  std_logic;
      RX_HEADER_LOCKED_I                        : in  std_logic;
      RX_WRITE_ADDRESS_I                        : in  std_logic_vector(WORD_ADDR_MSB downto 0);
      READY_O                                   : out std_logic;
      RX_WORD_I                                 : in  std_logic_vector(WORD_WIDTH-1 downto 0);
      RX_FRAME_O                                : out std_logic_vector(119 downto 0)
   );
end gbt_rx_gearbox_latopt;
architecture behavioral of gbt_rx_gearbox_latopt is  
   signal reg2                                  : std_logic_vector (119 downto 0);
begin

   gbLatOpt20b_gen: if WORD_WIDTH = 20 generate

      gbLatOpt20b: process(RX_RESET_I, RX_WORDCLK_I)
         variable reg1                          : std_logic_vector (99 downto 0);
      begin
         if RX_RESET_I = '1' then
            reg1                                := (others => '0');
            reg2                                <= (others => '0');
         elsif rising_edge(RX_WORDCLK_I) then
            case RX_WRITE_ADDRESS_I (2 downto 0) is
               when "000"                       => reg1 (19 downto  0) := RX_WORD_I;
               when "001"                       => reg1 (39 downto 20) := RX_WORD_I;
               when "010"                       => reg1 (59 downto 40) := RX_WORD_I;
               when "011"                       => reg1 (79 downto 60) := RX_WORD_I;
               when "100"                       => reg1 (99 downto 80) := RX_WORD_I; 
               when "101"                       => reg2                <= RX_WORD_I & reg1;            
               when others                      => null;
            end case;
         end if;
      end process;     
   
   end generate;   

   gbLatOpt40b_gen: if WORD_WIDTH = 40 generate

      gbLatOpt40b: process(RX_RESET_I, RX_WORDCLK_I)
         variable reg1                          : std_logic_vector (79 downto 0);
      begin
         if RX_RESET_I = '1' then
            reg1                                := (others => '0');
            reg2                                <= (others => '0');
         elsif rising_edge(RX_WORDCLK_I) then
            case RX_WRITE_ADDRESS_I(1 downto 0) is
              when "00"                         => reg1 (39 downto  0)  := RX_WORD_I;
              when "01"                         => reg1 (79 downto 40)  := RX_WORD_I;
              when "10"                         => reg2                 <= RX_WORD_I & reg1;        
              when others                       => null;
            end case;
         end if;
      end process; 
   
   end generate;

   frameInverter: for i in 119 downto 0 generate
      RX_FRAME_O(i)                             <= reg2(119-i);
   end generate;
   gbtRdyCtrl: process(RX_RESET_I, RX_FRAMECLK_I)
   begin
      if RX_RESET_I = '1' then
         READY_O                                <= '0';
      elsif rising_edge(RX_FRAMECLK_I) then     
         READY_O                                <= RX_HEADER_LOCKED_I;      
      end if;
   end process;   
   
end behavioral;
