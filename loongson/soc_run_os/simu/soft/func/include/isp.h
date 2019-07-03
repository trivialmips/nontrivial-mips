void tgt_putchar(_u8 chr);
_u8 tgt_getchar();
_u8 tgt_testchar();
_u32 now();

void Flash_Erase(_u32 addr);
_u32 Flash_Write(_u32 addr, _u32 *data, _u32 num);
void spiflash_erase(_u32 addr_start, _u32 addr_end);  
void spiflash_write(_u32 addr_w, _u32 addr_r, _u32 length);

