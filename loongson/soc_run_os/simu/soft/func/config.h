#include "include/ls1d.h"
#include "include/SystemInit.h"
#include "include/Calendar.h"
#include "include/lcd.h"
#include "include/key.h"
#include "include/common.h"
#include "include/temp_flow.h"
#include "include/MonthData.h"
#include "include/Infrare.h"
#include "include/frame.h"
#include "include/battery.h"
#include "include/Interrupt.h"
#include "include/xmodem.h"
#include "include/isp.h"
#include "include/cmdline.h"
//#include "myprintf.h"
//#include "test_cycle.h"

//#include <stdio.h>
//#include <math.h>

#define DisableWatchDog()	PMU_Command &= 0xdfffffff ;
#define EnableWatchDog()	PMU_Command |= 0x20000000 ;
#define FeedWatchDog()		PMU_CommandW = 0x40000000 ;

#define NUM 10 
extern _u32 wait[NUM];
extern _u32 main_flag;
extern _u32 work_mode;
extern _u32 *PMU;
extern _u32 *Sonar;
extern _u32 *Thsens;

/********************************Defined by user*******************************************************************************************************************/
#define IR_PWR_ON   	PMU_GPIO_O |= (1 << 3)  //Infrare receiver power on
#define IR_PWR_OFF  	PMU_GPIO_O &=~(1 << 3)  //Infrare receiver power off 
#define KEY_OFF		0x10        //when the key is off, the key_bit of gpio_in will be high  

#define STDC_CALIBRATE		200      //default value
#define COUNT_MASK		0xffffff     //refer to count reg, PMU
#define COUNT_COMPARE		0X1000000     

#define LCD_MULTIPLE		100000      //every varible printed in lcd will plus LCD_MULTIPLE, thus the real value should divide LCD_MULTIPLE
#define LCD_LENGTH		10          //the lcd buf will divide into LCD_LENGTH
#define LCD_NUM_LENGTH		8           //the numbers of number that the lcd can print

#define CJT188_DI_SEQ		1           //it will change the sequence of DI0 and DI1
#define CJT188_DEF_READ		0x0e
#define CJT188_DEF_WRITE	0x1e

#define UART1_INT	0   //enable uart1_rx_int when a key comes, then disable it when received a right frame


/***********************************xmodem Option*****************************************************************************************************************/
#define FLASH_BLOCK_SIZE	256
#define FLASH_ERASE_START	0xbfc00000
#define FLASH_ERASE_END		0xbfc0efff   //60kB

/********************************Info flash Option****************************************************************************************************************/
#define INFO_FLASH_START	0xbfc0fe00
#define AUTO_SAVE_ADDR		0xbfc0fd00

/********************************Pipe Option**********************************************************************************************************************/
#define SOUND_PATH 	0.072f   //m
#define COS_RESULT	1
#define K_COEFFICIENT	0.5f
#define DIAMETER	0.020f   //m
#define PI 		3.1415926f
#define CONST		PI/4      

/********************************Compile Option**********************************************************************************************************************/
#define ISP	1   //ISP module
#define LS1D_FPGA	1   //Choose code for fpga_board or chip_flash.

#define AD_MODULE 		0  
#define ADC_MODULE 		0  
#define LCD_MODULE		0   
#define TDC_TEMP_MODULE		0
#define TDC_FLOW_MODULE		0
#define MONTHDATA_MODULE 	0
#define KEY_MODULE 		0
#define MBUS_MODULE 		0
#define INFRARE_MODULE 		0
#define CALENDAR_MODULE 	0   //need TIMER_MODULE and LCD_MODULE
#define FRAME_MODULE 		0
#define TIMER_MODULE 		0


/********************************Debug Option/Print*******************************************************************************************************************/
#define PRINT 1       //only print necessory information
#if PRINT
#define AD_TEST 	0   //need TIMER_MODULE for 2s delay
#define ADC_TEST 	0   
#define LCD_TEST 	0   //need TIMER_MODULE for 1s delay
#define TEMP_TEST 	0
#define FLOW_TEST 	0
#define MONTHDATA_TEST 	0   //use lcd A3
#define KEY_TEST 	0
#define MBUS_TEST 	0
#define INFRARE_TEST 	0
#define CALENDAR_TEST 	0
#define FRAME_TEST 	0
#define RES_TEST 	0
#define TIMER_TEST 	0
#endif

#if PRINT
#define DEBUG	1        //print information in detail
#endif

#if DEBUG
#define BUG	1
#define debug(fmt,args...)	printf(fmt ,##args);
#define debugX(level,fmt,args...) if(DEBUG>=level) printf(fmt,##args);
#else
#define BUG	0
#define debug(fmt,args...)
#define debugX(level,fmt,args...)
#endif

#if BUG
#define BUG() printf("BUG: failure at %s:%d in %s()!\n", __FILE__, __LINE__, __FUNCTION__); 
#define BUG_ON(condition) if(condition) BUG(); 
#endif /* BUG */


/*************************************main_flag***********************************************************************************************************************/
//unsigned char main_flag0;
#define test_bit	0x80   //低电压检测
#define temp_bit	0x40
#define flow_bit	0x20
#define month_bit	0x10
#define key_bit		0x8
#define lcd_bit		0x4
#define mbus_bit	0x2
#define infrare_bit	0x1
//unsigned char main_flag1;
#define state_bit	0x8000   //gp21的状态, '0'为正常，'1'为异常
#define lowV1_bit	0x4000    //低电压检测1,每隔2秒
#define lowV2_bit	0x2000    //低电压检测2,每月7、14、21、28日凌晨3点置'1'
#define time_bit	0x1000     //软时钟
#define long_key	0x800    //长按键
#define month_flag	0x400      //数据月结时间是否为默认时间，默认时间为每月月底，置'1'
#define A3_delay	0x200     //A3菜单内3秒自动切换
#define wait_halfsec	0x100      //等待0.5秒
//unsigned char main_flag2;
#define wait_3sec	0x800000      //间隔3秒
#define wait_8sec	0x400000      //间隔8秒
#define wait_9sec	0x200000      //间隔9秒
#define wait_10sec	0x100000      //间隔10秒
#define wait_1min	0x80000      //间隔1分钟
#define wait_2min	0x40000      //间隔2分钟
#define wait_16min	0x20000     //间隔16分钟
#define wait_2hour	0x10000    //间隔2小时
//unsigned char main_flag3;
#define rx_bit		0x80000000   //usart收到一个完整的帧
#define infrare_flag	0x40000000      //红外状态，'0'关闭'1'打开
#define lowV_flag	0x20000000       //低电压状态为'1'
#define wait_oneday	0x10000000       //低电压检测，等待一天
#define power_on	0x8000000        //上电检测
#define res_valid	0x4000000	//RES_VALID
#define per_timer	0x2000000

/********************************************************************************************************************************************************************/

/*************************************work_mode***********************************************************************************************************************/
#define MODE_0 0
#define MODE_1 1
#define MODE_2 2
#define MODE_3 3
#define MODE_4 4
#define MODE_5 5
#define MODE_6 6
#define MODE_7 7
#define MODE_8 8
#define MODE_9 9

/********************************************************************************************************************************************************************/

