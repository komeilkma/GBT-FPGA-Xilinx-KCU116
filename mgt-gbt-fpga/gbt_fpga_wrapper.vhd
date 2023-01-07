--Copyright (C) 2022 Komeil Majidi.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.gbt_bank_package.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_banks_user_setup.all;
entity gbt_fpga_wrapper is
    port(

        cpu_reset           : in  std_logic; 
        user_clock_p        : in  std_logic; 
        user_clock_n        : in  std_logic;
        sma_mgt_refclk_p    : in  std_logic; 
        sma_mgt_refclk_n    : in  std_logic;
        mgt_ready           : out std_logic;
        gbt_rx_ready        : out std_logic;
        pll_lock            : out std_logic;
        gbt_fpga_tx         : in  std_logic_vector(83 downto 0);
        gbt_fpga_rx         : out std_logic_vector(83 downto 0);
        userclk             : out std_logic; 
        clk_40              : out std_logic;
        clk_80              : out std_logic;
        clk_160             : out std_logic;
        clk_320             : out std_logic;
        sfp_rx_p            : in  std_logic;    
        sfp_rx_n            : in  std_logic;
        sfp_tx_p            : out std_logic;
        sfp_tx_n            : out std_logic
    );
end gbt_fpga_wrapper;
architecture RTL of gbt_fpga_wrapper is
COMPONENT xlx_k7v7_tx_pll 
    PORT(
        clk_in1     :  in std_logic;
        RESET       :  in std_logic;
        CLK_OUT1    : out std_logic;
        CLK_OUT2    : out std_logic;
        CLK_OUT3    : out std_logic;
        CLK_OUT4    : out std_logic;
        LOCKED      : out std_logic
    );
END COMPONENT;
   signal reset_from_genRst                      : std_logic := '0';
   signal fabricClk_from_userClockIbufgds        : std_logic := '0';     
   signal mgtRefClk_from_smaMgtRefClkIbufdsGtxe2 : std_logic := '0';   
                 signal txFrameClk_from_txPll    : std_logic := '0';
                 signal clk80_int                : std_logic := '0';
                 signal clk160_int               : std_logic := '0';
                 signal clk320_int               : std_logic := '0';
   signal generalReset_from_user                     : std_logic := '0';
   signal manualResetTx_from_user                    : std_logic := '0';
   signal manualResetRx_from_user                    : std_logic := '0';
   signal clkMuxSel_from_user                        : std_logic := '0';
   signal testPatterSel_from_user                    : std_logic_vector(1 downto 0) := (others => '0');
   signal loopBack_from_user                         : std_logic_vector(2 downto 0) := (others => '0');
   signal resetDataErrorSeenFlag_from_user           : std_logic_vector(0 downto 0) := (others => '0');
   signal resetGbtRxReadyLostFlag_from_user          : std_logic_vector(0 downto 0) := (others => '0');
   signal txIsDataSel_from_user                      : std_logic_vector(0 downto 0) := (others => '1');    
   signal latOptGbtBankTx_from_gbtExmplDsgn          : std_logic := '0';
   signal latOptGbtBankRx_from_gbtExmplDsgn          : std_logic := '0';
   signal txFrameClkPllLocked_from_gbtExmplDsgn      : std_logic := '0';
   signal mgtReady_from_gbtExmplDsgn                 : std_logic_vector(0 downto 0) := (others => '0'); 
   signal rxBitSlipNbr_from_gbtExmplDsgn1            : std_logic_vector(GBTRX_BITSLIP_NBR_MSB downto 0) := (others => '0');
   signal rxBitSlipNbr_from_gbtExmplDsgn2            : std_logic_vector(GBTRX_BITSLIP_NBR_MSB downto 0) := (others => '0');
   signal rxBitSlipNbr_from_gbtExmplDsgn3            : std_logic_vector(GBTRX_BITSLIP_NBR_MSB downto 0) := (others => '0');
   signal rxWordClkReady_from_gbtExmplDsgn           : std_logic := '0'; 
   signal rxFrameClkReady_from_gbtExmplDsgn          : std_logic := '0'; 
   signal gbtRxReady_from_gbtExmplDsgn               : std_logic_vector(0 downto 0) := (others => '0');    
   signal rxIsData_from_gbtExmplDsgn                 : std_logic_vector(0 downto 0) := (others => '0');        
   signal gbtRxReadyLostFlag_from_gbtExmplDsgn       : std_logic_vector(0 downto 0) := (others => '0'); 
   signal rxDataErrorSeen_from_gbtExmplDsgn          : std_logic_vector(0 downto 0) := (others => '0'); 
   signal rxExtrDataWidebusErSeen_from_gbtExmplDsgn  : std_logic_vector(0 downto 0) := (others => '0'); 
   signal gtx_polar_sel                              : std_logic_vector(0 downto 0) := (others => '0');
   signal gbtbank_tx_data                            : gbtframe_A(1 to 1); 
   signal txData_from_gbtExmplDsgn                   : gbtframe_A(1 to 1);
   signal rxData_from_gbtExmplDsgn                   : gbtframe_A(1 to 1);
   signal txExtraDataWidebus_from_gbtExmplDsgn       : std_logic_vector(31 downto 0) := (others => '0');
   signal rxExtraDataWidebus_from_gbtExmplDsgn       : std_logic_vector(31 downto 0) := (others => '0');
   signal rst1_b_i                                   : std_logic := '0';
   signal rst2_b_i                                   : std_logic := '0';

begin
    
    rst1_b_i <= not cpu_reset;
    rst2_b_i <= not generalReset_from_user;

   genRst: entity work.xlx_k7v7_reset
      generic map (
         CLK_FREQ                                    => 156e6)
      port map (     
         CLK_I                                       => fabricClk_from_userClockIbufgds,
         RESET1_B_I                                  => rst1_b_i,
         RESET2_B_I                                  => rst2_b_i,
         RESET_O                                     => reset_from_genRst 
      );

      userClockIbufgds: ibufgds
         generic map (
            IBUF_LOW_PWR                                => FALSE,      
            IOSTANDARD                                  => "LVDS_25")
         port map (     
            O                                           => fabricClk_from_userClockIbufgds,   
            I                                           => user_clock_p,  
            IB                                          => user_clock_n 
         );

   smaMgtRefClkIbufdsGtxe2: ibufds_gte2
      port map (
         O                                           => mgtRefClk_from_smaMgtRefClkIbufdsGtxe2,
         ODIV2                                       => open,
         CEB                                         => '0',
         I                                           => sma_mgt_refclk_p,
         IB                                          => sma_mgt_refclk_n
      );

   txPll: xlx_k7v7_tx_pll
      port map(
        clk_in1                                  => mgtRefClk_from_smaMgtRefClkIbufdsGtxe2,
        CLK_OUT1                                 => txFrameClk_from_txPll,
        CLK_OUT2                                 => clk80_int,
        CLK_OUT3                                 => clk160_int,
        CLK_OUT4                                 => clk320_int,
        RESET                                    => '0',
        LOCKED                                   => txFrameClkPllLocked_from_gbtExmplDsgn
      );

  gbtExmplDsgn_inst: entity work.xlx_k7v7_gbt_example_design
      generic map(
          GBT_BANK_ID                                            => 1,
          NUM_LINKS                                              => GBT_BANKS_USER_SETUP(1).NUM_LINKS,
          TX_OPTIMIZATION                                        => GBT_BANKS_USER_SETUP(1).TX_OPTIMIZATION,
          RX_OPTIMIZATION                                        => GBT_BANKS_USER_SETUP(1).RX_OPTIMIZATION,
          TX_ENCODING                                            => GBT_BANKS_USER_SETUP(1).TX_ENCODING,
          RX_ENCODING                                            => GBT_BANKS_USER_SETUP(1).RX_ENCODING
      )
      port map (

          FRAMECLK_40MHZ                                         => txFrameClk_from_txPll,
          XCVRCLK                                                => mgtRefClk_from_smaMgtRefClkIbufdsGtxe2,
          TX_FRAMECLK_O                                          => open,        
          TX_WORDCLK_O                                           => open,        
          RX_FRAMECLK_O                                          => open,          
          RX_WORDCLK_O                                           => open,      
          GBTBANK_GENERAL_RESET_I                                => reset_from_genRst,
          GBTBANK_MANUAL_RESET_TX_I                              => manualResetTx_from_user,
          GBTBANK_MANUAL_RESET_RX_I                              => manualResetRx_from_user,
          GBTBANK_MGT_RX_P(1)                                       => sfp_rx_p,
          GBTBANK_MGT_RX_N(1)                                       => sfp_rx_n,
          GBTBANK_MGT_TX_P(1)                                       => sfp_tx_p,
          GBTBANK_MGT_TX_N(1)                                       => sfp_tx_n,
          GBTBANK_GBT_DATA_I                                     => gbtbank_tx_data,
          GBTBANK_WB_DATA_I                                      => (others => "0"),
          TX_DATA_O                                              => txData_from_gbtExmplDsgn,            
          WB_DATA_O                                              => open, 
          GBTBANK_GBT_DATA_O                                     => rxData_from_gbtExmplDsgn,
          GBTBANK_WB_DATA_O                                      => open, 
          GBTBANK_MGT_DRP_RST                                    => '0',
          GBTBANK_MGT_DRP_CLK                                    => fabricClk_from_userClockIbufgds, 
          GBTBANK_TX_ISDATA_SEL_I                                => txIsDataSel_from_user, 
          GBTBANK_TEST_PATTERN_SEL_I                             => testPatterSel_from_user, 
          GBTBANK_RESET_GBTRXREADY_LOST_FLAG_I                   => resetGbtRxReadyLostFlag_from_user, 
          GBTBANK_RESET_DATA_ERRORSEEN_FLAG_I                    => resetDataErrorSeenFlag_from_user, 
          GBTBANK_LINK_READY_O                                   => mgtReady_from_gbtExmplDsgn, 
          GBTBANK_TX_MATCHFLAG_O                                 => open,
          GBTBANK_GBTRX_READY_O                                  => gbtRxReady_from_gbtExmplDsgn, 
          GBTBANK_LINK1_BITSLIP_O                                => rxBitSlipNbr_from_gbtExmplDsgn1, 
          GBTBANK_GBTRXREADY_LOST_FLAG_O                         => gbtRxReadyLostFlag_from_gbtExmplDsgn, 
          GBTBANK_RXDATA_ERRORSEEN_FLAG_O                        => rxDataErrorSeen_from_gbtExmplDsgn, 
          GBTBANK_RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O           => rxExtrDataWidebusErSeen_from_gbtExmplDsgn, 
          GBTBANK_RX_MATCHFLAG_O                                 => open,
          GBTBANK_RX_ISDATA_SEL_O                                => rxIsData_from_gbtExmplDsgn, 
          GBTBANK_RX_ERRORDETECTED_O                             => open,
          GBTBANK_LOOPBACK_I                                     => loopBack_from_user, 
          GBTBANK_TX_POL                                         => gtx_polar_sel,
          GBTBANK_RX_POL                                         => "0"
     );
        mgt_ready           <= mgtReady_from_gbtExmplDsgn(0);
        gbt_rx_ready        <= gbtRxReady_from_gbtExmplDsgn(0);
        pll_lock            <= txFrameClkPllLocked_from_gbtExmplDsgn;
        userclk             <= fabricClk_from_userClockIbufgds;
        clk_40              <= txFrameClk_from_txPll;
        clk_80              <= clk80_int;
        clk_160             <= clk160_int;
        clk_320             <= clk320_int;
        gbtbank_tx_data(1)  <= gbt_fpga_tx;
        gbt_fpga_rx         <= rxData_from_gbtExmplDsgn(1);
        
end RTL;
