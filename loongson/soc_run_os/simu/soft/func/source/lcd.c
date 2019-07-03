#include "../config.h"

/******************************************************************************
lcd module
	1.LcdClear
	2.LcdPrintAll
	3.LcdLowV
	4.LcdDisplay	

	Notice: Some variable of Lcd_data = real_value * LCD_MULTIPLE
******************************************************************************/

#if LCD_MODULE
//clear lcd_buf
static void LcdClear(_u8 *LCD_BUF)
{
    _u32 i ;

    for(i=0;i<LCD_LENGTH;i++) LCD_BUF[i]= 0x00 ;
}

static void LcdPrintAll(_u8 *LCD_BUF)
{
    _u32 i;
    
    for(i=0; i<LCD_LENGTH; i++)
    {
         LCD_BUF[i] = 0xff;
    }
}

static void LcdLowV(_u8 *LCD_BUF)
{
    LCD_BUF[1] |= 0x80; //P6
}

static void WriteLcdRegs(_u8 *LCD_BUF)
{
	/******************Notice!*******************
	     the rignt format is (a<<b)+(c),
	*********************************************
	     a<<b+c  equal  a<<(b+c)
	********************************************/
    LCD_FB_0 = ((_u32)LCD_BUF[3]<<24) + ((_u32)LCD_BUF[2]<<16) + ((_u32)LCD_BUF[1]<<8) + ((_u32)LCD_BUF[0]);
 	//printf("0x%x\n", LCD_FB_0);   
	//printf("0x%x 0x%x 0x%x 0x%x\n", LCD_BUF[3], LCD_BUF[2], LCD_BUF[1], LCD_BUF[0]);
    LCD_FB_1 = ((_u32)LCD_BUF[7]<<24) + ((_u32)LCD_BUF[6]<<16) + ((_u32)LCD_BUF[5]<<8) + ((_u32)LCD_BUF[4]);
 	//printf("0x%x\n", LCD_FB_1);   
	//printf("0x%x 0x%x 0x%x 0x%x\n", LCD_BUF[7], LCD_BUF[6], LCD_BUF[5], LCD_BUF[4]);
    LCD_FB_2 = ((_u32)LCD_BUF[9]<<8) + ((_u32)LCD_BUF[8]);
 	//printf("0x%x\n", LCD_FB_2);   
	//printf("0x%x 0x%x 0x%x 0x%x\n", LCD_BUF[9], LCD_BUF[8]);

}

//0~9 A b C d E F
const _u8 number[] = {
    0x7d, /* "0" */
    0X60, /* "1" */
    0X3e, /* "2" */
    0X7a, /* "3" */
    0X63, /* "4" */
    0X5b, /* "5" */
    0X5F, /* "6" */
    0X70, /* "7" */
    0X7F, /* "8" */
    0X7b  /* "9" */
};
const _u8 word[] = {
    0x77, /* "A" */
    0x4F, /* "b" */
    0x1D, /* "C" */
    0x6E, /* "d" */
    0x1F, /* "E" */
    0x17  /* "F" */
};
#define MINUS 0x2

#if LCD_TEST
static void LcdTest1()   //print every segment
{	
	static volatile _u32 i = 0;
	static volatile _u32 j = 0;

	if(j == 0) {LCD_FB_2 = 0; LCD_FB_0 = i;}
	if(j == 1) {LCD_FB_0 = 0; LCD_FB_1 = i;}
	if(j == 2) {LCD_FB_1 = 0; LCD_FB_2 = i;}

	if(j == 2)
	{
		if(i == 0x8000)
		{
			i = 0;
			j = 0;
		}
	}
	else
	{
		if(i == 0x80000000)
		{
			i = 0;
			j +=1;
		}
	}

	if(i == 0) i++;
	else i<<1;

}

static void LcdTest2(_u8 *LCD_BUF) //print number 0~9 
{
	static _u32 i = 0;
	static _u32 j = 0;

	LCD_BUF[i] = number[j++];
	if(j == LCD_LENGTH)
	{
		j = 0;
		i++;
		if(i == LCD_NUM_LENGTH)
		{
			i = 0;
		}
	}    

	WriteLcdRegs(LCD_BUF);
}
#endif


static void LcdBufWrite(_u8 *LCD_BUF, _u8 *bcd_buf, _u32 decimal_length, _u32 minus)
{
	if(bcd_buf[3]&0xf0) goto step0;
	else if(bcd_buf[3]&0xf) goto step1;
	else if( (decimal_length==5)||(bcd_buf[2]&0xf0) ) goto step2;
	else if( (decimal_length==4)||(bcd_buf[2]&0xf) ) goto step3;
	else if( (decimal_length==3)||(bcd_buf[1]&0xf0) ) goto step4;
	else if( (decimal_length==2)||(bcd_buf[1]&0xf) ) goto step5;
	else if( (decimal_length==1)||(bcd_buf[0]&0xf0) ) goto step6;
	else if( (decimal_length==0)||(bcd_buf[0]&0xf) ) goto step7;
	
	//if minus==0, it will print '-'.
step0:
	LCD_BUF[0] = number[(bcd_buf[3]>>4)];
	if(!(minus++)) LCD_BUF[0] = word[5]; //'F', overflow
step1:
	if(!(minus++)) LCD_BUF[0] = MINUS; 
	LCD_BUF[1] = number[(bcd_buf[3])&0xf];
step2:
	if(!(minus++)) LCD_BUF[1] = MINUS; 
	LCD_BUF[2] = number[(bcd_buf[2]>>4)];
step3:
	if(!(minus++)) LCD_BUF[2] = MINUS; 
	LCD_BUF[3] = number[(bcd_buf[2])&0xf];
step4:
	if(!(minus++)) LCD_BUF[3] = MINUS; 
	LCD_BUF[4] = number[(bcd_buf[1]>>4)];
step5:
	if(!(minus++)) LCD_BUF[4] = MINUS; 
	LCD_BUF[5] = number[(bcd_buf[1])&0xf];
step6:
	if(!(minus++)) LCD_BUF[5] = MINUS; 
	LCD_BUF[6] = number[(bcd_buf[0]>>4)];
step7:
	if(!(minus++)) LCD_BUF[6] = MINUS; 
	LCD_BUF[7] = number[(bcd_buf[0])&0xf];

	if(decimal_length==5) LCD_BUF[2] |= 0x80;  //print p1 
	if(decimal_length==4) LCD_BUF[3] |= 0x80;  //print p2
	if(decimal_length==3) LCD_BUF[4] |= 0x80;  //print p3
	if(decimal_length==2) LCD_BUF[5] |= 0x80;  //print p4
	if(decimal_length==1) LCD_BUF[6] |= 0x80;  //print p5
}

void LcdDisplay(struct Date_Time *Date_and_Time, struct Data *Lcd_data)
{
	_u8 LCD_BUF[LCD_LENGTH];
	LcdClear(&LCD_BUF) ;

#if LCD_TEST
	//LcdTest1();
	LcdTest2(&LCD_BUF);
#else
	//printf("lcdmode = %d\n", Lcd_data->lcdmode);

	_u8 bcd_buf[4];
	_u32 i;
	_u32 minus = 1;
	volatile _u32 display;

	i = Lcd_data->lcdmode/10;
    if(i == A1){    //-------------------------A1----- 
      switch(Lcd_data->lcdmode){
        case A1_0:
		LCD_BUF[0] = word[0];    //'A'
		LCD_BUF[1] = number[1];    //'1'
            	break;
        case A1_1:
		if(Lcd_data->total_heat < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->total_heat):(_u32)(0 - Lcd_data->total_heat);
		UintToBcd((display/100000), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);
        	LCD_BUF[8] = A1_1_0;   
        	LCD_BUF[9] = A1_1_1;   //KW*h
		break;
       case A1_2:
		if(Lcd_data->heat < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->heat):(_u32)(0 - Lcd_data->heat);
		UintToBcd((display/10000), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 1, minus);
        	LCD_BUF[8] = A1_2_0;   
        	LCD_BUF[9] = A1_2_1;   
		break;
       case A1_3:
		if(Lcd_data->temp1 < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->temp1):(_u32)(0 - Lcd_data->temp1);
		UintToBcd((display), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 5, minus);
		LCD_BUF[4] = 0x0;

		if(Lcd_data->temp2 < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->temp2):(_u32)(0 - Lcd_data->temp2);
		UintToBcd((display/10000), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 1, minus);

        	LCD_BUF[8] = A1_3_0;   
        	LCD_BUF[9] = A1_3_1;  
		break;
      case A1_4:
		if(Lcd_data->temp0 < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->temp0):(_u32)(0 - Lcd_data->temp0);
		UintToBcd((display/1000), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 2, minus);
        	LCD_BUF[8] = A1_4_0; 
        	LCD_BUF[9] = A1_4_1;
		break;
       case A1_5:
		if(Lcd_data->total_flow < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->total_flow):(_u32)(0 - Lcd_data->total_flow);
		UintToBcd((display/1000), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 2, minus);
        	LCD_BUF[8] = A1_5_0;  
        	LCD_BUF[9] = A1_5_1; 
		break;
       case A1_6:
		if(Lcd_data->flow < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->flow):(_u32)(0 - Lcd_data->flow);
		UintToBcd((display/100), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 3, minus);
        	LCD_BUF[8] = A1_6_0; 
        	LCD_BUF[9] = A1_6_1;
		break;
       case A1_7:
        	display = Lcd_data->total_time;
		UintToBcd(display, &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);
        	LCD_BUF[8] = A1_7_0;   
        	LCD_BUF[9] = A1_7_1;  
		break;
       case A1_8:
        	display = Lcd_data->alarm_time;
		UintToBcd(display, &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);
        	LCD_BUF[8] = A1_8_0;   
        	LCD_BUF[9] = A1_8_1;  
		break;
	}
    }
    else if(i == A2){    //--------------------A2-----
      switch(Lcd_data->lcdmode){
        case A2_0:
		LCD_BUF[0] = word[0];    //'A'
		LCD_BUF[1] = number[2];    //'2'
       		break;
        case A2_1:
	        Lcd_data->date = Date_and_Time->Year*10000 + Date_and_Time->Month*100 + Date_and_Time->Day;   //注意，需要进行类型转换防止结果溢出错误
        	display = Lcd_data->date; 
      		UintToBcd(display, &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);
            	LCD_BUF[3] |= 0x80;
            	LCD_BUF[5] |= 0x80;
	 	LCD_BUF[8] = A2_1_0;   //时间 年月日
	    	LCD_BUF[9] = A2_1_1;   //
            	break;
        case A2_2:
            	Lcd_data->time = Date_and_Time->Hour*1000000 + Date_and_Time->Minute*1000 + Date_and_Time->Second;   //注意，需要进行类型转换防止结果溢出错误
            	display = Lcd_data->time; 
     		UintToBcd(display, &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);
            	LCD_BUF[2] = 0x02;
            	LCD_BUF[5] = 0x02;
	    	LCD_BUF[8] = A2_2_0;   //时间 时分秒
	    	LCD_BUF[9] = A2_2_1;   //
	    	break;
        case A2_3:        //用户编号
            	display = Lcd_data->usercode;
           	UintToBcd(display, &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);
            	break;
        case A2_4:       //版本号
            	display = (_u32)(Lcd_data->version*10);
        	UintToBcd(display, &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 1, minus);
            	break;
        case A2_5:      //低电压
            	LcdLowV(&LCD_BUF);
            	break;
        case A2_6:      /*全显*/
            	LcdPrintAll(&LCD_BUF);
	    	break;
        }
    }
    else if(i == A3){    //--------------------A3-----
      switch(Lcd_data->lcdmode){
        case A3_0:
            	LCD_BUF[0] = word[0];    //'A'
	    	LCD_BUF[1] = number[3];    //'3'
            	break;
        case A3_1:
		display = *(_u32 *)(INFO_FLASH_START + Lcd_data->history*12);
     		UintToBcd(display, &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);
            	LCD_BUF[4] = 0x02;
            	LCD_BUF[7] = 0x0;
            	LCD_BUF[8] = A3_1_0;   //时间  年月
	    	LCD_BUF[9] = A3_1_1;   //
            	break;
        case A3_2:
		display = *(_u32 *)(INFO_FLASH_START + Lcd_data->history*12+8);
		UintToBcd((display), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 2, minus);
	    	LCD_BUF[8] = A3_2_0;   //累积流量
	    	LCD_BUF[9] = A3_2_1;   //m3
            	break;
        case A3_3:
		display = *(_u32 *)(INFO_FLASH_START + Lcd_data->history*12+4);
		UintToBcd((display), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 2, minus);
	    	LCD_BUF[8] = A3_3_0;   //累计热量
	    	LCD_BUF[9] = A3_3_1;   //KW*h
            	break;
 	}
    }
    else if(i == A4){    //--------------------A4-----
      switch(Lcd_data->lcdmode){
        case A4_0:
		LCD_BUF[0] = word[0];    //'A'
		LCD_BUF[1] = number[4];    //'4'
           	break;
 	case A4_1:
		if(Lcd_data->flow < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->flow):(_u32)(0 - Lcd_data->flow);
		UintToBcd((display/100), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 3, minus);
        	LCD_BUF[8] = A4_1_0; 
        	LCD_BUF[9] = A4_1_1;
		break;
        case A4_2:
		if(Lcd_data->total_flow < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->total_flow):(_u32)(0 - Lcd_data->total_flow);
		UintToBcd((display), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 5, minus);
        	LCD_BUF[8] = A4_2_0;  
        	LCD_BUF[9] = A4_2_1; 
		break;
        case A4_3:
		if(Lcd_data->heat < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->heat):(_u32)(0 - Lcd_data->heat);
		UintToBcd((display/10), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 4, minus);
        	LCD_BUF[8] = A4_3_0;   
        	LCD_BUF[9] = A4_3_1;   
		break;
        case A4_4:
		if(Lcd_data->total_heat < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->total_heat):(_u32)(0 - Lcd_data->total_heat);
		UintToBcd((display/10), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 4, minus);
        	LCD_BUF[8] = A4_4_0;   
        	LCD_BUF[9] = A4_4_1;   //KW*h
		break;
        case A4_5:
		if(Lcd_data->temp1 < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->temp1):(_u32)(0 - Lcd_data->temp1);
		UintToBcd((display*10), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);

		if(Lcd_data->temp2 < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->temp2):(_u32)(0 - Lcd_data->temp2);
		UintToBcd((display/1000), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 0, minus);

        	LCD_BUF[8] = A4_5_0;   
        	LCD_BUF[9] = A4_5_1;  
		break;
        case A4_6:
		if(Lcd_data->temp0 < 0) minus = 0;   
        	display = minus?(_u32)(Lcd_data->temp0):(_u32)(0 - Lcd_data->temp0);
		UintToBcd((display/1000), &bcd_buf);
		LcdBufWrite(&LCD_BUF, &bcd_buf, 2, minus);
        	LCD_BUF[8] = A4_6_0; 
        	LCD_BUF[9] = A4_6_1;
		break;
  	}
    }
 
	if(main_flag & lowV_flag) LcdLowV(&LCD_BUF);

	WriteLcdRegs(&LCD_BUF);
#endif	
}

#endif
