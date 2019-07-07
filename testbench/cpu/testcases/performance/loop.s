	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	ori $3, $0, 0x400
j1:
	addu $1, $1, $2
	bne $2, $3, j1
	addiu $2, $2, 1

	ori $10, $0, 0x850
