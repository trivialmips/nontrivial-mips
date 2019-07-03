/**********************************************************************************************************************************************************************
	This file uses timer to supply a calendar funciton.
**********************************************************************************************************************************************************************/

#include "../config.h"

#if CALENDAR_MODULE
static void DateLowV(struct Date_Time *Date_and_Time)
{
    switch(Date_and_Time->Day){
        case 7:
        case 14:
        case 21:
        case 28:
            if(Date_and_Time->Hour == 3) 
            {
                main_flag |= test_bit;
                main_flag |= lowV2_bit;
            }
            break;
        default:
            break;
    }
}

static void AddDay(struct Date_Time *Date_and_Time)
{
  Date_and_Time->Day +=1;
  Date_and_Time->Hour =0;
}

static void AddMonth(struct Date_Time *Date_and_Time)
{
  Date_and_Time->Month +=1;
  Date_and_Time->Day =1;    //注意,每月第一天是'1'，不是'0'
  Date_and_Time->Hour =0;
  if(main_flag & month_flag) main_flag |= month_bit;  //默认数据月结时间为每月月底
}

static void AddYear(struct Date_Time *Date_and_Time)
{
  Date_and_Time->Year +=1;
  Date_and_Time->Month =1;   //注意
  Date_and_Time->Day =1;    //注意
  Date_and_Time->Hour =0;
  if(main_flag & month_flag) main_flag |= month_bit;  //默认数据月结时间为每月月底
}

//void calendar(struct Date_Time *Date_and_Time, unsigned short lcdmode)
void calendar(struct Date_Time *Date_and_Time)
{
#if CALENDAR_TEST
	printf("calendar()...\n");
#endif
	//if(lcdmode == A2_1 || lcdmode == A2_2)   //once per second
	if(1)
	{
		Date_and_Time->Second +=1;
        	if(Date_and_Time->Second == 60){
	        	Date_and_Time->Minute += 1;
        		Date_and_Time->Second = 0;
        	}
        	if(Date_and_Time->Minute == 60){
        		Date_and_Time->Hour += 1;
       		 	Date_and_Time->Minute =0;
        	}
	}
	else   //cpu will sleep less than a day in most.
	{
    		static _u32 last_count;
		_u32 count, sleep_time;
		count = *(volatile _u32 *)0xbfeb001c; 
		count &= COUNT_MASK;
		sleep_time = (count - last_count)%COUNT_COMPARE;
		_u32 i;
		for(i=0;i<(sleep_time/57600);i++)  //57600=3600*16, one hour
        		Date_and_Time->Hour += 1;
		for(i=0;i<((sleep_time%57600)/960);i++)  //960=60*16, one minute
        		Date_and_Time->Minute += 1;
		for(i=0;i<((sleep_time%960)/16);i++)  
        		Date_and_Time->Second += 1;
		last_count = count - (count%16);  //This is a good write! Read the last 6 lines to understand it.
		if(Date_and_Time->Second >= 60) 
		{
        		Date_and_Time->Minute += 1;
			Date_and_Time->Second %= 60;
		}
		if(Date_and_Time->Minute >= 60) 
		{
        		Date_and_Time->Hour += 1;
			Date_and_Time->Minute %= 60;
		}
	}

    if(Date_and_Time->Hour >= 24)
    {
        /*闰年*/
        if((Date_and_Time->Year%400==0)||((Date_and_Time->Year%4 ==0)&&(Date_and_Time->Year%100 !=0))){
            switch(Date_and_Time->Day){
                case 29:
                    if(Date_and_Time->Month == 2) AddMonth(Date_and_Time);
                    else AddDay(Date_and_Time);
                    break;
                case 30:
                    if((Date_and_Time->Month ==4)||(Date_and_Time->Month ==6)||(Date_and_Time->Month ==9)||(Date_and_Time->Month ==11))
                        AddMonth(Date_and_Time);
                    else AddDay(Date_and_Time);
                    break;
                case 31:
                    if(Date_and_Time->Month == 12) AddYear(Date_and_Time);
                    else AddMonth(Date_and_Time);
                    break;
                default:
                    AddDay(Date_and_Time);
                    break;
            }
        }
        else{
            switch(Date_and_Time->Day){
                case 28:
                    if(Date_and_Time->Month == 2) AddMonth(Date_and_Time);
                    else AddDay(Date_and_Time);
                    break;
                case 30:
                    if((Date_and_Time->Month ==4)||(Date_and_Time->Month ==6)||(Date_and_Time->Month ==9)||(Date_and_Time->Month ==11))
                        AddMonth(Date_and_Time);
                    else AddDay(Date_and_Time);
                    break;
                case 31:
                    if(Date_and_Time->Month == 12) AddYear(Date_and_Time);
                    else AddMonth(Date_and_Time);
                    break;
                default:  
                    AddDay(Date_and_Time);
                    break;
            }
        }
	Date_and_Time->Hour %= 24;
    }

    DateLowV(Date_and_Time);
}

void DateInit(struct Date_Time *Date_and_Time)
{
    Date_and_Time->Year = 2012;
    Date_and_Time->Month = 1;
    Date_and_Time->Day = 31;
    Date_and_Time->Hour = 23;
    Date_and_Time->Minute = 40; //59;
    Date_and_Time->Second = 15; //45; 
    main_flag |= month_flag;
}
#endif
