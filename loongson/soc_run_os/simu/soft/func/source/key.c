/**********************************************************************************************************************************************************************
	This file uses key to jump between diffrence cases.
**********************************************************************************************************************************************************************/

#include "../config.h"

#if KEY_MODULE
static void Auto_jump(struct Data *Lcd_data)
{
    wait[1] = 0;  
    main_flag &= ~A3_delay;  
    if(Lcd_data->lcdmode/10 == A4) {
        main_flag |= wait_2hour;
    }
    else {
        if(Lcd_data->lcdmode/10 == A3){
            wait[2] = 0;
            main_flag |= A3_delay;
        }
        main_flag |= wait_1min;
    }
    main_flag |= lcd_bit;
}

static void Key_short(struct Data *Lcd_data)
{
    if(Lcd_data->lcdmode/10 == A4) Lcd_data->lcdmode = (Lcd_data->lcdmode%10 + 1)%7 + (Lcd_data->lcdmode/10)*10;
    if(Lcd_data->lcdmode/10 == A1) Lcd_data->lcdmode = (Lcd_data->lcdmode%10 + 1)%9 + (Lcd_data->lcdmode/10)*10;
    if(Lcd_data->lcdmode/10 == A2) Lcd_data->lcdmode = (Lcd_data->lcdmode%10 + 1)%7 + (Lcd_data->lcdmode/10)*10;
    if(Lcd_data->lcdmode/10 == A3){
        if(Lcd_data->lcdmode == A3_0){
            Lcd_data->lcdmode = A3_1;
            Lcd_data->history = Last_month_num;
        }
        else {
            Lcd_data->lcdmode = A3_1;
            Lcd_data->history += 1;
            Lcd_data->history %= 18;
        }
    }
    Auto_jump(Lcd_data);
}

static void Key_long(struct Data *Lcd_data)
{
        /*³¤°´*/
        if(Lcd_data->lcdmode == A1_6) {
            Lcd_data->lcdmode = A4_0;
		PMU[0] = 0x4;    //cruise delay 0.25s,2s
            main_flag &= ~wait_1min;
        }
        else {
            if(Lcd_data->lcdmode/10 == A4) {
                Lcd_data->lcdmode = A1_0;
		PMU[0] = 0x7004;    //cruise delay 2s,8s
                main_flag &= ~wait_2hour;
            }
            else if(Lcd_data->lcdmode/10 == A1) Lcd_data->lcdmode = A2_0;
            else if(Lcd_data->lcdmode/10 == A2) Lcd_data->lcdmode = A3_0;
            else if(Lcd_data->lcdmode/10 == A3) Lcd_data->lcdmode = A1_0;
        }
        Auto_jump(Lcd_data);
}

void Key(struct Data *Lcd_data)
{
    if(main_flag & long_key)
    {
	 main_flag &= ~long_key;
         Key_long(Lcd_data);
    }
    else
    {
         Key_short(Lcd_data);
    }
}
#endif
