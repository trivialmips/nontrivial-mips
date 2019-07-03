/**********************************************************************************************************************************************************************
	This file writes the info flash when MonthDate comes.
		It should need four step to write flash:
			1) clear page_latch
			2) write data into page_latch
			3) clear the flash page
			4) write the flash page
		*page_latch just like a buffer.
**********************************************************************************************************************************************************************/

#include "../config.h"

_u32 Last_month_num;  //0~17
#if MONTHDATA_MODULE
struct Record_1 Latest_Record;

void Flash_Read_Info()
{

}

void MonthData(struct Date_Time *Date_and_Time, struct Data *Lcd_data)     //flash中数据保存格式为BCD码
{
#if MONTHDATA_TEST
	printf("%s()...\n", __FUNCTION__);
#endif
	struct Record_0 Month_Record;
	if(Date_and_Time->Month == 1) 
	{
		Month_Record.Date = (Date_and_Time->Year-1)*1000 + 12*10;  //store in _u32 format
	}
	else
	{	   
		Month_Record.Date = Date_and_Time->Year*1000 + (Date_and_Time->Month-1)*10;   //store in _u32 format
	} //eg: 20110120

	Month_Record.TotalHeat = (_u32)(Lcd_data->total_heat)*100/LCD_MULTIPLE;
	Month_Record.TotalFlow = (_u32)(Lcd_data->total_flow)*100/LCD_MULTIPLE;

	//write flash
	Last_month_num++;
	Last_month_num %= 18;

	_u32 addr, err=1;
	addr = INFO_FLASH_START + Last_month_num*12 ;
	err = Flash_Write( addr, &Month_Record, 3) ;

	BUG_ON(err) 

}

void Flash_Write_Test()
{
	_u32 data[4];
	_u32 i,addr;
	for(i=0;i<4;i++)
		data[i] = i;
	addr = 0xbfc0f004;
	Flash_Write(addr, data, 4) ;

}
#endif
