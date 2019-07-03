#include "../config.h"

/****************************
*ADC* 	base addr	: 0xbfea8000
	cr offset	: 0x0
	datalow offset	: 0x1	(result[3:0]  in D0[7:4])
	datahigh offset	: 0x2	(result[11:4] in D1[7:0])
*cr*	[8]	: start
	[7]	: standby (RO)
	[2:0]	: select  
		  select=0: adci_a     (battery voltage 3~3.7V )
		  select=1: ldo output (core voltage    1.8V   )

Liu Su
liusu-cpu@ict.ac.cn
****************************/

#if ADC_MODULE

#define adc_start   0x80
#define adc_standby 0x40

static _u32 ADC_measure(_u8 adc_sel)
{
	ADC_CR = adc_start | adc_sel;
	while (ADC_CR & adc_standby != adc_standby) {}
	return (ADC_D1 << 8 + ADC_D0) >> 4;
}

float BatteryMeasure(void)
{
	float BatteryVoltage;
	_u32  result_battery, result_core;

	result_core = ADC_measure(0);
	result_battery = ADC_measure(1);

	BatteryVoltage = 1.8 * result_battery / result_core;
	//printf("Battery Voltage : %f V\n", BatteryVoltage);
	return BatteryVoltage;
}

#endif // ADC_MODULE
int ADC_test(int argc, char argv[][30])
{
	printf("\nin ADC_test");
	return 0;
}

