#include "../config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#define write_u32(addr,value) (*(volatile _u32*)(addr) = (value))
#define read_u32(addr) (*(volatile _u32*)(addr))

#define LS1D
int help(int argc, char argv[][30]);
int m4(int argc, char argv[][30]);
int m1(int argc, char argv[][30]);
int d4(int argc, char argv[][30]);
int d1(int argc, char argv[][30]);
int float_test(int argc, char argv[][30]);


unsigned int str2num(char str[30]);
	char cmdpara[10][30];
	char **pp;
static _u8 mygetchar();
static void myputchar(_u8 chr);
struct cmd_struc {
	const char *cmdname;
	int (*func) __P((int, char *[]));
} cmd[] = {{"exit", NULL},
	   {"help", help},
	   {"m4", m4},
	   {"m1", m1},
	   {"d4", d4},
	   {"d1", d1},
	   {"", NULL}
};

int float_test(int argc, char argv[][30])
{
	unsigned int a,b;
	float i,j,k,l,m;
	a = 3000;
	b = 4096;
	k = (float)a/(float)b;
	i = 2.0;
	j = 3.3;
	l = 0.99;
	m = 1.01;
	i = i/j;
	l = l/m;
	k = i/l;
	if(k>0.99 && k<1.01) a++;	
	else a--;
	return 0;
}


static void myputchar(_u8 chr)
{
	while(!(Uart0_LSR & 0x20)) ;
	Uart0_TxData = chr;
}

static _u8 mygetchar()
{
	_u8 chr;
//	int i=0,j;
//	while(1) {if(Uart0_LSR & 0x1) break;else 
//	for(i=0;i<100;i++) {j=*(volatile _u32*)(0xbe000000);}}
	while(!(Uart0_LSR & 0x1)) ;
	chr = Uart0_RxData ;
//	printf("f");
//	printf("%d",chr);
	return chr;
}

int help(int argc, char argv[][30])
{
	int i;
	printf("\ncommands:\n");
		for(i=1;i<100;i++)
		{
			if(strcmp(cmd[i].cmdname,"")==0) break;
			else printf(" %s",cmd[i].cmdname);
		}
//	printf("\n");

	return 0;
}

unsigned int str2num(char str[30])
{
   int value = 0;
   int sign = 1;
   int radix;
 
   if(*str == '-')
   {
      sign = -1;
      str++;
   }
   if(*str == '0' && (*(str+1) == 'x' || *(str+1) == 'X'))
   {
      radix = 16;
      str += 2;
   }
   else if(*str == '0')      // 八进制首字符为0
   {
      radix = 8;
      str++;
   }
   else
      radix = 10;
   while(*str)
   {
      if(radix == 16)
      {
        if(*str >= '0' && *str <= '9')
           value = value * radix + *str - '0';
        else
           value = value * radix + (*str | 0x20) - 'a' + 10;
       // value = value * radix + *str - 'a' + 10; // 也没问题啊
      }
      else
        value = value * radix + *str - '0';
      str++;
   }
   return (unsigned int *)(sign*value);
}

int m4(int argc, char argv[][30])
{
	unsigned int addr,value;
//	printf("%s\n",argv[1]);
	if(argc != 3) 
	{
		printf("\nusage: m4 <addr> <value>"); 
		return 1;
	}
	addr=str2num(argv[1]);
	value=str2num(argv[2]);
#ifdef LS1D
	*(volatile unsigned int*)(addr) = value;
#else
	printf("addr: %x ,value: %x\n",addr,value);
#endif
	return 0;
}

int m1(int argc, char argv[][30])
{
	unsigned int addr,value;
//	printf("%s\n",argv[1]);
	if(argc != 3) 
	{
		printf("\nusage: m1 <addr> <value>"); 
		return 1;
	}
	addr=str2num(argv[1]);
	value=str2num(argv[2]);
#ifdef LS1D
	*(volatile unsigned char*)(addr) = value;
#else
	printf("addr: %x ,value: %x\n",addr,value);
#endif
	return 0;
}

int d4(int argc, char argv[][30])
{
	unsigned int addr;
	if(argc != 2)
	{
		printf("\nusage: d4 <addr>");
		return 1;
	}
	addr=str2num(argv[1]);
#ifdef LS1D
	printf("\n0x%08x: %08x",addr,*(volatile unsigned int*)(addr));
#else
	printf("0x%08x:\n",addr);
#endif
	return 0;
}

int d1(int argc, char argv[][30])
{
	unsigned int addr;
	if(argc != 2)
	{
		printf("\nusage: d1 <addr>");
		return 1;
	}
	addr=str2num(argv[1]);
#ifdef LS1D
	printf("\n0x%08x: %02x",addr,*(volatile unsigned char*)(addr));
#else
	printf("0x%08x:\n",addr);
#endif
	return 0;
}

int cmdline(void)
{
	char c;
	char cmdbuffer[40];
	char *cbuffer;
	short ccc,cpc,cbc,i,j;
	int count=0;
//	int (*func) (int , char **);
	int (*op)(int argc,char **argv);
	i=0;
	j=0;
	ccc=0;
	cpc=0;
    printf("This is the 1st test!\n");
    printf("This is the 2nd test!\n");
//    printf("This is the 3rd test!\n");
//    printf("This is the 4th test!\n");
//    printf("This is the 5th test!\n");
// test mult    
    int opa = 1;
    int opb = 2;
    int result1 = opa * opb;
    int result10 = 1 * 2;
    int result2 = (opa+1) * (opb+4);
    int result20 = 2 * 6;
    int result3 = (opa+299) * (opb+298);
    int result30 = 300 * 300;
    printf("result: %d  %d\n", result1, result10);
    printf("result: %d  %d\n", result2, result20);
    printf("result: %d  %d\n", result3, result30);
    while(1){}
while(1)
{
	for(i=0;i<10;i++)
		for(j=0;j<30;j++)
			cmdpara[i][j] = '\0';
	for(i=0;i<40;i++) cmdbuffer[i]= '\0';
//	printf("\n$ ");
	cbuffer = cmdpara[0];
//	printf("@ ");
	ccc=0;
//	printf("@ ");
	cpc=0;
//	printf("@ ");
	cbc=0;
//	printf("@ ");
	count++;
//	for(i=0;i<1000;i++) i++;
	printf("\nS ");
//	for(i=0;i<500;i++) j=Uart0_LSR;
//	printf("%4d ",count);
//	i=1;
//	while(i++) {printf("\n%4d",i);j++;}
	// internal loop
	while(1)
	{
//		printf("|\n");
		c=mygetchar();
//		printf("%d\n",c);
//		printf("/");
//		c=13;
//		c=53;
		if(c==8) 
		{
			cbc=cbc-1;
			cmdbuffer[cbc] = '\0';
			myputchar(8);myputchar(32);myputchar(8);
		}
		else 
		{
			cmdbuffer[cbc++] = c;
			myputchar(c);
		}
//		printf("\r%s",cmdbuffer);
		if(c==10 || c==13) break;
	}
	for(i=0;i<cbc;i++){
		c=cmdbuffer[i];
		if(c==10 || c==13) 
		{
			*(cbuffer + ccc) = '\0'; 
			break;
		}
		else 
		if(c==' ')
		{
			*(cbuffer + ccc) = '\0';
			if(ccc) cpc++;
//			printf("cpc:%d\n",cpc);
			cbuffer = cmdpara[cpc];
			ccc=0;
		}
		else
		{
			*(cbuffer + ccc) = c;
			ccc++;
		}
	}
	// cmd decode
	cbuffer = cmdpara[0];
//	pp = cmdpara;
//for (i=0;i<10;i++)
//	*pp++ = cmdpara[i];
	if(strcmp(cbuffer, cmd[0].cmdname)==0) break;
	else 
		for(i=1;i<100;i++)
		{
			if(strcmp(cmd[i].cmdname,"")==0) break;
			if(strcmp(cbuffer, cmd[i].cmdname)!=0) continue;
//			printf("match func: %s\n",cmd[i].cmdname);

			op= cmd[i].func;
			op(cpc+1,cmdpara);
//			printf("%x",aaa);
//			printf("1 ");
//			func = aaa;
//			printf("%x",func);
//			j=func(cpc,cmdpara); 
//			printf("%d\n",j);
		}
//	printf("argc: %d\n",cpc);
//	for(i=0; i<10; i++)
//		if(cmdpara[i][0]=='\0') break;
//		else printf("argv[%d]: %s\n",i,cmdpara[i]);
}
return 0;
}	
