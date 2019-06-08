/*
 * main.c
 *
 *  Created on: 2019年6月1日
 *      Author: biaogexf
 */
 
#define MANUAL_MODE 'b'   //蓝牙
#define AUTOMATIC_MODE 'c'  //避障
#define SENSOR_MODE 'h'  //循迹


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

#include "xuartlite.h"
#include "xuartlite_l.h"

#include "macros.h"
#include "cmd.h"
#include "pwm.h"
#include "xil_printf.h"
#include "ult.h"

//
//
//int main()
//{
//char mode = SENSOR_MODE; //模式选择
//int fsm = 0;
//u16 cmd = 1;
//int i=0;
//
//int num1 = 0;  //红外1
//int num2 = 0;  //红外2
//int num3 = 0;  //红外3
//
//double *wav0 = (double *)malloc(sizeof(double)); *wav0 = 0;
//double *wav1 = (double *)malloc(sizeof(double)); *wav1 = 0;
//
////PWM Initiation XPAR_PWM_CAR_V1_0_0_BASEADDR
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,FRE_THRES);   //pwm fre
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,WAV_THRES); //pwm wav
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,FRE_THRES);  //pwm1 fre
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,WAV_THRES);  //pwm1 wav
//
//Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,0);
//
////Ultrasonic Initiation
//zrcar_ultra_init();
//float *ult_data_0 = (float*)malloc(sizeof(float)); *ult_data_0 = 0;
//float *ult_data_1 = (float*)malloc(sizeof(float)); *ult_data_1 = 0;
//float *ult_data_2 = (float*)malloc(sizeof(float)); *ult_data_2 = 0;
//
//while(1){
//	//Variable Initiation
//	//通过蓝牙接收控制模式
////	mode=XUartLite_RecvByte(XPAR_AXI_UARTLITE_0_BASEADDR);
////	printf("%c\n",mode);
//
//
//	if(mode=='w' || mode =='a' || mode =='s' || mode=='d' || mode=='q')  //蓝牙模式
//	{
//		switch(mode)
//		{
//		case 'w': cmd = START_UP; break;
//		case 'a': cmd = TURN_RIGHT; break;
//		case 's': cmd = BACK_UP; break;
//		case 'q': cmd = SHUT_DOWN; break;
//      case 'd': cmd = TURN_LEFT; break;
//		}
//	}else if( mode=='h' )  //红外
//	{
//		//红外循迹代码
//		num1 = Xil_In32(XPAR_SENSOR_V1_0_0_BASEADDR) & 0x000f;
//		printf("%d\n", num1);
//		num2 = Xil_In32(XPAR_SENSOR_V1_0_0_BASEADDR+4) & 0x000f;
//		printf("%d\n", num2);
//		num3 = Xil_In32(XPAR_SENSOR_V1_0_0_BASEADDR+8) & 0x000f ;
//		printf("%d\n", num3);
//		//特殊情况
//
//		if(num3==0 && num2==1 && num1==0)
//		{
//			cmd = START_UP;
//			printf("前进\n");
//		}
//		else if((num1==0 && num2==0) || (num2==1 && num3==1) )
//		{
//			cmd = TURN_LEFT;
//			printf("右转\n");
//		}
//		else if((num3==0 && num2==0) || (num1==1 && num2==1))
//		{
//			cmd = TURN_RIGHT;
//			printf("左转\n");
//		}
//		else if(num1==0 && num2==0 && num3==0)
//		{
//			cmd = BACK_UP;
//			printf("后退\n");
//		}
//		else
//		{
//			cmd = SHUT_DOWN;
//			printf("停止\n");
//		}
//
//
//	}
//	else
//	{  //避障功能
//		//Every 222 ticks get an ultra data
//		if(i % 500 == 1){
//			cmd = START_UP;
//			//usleep(2000);
//			zrcar_ultra_get_all_0(ult_data_0);  //右边
//
//			zrcar_ultra_get_all_1(ult_data_1);  //正面
//
//			zrcar_ultra_get_all_2(ult_data_2);  //左边
//
//			printf("%f mm1正\n",*ult_data_1);
//	     	printf("%f mm0 右\n",*ult_data_0);
//			printf("%f mm2左\n",*ult_data_2);
//
//           if(*ult_data_1 > 3 || *ult_data_2 >3)
//           {
//
//
//
//			if(*ult_data_1 > 300)
//			{
//				cmd = START_UP;
//				printf("go\n");
//			}
//
//			else if(*ult_data_2 > 1000)
//			{
//				cmd = TURN_RIGHT;
//				printf("right\n");
//			}
//
//
//			else if((*ult_data_1 < 400 && *ult_data_2 < 1300) )
//			{
//				cmd = TURN_LEFT;
//				printf("left\n");
//			}
//
//			else
//			{
//				cmd = TURN_LEFT;
//			}
//
//           }
//
//
//
//		}
//
//			//*ult_data_0 > 1900
//			//带着正确的、正和左出去，沿着障碍物左边走
//
//
//	}
//
//
//	//Finite State Machine(fsm) for car move state
//	switch(cmd & 0x000f){
//	case START_UP:
//		fsm = START_UP;
//		update_mode(BOTH_WHEEL_FORWARD);
//		break;
//	case PULL_OVER:
//		fsm = PULL_OVER;
//		break;
//	case BACK_UP:
//		fsm = BACK_UP;
//		update_mode(BOTH_WHEEL_BACK);
//		break;
//	case TURN_LEFT:
//		fsm = TURN_LEFT;
//		update_mode(RIGHT_WHEEL_FORWARD);
//		break;
//	case TURN_RIGHT:
//		fsm = TURN_RIGHT;
//		update_mode(LEFT_WHEEL_FORWARD);
//		break;
//	case TURN_AROUND:
//		fsm = TURN_AROUND;
//		car_shut_down(wav0, wav1);
//		update_mode(BOTH_WHEEL_CLOCKWISE);
//		break;
//	case SHUT_DOWN:
//		fsm = SHUT_DOWN;
//		car_shut_down(wav0, wav1);
//		update_mode(BOTH_WHEEL_FORWARD);
//		break;
//	default:
//		break;
//	}
//
//	//Car control & Assign wavs to electrical machinery
//	//Car control & Assign wavs to electrical machinery
//	switch(fsm){
//	case HOLD_PACE:
//		break;
//	case START_UP:
//		car_start_up(wav0, wav1);
//		break;
//	case PULL_OVER:
//		car_pull_over(wav0, wav1);
//		break;
//	case BACK_UP:
//		car_back_up(wav0, wav1);
//		break;
//	case TURN_LEFT:
//		car_turn_left(wav0, wav1);
//		break;
//	case TURN_RIGHT:
//		car_turn_right(wav0, wav1);
//		break;
//	case TURN_AROUND:
//		car_turn_around(wav0, wav1);
//		break;
//	case SHUT_DOWN:
//		car_shut_down(wav0, wav1);
//		break;
//	default:
//		break;
//	}
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
//
//  }
//
//   return 0;
//}
//

////蓝牙功能
//int main(){
//	char num;
//	int mode;
//
//	//设置PWM  占空比 = f/w (周期/脉宽)
//		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,1500);   //pwm fre
//		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,500); //pwm wav
//		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,1500);  //pwm1 fre
//		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,458);  //pwm1 wav
//
//	while(1){
//
//		num=XUartLite_RecvByte(XPAR_AXI_UARTLITE_0_BASEADDR);
//		printf("%c\n",num);
//		switch(num){
//		case 'q':
//			{
//				mode=0;
//				printf("停止\n");
//				break;
//			}
//		case 'w':
//			{
//				mode=6;
//				printf("前进\n");
//				break; //前进
//			}
//		case 's':
//			{
//				mode=9;
//				printf("后退\n");
//				break; //后退
//			}
//		case 'a':
//			{
//				mode=2;
//				printf("左转\n");
//				break; //左转
//			}
//		case 'd':
//			{
//				mode=4;
//				printf("右转\n");
//				break; //右转
//			}
//		default:
//			{
//				mode=10;break;
//			}
//				}
//
//	    usleep(1000);    //delay lms
//	    Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,mode);  //根据开关值控制电机转动
//	    }
//	return XST_SUCCESS;
//}





//U型车 - 2 - test
int main()
{
	int mode;
    int i = 0;

	//Ultrasonic Initiation
	zrcar_ultra_init();
	float *ult_data_0 = (float*)malloc(sizeof(float)); *ult_data_0 = 0;
	float *ult_data_1 = (float*)malloc(sizeof(float)); *ult_data_1 = 0;
	float *ult_data_2 = (float*)malloc(sizeof(float)); *ult_data_2 = 0;
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,1400);   //pwm fre
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,500); //pwm wav
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,1400);  //pwm1 fre
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,600);  //pwm1 wav

	while(1)
	{
		if(i % 300 == 1){
		//usleep(2000);
//		zrcar_ultra_get_all_0(ult_data_0);  //右边

		zrcar_ultra_get_all_1(ult_data_1);  //正面

		zrcar_ultra_get_all_2(ult_data_2);  //左边

		printf("%f mm1正\n",*ult_data_1);
	//	printf("%f mm0 右\n",*ult_data_0);
		printf("%f mm2左\n",*ult_data_2);

	   if(*ult_data_1 > 3 || *ult_data_2 >3)
	   {

			if(*ult_data_1 > 300)
			{
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,1500);   //pwm fre
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,500); //pwm wav
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,1500);  //pwm1 fre
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,485);  //pwm1 wav

				mode = 6;
				printf("go\n");
			}

			else if(*ult_data_2 > 600 && *ult_data_1<400)    //*ult_data_1<300  //*ult_data_2 > 500
			{
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,1400);   //pwm fre
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,1200); //pwm wav
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,1400);  //pwm1 fre
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,500);  //pwm1 wav
				mode = 2;
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,mode);  //根据开关值控制电机转动

				printf("左转\n");
			}

			else if((*ult_data_1 < 450 && *ult_data_2 < 1300) )  //*ult_data_1 < 400
			{
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,1400);   //pwm fre
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,500); //pwm wav
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,1400);  //pwm1 fre
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,1200);  //pwm1 wav
				mode = 4;
				Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,mode);  //根据开关值控制电机转动
				printf("右转\n");
			}
			else
			{
				mode = 6;
			}
		   }
	   //     usleep(1000);    //delay lms
	   	    Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,mode);  //根据开关值控制电机转动
	  // 	 usleep(10000);
    	}


		i++;
		if(i>100000){
			//Reset in order to avoid overstep the Integer boundary
			i = 0;
		}
	}
	return XST_SUCCESS;
}

