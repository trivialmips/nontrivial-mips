#include <stdio.h>
#include "../config.h"
#include "../include/asm/ns16550.h"

#define COM_BASE 0xbfe88000 //com1 for 1D
#define NS16550_LSR  5
#define NS16550_DATA 0

#define LSR_TXRDY 0x20
#define LSR_RXRDY 0x01

#define writeb(val, addr) (*(volatile unsigned char*)(addr) = (val)) 
#define readb(addr) (*(volatile unsigned char*)(addr))
int dg_write(char *str);
int dg_read(char *buffer, unsigned num);
static void uart_putchar(char a0);
static char uart_getchar(void);
static void uart1_init(void)
{
	Uart1_FCR = FIFO_ENABLE|FIFO_RCV_RST|FIFO_XMT_RST|FIFO_TRIGGER_4;
	Uart1_LCR = CFCR_DLAB;
	Uart1_BaudL = 52;  //set 9600Baut
	Uart1_LCR = CFCR_8BITS;  //8bit, 1stop
	Uart1_MCR = MCR_DTR|MCR_RTS;
	Uart1_IER = 0;
}
	
int dg_ctrl(int argc, char argv[][30]) // main 
{
	char buffer[1024];
	uart1_init();
	printf("\n");
	/* Make sure ip address is supplied on the command line */
//	if ( argc < 2 ) {
//		printf("Usage: dg_ctrl IP_ADDRESS\n");
//		exit(1);
//	}
	/* Initialize the sockets library */
//	init_tcpip();
	/* Connect to the dg645 */
//	if ( dg_connect( inet_addr(argv[1]) ) ) {
//		printf("Connection Succeeded\n");
		/* Get identification string */
		dg_write("*idn?\n");
//		printf("\n*idn?\n");
		if ( dg_read(buffer,sizeof(buffer)) )
			printf("%s\n",buffer);
		else
			printf("Timeout\n");
		/* Load default settings */
		dg_write("*rst\n"); 		// load default settings
		dg_write("tsrc 1\n"); 		// set trigger source 	to 1(external posedge)
		dg_write("burc 1\n"); 		// set burst count 	to 1
		dg_write("burd 4e-6\n");	// set burst delay 	to 4us
		dg_write("burm 1\n");		// set burst mode 	to ON
		dg_write("burp 1e-6\n");	// set burst period 	to 1us
		dg_write("dlay 2,0,5e-8\n");	// set A to 0 delay	to 50ns
		dg_write("dlay 3,2,5e-7\n");	// set B to A delay	to 500ns
		dg_write("tlvl 0.9\n");		// set trigger level	to 0.9V
		dg_write("lamp 0,1.66\n");	// set T0 amplitude	to 1.66V
		dg_write("lamp 1,1.66\n");	// set AB amplitude	to 1.66V
		dg_write("*sav 4\n");		// save config		to 4
//		dg_write("*wai\n");		// wait execute
		/* Make sure all commands have executed before closing connection */
//		dg_write("*opc?\n");
//		if ( !dg_read(buffer,sizeof(buffer)) )
//			printf("Timeout\n");
		/* Close the connection */
//		if (dg_close())
//			printf("Closed connection\n");
//		else
//			printf("Unable to close connection");
//	}
//	else
//		printf("Connection Failed\n");
	return 0;
}

int dg_cmd(int argc, char argv[][30])
{
	printf("\n");
	dg_write(argv[1]);
	dg_write("\n");
return 0;
}

int dg_write(char *str)
{
//	printf("\n");
	while(*str != '\0'){
		uart_putchar(*str);
		printf("%c",*str);
		str++;
	}
	if(*(str-1) == '\n') printf("\r");
	return 0;
}

int dg_read(char *buffer, unsigned num)
{
	char t;
	int count=0;
	unsigned flag=0;
	while(1){
		t=uart_getchar();
		if(t==-1) {
			*buffer = '\0'; return count;
		}
		//if(t==10 || t==13 || t=='\0') flag=1; //
		if(flag){
			*buffer = '\0'; return count;
		}
		else{
			*buffer = t; buffer++; count++;
		}
	}
} 

static void uart_putchar(char a0)
{
	while((readb(COM_BASE + NS16550_LSR) & LSR_TXRDY)==0){}
	writeb(a0, COM_BASE + NS16550_DATA);
}

static char uart_getchar()
{
//printf("fly to here\n");
	int cnt=0;
	while(cnt<1000000 && (readb(COM_BASE + NS16550_LSR) & LSR_RXRDY)==0){cnt++;}
	if (cnt>=1000000) return -1;
	return readb(COM_BASE + NS16550_DATA);
}

/*

TSRC(?){i} Trigger Source
Set (query) the trigger source {to i}. The parameter i determines the trigger
source according to the following table:
i Trigger Source
0 Internal
1 External rising edges
2 External falling edges
3 Single shot external rising edges
4 Single shot external falling edges
5 Single shot
6 Line
Example
TSRC 5<CR> Set up the DG645 for single shot triggering.

///-------------------------

DLAY(?)c{,d,t} Delay
Set (query) the delay for channel c {to t relative to channel d}.
Example
DLAY 2,0,10e-6<CR> Set channel A delay to equal channel T0 plus 10 μs.
DLAY 3,2,1e-3<CR> Set channel B delay to equal channel A delay plus 1 ms.
DLAY?3<CR> Query channel B. Should return ‘2,+0.001000000000’ to
indicate that B = A + 1 ms.

///-------------------------BURST

BURC(?){i} Burst Count
Set (query) the burst count {to i}. When burst mode is enabled, the DG645
outputs burst count delay cycles per trigger.
Example
BURC 10<CR> Set the burst count to 10 so that the DG645 will output
10 delay cycles per triggered burst.

BURD(?){t} Burst Delay
Set (query) the burst delay {to t}. When burst mode is enabled the DG645 delays
the first burst pulse relative to the trigger by the burst delay.
Example
BURD 5e-6<CR> Set the burst delay to 5 μs so that the DG645 will delay the
first cycle of the burst by 5 μs relative to the trigger.

BURM(?){i} Burst Mode
Set (query) the burst mode {to i}. If i is 0, burst mode is disabled. If i is 1, burst
mode is enabled.

BURP(?){t} Burst Period
Set (query) the burst period {to t}. The burst period sets the time between delay
cycles during a burst. The burst period may range from 100 ns to 2000 – 10 ns in
10 ns steps.
Example
BURP 1e-3<CR> Set burst period to 1 ms. When a burst is triggered, the
DG645 will generate burst count delay cycles at a 1 kHz rate.

BURT(?){i} Burst T0 Configuration
Set (query) the burst T0 configuration {to i}. If i is 0, the T0 output is enabled for
all delay cycles of the burst. If i is 1, the T0 output is enabled for first delay cycle
of the burst only.

*/
