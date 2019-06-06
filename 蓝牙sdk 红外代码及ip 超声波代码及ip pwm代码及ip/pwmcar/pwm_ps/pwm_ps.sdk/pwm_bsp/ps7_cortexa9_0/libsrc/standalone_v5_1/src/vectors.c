nvalidateRange(ReadBuff, 64);

	XSdPs_WriteReg16(InstancePtr->Config.BaseAddress,
			XSDPS_XFER_MODE_OFFSET,
			XSDPS_TM_DAT_DIR_SEL_MASK | XSDPS_TM_DMA_EN_MASK);

	Arg = XSDPS_SWITCH_CMD_HS_SET;
	Status = XSdPs_CmdTransfer(InstancePtr, CMD6, Arg, 1);
	if (Status != XST_SUCCESS) {
		Status = XST_FAILURE;
		goto RETURN_PATH;
	}

	/*
	 * Check for transfer complete
	 * Polling for response for now
	 */
	do {
		StatusReg = XSdPs_ReadReg16(InstancePtr->Config.BaseAddress,
					XSDPS_NORM_INTR_STS_OFFSET);
		if (StatusReg & XSDPS_INTR_ERR_MASK) {
			/*
			 * Write to clear error bits
			 */
			XSdPs_WriteReg16(InstancePtr->Config.BaseAddress,
					XSDPS_ERR_INTR_STS_OFFSET,
					XSDPS_ERROR_INTR_ALL_MASK);
			Status = XST_FAILURE;
			goto RETURN_PATH;
		}
	} while ((StatusReg & XSDPS_INTR_TC_MASK) == 0);

	/*
	 * Write to clear bit
	 */
	XSdPs_WriteReg16(InstancePtr->Config.BaseAddress,
			XSDPS_NORM_INTR_STS_OFFSET, XSDPS_INTR_TC_MASK);

	/*
	 * Change the clock frequency to 50 MHz
	 */
	Status = XSdPs_Change_ClkFreq(InstancePtr, XSDPS_CLK_50_MHZ);
	if (Status != XST_SUCCESS) {
			Status = XST_FAILURE;
			goto RETURN_PATH;
	}

	StatusReg = XSdPs_ReadReg8(InstancePtr->Config.BaseAddress,
					XSDPS_HOST_CTRL1_OFFSET);
	StatusReg |= XSDPS_HC_SPEED_MASK;
	XSdPs_WriteReg8(InstancePtr->Config.BaseAddress,
			XSDPS_HOST_CTRL1_OFFSET,StatusReg);

	Status = XSdPs_ReadReg(InstancePtr->Config.BaseAddress,
			XSDPS_RESP0_OFFSET);

#else

	Arg = XSDPS_MMC_HIGH_SPEED_ARG;
	Status = XSdPs_CmdTransfer(InstancePtr, CMD6, Arg, 0);
	if (Status != XST_SUCCESS) {
		Status = XST_FAILURE;
		goto RETURN_PATH;
	}

#ifdef __arm__

	usleep(XSDPS_MMC_DELAY_FOR_SWITCH);

#endif

#ifdef __MICROBLAZE__

	/* 2 msec delay */
	MB_Sleep(2);

#endif

	XSdPs_Change_ClkFreq(InstancePtr, XSDPS_CLK_52_MHZ);

	StatusReg = XSdPs_ReadReg8(InstancePtr->Config.BaseAddress,
					XSDPS_HOST_CTRL1_OFFSET);
	StatusReg |= XSDPS_HC_SPEED_MASK;
	XSdPs_WriteReg8(InstancePtr->Config.BaseAddress,
			XSDPS_HOST_CTRL1_OFFSET,StatusReg);

	Status = XSdPs_ReadReg(InstancePtr->Config.BaseAddress,
			XSDPS_RESP0_OFFSET);
#endif

	Status = XST_SUCCESS;

	RETURN_PATH:
		return Status;

}

/*****************************************************************************/
/**
*
* API to change clock freq to given value.
*
*
* @param	InstancePtr is a pointer to the XSdPs instance.
* @param	SelFreq - Clock frequency in Hz.
*
* @return	None
*
* @note		This API will change clock frequency to the value less than
*		or equal to the given value using the permissible dividors.
*
******************************************************************************/
int XSdPs_Change_ClkFreq(XSdPs *InstancePtr, u32 SelFreq)
{
	u16 ClockReg;
	int DivCnt;
	u16 Divisor;
	u16 ClkLoopCnt;
	int Status;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Disable clock
	 */
	ClockReg = XSdPs_ReadReg16(InstancePtr->Config.BaseAddress,
			XSDPS_CLK_CTRL_OFFSET);
	ClockReg &= ~(XSDPS_CC_INT_CLK_EN_MASK | XSDPS_CC_SD_CLK_EN_MASK);

	XSdPs_WriteReg16(InstancePtr->Config.BaseAddress,
			XSDPS_CLK_CTRL_OFFSET, ClockReg);

	/*
	 * Calculate divisor
	 */
	DivCnt = 0x1;
	for(ClkLoopCnt = 0; ClkLoopCnt < XSDPS_CC_MAX_NUM_OF_DIV;
		ClkLoopCnt++) {
		if( ((InstancePtr->Config.InputClockHz)/DivCnt) <= SelFreq) {
			Divisor = DivCnt/2;
			Divisor = Divisor << XSDPS_CC_DIV_SHIFT;
			break;
		}
		DivCnt = DivCnt << 1;
	}

	if(ClkLoopCnt == 9) {

		/*
		 * No valid divisor found for given frequency
		 */
		Status = XST_FAILURE;
		goto RETURN_PATH;
	}

	/*
	 * Set clock divisor
	 */
	ClockReg = XSdPs_ReadReg16(InstancePtr->Config.BaseAddress,
			XSDPS_CLK_CTRL_OFFSET);
	ClockReg &= (~XSDPS_CC_SDCLK_FREQ_SEL_MASK);

	ClockReg |= Divisor | XSDPS_CC_INT_CLK_EN_MASK;
	XSdPs_WriteReg16(InstancePtr->Config.BaseAddress,
			XSDPS_CLK_CTRL_OFFSET, ClockReg);

	/*
	 * Wait for internal clock to stabilize
	 */
	while((XSdPs_ReadReg16(InstancePtr->Config.BaseAddress,
		XSDPS_CLK_CTRL_OFFSET) & XSDPS_CC_INT_CLK_STABLE_MASK) == 0);

	/*
	 * Enable SD clock
	 */
	ClockReg = XSdPs_ReadReg16(InstancePtr->Config.BaseAddress,
			XSDPS_CLK_CTRL_OFFSET);
	XSdPs_WriteReg16(InstancePtr->Config.BaseAddress,
			XSDPS_CLK_CTRL_OFFSET,
			ClockReg | XSDPS_CC_SD_CLK_EN_MASK);

	Status = XST_SUCCESS;

	RETURN_PATH:
		return Status;

}

/*****************************************************************************/
/**
*
* API to send pullup command to card before using DAT line 3(using 4-bit bus)
*
*
* @param	InstancePtr is a pointer to the XSdPs instance.
*
* @return
*		- XST_SUCCESS if successful.
*		- XST_FAILURE if fail.
*
* @note		None.
*
******************************************************************************/
int XSdPs_Pullup(XSdPs *InstancePtr)
{
	u32 Status = 0;

	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	Status = XSdPs_CmdTransfer(InstancePtr, CMD55,
			InstancePtr->RelCardAddr, 0);
	if (Status != XST_SUCCESS) {
		Status = XST_FAILURE;
		goto RETURN_PATH;
	}

	Status = XSdPs_CmdTransf