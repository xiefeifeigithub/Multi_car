/*
 * ult.h
 *
 *  Created on: 2018��1��17��
 *      Author: wzx
 */

#ifndef ULT_H_
#define ULT_H_
#include "xil_io.h"
#include "xil_types.h"
#include "xstatus.h"
//#include "xgpio.h"
//#include "xuartps.h"
#include "xparameters.h"

/*************************ULTRASONIC base address********************************/
u32 ULTRASONIC_BASEADDR;

/************************* ULTRASONIC_PARAM************************************/
#define ULTRASONIC_PARAM 0.0017

/****************************************************************************/
/**
* Init ultrasonic'base address.
*
** @return	return 0 if succeed
*
*****************************************************************************/
int zrcar_ultra_init();

/****************************************************************************/
/**
* Get value of  ultrasonic module
*
* @param	pointor  value store here
*
* @return	return 0 if succeed
*
*****************************************************************************/
int zrcar_ultra_get_all(float *val);

#endif /* ULT_H_ */


