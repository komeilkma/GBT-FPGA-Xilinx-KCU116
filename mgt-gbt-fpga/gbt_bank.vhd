--Copyright (C) 2022 Komeil Majidi.

Library IEEE;
Use IEEE.std_logic_1164.All;
Use IEEE.numeric_std.All;
Use work.gbt_bank_package.All;
Use work.vendor_specific_gbt_bank_package.All;
Use work.gbt_banks_user_setup.All;

Entity gbt_bank Is
	Generic (
		GBT_BANK_ID : Integer := 0;
		NUM_LINKS : Integer := 1;
		TX_OPTIMIZATION : Integer Range 0 To 1 := STANDARD;
		RX_OPTIMIZATION : Integer Range 0 To 1 := STANDARD;
		TX_ENCODING : Integer Range 0 To 1 := GBT_FRAME;
		RX_ENCODING : Integer Range 0 To 1 := GBT_FRAME
	);
	Port (

		CLKS_I : In gbtBankClks_i_R;
		CLKS_O : Out gbtBankClks_o_R;

		GBT_TX_I : In gbtTx_i_R_A (1 To NUM_LINKS);
		GBT_TX_O : Out gbtTx_o_R_A (1 To NUM_LINKS);

		MGT_I : In mgt_i_R;
		MGT_O : Out mgt_o_R;
		GBT_RX_I : In gbtRx_i_R_A (1 To NUM_LINKS);
		GBT_RX_O : Out gbtRx_o_R_A (1 To NUM_LINKS)

	);
End gbt_bank;

Architecture structural Of gbt_bank Is

	Signal tx_wordNbit_from_gbtTx : word_mxnbit_A (1 To NUM_LINKS);
	Signal phaligned_from_gbtTx : Std_logic_vector (1 To NUM_LINKS);
	Signal phcomputing_from_gbtTx : Std_logic_vector (1 To NUM_LINKS);

	Signal tx_wordclk : Std_logic_vector (1 To NUM_LINKS);
	Signal txReady_from_mgt : Std_logic_vector (1 To NUM_LINKS);
	Signal rxReady_from_mgt : Std_logic_vector (1 To NUM_LINKS);
	Signal rxWordClkReady_from_mgt : Std_logic_vector (1 To NUM_LINKS);
	Signal rx_wordNbit_from_mgt : word_mxnbit_A (1 To NUM_LINKS);
	Signal rxBitSlipNbr_from_gbtRx : rxBitSlipNbr_mxnbit_A (1 To NUM_LINKS);
	Signal rxHeaderLocked_from_gbtRx : Std_logic_vector (1 To NUM_LINKS);

	Signal rx_wordclk : Std_logic_vector (1 To NUM_LINKS);
Begin

	gbtTx_param_generic_src_gen : If GBT_BANK_ID = 0 Generate
		gbtTx_gen : For i In 1 To NUM_LINKS Generate
			gbtTx : Entity work.gbt_tx
				Generic Map(
					GBT_BANK_ID => GBT_BANK_ID,
					NUM_LINKS => NUM_LINKS,
					TX_OPTIMIZATION => TX_OPTIMIZATION,
					RX_OPTIMIZATION => RX_OPTIMIZATION,
					TX_ENCODING => TX_ENCODING,
					RX_ENCODING => RX_ENCODING
				)
				Port Map(
					-- Reset & Clocks:
					TX_RESET_I => GBT_TX_I(i).reset,
					TX_FRAMECLK_I => CLKS_I.tx_frameClk(i),
					TX_WORDCLK_I => tx_wordclk(i),
					-- Control:              
					TX_MGT_READY_I => txReady_from_mgt(i),
					PHASE_ALIGNED_O => phaligned_from_gbtTx(i),
					PHASE_COMPUTING_DONE_O => phcomputing_from_gbtTx(i),
					TX_ISDATA_SEL_I => GBT_TX_I(i).isDataSel,
					-- Data & Word:        
					TX_DATA_I => GBT_TX_I(i).data,
					TX_WORD_O => tx_wordNbit_from_gbtTx(i),
					------------------------------------
					TX_EXTRA_DATA_WIDEBUS_I => GBT_TX_I(i).extraData_widebus
				);

			GBT_TX_O(i).txGearboxAligned_o <= phaligned_from_gbtTx(i);
			GBT_TX_O(i).txGearboxAligned_done <= phcomputing_from_gbtTx(i);

		End Generate;
	End Generate;

	gbtTx_param_pacakge_src_gen : If GBT_BANK_ID > 0 Generate
		gbtTx_gen : For i In 1 To GBT_BANKS_USER_SETUP(GBT_BANK_ID).NUM_LINKS Generate
			gbtTx : Entity work.gbt_tx
				Generic Map(
					GBT_BANK_ID => GBT_BANK_ID,
					NUM_LINKS => GBT_BANKS_USER_SETUP(GBT_BANK_ID).NUM_LINKS,
					TX_OPTIMIZATION => GBT_BANKS_USER_SETUP(GBT_BANK_ID).TX_OPTIMIZATION,
					RX_OPTIMIZATION => GBT_BANKS_USER_SETUP(GBT_BANK_ID).RX_OPTIMIZATION,
					TX_ENCODING => GBT_BANKS_USER_SETUP(GBT_BANK_ID).TX_ENCODING,
					RX_ENCODING => GBT_BANKS_USER_SETUP(GBT_BANK_ID).RX_ENCODING
				)
				Port Map(
					-- Reset & Clocks:
					TX_RESET_I => GBT_TX_I(i).reset,
					TX_FRAMECLK_I => CLKS_I.tx_frameClk(i),
					TX_WORDCLK_I => tx_wordclk(i),
					-- Control:              
					TX_MGT_READY_I => txReady_from_mgt(i),
					PHASE_ALIGNED_O => phaligned_from_gbtTx(i),
					PHASE_COMPUTING_DONE_O => phcomputing_from_gbtTx(i),
					TX_ISDATA_SEL_I => GBT_TX_I(i).isDataSel,
					-- Data & Word:        
					TX_DATA_I => GBT_TX_I(i).data,
					TX_WORD_O => tx_wordNbit_from_gbtTx(i),
					------------------------------------
					TX_EXTRA_DATA_WIDEBUS_I => GBT_TX_I(i).extraData_widebus
				);

			GBT_TX_O(i).txGearboxAligned_o <= phaligned_from_gbtTx(i);
			GBT_TX_O(i).txGearboxAligned_done <= phcomputing_from_gbtTx(i);
		End Generate;
	End Generate;

	mgt_param_generic_src_gen : If GBT_BANK_ID = 0 Generate
		mgt : Entity work.multi_gigabit_transceivers
			Generic Map(
				GBT_BANK_ID => GBT_BANK_ID,
				NUM_LINKS => NUM_LINKS,
				TX_OPTIMIZATION => TX_OPTIMIZATION,
				RX_OPTIMIZATION => RX_OPTIMIZATION,
				TX_ENCODING => TX_ENCODING,
				RX_ENCODING => RX_ENCODING
			)
			Port Map(
				-- Clocks:    
				MGT_CLKS_I => CLKS_I.mgt_clks,
				MGT_CLKS_O => CLKS_O.mgt_clks,
				-- MGT I/O:                
				MGT_I => MGT_I,
				MGT_O => MGT_O,

				-- Control:
				PHASE_ALIGNED_I => phaligned_from_gbtTx(1),
				PHASE_COMPUTING_DONE_I => phcomputing_from_gbtTx(1),

				TX_WORDCLK_O => tx_wordclk,
				RX_WORDCLK_O => rx_wordclk,

				GBTTX_MGTTX_RDY_O => txReady_from_mgt,
				---------------------------------------
				GBTRX_MGTRX_RDY_O => rxReady_from_mgt,
				GBTRX_RXWORDCLK_READY_O => rxWordClkReady_from_mgt,
				GBTRX_HEADER_LOCKED_I => rxHeaderLocked_from_gbtRx,
				GBTRX_BITSLIP_NBR_I => rxBitSlipNbr_from_gbtRx,
				-- Words:      
				GBTTX_WORD_I => tx_wordNbit_from_gbtTx,
				GBTRX_WORD_O => rx_wordNbit_from_mgt
			);
	End Generate;

	mgt_param_package_src_gen : If GBT_BANK_ID > 0 Generate
		mgt : Entity work.multi_gigabit_transceivers
			Generic Map(
				GBT_BANK_ID => GBT_BANK_ID,
				NUM_LINKS => GBT_BANKS_USER_SETUP(GBT_BANK_ID).NUM_LINKS,
				TX_OPTIMIZATION => GBT_BANKS_USER_SETUP(GBT_BANK_ID).TX_OPTIMIZATION,
				RX_OPTIMIZATION => GBT_BANKS_USER_SETUP(GBT_BANK_ID).RX_OPTIMIZATION,
				TX_ENCODING => GBT_BANKS_USER_SETUP(GBT_BANK_ID).TX_ENCODING,
				RX_ENCODING => GBT_BANKS_USER_SETUP(GBT_BANK_ID).RX_ENCODING
			)
			Port Map(
				-- Clocks:    
				MGT_CLKS_I => CLKS_I.mgt_clks,
				MGT_CLKS_O => CLKS_O.mgt_clks,
				-- MGT I/O:                
				MGT_I => MGT_I,
				MGT_O => MGT_O,

				-- Control:
				PHASE_ALIGNED_I => phaligned_from_gbtTx(1),
				PHASE_COMPUTING_DONE_I => phcomputing_from_gbtTx(1),

				TX_WORDCLK_O => tx_wordclk,
				RX_WORDCLK_O => rx_wordclk,

				GBTTX_MGTTX_RDY_O => txReady_from_mgt,
				---------------------------------------
				GBTRX_MGTRX_RDY_O => rxReady_from_mgt,
				GBTRX_RXWORDCLK_READY_O => rxWordClkReady_from_mgt,
				GBTRX_HEADER_LOCKED_I => rxHeaderLocked_from_gbtRx,
				GBTRX_BITSLIP_NBR_I => rxBitSlipNbr_from_gbtRx,
				-- Words:      
				GBTTX_WORD_I => tx_wordNbit_from_gbtTx,
				GBTRX_WORD_O => rx_wordNbit_from_mgt
			);
	End Generate;
	gbtRx_param_generic_src_gen : If GBT_BANK_ID = 0 Generate
		gbtRx_gen : For i In 1 To NUM_LINKS Generate

			gbtRx : Entity work.gbt_rx
				Generic Map(
					GBT_BANK_ID => GBT_BANK_ID,
					NUM_LINKS => NUM_LINKS,
					TX_OPTIMIZATION => TX_OPTIMIZATION,
					RX_OPTIMIZATION => RX_OPTIMIZATION,
					TX_ENCODING => TX_ENCODING,
					RX_ENCODING => RX_ENCODING
				)
				Port Map(
					-- Reset & Clocks:
					RX_RESET_I => GBT_RX_I(i).reset,
					RX_WORDCLK_I => rx_wordclk(i),
					RX_FRAMECLK_I => CLKS_I.rx_frameClk(i),
					-- Control:    
					RX_MGT_RDY_I => rxReady_from_mgt(i),
					RX_WORDCLK_READY_I => rxWordClkReady_from_mgt(i),
					RX_FRAMECLK_READY_I => GBT_RX_I(i).rxFrameClkReady,
					------------------------------------
					RX_BITSLIP_NBR_O => rxBitSlipNbr_from_gbtRx(i),
					RX_HEADER_LOCKED_O => rxHeaderLocked_from_gbtRx(i),
					RX_HEADER_FLAG_O => GBT_RX_O(i).header_flag,
					RX_ISDATA_FLAG_O => GBT_RX_O(i).isDataFlag,
					RX_READY_O => GBT_RX_O(i).ready,
					-- Word & Data:                  
					RX_WORD_I => rx_wordNbit_from_mgt(i),
					RX_DATA_O => GBT_RX_O(i).data,
					------------------------------------
					RX_EXTRA_DATA_WIDEBUS_O => GBT_RX_O(i).extraData_widebus,
					------------------------------------
					RX_BIT_MODIFIED_CNTER => GBT_RX_O(i).rxBitModifiedCnter,
					RX_ERROR_DETECTED => GBT_RX_O(i).rxErrorDetected
				);

			GBT_RX_O(i).bitSlipNbr <= rxBitSlipNbr_from_gbtRx(i);
			GBT_RX_O(i).header_lockedFlag <= rxHeaderLocked_from_gbtRx(i);

		End Generate;
	End Generate;

	gbtRx_param_package_src_gen : If GBT_BANK_ID > 0 Generate
		gbtRx_gen : For i In 1 To GBT_BANKS_USER_SETUP(GBT_BANK_ID).NUM_LINKS Generate

			gbtRx : Entity work.gbt_rx
				Generic Map(
					GBT_BANK_ID => GBT_BANK_ID,
					NUM_LINKS => GBT_BANKS_USER_SETUP(GBT_BANK_ID).NUM_LINKS,
					TX_OPTIMIZATION => GBT_BANKS_USER_SETUP(GBT_BANK_ID).TX_OPTIMIZATION,
					RX_OPTIMIZATION => GBT_BANKS_USER_SETUP(GBT_BANK_ID).RX_OPTIMIZATION,
					TX_ENCODING => GBT_BANKS_USER_SETUP(GBT_BANK_ID).TX_ENCODING,
					RX_ENCODING => GBT_BANKS_USER_SETUP(GBT_BANK_ID).RX_ENCODING
				)
				Port Map(
					-- Reset & Clocks:
					RX_RESET_I => GBT_RX_I(i).reset,
					RX_WORDCLK_I => rx_wordclk(i),
					RX_FRAMECLK_I => CLKS_I.rx_frameClk(i),
					-- Control:    
					RX_MGT_RDY_I => rxReady_from_mgt(i),
					RX_WORDCLK_READY_I => rxWordClkReady_from_mgt(i),
					RX_FRAMECLK_READY_I => GBT_RX_I(i).rxFrameClkReady,
					------------------------------------
					RX_BITSLIP_NBR_O => rxBitSlipNbr_from_gbtRx(i),
					RX_HEADER_LOCKED_O => rxHeaderLocked_from_gbtRx(i),
					RX_HEADER_FLAG_O => GBT_RX_O(i).header_flag,
					RX_ISDATA_FLAG_O => GBT_RX_O(i).isDataFlag,
					RX_READY_O => GBT_RX_O(i).ready,
					-- Word & Data:                  
					RX_WORD_I => rx_wordNbit_from_mgt(i),
					RX_DATA_O => GBT_RX_O(i).data,
					------------------------------------
					RX_EXTRA_DATA_WIDEBUS_O => GBT_RX_O(i).extraData_widebus,
					------------------------------------
					RX_BIT_MODIFIED_CNTER => GBT_RX_O(i).rxBitModifiedCnter,
					RX_ERROR_DETECTED => GBT_RX_O(i).rxErrorDetected
				);

			GBT_RX_O(i).bitSlipNbr <= rxBitSlipNbr_from_gbtRx(i);
			GBT_RX_O(i).header_lockedFlag <= rxHeaderLocked_from_gbtRx(i);

		End Generate;
	End Generate;

	optFlag_param_generic_src_gen : If GBT_BANK_ID = 0 Generate
		optFlag_gen : For i In 1 To NUM_LINKS Generate

			-- TX:
			------

			stdGbtBankTx_gen : If TX_OPTIMIZATION = STANDARD Generate
				GBT_TX_O(i).latOptGbtBank_tx <= '0';
			End Generate;

			latOptGbtBankTx_gen : If TX_OPTIMIZATION = LATENCY_OPTIMIZED Generate
				GBT_TX_O(i).latOptGbtBank_tx <= '1';
			End Generate;

			-- RX:
			------

			stdGbtBankRx_gen : If RX_OPTIMIZATION = STANDARD Generate
				GBT_RX_O(i).latOptGbtBank_rx <= '0';
			End Generate;

			latOptGbtBankRx_gen : If RX_OPTIMIZATION = LATENCY_OPTIMIZED Generate
				GBT_RX_O(i).latOptGbtBank_rx <= '1';
			End Generate;

		End Generate;
	End Generate;

	optFlag_param_package_src_gen : If GBT_BANK_ID > 0 Generate
		optFlag_gen : For i In 1 To GBT_BANKS_USER_SETUP(GBT_BANK_ID).NUM_LINKS Generate

			-- TX:
			------
			stdGbtBankTx_gen : If GBT_BANKS_USER_SETUP(GBT_BANK_ID).TX_OPTIMIZATION = STANDARD Generate
				GBT_TX_O(i).latOptGbtBank_tx <= '0';
			End Generate;

			latOptGbtBankTx_gen : If GBT_BANKS_USER_SETUP(GBT_BANK_ID).TX_OPTIMIZATION = LATENCY_OPTIMIZED Generate
				GBT_TX_O(i).latOptGbtBank_tx <= '1';
			End Generate;

			-- RX:
			------
			stdGbtBankRx_gen : If GBT_BANKS_USER_SETUP(GBT_BANK_ID).RX_OPTIMIZATION = STANDARD Generate
				GBT_RX_O(i).latOptGbtBank_rx <= '0';
			End Generate;

			latOptGbtBankRx_gen : If GBT_BANKS_USER_SETUP(GBT_BANK_ID).RX_OPTIMIZATION = LATENCY_OPTIMIZED Generate
				GBT_RX_O(i).latOptGbtBank_rx <= '1';
			End Generate;

		End Generate;
	End Generate;
End structural;
End structural;
End structural;