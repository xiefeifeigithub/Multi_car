################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

C_SRCS += \
../src/helloworld.c \
../src/main.c \
../src/platform.c \
../src/pwm.c \
../src/ult.c 

OBJS += \
./src/helloworld.o \
./src/main.o \
./src/platform.o \
./src/pwm.o \
./src/ult.o 

C_DEPS += \
./src/helloworld.d \
./src/main.d \
./src/platform.d \
./src/pwm.d \
./src/ult.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM gcc compiler'
	arm-xilinx-eabi-gcc -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -I../../ultrasonic_pwm_bsp/ps7_cortexa9_0/include -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


