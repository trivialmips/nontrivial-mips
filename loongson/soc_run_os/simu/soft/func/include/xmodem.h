_u32 xmodem(void);

//³£Êý¶¨Òå
#define BLOCKSIZE       128            //M16µÄÒ»¸öFlashÒ³Îª128×Ö½Ú(64×Ö)


//¶¨ÒåÈ«¾Ö±äÁ¿
struct str_XMODEM
{
    unsigned char SOH;                  //ÆðÊ¼×Ö½Ú
    unsigned char BlockNo;               //Êý¾Ý¿é±àºÅ
    unsigned char nBlockNo;               //Êý¾Ý¿é±àºÅ·´Âë
    unsigned char Xdata[BLOCKSIZE];            //Êý¾Ý128×Ö½Ú
    unsigned char CRC16hi;               //CRC16Ð£ÑéÊý¾Ý¸ßÎ»
    unsigned char CRC16lo;               //CRC16Ð£ÑéÊý¾ÝµÍÎ»
};
