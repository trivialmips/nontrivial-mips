	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	ori $3, $0, 0x400
	la  $30, plus_1
	lui $29, 0xbfc0
	or  $30, $30, $29
	nop

j1:
	jalr $29, $30
	nop
	bne $2, $3, j1
	addiu $2, $2, 1

	lui $10, 0x1200
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

plus_1:
	addu $1, $1, $2
	jr $29  # address = j1 + 32 * 4
	nop
