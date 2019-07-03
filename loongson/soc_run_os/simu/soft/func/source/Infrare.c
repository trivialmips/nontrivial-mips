/**********************************************************************************************************************************************************************
	This file enables the Infrare receiver to receive signals.
**********************************************************************************************************************************************************************/

#include "../config.h"

#if INFRARE_MODULE
void Infrare()
{    
    if((main_flag & wait_8sec)==0){
        if(main_flag & infrare_flag)   //ºìÍâ´¦ÓÚ´ò¿ª×´Ì¬
        {            
	    PMU_GPIO_O &= 0xfffffff7;  //IR_PWR OFF
	    //rUart1_MCR &= ~0xa0;  	//MCR bit7:  ¿¿¿¿;  bit6:Rx¿¿  bit5:Tx¿¿¿¿
            main_flag &= ~infrare_flag;
        }
        else    //ºìÍâ´¦ÓÚ¹Ø±Õ×´Ì¬
        {       
            main_flag |= infrare_flag;
	    PMU_GPIO_OE |= 1 << 3;  //¿¿¿¿IO ¿¿
	    PMU_GPIO_O |= 1 << 3;  //IR ¿¿
            RX_IndexW = 0;
#if UART1_INT
	    Uart1_IER  |= 0x1;    //enable uart1 rx int
#endif
    
            wait[1] = 0;
            main_flag |= wait_8sec; 
        }
    }
}

#endif
