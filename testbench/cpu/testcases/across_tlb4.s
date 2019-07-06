	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	la   $10, 0x12340000 # ans: $10=0x12340000
	# FPN1=0x0000, FPN2=0x2000
	la   $11, 0x2        # ans: $11=0x00000002
	la   $12, 0x82       # ans: $12=0x00000082
	# $10 = VPN2, $11 = FPN1, $12 = FPN2
	mtc0 $10, $10       # entry_hi
	mtc0 $11, $2        # entry_lo0
	mtc0 $12, $3        # entry_lo1
	mtc0 $0, $0         # index
	tlbwi
	nop
	nop
	nop

	addi $10, $10, 0xffc # ans: $10=0x12340ffc
	jr $10

.org 0x0ffc
	jr $10
	ori $4, $0, 0xdead   # PA=0x1000, not in TLB

	# pc = 0x1000 (PA=0x2000)
.org 0x2000
	ori $5, $0, 0x2333   # ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
	# ans: $5=0x00002333
