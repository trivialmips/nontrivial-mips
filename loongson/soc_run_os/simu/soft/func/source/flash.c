#include "../config.h"

extern unsigned int str2num (char str[30]);
void mywait(void);
/******************************
*Flash Test*   CONFIDENTIAL

>CAUTION< 
DO NOT add this program to ANY release version!

Liu Su
liusu-cpu@ict.ac.cn
******************************/

//#if FLASH_TEST

static void flash_clearHVPL(void)
{
	*(volatile _u32*)(0xbfe60000) = 0x40000000;
}

static void flash_erase(_u32 offset)
{
	*(volatile _u32*)(0xbfe60000) = 0xa0000000|offset;
}

static void flash_page(_u32 offset)
{
	*(volatile _u32*)(0xbfe60000) = 0xe0000000|offset;
}

static void flash_setca(_u32 cah, _u32 cal)
{
	*(volatile _u32*)(0xbfe60008) = cal;
	*(volatile _u32*)(0xbfe60004) = cah;
	*(volatile _u32*)(0xbfe60000) = 0xf0000000;
}

int set_ca(int argc, char argv[][30])
{
	_u32 cah,cal;
	if(argc !=3 ) {printf("\nUsage: setca <cah> <cal>");return 1;}
	cah = str2num(argv[1]);
	cal = str2num(argv[2]);
	*(volatile _u32*)(0xbfe60008) = cal;
	*(volatile _u32*)(0xbfe60004) = cah;
	*(volatile _u32*)(0xbfe60000) = 0xf0000000;
//	mywait();
	return 0;
}	

static void flash_writepl()
{
	int i;
	for(i=0; i<128; i+=4)
		*(volatile _u32*)(0xbf00e000 + i) = i;
}

int verif(int argc, char argv[][30])
{
	printf("\nverif");
	_u32 page_offset;
	_u32 page_latch[33];
	int i;
	page_offset = 0xe000;
	printf("\noffset");
// crypt
	flash_setca(0x1f00e100,0x1f00e000);
	printf("\nsetca\n");
// normal page
	flash_clearHVPL();
	printf("clearHVPL\n");
	flash_writepl();
	printf("writepl\n");
	flash_erase(page_offset);
//	mywait();
	printf("erase\n");
	flash_page(page_offset);
//	mywait();
	printf("page\n");
// verif	
	*(volatile _u32*)(0xbfe60010) = 0x14;
	*(volatile _u32*)(0xbfe60000) = 0x1000e014;
	while(*(volatile _u32*)(0xbfe60014) & 0x2 != 0x2){}
	if(*(volatile _u32*)(0xbfe60014) & 0x1)
		printf("verif correct\n");
	else
		printf("verif error");
//	flash_setca(0x1f000001,0x1f000001);
return 0;
}

int set_pe_time_mode(int argc, char argv[][30])
{
	unsigned int mode;
	mode = str2num(argv[1]);	
	*(volatile _u32*)(0xbfe60024) = mode;
/****************************
mode:	0: 1.5ms
	1: 2.0ms
	2: 2.5ms
	3: 3.0ms
	4: 3.5ms
****************************/
return 0;
}

static void set_pe_time(int mode)
{
	*(volatile _u32*)(0xbfe60024) = mode;
}

int flash_tk(int argc, char argv[][30])
{
	unsigned int i,num;
	num = str2num(argv[1]);
	for(i=0; i<num; i++)
	{
		*(volatile _u32*)(0xbfe60000) = 0x20000000;
		while(*(volatile _u32*)(0xbfe60014) & 0x4 != 0x4){}
		printf("\n%8x%8x",*(volatile _u32*)(0xbfe60018),*(volatile _u32*)(0xbfe6001c));
	}
return 0;
}

int flash_accg(int argc, char argv[][30])
{
	printf("\n%x\n",*(volatile _u32*)(0xbf010008));
	*(volatile _u32*)(0xbfe60020) = 0x37116327;
	*(volatile _u32*)(0xbfe60020) = 0x90d112e5;
	*(volatile _u32*)(0xbfe60020) = 0x41237f48;
	*(volatile _u32*)(0xbfe60020) = 0xbeb9fb58;
	printf("%x",*(volatile _u32*)(0xbf010008));
return 0;
}

void mywait(void)
{
	__asm__ volatile(
	".set mips3\n"
	"wait;\n"
	".set mips1\n"
	);
}	

int copy_flash(int argc, char argv[][30])
{
	_u32 i,j,k,cnt;
	flash_setca(0x1f000001,0x1f000000);
	mywait();
	flash_clearHVPL();
	printf("\n");
	*(volatile _u8*)(0xbfea0000) = 0x10; // open int_en of flash in confreg
	for(i=511;; i=i-1)
	{
		for(j=0;j<128;j+=4){
			k= *(volatile _u32*)(0xbfc00000+i*128+j);
			*(volatile _u32*)(0xbf000000+i*128+j) = k;
		}
//		if(i%0x80 == 0x7c) 
//		{
			printf("page %3d\n",i);
			set_pe_time(2);
			flash_erase(i*128);
			mywait();
//			while(*(volatile _u8*)(0xbfea0005) != 0x10) {}
			set_pe_time(2);
			flash_page(i*128);
			mywait();
//			while(*(volatile _u8*)(0xbfea0005) != 0x10) {}
			flash_clearHVPL();
//		}
		if(i==0) break;
	}
	printf("\n\r\n\r\n");
	cnt = 0;
	for(i=0;i<0x10000;i+=4)
	{
		j = *(volatile _u32*)(0xbf000000+i);
		k = *(volatile _u32*)(0xbfc00000+i);
		cnt = (j==k) ? cnt : cnt + 1;
	//	printf("@%4x : %8x %8x %1d\n",i,j,k,(j==k));
	}
	printf("error count: %d\n",cnt);
return 0;
}

int write_trim(int argc, char argv[][30])
{
	flash_clearHVPL();
	*(volatile _u32*)(0xbfe60020) = 0x37116327;
	*(volatile _u32*)(0xbfe60020) = 0x90d112e5;
	*(volatile _u32*)(0xbfe60020) = 0x41237f48;
	*(volatile _u32*)(0xbfe60020) = 0xbeb9fb58;
	*(volatile _u32*)(0xbf0101f0) = 0x01aadd00;
	*(volatile _u32*)(0xbf0101f4) = 0x1f190106;
	*(volatile _u32*)(0xbf0101f8) = 0x091e5522;
	*(volatile _u32*)(0xbf0101fc) = 0x6d920606;
	set_pe_time(2);
	flash_erase(0x10180);
	mywait();
	flash_page(0x10180);
	mywait();
	printf("\ntrim write ok");
	return 0;
}

int jump(int argc, char argv[][30])
{
	__asm__ volatile(
	"li $8, 0xbf000000;\n"
	"jalr $8;\n"
	"nop;\n"
	:::"$8");
	return 0;
}

int flash_test(int argc, char argv[][30])
{
	_u32 i,j,k,cnt;
	k = str2num(argv[1]);
	*(volatile _u8*)(0xbfea0000) = 0x10; // open int_en of flash in confreg
	flash_setca(0x1f000001,0x1f000000);
	mywait();
	flash_clearHVPL();
	set_pe_time(2);
	printf("\npaging");
	*(volatile _u32*)(0xbfe60000) = 0x80000000; // erase all
	mywait();
	for(i=0;i<512;i++)
	{
		for(j=0;j<128;j+=4){
//			k= *(volatile _u32*)(0xbfc00000+i*128+j);
			*(volatile _u32*)(0xbf000000+i*128+j) = k;
		}
//			printf("page %3d\n",i);
			flash_page(i*128);
			mywait();
//			while(*(volatile _u8*)(0xbfea0005) != 0x10) {}
			flash_clearHVPL();
	}
	printf("\nverifying\n");
	cnt = 0;
	for(i=0;i<0x10000;i+=4)
	{
		j = *(volatile _u32*)(0xbf000000+i);
//		k = *(volatile _u32*)(0xbfc00000+i);
		cnt = (j==k) ? cnt : cnt + 1;
		if(j!=k) printf("@addr:0x%4x : j=0x%8x k=0x%8x\n",i,j,k);
	//	printf("@%4x : %8x %8x %1d\n",i,j,k,(j==k));
	}
	printf("error count: %d\n",cnt);
return 0;
}
//#endif //FLASH_TEST
