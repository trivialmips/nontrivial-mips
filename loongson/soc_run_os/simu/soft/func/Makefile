TOPDIR = $(shell pwd)

CROSS_COMPILE = mipsel-linux-
DEBUG = -g
FLAGS = 

CC	= $(CROSS_COMPILE)gcc
LD	= $(CROSS_COMPILE)ld
OBJCOPY	= $(CROSS_COMPILE)objcopy
OBJDUMP	= $(CROSS_COMPILE)objdump
AR	= $(CROSS_COMPILE)ar

export TOPDIR AR CC DEBUG FLAGS

all:test.bin convert
	./convert
	$(OBJDUMP) -ald test >test.s

libtinyc.a:
	make -C lib $(TOPDIR)/$@

start.o:start.S include/ls1d.h include/asm/mipsregs.h include/asm/regdef.h include/asm/ns16550.h
	$(CC) $(DEBUG) $(FLAGS) -mips32 -EL -c -o $@ $<    

nand.o:nand_test.S include/ls1d.h include/asm/mipsregs.h include/asm/regdef.h include/asm/ns16550.h
	$(CC) $(DEBUG) $(FLAGS) -mips32 -EL -c -o $@ $<    

main.o:main.c  include/*.h
	$(CC) $(DEBUG) $(FLAGS) -EL -c -o $@ $<

%.o:source/%.c include/%.h include/ls1d.h 
	$(CC) $(DEBUG) $(FLAGS) -EL -c -o $@ $<

#test_cycle.o  myprintf.o
OBJ1	= Interrupt.o lcd.o SystemInit.o Calendar.o key.o battery.o common.o temp_flow.o Infrare.o frame.o MonthData.o isp.o adc.o cmdline.o flash.o dg_rs232.o

test:start.o nand.o main.o $(OBJ1) libtinyc.a
	$(LD) -T test.lds -Ttext 0xBFC00000 -Map test.map start.o nand.o main.o $(OBJ1) -o $@ -L . -ltinyc 
	#rm -f *.o

test.bin:test
	$(OBJCOPY) --gap-fill=0xff -O binary $< $@

clean:
	rm -f *.o *.a test test.bin test.map test.s convert flash.vlog
	make -C lib clean
convert:convert.c
	gcc -o convert convert.c
