	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	ori $1, $0, 0x0001  # ans: $1=0x00000001
	ori $2, $0, 0x0002  # ans: $2=0x00000002
	ori $3, $0, 0x0003  # ans: $3=0x00000003
	mfc0 $9, $11        # ans: $9=0x00000000
	nop
	nop
	mtc0 $1, $11
	nop
	nop
	mfc0 $9, $11        # ans: $9=0x00000001
	mtc0 $2, $11
	mfc0 $9, $11        # ans: $9=0x00000002
	mtc0 $1, $11
	mtc0 $3, $11
	mfc0 $9, $11        # ans: $9=0x00000003
	nop
	nop
	lui $10, 0xdead   # ans: $10=0xdead0000
