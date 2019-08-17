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
	c.lt.s $f1, $f2
	bc1f j0
	nop

	ori $3, $0, 0xffff # not reached

j0:
	ori $3, $0, 0x0fff # ans: $3=0x00000fff

	c.lt.s $f2, $f1
	bc1f j1
	nop

	ori $3, $0, 0x00ff # ans: $3=0x000000ff

j1:
	ori $3, $0, 0x000f # ans: $3=0x0000000f

	bc1f j1
	nop
	bc1f j1
	nop

	ori $3, $0, 0xdead # ans: $3=0x0000dead
