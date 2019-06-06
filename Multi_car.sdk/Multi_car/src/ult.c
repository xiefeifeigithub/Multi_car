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
//	Xil_Out32(ULTRASONIC_BASEADDR, 1);
	return XST_SUCCESS;
}

//获取超声波传感器计算得到的距离数据到val指针中
int zrcar_ultra_get_all_0(float *val)
{
	Xil_Out32(ULTRASONIC_BASEADDR, 1);  //trig信号  slv_reg0[0]  三个共用一个

	while(!(Xil_In32(ULTRASONIC_BASEADDR) & 2)); //done_0信号   slv_reg0[1]

	*val = (float) Xil_In32(ULTRASONIC_BASEADDR + 4) * ULTRASONIC_PARAM;  //value[0] -- slv_reg1

	return XST_SUCCESS;
}

//获取超声波传感器计算得到的距离数据到val指针中
int zrcar_ultra_get_all_1(float *val)
{
	Xil_Out32(ULTRASONIC_BASEADDR, 1);  //trig信号 slv_reg0[0]

	while(!(Xil_In32(ULTRASONIC_BASEADDR) & 4));  //done_1信号  slv_reg0[2][

	*val = (float) Xil_In32(ULTRASONIC_BASEADDR + 8) * ULTRASONIC_PARAM;  //value[1] -- slv_reg2

	return XST_SUCCESS;
}

//获取超声波传感器计算得到的距离数据到val指针中
int zrcar_ultra_get_all_2(float *val)
{
	Xil_Out32(ULTRASONIC_BASEADDR, 1);  //trig信号 slv_reg0[0]

	while(!(Xil_In32(ULTRASONIC_BASEADDR) & 8));  //done_1信号  slv_reg0[2][

	*val = (float) Xil_In32(ULTRASONIC_BASEADDR + 12) * ULTRASONIC_PARAM;  //value[2] -- slv_reg3

	return XST_SUCCESS;
}
