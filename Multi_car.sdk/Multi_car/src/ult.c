/*
 * ult.c
 *
 *  Created on: 2018年1月17日
 *      Author: wzx
 */

#include "ult.h"


/****************************Optical gpio declaration************************/

//初始化超声波模块
int zrcar_ultra_init()
{
	//ULTRASONIC_BASEADDR = XPAR_ULTRASONIC_0_S00_AXI_BASEADDR; // XPAR_ULTRASONIC_V1_0_0_BASEADDR
	ULTRASONIC_BASEADDR =XPAR_ULTRASONIC_V1_0_0_BASEADDR;
	return XST_SUCCESS;
}
//获取超声波传感器计算得到的距离数据到val指针中
int zrcar_ultra_get_all(float *val)
{
	Xil_Out32(ULTRASONIC_BASEADDR, 1);

	while(!(Xil_In32(ULTRASONIC_BASEADDR) & 2));

	*val = (float) Xil_In32(ULTRASONIC_BASEADDR + 4) * ULTRASONIC_PARAM;

	return XST_SUCCESS;
}
