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
	la $20, 0x80001000  # ans: skip
	                    # ans: $20=0x80001000
	sw $1, 0x0($20)    # ans: [0x1000]=0x40133333
	sw $2, 0x4($20)    # ans: [0x1004]=0xc0966666
	b p0
	ssnop
	ssnop
	ssnop

p0:
	lwc1 $f1, 0x0($20)
	lwc1 $f2, 0x4($20)
	div.s $f0, $f1, $f1
	addiu $9, $0, 0x1  # ans: skip
	sub.s $f2, $f2, $f0
	mul.s $f3, $f2, $f2
	sub.s $f0, $f2, $f1
	mul.s $f0, $f0, $f1
	cfc1 $4, $31   # ans: skip
	mfc1 $3, $f3   # ans: $3=0x4201f5c2
	mfc1 $2, $f2   # ans: $2=0xc0b66666
	mfc1 $1, $f1   # ans: $1=0x40133333
	mfc1 $9, $f0   # ans: $9=0xc1933333
