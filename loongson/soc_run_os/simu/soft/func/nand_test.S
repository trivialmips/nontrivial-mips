#include "regdef.h"
#define SIZE_2K

###define ECC

#define NAND_BASE  0xbfe78000
#define CONFREG_BASE  0xbfd00000
#define NAND_RD_MEM_BASE 0x84600000
#define NAND_WR_MEM_BASE 0x84700800
#define OPERATION_PAGES   0x1
#define OPERATION_GRID    0x7
  

#ifdef SIZE_2K
    #define SIZE_OOB  0x40
    #define SIZE_MAIN 0x800
    #define ECC_GRID  0xcc
#else
    #define SIZE_OOB  0x10
    #define SIZE_MAIN 0x200
    #define ECC_GRID  0xcc
#endif

#ifdef ECC
     #define NAND_WR_CMD 0x1005
     #define NAND_RD_CMD 0x4803
     #define NAND_NUM   204*OPERATION_GRID
     #define DMA_NUM    47*OPERATION_GRID
#else
     #define NAND_WR_CMD 0x5
     #define NAND_RD_CMD 0x3
     #define NAND_NUM   2048*OPERATION_PAGES   
     #define DMA_NUM    512*OPERATION_PAGES
#endif

#define NAND_START_ADDR 0x0
#define NAND_END_ADDR   0x4000
#define MALLOC_ADDR     0x80020000
#define SLOW_LOOP
	.set    noat
 	.set    noreorder

        .global nand_test 
	.ent    nand_test 
nand_test:
   move k0, ra 

   la	a0, msg_nand_test_begin
   jal stringserial
   nop

   li  t0, NAND_BASE
   li  t1, 0x40a
   sw  t1, 0xc(t0)
   li  t1, 0x7f85100
   sw  t1, 0x18(t0)
   li  t1, NAND_NUM 
   sw  t1, 0x1c(t0)
########################################## read_id
   li  t1, 0x21
   sw  t1, 0x0(t0)
3:
    lw      a1, 0x0(t0)
    and     a1, a1, 0x400
    beqz    a1, 3b
    nop
########################################## reset
   li  t1, 0x41
   sw  t1, 0x0(t0)
3:
    lw      a1, 0x0(t0)
    and     a1, a1, 0x400
    beqz    a1, 3b
    nop
########################################## erase
   li  t1, 0x9
   sw  t1, 0x0(t0)
3:
    lw      a1, 0x0(t0)
    and     a1, a1, 0x400
    beqz    a1, 3b
    nop

#initial memory data
    li s0, NAND_WR_MEM_BASE
    li s1, 0x11223344
    sw s1, 0x0(s0)
    li s1, 0x55667788
    sw s1, 0x4(s0)
    li s1, 0x99aabbcc
    sw s1, 0x8(s0)
    li s1, 0xddeeff00
    sw s1, 0xc(s0)
    li s1, 0x12345678
    sw s1, 0x10(s0)
    li s1, 0x9abcdef0
    sw s1, 0x14(s0)
    li s1, 0x87654321
    sw s1, 0x18(s0)
    li s1, 0x0fedcba9
    sw s1, 0x1c(s0)
    li s1, 0x5a5a5a5a
    sw s1, 0x20(s0)
    li s1, 0xa5a5a5a5
    sw s1, 0x24(s0)

########################################## write
    li a1, 0xa0001000
#if 1
    li a2, 0x00001100
    sw a2, 0x0(a1) # dma_order_addr
    li a2, 0x1fe78040
    sw a2, 0x8(a1) # dma_dev_addr
   # li a2, DMA_NUM
    li a2, 10  #10 words, see initial memory data
    sw a2, 0xc(a1) # dma_length
    li a2, 0x1
    sw a2, 0x10(a1) # dma_step_length
    li a2, 0x1
    sw a2, 0x14(a1) #step times
#endif

    li a2, NAND_WR_MEM_BASE
    sw a2, 0x4(a1) # dma_mem_addr
    li a2, 0x00001001
    sw a2, 0x18(a1) 
    li a1, 0x0001008 # which dma channel to be configured
    li a2, CONFREG_BASE
    sw a1, 0x1160(a2)

   li  t1, 40 #40 bytes
   sw  t1, 0x1c(t0)

   li  t1, 0x0
   sw  t1, 0x0(t0)
   li  t1, NAND_WR_CMD
   sw  t1, 0x0(t0)

4:
    lw      a1, 0x0(t0)
    and     a1, a1, 0x400
    beqz    a1, 4b
    nop
    li a1, 0x0001010 # which dma channel to be configured
    li a2, CONFREG_BASE
    sw a1, 0x1160(a2)

   la	a0, msg_nand_test_write_end
   jal stringserial
   nop
########################################## read
    li a1, 0xa0001000
#if 0
    li a2, 0x00001100
    sw a2, 0x0(a1) # dma_order_addr
    li a2, 0x1fe78040
    sw a2, 0x8(a1) # dma_dev_addr
    #li a2, 0x2f
    li a2, 10      # 10 words, see initial memory data
    sw a2, 0xc(a1) # dma_length
    li a2, 0x1
    sw a2, 0x10(a1) # dma_step_length
    li a2, 0x1
    sw a2, 0x14(a1) #step times
#endif

    li a2, NAND_RD_MEM_BASE
    sw a2, 0x4(a1) # dma_mem_addr
    li a2, 0x00000001
    sw a2, 0x18(a1) 
    li a1, 0x0001008 # which dma channel to be configured
    li a2, CONFREG_BASE
    sw a1, 0x1160(a2)

   li  t1, 0x0
   sw  t1, 0x0(t0)
   li  t1, NAND_RD_CMD
   sw  t1, 0x0(t0)

5:
    lw      a1, 0x0(t0)
    and     a1, a1, 0x400
    beqz    a1, 5b
    nop

   li  t1, 0x0
   sw  t1, 0x0(t0)

   la	a0, msg_nand_test_read_end
   jal stringserial
   nop
#############################################check
   li  s0, NAND_RD_MEM_BASE

   lw  s2, 0x0(s0)
   li  s1, 0x11223344
   bne s1, s2, check_err

   lw  s2, 0x4(s0)
   li  s1, 0x55667788
   bne s1, s2, check_err

   lw  s2, 0x8(s0)
   li  s1, 0x99aabbcc
   bne s1, s2, check_err

   lw  s2, 0xc(s0)
   li  s1, 0xddeeff00
   bne s1, s2, check_err

   lw  s2, 0x10(s0)
   li  s1, 0x12345678
   bne s1, s2, check_err

   lw  s2, 0x14(s0)
   li  s1, 0x9abcdef0
   bne s1, s2, check_err

   lw  s2, 0x18(s0)
   li  s1, 0x87654321
   bne s1, s2, check_err

   lw  s2, 0x1c(s0)
   li  s1, 0x0fedcba9
   bne s1, s2, check_err

   lw  s2, 0x20(s0)
   li  s1, 0x5a5a5a5a
   bne s1, s2, check_err

   lw  s2, 0x24(s0)
   li  s1, 0xa5a5a5a5
   bne s1, s2, check_err
   nop

   la	a0, msg_nand_check_ok
   jal stringserial
   nop

   b test_end
   nop

check_err:
   la	a0, msg_nand_check_fail
   jal stringserial
   nop

test_end:
   la	a0, msg_nand_test_end
   jal stringserial
   nop

   move ra, k0
   jr	ra
   nop

.end    nand_test


.rdata
msg_nand_test_end:
    .asciiz "nand test end\n"
msg_nand_test_begin:
    .asciiz "nand test beg\n"
msg_nand_test_addr:
    .asciiz "Addr:"
msg_nand_test_write_begin:
    .asciiz "wr go\n"
msg_nand_test_write_end:
    .asciiz "wr end\n"
msg_nand_test_read_begin:
    .asciiz "rd go\n"
msg_nand_test_read_end:
    .asciiz "rd end\n"
wait_nand_done:
    .asciiz "wait nand done \n"
msg_nand_check_begin:
    .asciiz "check\n"
msg_nand_check_ok:
    .asciiz "check pass\n"
msg_nand_check_fail:
    .asciiz "check fail\n"
hexdecarr:
        .asciiz "0123456789abcdef"
