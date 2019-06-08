/*
 * main.c
 *
 *  Created on: 2018��5��11��
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
int mode = AUTOMATIC_MODE;
int fsm = 0;
u16 cmd = 1;
u16 lastCmd = 0;
int move = 0;
int i=0;
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
float *ult_data=0;
float pre_ult_data = 0;

while(1){
	//Variable Initiation
	move = 0;
	lastCmd = cmd;
	

	//Every 222 ticks get an ultra data
	if(i % 222 == 1){
		pre_ult_data = *ult_data;
		zrcar_ultra_get_all(ult_data);
		printf("%f mm\n",*ult_data);
	}

	if( *ult_data > 10000)
	{
		cmd = START_UP;
	}

	else
	{
		//If no arm move appears
		//If distance towards obstacle is under 222 mm
		if(0 < *ult_data && *ult_data <= 222){
		//	if(cmd == START_UP || cmd == TURN_AROUND){
				cmd = TURN_AROUND;
				mode = AUTOMATIC_MODE;
		//	}
		//If distance towards obstacle is beyond 222 mm
		} else if(mode == AUTOMATIC_MODE && 222 < *ult_data){
			cmd = START_UP;
			mode = AUTOMATIC_MODE;
		}
	}
//	//If no arm move appears
//		//If distance towards obstacle is under 222 mm
//		if(0 < *ult_data && *ult_data <= 222){
//		//	if(cmd == START_UP || cmd == TURN_AROUND){
//				cmd = TURN_AROUND;
//				mode = AUTOMATIC_MODE;
//		//	}
//		//If distance towards obstacle is beyond 222 mm
//		} else if(mode == AUTOMATIC_MODE && 222 < *ult_data){
//			cmd = START_UP;
//			mode = AUTOMATIC_MODE;
//		}

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
	
	i++;
	if(i>100000){
		//Reset in order to avoid overstep the Integer boundary
		i = 0;
	}
	//usleep(1000);//Reserve for time delay 1ms
}

return 0;
}

