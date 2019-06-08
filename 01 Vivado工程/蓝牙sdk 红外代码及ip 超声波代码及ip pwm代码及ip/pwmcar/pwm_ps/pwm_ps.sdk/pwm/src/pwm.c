#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"
#include "xil_types.h"
#include "xgpio.h"
#include "xgpiops.h"


int main()
{
	static XGpio LED_Ptr;
	static XGpio SWS_Ptr;
	int XStatus;
	int num = 0;


	XStatus = XGpio_Initialize(&LED_Ptr,XPAR_AXI_GPIO_0_DEVICE_ID);
	if(XST_SUCCESS != XStatus)
		printf("GPIO INIT FALLED\n\r");
	XGpio_SetDataDirection(&LED_Ptr,1,0x00);
	XGpio_DiscreteWrite(&LED_Ptr,1,0xFF);

	XStatus = XGpio_Initialize(&SWS_Ptr,XPAR_AXI_GPIO_0_DEVICE_ID);
	if(XST_SUCCESS != XStatus)
		printf("GPIO INIT FAILED\n\r");
	XGpio_SetDataDirection(&SWS_Ptr,2,0xFF);

	//ÉèÖÃPWM
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR,1000);   //pwm fre
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+4,500); //pwm wav
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+8,1000);  //pwm1 fre
	Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+12,500);  //pwm1 wav

	while(1){
		num = XGpio_DiscreteRead(&SWS_Ptr,2);
		printf("Numb %d\n\r", num);
		XGpio_DiscreteWrite(&LED_Ptr,1,num);

		usleep(1000);
		Xil_Out32(XPAR_PWM_CAR_V1_0_0_BASEADDR+16,9); //1001 - Õý×ª
	}


	return 0;


}
