#include<stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"
#include "xil_types.h"
#include "xuartlite.h"
#include "xuartlite_l.h"
#include "xstatus.h"
#include "xil_printf.h"


int main(){
	char num;
	int mode;

	//设置PWM
		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,1000);   //pwm fre
		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,500); //pwm wav
		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,1000);  //pwm1 fre
		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,500);  //pwm1 wav

	while(1){

		num=XUartLite_RecvByte(XPAR_AXI_UARTLITE_0_BASEADDR);
		printf("%d",num);
			switch(num){
					case '0':mode=0;break;
					case '1':mode=6;break; //前进
					case '2':mode=9;break; //后退
					case '3':mode=2;break; //左转
					case '4':mode=4;break; //右转
					default:mode=10;break;
					}

	    usleep(1000);    //delay lms
	    Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,mode);  //根据开关值控制电机转动
	    }
	return XST_SUCCESS;
}
