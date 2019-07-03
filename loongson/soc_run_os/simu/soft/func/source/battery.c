/**********************************************************************************************************************************************************************
	This file uses ADC module to detect and measure the voltage of battery.
**********************************************************************************************************************************************************************/

#include "../config.h"

#if AD_MODULE
void ADC_Init(void)
{
	   IIC_PRER_L =  0x64;    //Baud rate= 8M/4/PRER 
	   IIC_PRER_H =  0x0;
	   IIC_CTR    =  0xa0;    //CTR[7]:core_en [6]:int_en [5]:master:1 slave:0 [4]:txr_ok [3]:rxr_ok  bit[4,3] use in slave mode
		   
		IIC_TXR    =  0x6c;    //slave addr + w
		IIC_CR     =  0x90;    //start and  write
		while( (IIC_SR & 0x83) != 0x01 );
		IIC_CR  = 0x01;

      IIC_TXR    =  0x63;    // max11645 config byte     converte channel AN1  ,single ended
	   IIC_CR     =  0x50;    //send  congig byte  and stop
	   while( (IIC_SR & 0x83) != 0x01 );
	   IIC_CR     = 0x01;

#if AD_TEST
	printf("AD module initted...\n");
#endif
}


static _u32 ADC()  //power_detect
{
	 _u32 sum = 0;
	 _u32 tmp = 0;
	 _u32 i;
	 for( i = 0; i < 8; i++)
	 {
		 IIC_TXR    =  0x6c;    //slave addr + w
		 IIC_CR     =  0x90;    //start and  write
		 while( (IIC_SR & 0x83) != 0x01 );
		 IIC_CR  = 0x01;
		
		 //IIC_TXR    =  0xd2;    //max11645 setup byte      Vref = 2.048 (internal Vref), if use external Vref :a2
		 IIC_TXR    =  0xa2;    //max11645 setup byte      Vref = 2.048 (internal Vref), if use external Vref :a2
		 IIC_CR     =  0x50;    //tx  and  stop
		 while( (IIC_SR & 0x83) != 0x01 );
		 IIC_CR     = 0x01;
		 
		/************ read *********************/
		 IIC_TXR    =  0x6d;    //slave addr + r
		 IIC_CR     =  0x90;
		 while( (IIC_SR & 0x83) != 0x01 );
		 IIC_CR     = 0x01;
			          
		 IIC_CR     =  0x20;    //read
		 while( (IIC_SR & 0x83) != 0x01 );
		 IIC_CR     = 0x01;
		 tmp        =  IIC_RXR & 0x0f;
										          
		 IIC_CR     =  0x60;    //read & stop 
		 while( (IIC_SR & 0x83) != 0x01 );
		 IIC_CR     = 0x01;

	tmp        =  tmp << 8;
	tmp       |=  IIC_RXR & 0xff;
	sum        += tmp;
 	}
   return (sum >> 3);
}

void BatteryTest1()   
{    
	_u32 i;
	_fp32 V_BAT;   

	i = ADC();
	V_BAT = 4096*1.8f/i ;
#if AD_TEST
	printf("---------------------------------------------------Battery: 0x%x------------", i);
	printf_float(V_BAT);
#endif

#if 0
    if(main_flag & wait_10sec){   //放电测电压
        if((main_flag & lowV_flag) == 0)    //当前为正常状态  
        {
            if(i<0x0900)    //检测为低电压
            {
                if(main_flag & wait_oneday)    //第二次放电
                {
                    main_flag |= lowV_flag;
                    main_flag |= lcd_bit;                    
                }
                else    //第一次放电
                {
                    wait[6] = 0;
                    main_flag |= wait_oneday;
                }
            }
            else    //检测为正常
            {             
            }
        }
        else  //当前已经为低电压状态 或者//延迟一天  第二次放电
        {
            if(i>0x0b00){
                main_flag &= ~lowV_flag; 
                main_flag |= lcd_bit;
            }
        }
    }
    else   //不放电测电压
    {
        static unsigned short m;
        if((main_flag & lowV_flag) == 0)   //当前为正常状态
        {
            if(i<0x0aaa){
                main_flag |= lowV_flag;
                main_flag |= lcd_bit;
            }
        }
        else    //当前已经为低电压状态
        {
            if(i>0x0b00){
                if(m==0) 
                {
                    wait[4] = 0;
                    main_flag |= wait_16min;
                }
                m = 1;
            }
            else m = 0;
        }
    }
#endif    
    //P3DIR &= ~0x10;
}

void BatteryTest2()    //放电
{ 
    //电池放电
#if 0
    P3DIR |=0x20;
    P3OUT |=0x20;
#endif    
    wait[5] = 0;
    main_flag |= wait_10sec;
}
#endif
