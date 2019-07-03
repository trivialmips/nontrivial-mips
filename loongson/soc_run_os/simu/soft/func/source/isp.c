
#include "../config.h"

#if PRINT
void tgt_putchar(_u8 chr)
{
	while(!(Uart0_LSR & 0x20)) ;
	Uart0_TxData = chr;
}

_u8 tgt_getchar()
{
	_u8 chr;
	while(!(Uart0_LSR & 0x1)) ;
	chr = Uart0_RxData ;

	return chr;
}

_u8 tgt_testchar()
{
	_u8 chr;
	chr = (Uart0_LSR & 0x1);

	return chr;
}
#endif

_u32 now()
{
	_u32 count;
	count = PMU_Count;
	count &= COUNT_MASK;

	return count;
}

#if (ISP || MONTHDATA_MODULE)
#if (LS1D_FPGA)
void spiflash_erase(_u32 addr_start, _u32 addr_end)  
{
	__asm__ volatile(
	"move	$15,$31;\n"
/**spi_flash init**/
	"li     $8,0xbfe70000;\n" 
	"li     $9,0xc0;\n" 
	"sb     $9,1($8);\n" 
	"li     $9,0x10;\n" 
	"sb     $9,4($8);\n" 
	"li     $9,0x5;\n" 
	"sb     $9,3($8);\n" 
	"li     $9,0x1;\n" 
	"sb     $9,6($8);\n" 
	"li     $9,0x50;\n" 
	"sb     $9,0($8);\n"   
/**spi_flash code_program**/
	"li	$14, 0x1000;\n" 
	"1:li	$9,0x11;\n" 
	"sb	$9,5($8);\n"  /*high cs*/
	"bal	102f;\n"  /*wait sr */
	"nop;\n" 
	"li $9,6;\n"  /* write enable */
	"bal 101f;\n" 
	"nop;\n" 
	"li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"li $9,1;\n"   /* write status*/
	"bal 101f;\n" 
	"nop;\n" 
	"li $9,0;\n"   /* write 0*/
	"bal 103f;\n" 
	"nop;\n" 
	"li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"bal 102f;\n"  /*wait sr */
	"nop;\n" 
	"li $9,6;\n"  /* write enable */
	"bal 101f;\n" 
	"nop;\n" 
	"li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"li $9,0x20;\n"  /*bulk erase, 4kB*/
	"bal 101f;\n" 
	"nop;\n" 
	"srl $9,$4,16;\n"  /*addr*/
	"bal 103f;\n" 
	"nop;\n" 
	"srl $9,$4,8;\n" 
	"bal 103f;\n" 
	"nop;\n" 
	"move $9,$4;\n" 
	"bal 103f;\n" 
	"nop;\n" 
	"li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"bal 102f;\n"  /*wait sr*/
	"nop;"
	"addu $4,$14;\n" 
	"slt $9,$5,$4;\n" 
	"beqz $9,1b;\n" 
	"nop;\n" 
	"3:\n" 
	"li $9,0x11;\n"  
	"sb $9,5($8);\n" /*high cs*/

	"li	$9,0x11;\n"
	"sb	$9,4($8);\n"
	"b	999f;\n"  
	"nop;\n"

	"101:li $11,1;\n" 
	"sb $11,5($8);\n"   /*enable and low cs*/
	"103:sb $9,2($8);\n" 
	"1:lb $9,1($8);\n" 
	"andi $9,1;\n" 
	"bnez $9,1b;\n" 
	"nop;\n" 
	"lb $9,2($8);\n" 
	"jr $31;\n"  
	"nop\n;"  
	"102:move $10,$31;\n" 
	"1:li $9,5;\n"  /*wait read sr*/
	"bal 101b;\n" 
	"nop;\n" 
	"andi $9,1;\n" 
	"bnez $9,1b;\n"  /*can continue read sr,write to gen clock*/
	"nop;\n" 
	"li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"jr $10;\n"  
	"nop;\n" 

	"999:move $31,$15;\n"
	:::"$8","$9","$10","$11","$4","$5","$14","$15"
	);
}
void spiflash_write(_u32 addr_w, _u32 addr_r, _u32 length)
{
	__asm__ volatile(
	"move	$15,$31;\n"
/**spi_flash init**/
	"li     $8,0xbfe70000;\n" 
	"li     $9,0xc0;\n" 
	"sb     $9,1($8);\n" 
	"li     $9,0x10;\n" 
	"sb     $9,4($8);\n" 
	"li     $9,0x5;\n" 
	"sb     $9,3($8);\n" 
	"li     $9,0x1;\n" 
	"sb     $9,6($8);\n" 
	"li     $9,0x50;\n" 
	"sb     $9,0($8);\n"   
/**spi_flash code_program**/
	"li	$9,0x11;\n" 
	"sb	$9,5($8);\n"  /*high cs*/
	"bal	102f;\n"  /*wait sr */
	"nop;\n" 
	"li $9,6;\n"  /* write enable */
	"bal 101f;\n" 
	"nop;\n" 
	"li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"li $9,1;\n"   /* write status*/
	"bal 101f;\n" 
	"nop;\n" 
	"li $9,0;\n"   /* write 0*/
	"bal 103f;\n" 
	"nop;\n" 
	"1:li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"bal 102f;\n"  /*wait sr */
	"nop;\n" 
	"li $9,6;\n"  /* write enable */
	"bal 101f;\n" 
	"nop;\n" 
	"li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"bal 102f;\n"  /*wait sr*/
	"nop;" 
	"li $9,2;\n"  /*write sector*/
	"bal 101f;\n" 
	"nop;\n" 
	"srl $9,$4,16;\n"  /*addr*/
	"bal 103f;\n" 
	"nop;\n" 
	"srl $9,$4,8;\n" 
	"bal 103f;\n" 
	"nop;\n" 
	"move $9,$4;\n" 
	"bal 103f;\n" 
	"nop;\n" 
	"2:lb $9,0($5);\n"  /*write 1 data*/ 
	"bal 103f;\n" 
	"nop;\n" 
	"addiu $4,1;\n" 
	"addiu $5,1;\n" 
	"addiu $6,-1;\n"
	"beqz $6,3f;\n" 
	"nop;\n" 
	"b 1b;\n" 
	"nop;\n"
	"3:\n" 
	"li $9,0x11;\n"  
	"sb $9,5($8);\n" /*high cs*/

	"li	$9,0x11;\n"
	"sb	$9,4($8);\n"
	"b	999f;\n"  
	"nop;\n"

	"101:li $11,1;\n" 
	"sb $11,5($8);\n"   /*enable and low cs*/
	"103:sb $9,2($8);\n" 
	"1:lb $9,1($8);\n" 
	"andi $9,1;\n" 
	"bnez $9,1b;\n" 
	"nop;\n" 
	"lb $9,2($8);\n" 
	"jr $31;\n"  
	"nop\n;"  
	"102:move $10,$31;\n" 
	"1:li $9,5;\n"  /*wait read sr*/
	"bal 101b;\n" 
	"nop;\n" 
	"andi $9,1;\n" 
	"bnez $9,1b;\n"  /*can continue read sr,write to gen clock*/
	"nop;\n" 
	"li $9,0x11;\n"  /*high cs*/
	"sb $9,5($8);\n" 
	"jr $10;\n"  
	"nop;\n" 

	"999:move $31,$15;\n"
	:::"$8","$9","$10","$11","$4","$5","$6","$15"
	);
}
#else
//²Á³ýaddrËùÔÚµÄ¶Î
void Flash_Erase(_u32 addr)
{
	FLASH_CMD_REG = FLASH_ERASE_CMD | (addr & FLASH_ADDR_MASK) ;

}

_u32 Flash_Write(_u32 addr, _u32 *data, _u32 num)
{    
	FLASH_CMD_REG = FLASH_PAGE_LATCH_CLEAR;
	/*wait interrupt ? Should I disable other int??????*/
	//debug("Page_latch is clean now...\n")

	_u32 flash_block_mask = FLASH_BLOCK_SIZE - 1;
	_u32 *page_data = (_u32 *)(addr & ~flash_block_mask) ;
	_u32 *old_data = (_u32 *)(addr & ~flash_block_mask) ;
	_u32 i, j, offset;

	j = 0;
	offset = ((addr & flash_block_mask)>>2);
	for(i=0; i<(FLASH_BLOCK_SIZE/4); i++)
	{
		if( (offset <= i)  && (j < num) )
			page_data[i] = data[j++];
		else
			page_data[i] = old_data[i];
	}

	Flash_Erase(addr);
	/*wait interrupt ? */
	//debug("Flash page is clean now...\n")

	FLASH_CMD_REG = FLASH_WRITE_CMD | (addr & FLASH_ADDR_MASK) ;
	/*wait interrupt ? */
	//debug("Flash page write is finish...\n")

	return 0;
}
#endif
#endif


