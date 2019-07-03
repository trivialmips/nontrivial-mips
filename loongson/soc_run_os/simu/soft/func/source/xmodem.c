/**********************************************************************************************************************************************************************
	This file uses xmodem to download code, then writes it into flash. 
**********************************************************************************************************************************************************************/

#include "../config.h"

static _u16 _crc_xmodem_update (_u16 crc, _u8 data)
{
    int i;
    crc = crc ^ ((_u16)data << 8);
    for (i=0; i<8; i++)
    {
        if (crc & 0x8000)
            crc = (crc << 1) ^ 0x1021;
        else
            crc <<= 1;
    }
    return crc;
}

//定义Xmoden控制字符
#define XMODEM_NUL          0x00
#define XMODEM_SOH          0x01
#define XMODEM_STX          0x02
#define XMODEM_EOT          0x04
#define XMODEM_ACK          0x06
#define XMODEM_NAK          0x15
#define XMODEM_CAN          0x18
#define XMODEM_EOF          0x1A
#define XMODEM_WAIT_CHAR    'C'


#define ST_WAIT_START	0x00         //等待启动
#define ST_BLOCK_OK	0x01         //接收一个数据块成功
#define ST_BLOCK_FAIL	0x02         //接收一个数据块失败
#define ST_OK		0x03         //完成

#if LS1D_FPGA
static int testchar(unsigned int timeout)
{
	int total, start;
	start = now();

	while(1)
	{
		if(tgt_testchar()) return 100;
		if( (now()-start) > timeout ) break;  
	}

	return 0;
}
#else
static int testchar(unsigned int timeout)
{
	int total, start;
	//start = now();

	_u32 i,j;
	for(i=1000;i>0;i--)
		for(j=500;j>0;j--)
	//while(1)
	{
		if(tgt_testchar()) return 100;
		//if( ((now()-start)%COUNT_COMPARE) > timeout ) break;  
	}

	return 0;
}
#endif
static int get_data(unsigned char *ptr,unsigned int len,unsigned int timeout)
{
	int i=0;
	while(i<len)
	{
		if(testchar(timeout)>0)
			ptr[i++] = tgt_getchar();
		else break;   //It doesn't receive data in 1 second.
	}

	return i;
}
//计算CRC16
static unsigned int calcrc(unsigned char *ptr, unsigned int count, _u8 crc_mode)
{
	_u16 crc = 0;
	while (count--)
	{
		if(crc_mode)
			crc = _crc_xmodem_update(crc,*ptr++);
		else
		{
			crc += *ptr++ ;
			crc &= 0xff;
		}
	}

	return crc;
}

static int xmodem_transfer(_u32 base)
{
	unsigned int i;
	_u16 crc;
	unsigned int filesize=0;
	unsigned char BlockCount=1;               //数据块累计(仅8位，无须考虑溢出)
	_u8 crc_mode = 1;
	_u8 chr;
#if LS1D_FPGA
	_u32 addr_w = base;
	_u32 length = 128;
#endif
	unsigned char STATUS;                  //运行状态
        STATUS = ST_WAIT_START;               //并且数据='d'或'D',进入XMODEM
	while(1)
	{	
		chr = crc_mode?XMODEM_WAIT_CHAR:XMODEM_NAK ;
		tgt_putchar(chr);
		if(testchar(80)>0)break;   //5 seconds timeout
		crc_mode += 1;
		crc_mode %= 2;
	}   //send 'c' first, if there is no respond, then send NAK.

	struct str_XMODEM strXMODEM;      //XMODEM的接收数据结构
	while(STATUS!=ST_OK)                  //循环接收，直到全部发完
	{
/**********************************************************************************************************************************************************************************************************************************************************************************************************************************************/
		i = get_data(&strXMODEM.SOH, BLOCKSIZE+5, 1);   // 1/16 second timeout, it'll affect the total time of download.

/**********************************************************************************************************************************************************************************************************************************************************************************************************************************************/
		if(i)
		{
			//分析数据包的第一个数据 SOH/EOT/CAN
			switch(strXMODEM.SOH)
			{
				case XMODEM_SOH:			   //收到开始符SOH
					if (i>=(crc_mode?(BLOCKSIZE+5):(BLOCKSIZE+4)))
					{
						STATUS=ST_BLOCK_OK;
					}
					else
					{
						STATUS=ST_BLOCK_FAIL;	  //如果数据不足，要求重发当前数据块
						tgt_putchar(XMODEM_NAK);
					}
					break;
				case XMODEM_EOT:			   //收到结束符EOT
					tgt_putchar(XMODEM_ACK);			//通知PC机全部收到
					STATUS=ST_OK;
					break;
				case XMODEM_CAN:			   //收到取消符CAN
					tgt_putchar(XMODEM_ACK);			//回应PC机
					STATUS=ST_OK;
					break;
				default:					 //起始字节错误
					tgt_putchar(XMODEM_NAK);			//要求重发当前数据块
					STATUS=ST_BLOCK_FAIL;
					break;
			}
		}
		else 
		{
			break;
			//tgt_putchar(XMODEM_NAK);			//数据块编号错误，要求重发当前数据块
			//continue;
		}

		if (STATUS==ST_BLOCK_OK)			//接收133字节OK，且起始字节正确
		{
			if (BlockCount != strXMODEM.BlockNo)//核对数据块编号正确
			{
				tgt_putchar(XMODEM_NAK);			//数据块编号错误，要求重发当前数据块
				continue;
			}
			if (BlockCount !=(unsigned char)(~strXMODEM.nBlockNo))
			{
				tgt_putchar(XMODEM_NAK);			//数据块编号反码错误，要求重发当前数据块
				continue;
			}

			if(crc_mode)
			{
				crc = strXMODEM.CRC16hi<<8;
				crc += strXMODEM.CRC16lo;
			}
			else
			{
				crc = strXMODEM.CRC16hi;
			}

			if(calcrc(&strXMODEM.Xdata[0], BLOCKSIZE, crc_mode)!=crc)
			{
				tgt_putchar(XMODEM_NAK);			  //CRC错误，要求重发当前数据块
				continue;
			}

#if LS1D_FPGA
			_u32 addr_r = (_u32)&strXMODEM.Xdata[0];
			spiflash_write(addr_w, addr_r, length);
			addr_w += length;
#else
			//Flash_Write(base+filesize, &buf[0],32) ;
#endif

			filesize += 128;
			tgt_putchar(XMODEM_ACK);				 //回应已正确收到一个数据块
			BlockCount++;					   //数据块累计加1
		}
	}

	//printf("xmodem finished\n");

	return filesize;
}


_u32 xmodem()
{
	_u32 base = FLASH_ERASE_START;
	int file_size;

	//printf("Waiting for serial transmitting datas...\n");
#if LS1D_FPGA
	_u32 addr_start = FLASH_ERASE_START;
	_u32 addr_end = FLASH_ERASE_END;
	spiflash_erase(addr_start, addr_end);
#endif
	file_size = xmodem_transfer(base);
	//printf("Load successfully! Start at 0x%x, size 0x%x\n", base, file_size);

	return 0; 
}


