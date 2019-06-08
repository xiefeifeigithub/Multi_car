/*
 * pwm.c
 *
 *  Created on: 2018年5月11日
 *      Author: Lab
 */

#include "xparameters.h"
#include "xil_io.h"
#include "macros.h"
#include "pwm.h"

//update_freq负责为电机的fre地址赋值
void update_freq(const double *fre0, const double *fre1)
{
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,*fre0);//pwm0 fre
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,*fre1);//pwm1 fre
}

//update_speed负责为电机的wav地址赋值
void update_speed(const double *wav0, const double *wav1)
{
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,*wav0);//pwm0 wav
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,*wav1);//pwm1 wav
}

//update_mode负责更新双电机的运行模式mode
void update_mode(const int mode)
{
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,mode);
}

//car_start_up负责双电机wav递增使得小车前进
void car_start_up(double *wav0, double *wav1)
{
	*wav0 = (*wav0<=*wav1?*wav0:*wav1);
	*wav1 = (*wav0<=*wav1?*wav0:*wav1);

	if(*wav0<WAV_THRES && *wav1<WAV_THRES){
		*wav0 += ACC_PACE;
		*wav1 += ACC_PACE;
	}
}

//car_pull_over负责双电机wav递减使得小车前进
void car_pull_over(double *wav0, double *wav1)
{
	*wav0 = (*wav0<=*wav1?*wav0:*wav1);
	*wav1 = (*wav0<=*wav1?*wav0:*wav1);

	if(*wav0>0 && *wav1>0)
	{
		*wav0 -= DEC_PACE;
		*wav1 -= DEC_PACE;
	}
}

//car_back_up负责双电机wav递增使得小车后退
void car_back_up(double *wav0, double *wav1)
{
	*wav0 = (*wav0<=*wav1?*wav0:*wav1);
	*wav1 = (*wav0<=*wav1?*wav0:*wav1);

	if(*wav0<WAV_THRES && *wav1<WAV_THRES){
		*wav0 += ACC_PACE;
		*wav1 += ACC_PACE;
	}
}

//car_turn_left负责右侧电机wav递增使得小车左转
void car_turn_left(double *wav0, double *wav1)
{
	*wav0 = DRIVEN_THRES;
	*wav1 = (*wav1<DRIVE_THRES?(*wav1)+ACC_PACE:DRIVE_THRES);
}

//car_turn_right负责左侧电机wav递增使得小车右转
void car_turn_right(double *wav0, double *wav1)
{
	*wav0 = (*wav0<DRIVE_THRES?(*wav0)+ACC_PACE:DRIVE_THRES);
	*wav1 = DRIVEN_THRES;
}

//car_turn_around负责双电机wav递增使得小车原地旋转
void car_turn_around(double *wav0, double *wav1)
{
	*wav0 = (*wav0<=*wav1?*wav0:*wav1);
	*wav1 = (*wav0<=*wav1?*wav0:*wav1);

	if(*wav0<DRIVE_THRES && *wav1<DRIVE_THRES){
		*wav0 += GEAR * ACC_PACE;
		*wav1 += GEAR * ACC_PACE;
	}
}

//car_shut_down负责双电机wav赋值为0使得小车紧急刹车
void car_shut_down(double *wav0, double *wav1)
{
	*wav0 = 0.;
	*wav1 = 0.;
}
