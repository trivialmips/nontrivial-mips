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

	addi $10, $10, 0xff8 # ans: $10=0x12340ff8
	jr $10

.org 0x0ff8
	ori $2, $0, 0x0002   # ans: $2=0x00000002
	ori $3, $0, 0x0003   # ans: $3=0x00000003
	ori $4, $0, 0xdead   # PA=0x1000, not in TLB
	ori $5, $0, 0xdeaf
	ori $5, $0, 0xdeae

	# pc = 0x1000 (PA=0x2000)
.org 0x2000
	ori $5, $0, 0x2333   # ans: $5=0x00002333
	ori $6, $0, 0x1333   # ans: $6=0x00001333
	ori $7, $0, 0x0333   # ans: $7=0x00000333
