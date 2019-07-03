
/************************************************************************************************************************************************************************************************/
 
#include "include/asm/regdef.h"
#include "include/asm/mipsregs.h"
#include "include/asm/ns16550.h"
#include "include/asm/interrupt.h"

#define NAND_TEST
#define SRAM_BASEADDR			0xa0000000
#define UART0_BASEADDR  		0xbfe40000 
#define NAND_BASEADDR  		    0xbfe48000 
#define CONFIG_BASE             0xaff00000
#define MAC_BASEADDR            0xbff00000
#define CONFREG_BASE            0xbfd00000

#define DELAY 0x4
#define print_hex 1
#define print_reg 0
#define PRINTSTR(x) \
    .rdata;98: .asciz x; .text; la a0, 98b; bal stringserial; nop
#define PRINT(x) \
    .rdata; .text; la a0, x; bal stringserial; nop
#define RVECENT(f,n)	\
	b	f;	\
	nop
#define XVECENT(f,bev)	\
	b	f;	\
	nop

	.set noreorder

	.globl _start
	.text
_start:
	RVECENT(reset,0)	/* hard-reset entry point */
	RVECENT(reset,1)	/* software reboot */
	RVECENT(romReserved,2)
	RVECENT(romReserved,3)
	RVECENT(romReserved,4)
	RVECENT(romReserved,5)
	RVECENT(romReserved,6)
	RVECENT(romReserved,7)
	RVECENT(romReserved,8)
	RVECENT(romReserved,9)
	RVECENT(romReserved,10)
	RVECENT(romReserved,11)
	RVECENT(romReserved,12)
	RVECENT(romReserved,13)
	RVECENT(romReserved,14)
	RVECENT(romReserved,15)
	RVECENT(romReserved,16)
	RVECENT(romReserved,17)
	RVECENT(romReserved,18)
	RVECENT(romReserved,19)
	RVECENT(romReserved,20)
	RVECENT(romReserved,21)
	RVECENT(romReserved,22)
	RVECENT(romReserved,23)
	RVECENT(romReserved,24)
	RVECENT(romReserved,25)
	RVECENT(romReserved,26)
	RVECENT(romReserved,27)
	RVECENT(romReserved,28)
	RVECENT(romReserved,29)
	RVECENT(romReserved,30)
	RVECENT(romReserved,31)
	RVECENT(romReserved,32)
	RVECENT(romReserved,33)
	RVECENT(romReserved,34)
	RVECENT(romReserved,35)
	RVECENT(romReserved,36)
	RVECENT(romReserved,37)
	RVECENT(romReserved,38)
	RVECENT(romReserved,39)
	RVECENT(romReserved,40)
	RVECENT(romReserved,41)
	RVECENT(romReserved,42)
	RVECENT(romReserved,43)
	RVECENT(romReserved,44)
	RVECENT(romReserved,45)
	RVECENT(romReserved,46)
	RVECENT(romReserved,47)
	RVECENT(romReserved,48)
	RVECENT(romReserved,49)
	RVECENT(romReserved,50)
	RVECENT(romReserved,51)
	RVECENT(romReserved,52)
	RVECENT(romReserved,53)
	RVECENT(romReserved,54)
	RVECENT(romReserved,55)
	RVECENT(romReserved,56)
	RVECENT(romReserved,57)
	RVECENT(romReserved,58)
	RVECENT(romReserved,59)
	RVECENT(romReserved,60)
	RVECENT(romReserved,61)
	RVECENT(romReserved,62)
	RVECENT(romReserved,63)
	XVECENT(romExcHandle,0x200)	/* bfc00200: R4000 tlbmiss vector */
	RVECENT(romReserved,65)
	RVECENT(romReserved,66)
	RVECENT(romReserved,67)
	RVECENT(romReserved,68)
	RVECENT(romReserved,69)
	RVECENT(romReserved,70)
	RVECENT(romReserved,71)
	RVECENT(romReserved,72)
	RVECENT(romReserved,73)
	RVECENT(romReserved,74)
	RVECENT(romReserved,75)
	RVECENT(romReserved,76)
	RVECENT(romReserved,77)
	RVECENT(romReserved,78)
	RVECENT(romReserved,79)
	XVECENT(romExcHandle,0x280)	/* bfc00280: R4000 xtlbmiss vector */
	RVECENT(romReserved,81)
	RVECENT(romReserved,82)
	RVECENT(romReserved,83)
	RVECENT(romReserved,84)
	RVECENT(romReserved,85)
	RVECENT(romReserved,86)
	RVECENT(romReserved,87)
	RVECENT(romReserved,88)
	RVECENT(romReserved,89)
	RVECENT(romReserved,90)
	RVECENT(romReserved,91)
	RVECENT(romReserved,92)
	RVECENT(romReserved,93)
	RVECENT(romReserved,94)
	RVECENT(romReserved,95)
	XVECENT(romExcHandle,0x300)	/* bfc00300: R4000 cache vector */
	RVECENT(romReserved,97)
	RVECENT(romReserved,98)
	RVECENT(romReserved,99)
	RVECENT(romReserved,100)
	RVECENT(romReserved,101)
	RVECENT(romReserved,102)
	RVECENT(romReserved,103)
	RVECENT(romReserved,104)
	RVECENT(romReserved,105)
	RVECENT(romReserved,106)
	RVECENT(romReserved,107)
	RVECENT(romReserved,108)
	RVECENT(romReserved,109)
	RVECENT(romReserved,110)
	RVECENT(romReserved,111)
#if 0
	XVECENT(IntHandle,0x380)	/* bfc00380: R4000 general vector */
#else
IntHandle:
	SAVE_ALL
#	PRINTSTR("Interrupt 0 is coming...\r\n")
#if 1 // print_reg
#	bal	PRINT_CP0
#	nop
#endif

7:	
	mfc0	t0, CP0_CAUSE
	and	t1, t0, 0x400 
	bne	zero, t1, 1f	
	nop
	and	t1, t0, 0x800
	bne	zero, t1, 2f
	nop
	and	t1, t0, 0x1000
	bne	zero, t1, 3f
	nop
	and	t1, t0, 0x2000
	bne	zero, t1, 4f
	nop
	and	t1, t0, 0x4000
	bne	zero, t1, 5f
	nop
	and	t1, t0, 0x8000
	bne	zero, t1, 6f
	nop
	#PRINTSTR("No interrupt left...\r\n\r\n")
	b	8f
	nop

1:	/*timer*/
#	PRINTSTR("Timer interrupt is coming...\r\n")

2:	/*key*/
#        PRINTSTR("Key interrupt is coming...\r\n")

3:	/*batfail*/
#        PRINTSTR("BatFail interrupt is coming...\r\n")

4:	/*res_valid*/
#        PRINTSTR("ResVaild interrupt is coming...\r\n")

5:	/*INTC*/
#	PRINTSTR("IP6 is coming...\r\n")

6:	/*Ring*/
#	PRINTSTR("IP7 is coming...\r\n")

8:
	LOAD_ALL
    .set mips32
	eret
    .set mips1
	nop
#endif

	RVECENT(romReserved,113)
	RVECENT(romReserved,114)
	RVECENT(romReserved,115)
	RVECENT(romReserved,116)
	RVECENT(romReserved,116)
	RVECENT(romReserved,118)
	RVECENT(romReserved,119)
	RVECENT(romReserved,120)
	RVECENT(romReserved,121)
	RVECENT(romReserved,122)
	RVECENT(romReserved,123)
	RVECENT(romReserved,124)
	RVECENT(romReserved,125)
	RVECENT(romReserved,126)
	RVECENT(romReserved,127)

	/* We hope there are no more reserved vectors!
	 * 128 * 8 == 1024 == 0x400
	 * so this is address R_VEC+0x400 == 0xbfc00400
	 */
	.align 4
#if print_hex
	.rdata
hexchar:
        .ascii  "0123456789abcdef"
	.text   //Don't forget it!
#endif

reset:
	mtc0	zero, CP0_CAUSE  #
    li      t0, 0x30400000
    mtc0    t0, CP0_STATUS  #
	li	t0, 0x00000000  #set fp reg
	/* Initialize $gp.
	 */
	bal	1f
	nop
	.word	_gp
1:
	lw	gp, 0(ra)

	bal	initserial0
	nop

	PRINTSTR("\r\nInitializing...\r\n");
    PRINTSTR("\r\nHello, Loongson...\r\n");
    
    li t0, 0xbfd00010
    lw t1,0(t0)
    ori t1, t1, 0x0
    sw t1,0(t0)
###################################################
#####nand test
#####
#ifdef NAND_TEST
    bal nand_test
    nop
##    PRINTSTR("\r\nGouSheng!!!\r\n");
#endif
#####
#####nand test
###################################################


    PRINTSTR("\r\nMac_test start...\r\n");
    bal mac_test
    nop
    PRINTSTR("\r\nMac_test end...\r\n");
    // bal ddr2_config //old ddr config 
    // nop

    la  v0, SRAM_BASEADDR
    li  t0, 0x0a424242
    sw  t0, 0x0(v0)
    la  a0, 0x0(v0)
    bal stringserial
    nop

    la  a0, loongson
    bal stringserial
    nop

    la  v0, SRAM_BASEADDR
    li  t0, 0x0a454545
    sw  t0, 0x0(v0)
    la  a0, 0x0(v0)
    bal stringserial
    nop


###ddr3 test
# if 1
#####write data to sram    
	.align	5
    la  v0, SRAM_BASEADDR
    la  s0, SRAM_BASEADDR+0x00000100
    li  t0, 0x11111111
    li  t1, 0x21212121
    li  t2, 0x31313131
    li  t3, 0x41414141
    li  t4, 0x51515151
    li  t5, 0x61616161
    li  t6, 0x71717171
    li  t7, 0x81818181
1:    
    sw  t0, 0x0(v0)
    sw  t1, 0x4(v0)
    sw  t2, 0x8(v0)
    sw  t3, 0xc(v0)
    sw  t4, 0x10(v0)
    sw  t5, 0x14(v0)
    sw  t6, 0x18(v0)
    sw  t7, 0x1c(v0)
    addiu   v0, v0, 0x20
    bne v0, s0, 1b
    nop

#####read data from sram
    la  v0, SRAM_BASEADDR
2: 
    lw  t8, 0x0(v0)
    beq t0, t8, 1f
    nop
    jal checkerr
    nop
1:
    lw  t8, 0x4(v0)
    beq t1, t8, 1f
    nop
    jal checkerr
    nop
1:
    lw  t8, 0x8(v0)
    beq t2, t8, 1f
    nop
    jal checkerr
    nop
1:
    lw  t8, 0xc(v0)
    beq t3, t8, 1f
    nop
    jal checkerr
    nop
1:
    lw  t8, 0x10(v0)
    beq t4, t8, 1f
    nop
    jal checkerr
    nop
1:
    lw  t8, 0x14(v0)
    beq t5, t8, 1f
    nop
    jal checkerr
    nop
1:
    lw  t8, 0x18(v0)
    beq t6, t8, 1f
    nop
    jal checkerr
    nop
1:
    lw  t8, 0x1c(v0)
    beq t7, t8, 1f
    nop
    jal checkerr
    nop
1:
    addiu   v0, v0, 0x20
    bne v0, s0, 2b
    nop

#endif

#    la  a0, 0x0(v0)
#    bal stringserial
#    nop
#    la  a0, 0x4(v0)
#    PRINTSTR("\r\nHello, Loongson again...\r\n");
#    la  a0, loongsonagain
#    bal stringserial
#    nop



100:
#if 0
	/********enable interrupt**********/
	mfc0	t0, CP0_STATUS
	li	t1, 0xffff00fe
	and	t2, t0, t1 
	li	t1, 0xfc01   
	or	t0, t2, t1
	mtc0	t0, CP0_STATUS
#endif
	li	t0, SRAM_BASEADDR+0xffc
	la	sp, 0(t0)   #

	la	t9, main  
	jr	t9
	nop

1:
	b	1b
	nop

/*********************************************************************************/
##### mac func start
	.align  5
        .ent    mac_test
mac_test:
#    addi    sp, sp, 0xfffc
#    sw      ra, 0(sp)
    move     a3, ra
#read descriptor
    li      a2, 0xa0701100
    li      a1, 0x80000000
    sw      a1, 0x00(a2)
    li      a1, 0x00000100
    sw      a1, 0x04(a2)
    li      a1, 0x007027f0
    sw      a1, 0x08(a2)

#start read process
    li      a2, MAC_BASEADDR
    li      a1, 0x0
    sw      a1, 0x0(a2)
    li      a1, 0x00701000
    sw      a1, 0x20(a2)
    li      a1, 0x00701100
    sw      a1, 0x18(a2)
    li      a1, 0x40000002
    sw      a1, 0x30(a2)

#write gpio to enable virtual mac sw
    li      a0, 0x10
    li      a1, CONFREG_BASE
    sb      a0, 0(a1)
    sb      a0, 0x10(a1)    

#detect read frame
read_interrupt:
    lw      a1, 0x28(a2)
    li      a0, 0xa0700010
    and     a0, a1, 0x40
    beqz    a0, read_interrupt  
    nop

#write descriptor

    li      a2, 0xa0701000
    li      a1, 0x80000000
    sw      a1, 0x00(a2)
    li      a1, 0x62000100
    sw      a1, 0x04(a2)
    li      a1, 0x007027f0
    sw      a1, 0x08(a2)

#start write process
    li      a2, MAC_BASEADDR
    li      a1, 0x00701000
    sw      a1, 0x20(a2)
    li      a1, 0x00701100
    sw      a1, 0x18(a2)
    li      a1, 0x40002002
    sw      a1, 0x30(a2)

    j       a3
    nop
    .end mac_test
##### mac func end

initserial0:
	la 	v0, UART0_BASEADDR
1:
	li 	v1, FIFO_ENABLE|FIFO_RCV_RST|FIFO_XMT_RST|FIFO_TRIGGER_4
	sb	v1, NSREG(NS16550_FIFO)(v0)
	li	v1, CFCR_DLAB                  #DLAB
	sb	v1, NSREG(NS16550_CFCR)(v0)
    li  v1, 0xCF
    sb  v1, NSREG(NS16550_FIFO)(v0)
	li	v1, 0x23                 #set BRDL 57600Baut
	sb	v1, NSREG(NS16550_DATA)(v0)
	srl	v1, 8                                       #no necessary
	sb	v1, NSREG(NS16550_IER)(v0)     #set BRDH    #no necessary
	li	v1, CFCR_8BITS                 #8bit, 1stop
	sb	v1, NSREG(NS16550_CFCR)(v0)
	li	v1, MCR_DTR|MCR_RTS
	sb      v1, NSREG(NS16550_MCR)(v0)
	li      v1, 0x0
	sb      v1, NSREG(NS16550_IER)(v0)

	move    v1, v0
	la      v0, UART0_BASEADDR
	bne     v0, v1, 1b
	nop

	j       ra
	nop




tgt_putchar:
	la	v0, UART0_BASEADDR
1:
	lbu	v1, NSREG(NS16550_LSR)(v0)
	and	v1, LSR_TXRDY
	beqz	v1, 1b
	nop

	sb	a0, NSREG(NS16550_DATA)(v0)
	move	v1,v0
	la	v0, UART0_BASEADDR
	bne	v0,v1,1b
	nop
	j	ra
	nop
	
#if print_hex
hexserial:
	nop
	move	a2, ra
	move	a1, a0
	li	a3, 8
1:
	rol	a0, a1, 4
	move	a1, a0
	and	a0, 0xf
	la	v0, hexchar
	addu	v0, a0
	lbu	a0, 0(v0)
	bal	tgt_putchar
	nop

	addi	a3, -1
	bnez	a3, 1b
	nop

	j	a2
	nop
#endif

PRINT_CP0:
#if print_hex
	move	t0, ra
	PRINTSTR("STATUS=0x")
	mfc0	a0, CP0_STATUS
	bal	hexserial
	nop
	PRINTSTR("\r\n")

	PRINTSTR("CAUSE=0x")
	mfc0	a0, CP0_CAUSE
	bal	hexserial
	nop
	PRINTSTR("\r\n")

	j	t0
	nop
#endif


/*******************************************************************/

	/* Exception handlers.
	 */
romReserved:
        PRINTSTR("Interrupt 1 is coming...\r\n")
	b	romReserved
	nop

romExcHandle:
        PRINTSTR("Interrupt 2 is coming...\r\n")
	b	romExcHandle
	nop

ddr2_config:
    li      t0, 0xbfd00000
    li      t1, 0x1
    sw      t1, 0x0(t0)

    ##########start########
    li     t2, CONFIG_BASE
    li      a1, 0x1
    sb      a1, 0x18(t2)
    #######################

1:
    lb      a1, 0x163(t2)
    beqz    a1, 1b
    nop

    li      t0, 0xbfd00000
    li      t1, 0x0
    sw      t1, 0x0(t0)

    jr      ra
    nop
 
    .global stringserial
	.ent    stringserial
stringserial:
	move	a2, ra
	move 	a1, a0
	lbu	a0, 0(a1)
1:
	beqz	a0, 2f
	nop
	addiu	a1, 1
	bal	tgt_putchar
	nop
	lbu	a0, 0(a1)
	b	1b
	nop
2:
	j	a2
	nop
	.end    stringserial

    .ent checkerr
checkerr:
    la  a0, errstr
    bal stringserial
    nop
    jr ra
    nop
    .end checkerr

	.rdata
	.align	5
msg_nand_test_reset_begin:
    .asciiz "rst\n"
msg_nand_test_reset_end:
    .asciiz "nand rst pass\n"
msg_nand_test_write_begin:
    .asciiz "nand wr go\n"
msg_nand_test_write_end:
    .asciiz "nand write pass \n"
msg_nand_test_read_begin:
    .asciiz "nand rd go\n"
msg_nand_test_read_end:
    .asciiz "nand rd pass\n"
errstr:
    .asciz "error"
loongson:
    .asciz "Loongson Test\n"
loongsonagain:
    .asciz "Loongson Test Twice"
