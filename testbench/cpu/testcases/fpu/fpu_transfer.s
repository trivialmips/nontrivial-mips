	.org 0x0
	.global _start
	.set noat
_start:
	# 2.3
	la $1, 0x40133333 # ans: skip
	                  # ans: $1=0x40133333
	# -4.7
	la $2, 0xc0966666 # ans: skip
	                  # ans: $2=0xc0966666
	mtc1 $1, $f1
	mtc1 $2, $f2

	# ==== conditional/unconditional move ====
	mov.s $f3, $f1
	mfc1 $5, $f3     # ans: $5=0x40133333
	movn.s $f1, $f2, $0
	mfc1 $6, $f1     # ans: $6=0x40133333
	movn.s $f3, $f2, $6
	mfc1 $5, $f3     # ans: $5=0xc0966666

	movz.s $f3, $f1, $0
	mfc1 $7, $f3     # ans: $7=0x40133333
	movz.s $f3, $f2, $7
	mfc1 $8, $f3     # ans: $8=0x40133333

	# ==== load and store ====
	la $16, 0x80001000  # ans: skip
	                    # ans: $16=0x80001000
	ssnop
	nop
	swc1 $f1, 0x00($16) # ans: [0x1000]=0x40133333
	lwc1 $f9, 0x00($16)
	mfc1 $9, $f9        # ans: $9=0x40133333
	ssnop
	nop
	lwc1 $f12, 0x00($16)
	mfc1 $12, $f12        # ans: $12=0x40133333

	# ==== doubleword load and store ====
	sw $2, 4($16)       # ans: [0x1004]=0xc0966666
	ldc1 $f20, 0($16)
	mfc1 $20, $f20        # ans: $20=0x40133333
	mfc1 $21, $f21        # ans: $21=0xc0966666
	sdc1 $f20, 16($16)    # ans: [0x1010]=0x40133333
                          # ans: [0x1014]=0xc0966666
	sdc1 $f20, 32($16)    # ans: [0x1020]=0x40133333
                          # ans: [0x1024]=0xc0966666
	ldc1 $f22, 0($16)
	ldc1 $f24, 0($16)
	ldc1 $f26, 0($16)
	mfc1 $22, $f22        # ans: $22=0x40133333
	mfc1 $23, $f23        # ans: $23=0xc0966666
	mfc1 $24, $f24        # ans: $24=0x40133333
	mfc1 $25, $f25        # ans: $25=0xc0966666
	mfc1 $26, $f26        # ans: $26=0x40133333
	mfc1 $27, $f27        # ans: $27=0xc0966666
