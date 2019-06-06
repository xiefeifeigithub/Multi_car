################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include src/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
ELFSIZE += \
fsbl_zynq11.elf.size \


# All Target
all: fsbl_zynq11.elf secondary-outputs

# Tool invocations
fsbl_zynq11.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: ARM gcc linker'
	arm-xilinx-eabi-gcc -L"C:\Users\bjut\Desktop\ultrasonic\ultrasonic_ps\ultrasonic_ps.sdk\fsbl_zynq11\src" -Wl,-T -Wl,../src/lscript.ld -L../../fsbl_zynq11_bsp/ps7_cortexa9_0/lib -o "fsbl_zynq11.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

fsbl_zynq11.elf.size: fsbl_zynq11.elf
	@echo 'Invoking: ARM Print Size'
	arm-xilinx-eabi-size fsbl_zynq11.elf  |tee "fsbl_zynq11.elf.size"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(EXECUTABLES)$(OBJS)$(S_UPPER_DEPS)$(C_DEPS)$(ELFSIZE) fsbl_zynq11.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
