	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	lui  $1, 0x8000     # ans: $1=0x80000000
	sw  $1, 4($1)       # ans: [0x0004]=0x80000000
	ssnop
	ssnop
	ssnop
	ssnop
	ssnop
	ssnop
	nop
	nop
	lw  $2, 4($1)    # ans: $2=0x80000000
	addiu $3, $0, 1  # ans: $3=0x00000001
	addiu $2, $2, 4  # ans: $2=0x80000004
	addiu $4, $2, -4 # ans: $4=0x80000000
	bnez $4, j0
	lw  $9, 0($2)  # ans: $9=0x80000000
	ssnop
j0:
	ssnop
	ssnop
	ssnop
	lui $8, 0xdead  # ans: $8=0xdead0000
