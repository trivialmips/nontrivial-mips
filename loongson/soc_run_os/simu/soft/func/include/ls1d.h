
/********************************Variable Option**********************************************************************************************************************/
typedef char _s8;
typedef unsigned char _u8;

typedef short _s16;
typedef unsigned short _u16;

typedef int _s32;
typedef unsigned int _u32;

typedef float _fp32;

/********************************LS1D Chip Option**********************************************************************************************************************/
/********************************LS1D Address Space********************************/
#define UNCACHED_MEMORY_ADDR 	0xa0000000
#define UNCACHED_TO_PHYS(x)     ((x) & 0x1fffffff)
#define PHYS_TO_UNCACHED(x)     ((x) | UNCACHED_MEMORY_ADDR)

#define SRAM_BASEADDR			PHYS_TO_UNCACHED(0x0)          //sram
#define SPI_FLASH_BASEADDR		PHYS_TO_UNCACHED(0x1e000000)    //spi flash
#define FLASH_BASEADDR			PHYS_TO_UNCACHED(0x1f000000)   //spi/nand/lpc
#define BOOT_ADDR			PHYS_TO_UNCACHED(0x1fc00000)    //spi/flash
#define FLASH_REG_BASEADDR		PHYS_TO_UNCACHED(0x1fe60000)     //flash regs
#define SPI_REG_BASEADDR		PHYS_TO_UNCACHED(0x1fe80000)     //spi regs
#define UART0_BASEADDR  		PHYS_TO_UNCACHED(0x1fe40000) // LS 20130123 
#define UART1_BASEADDR			PHYS_TO_UNCACHED(0x1fe88000) 
#define I2C_BASEADDR			PHYS_TO_UNCACHED(0x1fe90000)
#define REGS_BASEADDR			PHYS_TO_UNCACHED(0x1fea0000)   //Interrupt_Regs_Baseaddr

#define PMU_BASEADDR			PHYS_TO_UNCACHED(0x1feb0000)
#define SONAR_BASEADDR			PHYS_TO_UNCACHED(0x1feb4000)
#define THSENS_BASEADDR			PHYS_TO_UNCACHED(0x1feb8000)

#define SLCD_REG_BASEADDR		PHYS_TO_UNCACHED(0x1febc000)
#define ADC_BASEADDR			PHYS_TO_UNCACHED(0x1fea8000)

/********************************PMU REGS********************************/
#define PMU_Timing    	*(volatile _u32 *)(PMU_BASEADDR)   
#define PMU_Command    	*(volatile _u32 *)(PMU_BASEADDR+0x04)
#define PMU_Compare    	*(volatile _u32 *)(PMU_BASEADDR+0x08)

#define PMU_ChipCtrl  	*(volatile _u32 *)(PMU_BASEADDR+0x0C)  
#define PMU_GPIO_OE    	*(volatile _u32 *)(PMU_BASEADDR+0x10)
#define PMU_GPIO_O  	*(volatile _u32 *)(PMU_BASEADDR+0x14)
#define PMU_GPIO_I   	*(volatile _u32 *)(PMU_BASEADDR+0x18)

#define PMU_Count 	*(volatile _u32 *)(PMU_BASEADDR+0x1c)

#define PMU_UserDat0	*(volatile _u32 *)(PMU_BASEADDR+0x20)
#define PMU_UserDat1    *(volatile _u32 *)(PMU_BASEADDR+0x24)
#define PMU_UserDat2    *(volatile _u32 *)(PMU_BASEADDR+0x28)
#define PMU_UserDat3    *(volatile _u32 *)(PMU_BASEADDR+0x2c)
#define PMU_UserDat4    *(volatile _u32 *)(PMU_BASEADDR+0x30)

#define PMU_AutoSave    *(volatile _u32 *)(PMU_BASEADDR+0x34)
#define PMU_Exint 	*(volatile _u32 *)(PMU_BASEADDR+0x38)   //external interrupt
#define PMU_CommandW 	*(volatile _u32 *)(PMU_BASEADDR+0x3c)

/******************************SONAR REGS********************************/
#define SONAR_PulseDef        *(volatile _u32 *)(SONAR_BASEADDR)
#define SONAR_SonarCtrl0      *(volatile _u32 *)(SONAR_BASEADDR+0x04)
#define SONAR_SonarCtrl1      *(volatile _u32 *)(SONAR_BASEADDR+0x08)
#define SONAR_GateDef1        *(volatile _u32 *)(SONAR_BASEADDR+0x0C)
#define SONAR_GateDef2        *(volatile _u32 *)(SONAR_BASEADDR+0x10)
#define SONAR_GateDef3        *(volatile _u32 *)(SONAR_BASEADDR+0x14)
#define SONAR_WaveW_Cur       *(volatile _u32 *)(SONAR_BASEADDR+0x18)
#define SONAR_WaveW_Last      *(volatile _u32 *)(SONAR_BASEADDR+0x1C)
#define SONAR_ResPtr          *(volatile _u32 *)(SONAR_BASEADDR+0x20)

#define SONAR_Result          *(volatile _u32 *)(SONAR_BASEADDR+0x40)
//Result[15:0]	SONAR_BASEADDR + [0x40 ~ 0x7c] 

/*****************************THSENS REGS********************************/
#define ThsensCtrl      *(volatile _u32 *)(THSENS_BASEADDR)


/*******************************LCD REGS*********************************/
#define LCD_FB_0  	 	*(volatile _u32 *)(SLCD_REG_BASEADDR)
#define LCD_FB_1		*(volatile _u32 *)(SLCD_REG_BASEADDR+0x04)
#define LCD_FB_2		*(volatile _u32 *)(SLCD_REG_BASEADDR+0x08)
#define LCD_RefeshRate   	*(volatile _u32 *)(SLCD_REG_BASEADDR+0x0C)

/***************************INTERRUPT REGS******************************/
#define INT_EN	       *(volatile _u8 *)(REGS_BASEADDR)
#define INT_EGDE       *(volatile _u8 *)(REGS_BASEADDR+0x01)
#define INT_POL        *(volatile _u8 *)(REGS_BASEADDR+0x02)
#define INT_CLR        *(volatile _u8 *)(REGS_BASEADDR+0x03)
#define INT_SET        *(volatile _u8 *)(REGS_BASEADDR+0x04)
#define INT_OUT        *(volatile _u8 *)(REGS_BASEADDR+0x05)

/*******************************ADC REGS********************************/

#define ADC_CR		*(volatile _u8 *)(ADC_BASEADDR)
#define ADC_D0		*(volatile _u8 *)(ADC_BASEADDR+0x1)
#define ADC_D1		*(volatile _u8 *)(ADC_BASEADDR+0x2)

/*******************************I2C REGS********************************/
#define IIC_PRER_L	*(volatile _u8 *)(I2C_BASEADDR+0x00)
#define IIC_PRER_H 	*(volatile _u8 *)(I2C_BASEADDR+0x01)
#define IIC_CTR   	*(volatile _u8 *)(I2C_BASEADDR+0x02)
#define IIC_TXR   	*(volatile _u8 *)(I2C_BASEADDR+0x03)     //w
#define IIC_RXR		*(volatile _u8 *)(I2C_BASEADDR+0x03)     //r
#define IIC_CR		*(volatile _u8 *)(I2C_BASEADDR+0x04)     //w
#define IIC_SR		*(volatile _u8 *)(I2C_BASEADDR+0x04)     //r
#define IIC_ADDR	*(volatile _u8 *)(I2C_BASEADDR+0x07)     // 7ä½å°å MSB æ æ

/*****************************UART0 REGS********************************/
//NS16550
#define Uart0_RxData    *(volatile _u8 *)(UART0_BASEADDR)
#define Uart0_TxData    *(volatile _u8 *)(UART0_BASEADDR)
#define Uart0_IER   	*(volatile _u8 *)(UART0_BASEADDR+0x01)
#define Uart0_IIR   	*(volatile _u8 *)(UART0_BASEADDR+0x02)	 	//read only
#define Uart0_FCR   	*(volatile _u8 *)(UART0_BASEADDR+0x02)  		//write only
#define Uart0_LCR   	*(volatile _u8 *)(UART0_BASEADDR+0x03)
#define Uart0_MCR   	*(volatile _u8 *)(UART0_BASEADDR+0x04)
#define Uart0_LSR   	*(volatile _u8 *)(UART0_BASEADDR+0x05)
#define Uart0_MSR   	*(volatile _u8 *)(UART0_BASEADDR+0x06)

#define Uart0_BaudL   	*(volatile _u8 *)(UART0_BASEADDR)  
#define Uart0_BaudH   	*(volatile _u8 *)(UART0_BASEADDR+0x01)

/*****************************UART1 REGS********************************/
//NS16550
#define Uart1_RxData    *(volatile _u8 *)(UART1_BASEADDR)
#define Uart1_TxData    *(volatile _u8 *)(UART1_BASEADDR)
#define Uart1_IER       *(volatile _u8 *)(UART1_BASEADDR+0x01)
#define Uart1_IIR       *(volatile _u8 *)(UART1_BASEADDR+0x02)	 	//read only
#define Uart1_FCR       *(volatile _u8 *)(UART1_BASEADDR+0x02)  		//write only
#define Uart1_LCR       *(volatile _u8 *)(UART1_BASEADDR+0x03)
#define Uart1_MCR       *(volatile _u8 *)(UART1_BASEADDR+0x04)
#define Uart1_LSR       *(volatile _u8 *)(UART1_BASEADDR+0x05)
#define Uart1_MSR       *(volatile _u8 *)(UART1_BASEADDR+0x06)

#define Uart1_BaudL     *(volatile _u8 *)(UART1_BASEADDR)  
#define Uart1_BaudH     *(volatile _u8 *)(UART1_BASEADDR+0x01)

/*******************************SPI REGS********************************/
#define SPI_SPCR	*(volatile _u8 *)(SPI_REG_BASEADDR)
#define SPI_SPSR	*(volatile _u8 *)(SPI_REG_BASEADDR+0x01)
#define SPI_TxFIFO	*(volatile _u8 *)(SPI_REG_BASEADDR+0x02)
#define SPI_RxFIFO	*(volatile _u8 *)(SPI_REG_BASEADDR+0x02)
#define SPI_SPER	*(volatile _u8 *)(SPI_REG_BASEADDR+0x03)
#define SPI_SFC_PARAM	*(volatile _u8 *)(SPI_REG_BASEADDR+0x04)
#define SPI_SFC_SOFTCS	*(volatile _u8 *)(SPI_REG_BASEADDR+0x05)
#define SPI_SFC_TIMING	*(volatile _u8 *)(SPI_REG_BASEADDR+0x06)

/*****************************FLASH REGS********************************/
#define FLASH_CMD_REG	*(volatile _u32 *)(FLASH_REG_BASEADDR)
#define FLASH_ERASE_ALL			0x80000000
#define FLASH_ERASE_CMD			0xa0000000
#define FLASH_WRITE_CMD			0xe0000000
#define FLASH_PAGE_LATCH_CLEAR		0X40000000
#define FLASH_ADDR_MASK			0x7ffff80

#define FLASH_PAGE_LATCH_BASEADDR	0xbfe68000     //128bytes	

/**********************************************************************************************************************************************************************/
