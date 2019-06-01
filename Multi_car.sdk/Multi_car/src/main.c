/*
 * main.c
 *
 *  Created on: 2018年5月11日
 *      Author: Lab
 */
 
 
 
#define MANUAL_MODE 0
#define AUTOMATIC_MODE 1


#include "xparameters.h"
#include "xstatus.h"
#include "xil_io.h"
#include "unistd.h"
#include "xil_types.h"
#include "xgpiops.h"
#include "xuartps.h"
#include "string.h"
#include "stdio.h"
#include "stdlib.h"

#include "macros.h"
#include "cmd.h"
#include "pwm.h"
#include "xil_printf.h"
#include "ult.h"

int main()
{
//int mode = AUTOMATIC_MODE;
int fsm = 0;
u16 cmd = 1;
int i=0;
int num1 = 0;
int num2 = 0;
int num3 = 0;
double *wav0 = (double *)malloc(sizeof(double)); *wav0 = 0;
double *wav1 = (double *)malloc(sizeof(double)); *wav1 = 0;

//PWM Initiation XPAR_PWM_CAR_V1_0_0_BASEADDR

Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,FRE_THRES);//pwm0 fre
Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,WAV_THRES);//pwm0 wav
Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,FRE_THRES);//pwm1 fre
Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,WAV_THRES);//pwm1 wav
Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,0);

//Ultrasonic Initiation
zrcar_ultra_init();
float *ult_data = (float*)malloc(sizeof(float)); *ult_data = 0;
float *ult_data1 = (float*)malloc(sizeof(float)); *ult_data1 = 0;
while(1){
//	//Variable Initiation
//	move = 0;
//
//
//	mode=XUartLite_RecvByte(XPAR_AXI_UARTLITE_0_BASEADDR);
//	printf("%c",mode);
//	switch(mode)
//	{
//		case 'm':cmd=0;break;
//		case 'a':mode=6;break; //前进
//		case 's':mode=9;break; //后退
//		case '3':mode=2;break; //左转
//		case '4':mode=4;break; //右转
//		default:mode=10;break;
//	}
	//usleep(1000);    //delay lms

	num1 = Xil_In32(XPAR_SENSOR_V1_0_0_BASEADDR) & 0x000f;
	printf("%d\n", num1);

	num2 = Xil_In32(XPAR_SENSOR_V1_0_0_BASEADDR+4) & 0x000f;
	printf("%d\n", num2);

	num3 = Xil_In32(XPAR_SENSOR_V1_0_0_BASEADDR+8) & 0x000f ;
	printf("%d\n", num3);

	if(num2==1 && num1==1 && num2==1)
	{
		cmd = START_UP;
		goto LOOP;
	}
	if(num1==0 && num2==0)
	{
		cmd = TURN_LEFT;
		goto LOOP;
	}
	if(num3==0 && num2==0)
	{
		cmd = TURN_RIGHT;
		goto LOOP;
	}
	if(num1==0 && num2==0 && num3==0)
	{
		cmd = TURN_AROUND;
		goto LOOP;
	}

	if(num3==0)
	{
		cmd = TURN_RIGHT;
	}
	else if(num1==0)
	{
		cmd = TURN_LEFT;
	}
	else
	{
		cmd = START_UP;
	}

	LOOP:



	//Finite State Machine(fsm) for car move state
	switch(cmd & 0x000f){
	case START_UP:
		fsm = START_UP;
		update_mode(BOTH_WHEEL_FORWARD);
		break;
	case PULL_OVER:
		fsm = PULL_OVER;
		break;
	case BACK_UP:
		fsm = BACK_UP;
		update_mode(BOTH_WHEEL_BACK);
		break;
	case TURN_LEFT:
		fsm = TURN_LEFT;
		update_mode(RIGHT_WHEEL_FORWARD);
		break;
	case TURN_RIGHT:
		fsm = TURN_RIGHT;
		update_mode(LEFT_WHEEL_FORWARD);
		break;
	case TURN_AROUND:
		fsm = TURN_AROUND;
		//car_shut_down(wav0, wav1);
		update_mode(BOTH_WHEEL_CLOCKWISE);
		break;
	case SHUT_DOWN:
		fsm = SHUT_DOWN;
		car_shut_down(wav0, wav1);
		update_mode(BOTH_WHEEL_FORWARD);
		break;
	default:
		break;
	}

	//Car control & Assign wavs to electrical machinery
	switch(fsm){
	case HOLD_PACE:
		break;
	case START_UP:
		car_start_up(wav0, wav1);
		break;
	case PULL_OVER:
		car_pull_over(wav0, wav1);
		break;
	case BACK_UP:
		car_back_up(wav0, wav1);
		break;
	case TURN_LEFT:
		car_turn_left(wav0, wav1);
		break;
	case TURN_RIGHT:
		car_turn_right(wav0, wav1);
		break;
	case TURN_AROUND:
		car_turn_around(wav0, wav1);
		break;
	case SHUT_DOWN:
		car_shut_down(wav0, wav1);
		break;
	default:
		break;
	}

	//Update electrical speed
	update_speed(wav0,wav1);
	
  }

   return 0;
}

