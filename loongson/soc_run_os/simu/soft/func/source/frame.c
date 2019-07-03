/***************************************************************************************************************************************************
	This file is used for CJT188 protocol.
***************************************************************************************************************************************************/
#include "../config.h"

#if FRAME_MODULE

#define HEAD 0x68
#define TAIL 0x16
/****************Unit******************/
#define danwei_Wh	0x02
#define danwei_KWh	0x05
#define danwei_MWh	0x08
#define danwei_MWhX100	0x0a
#define danwei_J	0x01
#define danwei_KJ	0x0b
#define danwei_MJ	0x0e
#define danwei_GJ	0x11
#define danwei_GJX100	0x13
#define danwei_W	0x14
#define danwei_KW	0x17
#define danwei_MW	0x1a
#define danwei_L	0x29
#define danwei_m3	0x2c
#define danwei_L_h	0x32
#define danwei_m3_h	0x35


void IrSend(_u8 *str)
{
	  //IR_PWR_OFF;  
	for( ; *str != '\0';str++)
	  Uart1_TxData = *str;
}


_u32 ST;  //状态ST
/**************************
	0x0004  //电池欠压
	0x0000  //阀门开
	0x0001  //阀门关
	0x0003  //阀门异常
	高位由厂商定义
***************************/
struct FrameFormat Frame;

static _u8 frame_tx[120] ; 
static _u8 frame_rx[70];
static _u32 UART_OutpLen;
static _u32 TX_IndexW;
_u32 RX_IndexW;

void uart_tx(void)
{
	if(UART_OutpLen > 0){
			UART_OutpLen--;
		Uart1_TxData = frame_tx[TX_IndexW];
		TX_IndexW +=1;
		}
	else{
		//IFG1 &= ~UTXIFG0;
		}
}

void uart_rx(void)
{
	static _u32 rx_head_flag;   //'0'尚未收到帧开始符
	frame_rx[RX_IndexW] = Uart1_RxData;   //波特率如果设的比较高，有时候会丢失第一个帧字符???
#if PRINT
printf("%x ", frame_rx[RX_IndexW]);
#endif
	RX_IndexW +=1;
	
	static _u32 len;
	if((rx_head_flag == 0) && (frame_rx[RX_IndexW-1] == HEAD)){
	len = RX_IndexW + 9;
	rx_head_flag = 1;	  //收到帧开始符
	}
	if(rx_head_flag == 1){
	if((frame_rx[RX_IndexW-1] == TAIL) && (RX_IndexW > (len+(_u32)frame_rx[len]+2))){
		//if(RX_BUFF[len+(_u32)RX_BUFF[len])+2] == TAIL){
		rx_head_flag = 0;
		//UART_InpLen = RX_IndexW;
		RX_IndexW =0;  
		main_flag |= rx_bit;	  //usart收到一个完整的帧
#if PRINT
printf("\n");
#endif
	}
	}

}

/*-----------------------发送应答帧----------------------*/
void Answer()
{
	_u32 i=0;
	_u32 j;
	_u32 head = 3;
	Frame.CheckSum = 0x0;
	frame_tx[i++] = 0xfe;
	frame_tx[i++] = 0xfe;
	frame_tx[i++] = 0xfe;
	frame_tx[i++] = Frame.HeadCode;
	frame_tx[i++] = Frame.TypeCode;
	for(j=0;j<7;j++)
	frame_tx[i++] = Frame.Address[j];
	frame_tx[i++] = Frame.CtrlCode;  //需要进行异常判断后置位
	frame_tx[i++] = Frame.DataLen;
#if CJT188_DI_SEQ
	frame_tx[i++] = Frame.DI0;
	frame_tx[i++] = Frame.DI1;
#else
	frame_tx[i++] = Frame.DI1;
	frame_tx[i++] = Frame.DI0;
#endif
	frame_tx[i++] = Frame.SER;
	for(j=0;j<((_u32)Frame.DataLen-3);j++)
	frame_tx[i++] = Frame.Data[j];
	while(head < i){
	Frame.CheckSum += frame_tx[head];
	Frame.CheckSum %= 256;
	head++;
	}
	frame_tx[i++] = Frame.CheckSum;
	frame_tx[i++] = Frame.TailCode;
	UART_OutpLen =i;
}

_u32 read1(struct Date_Time *Date_and_Time, struct Data *Lcd_data)
{
	_u32 i=0;
	_u32 j;
	_u32 dat;
	union uint_uchar uint2uchar;
	Frame.DataLen = 0x2e;
	
	dat = *(_u32 *)(INFO_FLASH_START + Last_month_num*12 + 4);//total heat of last month
	UintToBcd(dat, &uint2uchar);
	for(j=0; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	Frame.Data[i++] = danwei_KWh;
	
	dat = (_u32)Lcd_data->total_heat*100/LCD_MULTIPLE;  //当前热量
	UintToBcd(dat, &uint2uchar);
	for(j=0; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	Frame.Data[i++] = danwei_KWh;
	
	dat = (_u32)Lcd_data->heat*100/LCD_MULTIPLE;  //热功率
	UintToBcd(dat, &uint2uchar);
	for(j=0; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	Frame.Data[i++] = danwei_KW;
	
	dat = (_u32)Lcd_data->flow*10000;  //瞬时流量
	UintToBcd(dat, &uint2uchar);
	for(j=0; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	Frame.Data[i++] = danwei_m3;
	
	dat = (_u32)Lcd_data->total_flow*100/LCD_MULTIPLE;  //累计流量
	UintToBcd(dat, &uint2uchar);
	for(j=0; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	Frame.Data[i++] = danwei_m3;
	
	dat = (_u32)Lcd_data->temp1*100/LCD_MULTIPLE;  //入水温度
	UintToBcd(dat, &uint2uchar);
	for(j=1; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	
	dat = (_u32)Lcd_data->temp2*100/LCD_MULTIPLE;  //出水温度
	UintToBcd(dat, &uint2uchar);
	for(j=1; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	
	dat = (_u32)Lcd_data->total_time;  //累计工作时间
	UintToBcd(dat, &uint2uchar);
	for(j=1; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	
	//实时时间
	dat = (_u32)Date_and_Time->Day*1000000 + (_u32)Date_and_Time->Hour*10000 + (_u32)Date_and_Time->Minute*100 + (_u32)Date_and_Time->Second;
	UintToBcd(dat, &uint2uchar);
	for(j=0; j<4; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	dat = (_u32)Date_and_Time->Year*100 + (_u32)Date_and_Time->Month;
	UintToBcd(dat, &uint2uchar);
	for(j=0; j<3; j++)
		Frame.Data[i++] = uint2uchar.c_value[j];
	
	dat = (_u32)ST;	//状态ST
	UintToBcd(dat, &uint2uchar);
	Frame.Data[i++] = uint2uchar.c_value[0];
	Frame.Data[i++] = uint2uchar.c_value[1];
	
	return 0;
}

_u32 read2()   //上几月月结热量
{
	_u32 j;
	j = (_u32)Frame.DI1;
	Frame.DataLen = 0x08;
#if 0 
	Flash_Read_Info();
	_u32 i;
  for(i=0; i<256; i++)
  {
	TXBUF0 = Array[i];
	while((U0TCTL & TXEPT) == 0) ;
  }
#endif
	
	_u32 offset;
	_u32 dat;
	union uint_uchar uint2uchar;
	offset = ((Last_month_num-(j-32))%18)*12+4;   //0~216	
	dat = *(_u32 *)(INFO_FLASH_START + offset);//total heat 
	UintToBcd(dat, &uint2uchar);
	for(j=0; j<4; j++)
		Frame.Data[j] = uint2uchar.c_value[j];
	Frame.Data[4] = danwei_KWh;
	
	return 0;
}

_u32 read3()
{
	switch(Frame.DI1){
		case 0x02:   //读价格表
			Frame.DataLen = 0x12;			
			break;
		case 0x03:   //读结算日
			Frame.DataLen = 0x04;
			break;
		case 0x04:   //读抄表日
			Frame.DataLen = 0x04;
			break;
		case 0x05:   //读购入金额
			Frame.DataLen = 0x12;
			break;
		default:
			return ERROR;
			break;
	}
	
	return 0;
}

_u32 read4()
{
	Frame.DataLen = 0x04;
	
	return 0;
}

_u32 read5()
{
	Frame.DataLen = 0x03;
	
	return 0;
}

_u32 write1()
{
	switch(Frame.DI1){
		case 0x10:
			Frame.DataLen = 0x05;
			break;
		case 0x11:
			Frame.DataLen = 0x03;
			break;
		case 0x12:
			Frame.DataLen = 0x03;
			break;
		case 0x13:
			Frame.DataLen = 0x08;
			break;
		case 0x14:
			Frame.DataLen = 0x04;
			break;
		case 0x15:
			Frame.DataLen = 0x03;
			break;
		case 0x17:
			Frame.DataLen = 0x05;
			break;
		case 0x19:
			Frame.DataLen = 0x03;
			break;
		default:
			return ERROR;
			break;
	}
	
	return 0;
}

_u32 write2()
{
	Frame.DataLen = 0x03;
	
	return 0;
}

_u32 write3()
{
	Frame.DataLen = 0x05;
	
	return 0;
}

_u32 write4()
{
	switch(Frame.DI1){
		case 0x12:
			Frame.DataLen = 0x05;
			break;
		case 0x14:
			Frame.DataLen = 0x05;
			break;
		case 0x16:
			Frame.DataLen = 0x05;
			break;
		default:
			return ERROR;
			break;
	}	
	
	return 0;
}

void do_err()
{
	_u32 dat;
	union uint_uchar uint2uchar;
	
	Frame.CtrlCode |= 0x40;
	Frame.DataLen = 0x03;
	Frame.DI0 = Frame.SER;
	UintToBcd(ST, &uint2uchar);
	Frame.DI1 = uint2uchar.c_value[0];
	Frame.SER = uint2uchar.c_value[1];
}

//_u32 do_frame()  //下位机应答模式，对协议进行解析
_u32 do_frame(struct Date_Time *Date_and_Time, struct Data *Lcd_data)
{ 
	_u32 err;
	_u32 i,j,head,tail;
	/*----------------开始帧格式解析----------------*/  
	
	Frame.CheckSum = 0x0;
	for(i=0;frame_rx[i] == 0xfe;i++);
	head = i;
	j = head;
	
	Frame.HeadCode = frame_rx[head++];
	Frame.TypeCode = frame_rx[head++];
	for(i=0;i<7;i++)
	Frame.Address[i] = frame_rx[head++];
	Frame.CtrlCode = frame_rx[head++];
	Frame.DataLen = frame_rx[head++];
#if CJT188_DI_SEQ		
	Frame.DI0 = frame_rx[head++];
	Frame.DI1 = frame_rx[head++];
#else
	Frame.DI1 = frame_rx[head++];
	Frame.DI0 = frame_rx[head++];
#endif
	Frame.SER = frame_rx[head++];
	for(i=0;i<((_u32)Frame.DataLen-3);i++)
	Frame.Data[i] = frame_rx[head++];
	while(j < head){
	Frame.CheckSum += frame_rx[j];
	Frame.CheckSum %= 256;
	j++;
	}
	if(Frame.CheckSum != frame_rx[j]) {
	return 1;
	}
	tail = j+1;
	Frame.TailCode = frame_rx[tail];
	/*----------------完成帧格式解析----------------*/

	   /*------------------------根据控制码进行类型解析--------------------------*/
	switch(Frame.CtrlCode){
		case 0x01:   //read data
			if((Frame.DI0==0x90)&&(Frame.DI1==0x1f)) err = read1(Date_and_Time, Lcd_data);
			else if(Frame.DI0==0xd1) err = read2();
			else if(Frame.DI0==0x81) err = read3();
		break;
		case 0x09:   //读密钥版本号
			if((Frame.DI0==0x81)&&(Frame.DI1==0x06)) err = read4();
		break;
		case 0x03:   //读地址
			if((Frame.DI0==0x81)&&(Frame.DI1==0x0a)) err = read5();
		break;
		case 0x04:   //写数据
			if(Frame.DI0==0xa0) err = write1();
		break;
		case 0x15:   //写地址
			if((Frame.DI0==0xa0)&&(Frame.DI1==0x18)) err = write2();
		break;
		case 0x16:   //写机电同步数据
			if((Frame.DI0==0xa0)&&(Frame.DI1==0x16)) err = write3();
		break;
		case CJT188_DEF_READ:   //三川读
	
		break;
		case CJT188_DEF_WRITE:   //三川写
			if(Frame.DI0==0xb0) err = write4();
		break;
		default:
			err = 2;
			break;
	}	
	/*------------------------完成类型解析--------------------------*/
	Frame.CtrlCode |= 0x80;
	if(err) do_err();
	Answer();
	
	return 0;
}

void Frame_exe(struct Date_Time *Date_and_Time, struct Data *Lcd_data)
{
	_u32 err;
	err = do_frame(&Date_and_Time, &Lcd_data);
	if(err==0)
	{
		TX_IndexW = 0;
	Uart1_TxData = 0xfe;
		//IFG1 |= UTXIFG0;  
	}
	else if(err==1)
	{
		//TXBUF0 = 0xdd;
		//while((U0TCTL & TXEPT) == 0) ;		
	}
	else if(err==2)
	{
		//TXBUF0 = 0xee;
		//while((U0TCTL & TXEPT) == 0) ;		
	}
}
#endif
