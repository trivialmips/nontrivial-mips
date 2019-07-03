void MonthData(struct Date_Time *Date_and_Time, struct Data *Lcd_data);
void Flash_Read_Info();
void Flash_Write_Test();
extern _u32 Last_month_num; 

#define CHRWRITE 0
#define BLKWRITE 1
struct Record_0{
  _u32 Date;  /*保存年月信息，Date = Year*1000 + Month*10, 例如2011.10,则Date = 20110100 */
  _u32 TotalHeat;  //xxxxxx.xx, plus 100 
  _u32 TotalFlow;  //xxxxxx.xx, plus 100 
};

struct Record_1{
  _u32 Date;  /*保存年月日信息，Date = Year*10000 + Month*100 + Day, 例如2011.10.12,则Date = 20111012 */
  _u32 Time;   /*保存时分信息，Time = Hour*100 + Minute, 例如9：30，则Time = 930 */
  _fp32 TotalHeat;
  _fp32 TotalFlow;  
  _u32 WorkTime;
  _u32 ErrTime;
};
extern struct Record_1 Latest_Record;

