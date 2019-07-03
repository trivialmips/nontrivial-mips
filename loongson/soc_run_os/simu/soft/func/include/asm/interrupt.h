#if 1   /*It's not a good method. Don't use it!*/
#define SAVE_REGS	\
	li	k1, SRAM_BASEADDR+0x1000;	\
	sw	$0, 0x0(k1);	\
	sw	$1, 0x4(k1);	\
	sw	$2, 0x8(k1);	\
	sw	$3, 0xc(k1);	\
	sw	$4, 0x10(k1);	\
	sw	$5, 0x14(k1);	\
	sw	$6, 0x18(k1);	\
	sw	$7, 0x1c(k1);	\
	sw	$8, 0x20(k1);	\
	sw	$9, 0x24(k1);	\
	sw	$10, 0x28(k1);	\
	sw	$11, 0x2c(k1);	\
	sw	$12, 0x30(k1);	\
	sw	$13, 0x34(k1);	\
	sw	$14, 0x38(k1);	\
	sw	$15, 0x3c(k1);	\
	sw	$16, 0x40(k1);	\
	sw	$17, 0x44(k1);	\
	sw	$18, 0x48(k1);	\
	sw	$19, 0x4c(k1);	\
	sw	$20, 0x50(k1);	\
	sw	$21, 0x54(k1);	\
	sw	$22, 0x58(k1);	\
	sw	$23, 0x5c(k1);	\
	sw	$24, 0x60(k1);	\
	sw	$25, 0x64(k1);	\
	sw	$26, 0x68(k1);	\
	sw	$27, 0x6c(k1);	\
	sw	$28, 0x70(k1);	\
	sw	$29, 0x74(k1);	\
	sw	$30, 0x78(k1);  
	//sw	$31, 0x7c(k1)

#define LOAD_REGS	\
	li	k1, SRAM_BASEADDR+0x1000;	\
	lw	$0, 0x0(k1);	\
	lw	$1, 0x4(k1);	\
	lw	$2, 0x8(k1);	\
	lw	$3, 0xc(k1);	\
	lw	$4, 0x10(k1);	\
	lw	$5, 0x14(k1);	\
	lw	$6, 0x18(k1);	\
	lw	$7, 0x1c(k1);	\
	lw	$8, 0x20(k1);	\
	lw	$9, 0x24(k1);	\
	lw	$10, 0x28(k1);	\
	lw	$11, 0x2c(k1);	\
	lw	$12, 0x30(k1);	\
	lw	$13, 0x34(k1);	\
	lw	$14, 0x38(k1);	\
	lw	$15, 0x3c(k1);	\
	lw	$16, 0x40(k1);	\
	lw	$17, 0x44(k1);	\
	lw	$18, 0x48(k1);	\
	lw	$19, 0x4c(k1);	\
	lw	$20, 0x50(k1);	\
	lw	$21, 0x54(k1);	\
	lw	$22, 0x58(k1);	\
	lw	$23, 0x5c(k1);	\
	lw	$24, 0x60(k1);	\
	lw	$25, 0x64(k1);	\
	lw	$26, 0x68(k1);	\
	lw	$27, 0x6c(k1);	\
	lw	$28, 0x70(k1);	\
	lw	$29, 0x74(k1);	\
	lw	$30, 0x78(k1);	\
	//lw	$26, 0x7c(k1);	\
	//sw	$26, 0x10($30);  
	//lw	$31, 0x7c(k1)
#endif

/***********************************method 1*************************************/
#if 0
#define	SAVE_ALL	\
	addi	sp, -4;	\
	sw	$0, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$1, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$2, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$3, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$4, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$5, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$6, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$7, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$8, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$9, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$10, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$11, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$12, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$13, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$14, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$15, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$16, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$17, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$18, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$19, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$20, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$21, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$22, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$23, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$24, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$25, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$26, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$27, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$28, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$29, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$30, 0x0(sp);	\
	addi	sp, -4;	\
	sw	$31, 0x0(sp);	\
	addi	sp, -4


#define	LOAD_ALL	\
	addi	sp, 4;	\
	lw	$31, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$30, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$29, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$28, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$27, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$26, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$25, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$24, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$23, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$22, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$21, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$20, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$19, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$18, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$17, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$16, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$15, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$14, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$13, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$12, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$11, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$10, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$9, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$8, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$7, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$6, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$5, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$4, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$3, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$2, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$1, 0x0(sp);	\
	addi	sp, 4;	\
	lw	$0, 0x0(sp);	\
	addi	sp, 4
#endif
/****************************************************************************/

/*************************************method 2***********************************/
#if 1
#define	SAVE_ALL	\
	addi	sp, -132;	\
	sw	$0, 0x80(sp);	\
	sw	$1, 0x7c(sp);	\
	sw	$2, 0x78(sp);	\
	sw	$3, 0x74(sp);	\
	sw	$4, 0x70(sp);	\
	sw	$5, 0x6c(sp);	\
	sw	$6, 0x68(sp);	\
	sw	$7, 0x64(sp);	\
	sw	$8, 0x60(sp);	\
	sw	$9, 0x5c(sp);	\
	sw	$10, 0x58(sp);	\
	sw	$11, 0x54(sp);	\
	sw	$12, 0x50(sp);	\
	sw	$13, 0x4c(sp);	\
	sw	$14, 0x48(sp);	\
	sw	$15, 0x44(sp);	\
	sw	$16, 0x40(sp);	\
	sw	$17, 0x3c(sp);	\
	sw	$18, 0x38(sp);	\
	sw	$19, 0x34(sp);	\
	sw	$20, 0x30(sp);	\
	sw	$21, 0x2c(sp);	\
	sw	$22, 0x28(sp);	\
	sw	$23, 0x24(sp);	\
	sw	$24, 0x20(sp);	\
	sw	$25, 0x1c(sp);	\
	sw	$26, 0x18(sp);	\
	sw	$27, 0x14(sp);	\
	sw	$28, 0x10(sp);	\
	sw	$29, 0xc(sp);	\
	sw	$30, 0x8(sp);	\
	sw	$31, 0x4(sp)


#define	LOAD_ALL	\
	lw	$0, 0x80(sp);	\
	lw	$1, 0x7c(sp);	\
	lw	$2, 0x78(sp);	\
	lw	$3, 0x74(sp);	\
	lw	$4, 0x70(sp);	\
	lw	$5, 0x6c(sp);	\
	lw	$6, 0x68(sp);	\
	lw	$7, 0x64(sp);	\
	lw	$8, 0x60(sp);	\
	lw	$9, 0x5c(sp);	\
	lw	$10, 0x58(sp);	\
	lw	$11, 0x54(sp);	\
	lw	$12, 0x50(sp);	\
	lw	$13, 0x4c(sp);	\
	lw	$14, 0x48(sp);	\
	lw	$15, 0x44(sp);	\
	lw	$16, 0x40(sp);	\
	lw	$17, 0x3c(sp);	\
	lw	$18, 0x38(sp);	\
	lw	$19, 0x34(sp);	\
	lw	$20, 0x30(sp);	\
	lw	$21, 0x2c(sp);	\
	lw	$22, 0x28(sp);	\
	lw	$23, 0x24(sp);	\
	lw	$24, 0x20(sp);	\
	lw	$25, 0x1c(sp);	\
	lw	$26, 0x18(sp);	\
	lw	$27, 0x14(sp);	\
	lw	$28, 0x10(sp);	\
	lw	$29, 0xc(sp);	\
	lw	$30, 0x8(sp);	\
	lw	$31, 0x4(sp);	\
	addi	sp, 132	
#endif
/****************************************************************************/
