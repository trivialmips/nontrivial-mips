/**************************************************************************
***************************************************************************
	Notice: Some variable of Lcd_data = real_value * LCD_MULTIPLE
***************************************************************************
**************************************************************************/
struct Data{
    _fp32 total_heat;  //累计热量, plus LCD_MULTIPLE
    _fp32 heat;        //热功率, plus LCD_MULTIPLE  
    _fp32 temp1;       //入水温度, plus LCD_MULTIPLE 
    _fp32 temp2;       //出水温度, plus LCD_MULTIPLE 
    _fp32 temp0;      //温差, plus LCD_MULTIPLE 
    _fp32 total_flow; //累计流量, plus LCD_MULTIPLE 
    _fp32 flow;       //瞬时流量, plus LCD_MULTIPLE 
    _u32 total_time;  //工作时间
    _u32 alarm_time;  //报警时间
    _u32 date;        //年月日
    _u32 time;        //时分秒
    _u32 usercode;
    _fp32 version;
    _u32 history;
    _u32 lcdmode;  //A1_1;
    _u32 auto_caculate;
};
void LcdDisplay(struct Date_Time *Date_and_Time, struct Data *Lcd_data);

//---------------A1菜单-------------
#define A1 1
#define A1_0 10   //显示A1

#define A1_1 11 
#define A1_1_0 (0x08+0x04) //'累积热量 '
#define A1_1_1 (0x10+0x20) //'KW*h'

#define A1_2 12      //一位小数
#define A1_2_0 (0x10) //'功率 ' 
#define A1_2_1 (0x00) //

#define A1_3 13            //'T入 T出' 一位小数
#define A1_3_0 (0x20) //'T出'
#define A1_3_1 (0x04) //'`C'

#define A1_4 14        //两位小数
#define A1_4_0 (0x02) //'温差 '
#define A1_4_1 (0x04) //'`C'

#define A1_5 15        //两位小数
#define A1_5_0 (0x08+0x01) //'累积流量' 
#define A1_5_1 (0x02) //'m3' 

#define A1_6 16        //三位小数
#define A1_6_0 (0x01) //'瞬时流量 '
#define A1_6_1 (0x02+0x01+0x80) //'m3/h'

#define A1_7 17
#define A1_7_0 (0x08+0x80) //'累积运行时间' 
#define A1_7_1 (0x80) //'h' 

#define A1_8 18
#define A1_8_0 (0x40) //'报警时间' 
#define A1_8_1 (0x80) //'h' 

//--------------A2菜单-------------
#define A2 2
#define A2_0 20   //显示A2

#define A2_1 21 //年月日
#define A2_1_0 (0x80) //'时间'
#define A2_1_1 (0x00) 

#define A2_2 22 //时分秒
#define A2_2_0 (0x80) //'时间'
#define A2_2_1 (0x00)

#define A2_3 23 //用户编号
#define A2_3_0 (0x00) //
#define A2_3_1 (0x00)

#define A2_4 24 //版本号
#define A2_4_0 (0x00) //
#define A2_4_1 (0x00)

#define A2_5 25 //低电压'P6'
#define A2_5_0 (0x00) //
#define A2_5_1 (0x00)

#define A2_6 26 //屏全显

//--------------A3菜单--------------
#define A3 3
#define A3_0 30   //显示A3

#define A3_1 31 //年月
#define A3_1_0 (0x80) //'时间'
#define A3_1_1 (0x00)

#define A3_2 32
#define A3_2_0 (0x08+0x01) //'累积流量' 
#define A3_2_1 (0x02) //'m3' 

#define A3_3 33 
#define A3_3_0 (0x08+0x04) //'累计热量 '
#define A3_3_1 (0x10+0x20) //'KW*h'

//--------------A4菜单--------------
#define A4 4
#define A4_0 40   //显示A4

#define A4_1 41        //三位小数
#define A4_1_0 (0x01) //'瞬时流量 '
#define A4_1_1 (0x02+0x01+0x80+0x08) //'m3/h'+'检定'

#define A4_2 42          //五位小数
#define A4_2_0 (0x08+0x01) //'累积流量' 
#define A4_2_1 (0x02+0x08) //'m3'+'检定'

#define A4_3 43 
#define A4_3_0 (0x10) //'功率 '
#define A4_3_1 (0x00+0x08) // +'检定'

#define A4_4 44             //四位小数
#define A4_4_0 (0x08+0x04) //'累积热量 '
#define A4_4_1 (0x10+0x20+0x08) //'KW*h'+'检定'

#define A4_5 45            //'T入 T出' 两位小数
#define A4_5_0 (0x20) //'T出'
#define A4_5_1 (0x04+0x08) //'`C'+'检定'

#define A4_6 46 
#define A4_6_0 (0x02) //'温差 '
#define A4_6_1 (0x04+0x08) //'`C'+'检定'


