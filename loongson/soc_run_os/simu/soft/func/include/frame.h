
#define ERROR 1
#define DATA_LENGTH 100

extern _u32 RX_IndexW;
void IrSend(_u8 *str);
void uart_tx();
void uart_rx();
void Frame_exe(struct Date_Time *Date_and_Time, struct Data *Lcd_data);

union uint_uchar{
    _u32 i_value;
    _u8 c_value[4];
};

/*-----------------协议字段-----------------*/
struct FrameFormat{
  _u8 HeadCode;
  _u8 TypeCode;
  _u8 Address[7];
  _u8 CtrlCode;
  _u8 DataLen;
  _u8 DI0,DI1,SER;
  _u8 Data[DATA_LENGTH];
  _u8 CheckSum;
  _u8 TailCode;
};

/****************三川写*****************/
struct ModifyData{
    _u8 seg;  //修正段号
    _u32 flowpoint;   //修正流量点，使用时要除以10，xxxxx.x
    _u8 danwei;   //修正单位
    _u32 flowdata;   //标准流量数据，使用时要除以1000，xxx.xxx
    _u32 rcode;   //配对热电阻编号
    _u32 temp;   //标定温度值
    _u32 rdata;   //热电阻阻值，使用时要除以100，xxxx.xx
    _u32 tempmodify;   //温度修正系数，使用时要除以100000，x.xxxxx
};




