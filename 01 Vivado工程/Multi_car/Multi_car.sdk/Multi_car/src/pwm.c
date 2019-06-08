/*
 * pwm.c
 *
 *  Created on: 2018��5��11��
 *      Author: Lab
 */

#include "xparameters.h"
#include "xil_io.h"
#include "macros.h"
#include "pwm.h"

//update_freq����Ϊ�����fre��ַ��ֵ
void update_freq(const double *fre0, const double *fre1)
{
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,*fre0);//pwm0 fre
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,*fre1);//pwm1 fre
}

//update_speed����Ϊ�����wav��ַ��ֵ
void update_speed(const double *wav0, const double *wav1)
{
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,*wav0);//pwm0 wav
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,*wav1);//pwm1 wav
}

//update_mode�������˫���������ģʽmode
void update_mode(const int mode)
{
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,mode);
}

//car_start_up����˫���wav����ʹ��С��ǰ��
void car_start_up(double *wav0, double *wav1)
{
	*wav0 = (*wav0<=*wav1?*wav0:*wav1);
	*wav1 = (*wav0<=*wav1?*wav0:*wav1);

	if(*wav0<WAV_THRES && *wav1<WAV_THRES){
		*wav0 += ACC_PACE;
		*wav1 += ACC_PACE;
	}
}

//car_pull_over����˫���wav�ݼ�ʹ��С��ǰ��
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

//car_back_up����˫���wav����ʹ��С������
void car_back_up(double *wav0, double *wav1)
{
	*wav0 = (*wav0<=*wav1?*wav0:*wav1);
	*wav1 = (*wav0<=*wav1?*wav0:*wav1);

	if(*wav0<WAV_THRES && *wav1<WAV_THRES){
		*wav0 += ACC_PACE;
		*wav1 += ACC_PACE;
	}
}

//car_turn_left�����Ҳ���wav����ʹ��С����ת
void car_turn_left(double *wav0, double *wav1)
{
	*wav0 = DRIVEN_THRES;
	*wav1 = (*wav1<DRIVE_THRES?(*wav1)+ACC_PACE:DRIVE_THRES);
}

//car_turn_right���������wav����ʹ��С����ת
void car_turn_right(double *wav0, double *wav1)
{
	*wav0 = (*wav0<DRIVE_THRES?(*wav0)+ACC_PACE:DRIVE_THRES);
	*wav1 = DRIVEN_THRES;
}

//car_turn_around����˫���wav����ʹ��С��ԭ����ת
void car_turn_around(double *wav0, double *wav1)
{
	*wav0 = (*wav0<=*wav1?*wav0:*wav1);
	*wav1 = (*wav0<=*wav1?*wav0:*wav1);

	if(*wav0<DRIVE_THRES && *wav1<DRIVE_THRES){
		*wav0 += GEAR * ACC_PACE;
		*wav1 += GEAR * ACC_PACE;
	}
}

//car_shut_down����˫���wav��ֵΪ0ʹ��С������ɲ��
void car_shut_down(double *wav0, double *wav1)
{
	*wav0 = 0.;
	*wav1 = 0.;
}
