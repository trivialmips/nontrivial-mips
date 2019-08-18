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

	la $16, 0x80001000  # ans: skip
	                    # ans: $16=0x80001000
	mtc1 $1, $f1
	mtc1 $2, $f2
	sdc1 $f20, 16($16)    # ans: [0x1010]=0x40133333
                          # ans: [0x1014]=0xc0966666
	sdc1 $f20, 32($16)    # ans: [0x1020]=0x40133333
                          # ans: [0x1024]=0xc0966666
	ldc1 $f22, 16($16)
	ldc1 $f24, 32($16)
	ldc1 $f26, 16($16)
	mfc1 $22, $f22        # ans: $22=0x40133333
	mfc1 $23, $f23        # ans: $23=0xc0966666
	mfc1 $24, $f24        # ans: $24=0x40133333
	mfc1 $25, $f25        # ans: $25=0xc0966666
	mfc1 $26, $f26        # ans: $26=0x40133333
	mfc1 $27, $f27        # ans: $27=0xc0966666
