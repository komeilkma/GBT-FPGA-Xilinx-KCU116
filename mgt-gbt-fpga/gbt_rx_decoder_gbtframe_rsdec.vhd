--Copyright (C) 2023 Komeil Majidi.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.gbt_bank_package.all;

entity gbt_rx_decoder_gbtframe_rsdec is
   port (

      RX_FRAMECLK_I                             : in std_logic;
      RX_COMMON_FRAME_ENCODED_I                 : in  std_logic_vector(59 downto 0);
      RX_COMMON_FRAME_O                         : out std_logic_vector(43 downto 0);
      ERROR_DETECT_O                            : out std_logic;
      MODIFIED_BIT_CNT_O								: out integer range 0 to 44
		
   );
end gbt_rx_decoder_gbtframe_rsdec;
architecture structural of gbt_rx_decoder_gbtframe_rsdec is

   signal s1_from_syndromes                     : std_logic_vector( 3 downto 0);
   signal s2_from_syndromes                     : std_logic_vector( 3 downto 0);
   signal s3_from_syndromes                     : std_logic_vector( 3 downto 0);
   signal s4_from_syndromes                     : std_logic_vector( 3 downto 0);
   signal detIsZero_from_lambdaDeterminant      : std_logic;
   signal error1loc_from_errorLocPolynomial     : std_logic_vector( 3 downto 0);
   signal error2loc_from_errorLocPolynomial     : std_logic_vector( 3 downto 0);
   signal xx0_from_chienSearch                  : std_logic_vector( 3 downto 0);
   signal xx1_from_chienSearch                  : std_logic_vector( 3 downto 0);
   signal corCoeffs_from_rsTwoErrorsCorrect     : std_logic_vector(59 downto 0);
	signal bit_diff										: std_logic_vector(43 downto 0);
	signal error_detected								: std_logic;

begin
   syndromes: entity work.gbt_rx_decoder_gbtframe_syndrom
      port map ( 
         POLY_COEFFS_I                          => RX_COMMON_FRAME_ENCODED_I,
         S1_O                                   => s1_from_syndromes,
         S2_O                                   => s2_from_syndromes,
         S3_O                                   => s3_from_syndromes,
         S4_O                                   => s4_from_syndromes
      );

   lambdaDeterminant: entity work.gbt_rx_decoder_gbtframe_lmbddet
      port map (
         S1_I                                   => s1_from_syndromes,
         S2_I                                   => s2_from_syndromes,
         S3_I                                   => s3_from_syndromes,
         DET_IS_ZERO_O                          => detIsZero_from_lambdaDeterminant
      );

   errorLocPolynomial: entity work.gbt_rx_decoder_gbtframe_errlcpoly
      port map (
         S1_I                                   => s1_from_syndromes,
         S2_I                                   => s2_from_syndromes,
         S3_I                                   => s3_from_syndromes,
         S4_I                                   => s4_from_syndromes,
         DET_IS_ZERO_I                          => detIsZero_from_lambdaDeterminant,
         ERROR_1_LOC_O                          => error1loc_from_errorLocPolynomial,
         ERROR_2_LOC_O                          => error2loc_from_errorLocPolynomial
      );

   chienSearch: entity work.gbt_rx_decoder_gbtframe_chnsrch
      port map (
         ERROR_1_LOC_I                          => error1loc_from_errorLocPolynomial,
         ERROR_2_LOC_I                          => error2loc_from_errorLocPolynomial,
         DET_IS_ZERO_I                          => detIsZero_from_lambdaDeterminant,
         XX0_O                                  => xx0_from_chienSearch,
         XX1_O                                  => xx1_from_chienSearch
      );

   rsTwoErrorsCorrect: entity work.gbt_rx_decoder_gbtframe_rs2errcor
      port map(
         S1_I                                   => s1_from_syndromes,
         S2_I                                   => s2_from_syndromes,
         XX0_I                                  => xx0_from_chienSearch,
         XX1_I                                  => xx1_from_chienSearch,
         REC_COEFFS_I                           => RX_COMMON_FRAME_ENCODED_I,
         DET_IS_ZERO_I                          => detIsZero_from_lambdaDeterminant,
         COR_COEFFS_O                           => corCoeffs_from_rsTwoErrorsCorrect
      );

   RX_COMMON_FRAME_O <= RX_COMMON_FRAME_ENCODED_I(59 downto 16) when    (s1_from_syndromes = x"0"
                                                                     and s2_from_syndromes = x"0"
                                                                     and s3_from_syndromes = x"0"
                                                                     and s4_from_syndromes = x"0") else                                            
                        corCoeffs_from_rsTwoErrorsCorrect(59 downto 16);
    
	
	errdet_proc: process(RX_FRAMECLK_I)
	begin
	
	   if rising_edge(RX_FRAMECLK_I) then
	   
	       ERROR_DETECT_O  <= s1_from_syndromes(0) or s1_from_syndromes(1) or s1_from_syndromes(2) or s1_from_syndromes(3) or
	                          s2_from_syndromes(0) or s2_from_syndromes(1) or s2_from_syndromes(2) or s2_from_syndromes(3) or
	                          s3_from_syndromes(0) or s3_from_syndromes(1) or s3_from_syndromes(2) or s3_from_syndromes(3) or
	                          s4_from_syndromes(0) or s4_from_syndromes(1) or s4_from_syndromes(2) or s4_from_syndromes(3);
	       
	   end if;
	
	end process;
					
	MODIFIED_BIT_CNT_O <= 0;

end structural;
