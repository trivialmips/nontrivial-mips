/**********************************************************************************************************************************************************************
	This file inits some module in LS1D chip.
**********************************************************************************************************************************************************************/

#include "../config.h"
#include "../include/asm/ns16550.h"

void Uart0_Init()
{
	/*
	 8bit  1stop  38400Baut
	*/
#if 1
	Uart0_FCR = FIFO_ENABLE|FIFO_RCV_RST|FIFO_XMT_RST|FIFO_TRIGGER_4;
	Uart0_LCR = CFCR_DLAB;
    Uart0_FCR = 0xCF;
	Uart0_BaudL = 0x23;  //set 57600Baut
	Uart0_LCR = CFCR_8BITS;  //8bit, 1stop
	Uart0_MCR = MCR_DTR|MCR_RTS;
	Uart0_IER = 0;
#endif	
	/*the uart0 rx default state is high, it can work when egde_low or no_egde_low.*/
#if 0
	INT_EGDE   |= 0x08;    //egde change available
	INT_POL    |= 0x08;  	//low available
	//INT_POL    &= ~0x08;    //high available
	Uart0_IER  |= 0x01;    //enable uart0 rx int 
	INT_EN     |= 0x08;  	//enable uart0 int
#endif

#if PRINT
	printf("Uart0 init...\n");
#endif
}

static void Uart1_Init(void)
{
	/*
	 8bit  1stop  2400Baut  odd parity
	*/
#if 0
	__asm__ volatile(
	"lui     $2,0xbfe8;\n" \
	"ori     $2,$2,0x8000;\n" \
	"li      $3,7;\n" \
	"sb      $3,2($2);\n" \
	"li      $3,-128;\n" \
	"sb      $3,3($2);\n" \
	"li      $3,-48;\n" \
	"sb      $3,0($2);\n" \
	"li      $3,11;\n" \
	"sb      $3,3($2);\n" \
	"li      $3,3;\n" \
	"sb      $3,4($2);\n" \
	"li      $3,0;\n" \
	"sb      $3,1($2);\n" \
	:::"$2","$3"
	);
#else
	Uart1_FCR = FIFO_ENABLE|FIFO_RCV_RST|FIFO_XMT_RST|FIFO_TRIGGER_1;
	Uart1_LCR = CFCR_DLAB;
	Uart1_BaudL = 208;  //set 2400Baut
	Uart1_LCR = CFCR_8BITS|CFCR_PENAB|CFCR_PODD;  //8bit, 1stop, odd parity
	Uart1_MCR = MCR_DTR|MCR_RTS;
	Uart1_IER = 0;
#endif

	/*the uart1 rx default state is low, when IR_PWR is off; only can it work when no_egde_low.*/
	//INT_EGDE   |= 0x04;     //egde change available
	//INT_CLR     = 0x3f;		//clear all int bit
	//INT_POL    &= ~0x04;    //high available
	INT_POL    |= 0x04;    //low available
	INT_EN     |= 0x04;		//enable uart1 int

#if PRINT
	printf("Uart1 init...\n");
#endif

#if !(UART1_INT)
	_u8 data;
	data = Uart1_RxData;   //clear the receive fifo
	Uart1_IER  |= 0x01;    //enable uart1 rx int
#endif
}

static void ReLoad()   //上电恢复，从掉电保存位置读取数据，重新赋值给变量
{
#if 0
    DateInit();
#endif

    //Monthdata.h
    //temp_flow.h
    //Last_total_flow = 
}

void SystemInit()
{ 
	//DisableWatchDog();
	/*
	enable BT\UART\KEY\BAT_FAIL Interrupt
	*/
//	Interrupt_Init();

	//Uart0_Init();
#if (INFRARE_MODULE|FRAME_MODULE)
	Uart1_Init();
#endif
	ReLoad();
#if (TDC_TEMP_MODULE|TDC_FLOW_MODULE)
	InitTdc();
#endif
#if AD_MODULE
	ADC_Init();
#endif
    
}

