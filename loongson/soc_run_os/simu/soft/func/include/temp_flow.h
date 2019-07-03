
void InitTdc(void);
//_fp32 Time_Caculate(_u32 *result, struct Data *Lcd_data, _u16 start, _u32 stop_num);
//void Flow_Caculate(_fp32 delta_time, _fp32 duration, struct Data *Lcd_data);
//void Temp_Caculate(_u32 *result, struct Data *Lcd_data, _u32 num);
//void Heat_Caculate(_fp32 duration, struct Data *Lcd_data);
_u32 res_ready(struct Data *Lcd_data);

  
extern _fp32 Last_total_flow;    //上次计算时的累积流量

