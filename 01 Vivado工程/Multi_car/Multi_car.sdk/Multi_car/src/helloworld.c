//
//#define MANUAL_MODE 'm'
//#define AUTOMATIC_MODE 'a'
//#define Sensor_MODE 's'
//
//
//#include "xparameters.h"
//#include "xstatus.h"
//#include "xil_io.h"
//#include "unistd.h"
//#include "xil_types.h"
//#include "xgpiops.h"
//#include "xuartps.h"
//#include "xuartlite.h"
//#include "xuartlite_l.h"
//#include "string.h"
//#include "stdio.h"
//#include "stdlib.h"
//
//#include "cmd.h"
//#include "macros.h"
//#include "pwm.c"
//#include "pwm.h"
//#include "ult.h"
//#include "ult.c"
//
//
//#include "xil_printf.h"
//
//int main()
//{
//char mode = Sensor_MODE;
//int fsm = 0;
//u16 cmd = 0;
//u16 lastCmd = 0;
//int move = 0;
//int i=0;
//double *wav0 = (double *)malloc(sizeof(double)); *wav0 = 0;
//double *wav1 = (double *)malloc(sizeof(double)); *wav1 = 0;
//
////PWM Initiation
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,FRE_THRES);//pwm0 fre
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,WAV_THRES);//pwm0 wav
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,FRE_THRES);//pwm1 fre
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,WAV_THRES);//pwm1 wav
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,0);
//
////Ultrasonic Initiation
//zrcar_ultra_init();
//float *ult_data=0;
//
//while(1){
//	//Variable Initiation
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
//
//	usleep(1000);    //delay lms
//
//
//	//Update electrical speed
//	update_speed(wav0,wav1);
//
//	i++;
//	if(i>100000){
//		//Reset in order to avoid overstep the Integer boundary
//		i = 0;
//	}
//	//usleep(1000);//Reserve for time delay 1ms
//}
//
//return 0;
//}
