	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	lui  $1, 0x8000     # ans: $1=0x80000000
	sw  $1, 4($1)       # ans: [0x0004]=0x80000000
	addiu  $2, $1, 0x10     # ans: $2=0x80000010
	sw  $2, 0($1)       # ans: [0x0000]=0x80000010
	lw  $3, 4($1)       # ans: $3=0x80000000
	lw  $4, 0($3)       # ans: $4=0x80000010

	lui $30, 0xface # ans: skip

	b j0
	sw $30, 0($4)  # ans: [0x0010]=0xface0000
.org 0x40
j0:
	b j1
	lw $5, 4($1)    # ans: $5=0x80000000
	lui $10, 0x8000
j1:
	b j2
	lw $6, 0($5)    # ans: $6=0x80000010
	lui $10, 0x8000
j2:
	lw $7, -16($6)   # ans: $7=0x80000010
	lw $7, 0($7)     # ans: $7=0xface0000
	b j3
	nop

.org 0x80
j3:
	lw $8, 4($1)    # ans: $8=0x80000000
	lw $8, 0($8)    # ans: $8=0x80000010
	lw $8, -12($8)  # ans: $8=0x80000000
	lw $8, 0($8)    # ans: $8=0x80000010
	lw $8, -16($8)  # ans: $8=0x80000010
	lw $8, 0($8)    # ans: $8=0xface0000
	lui $8, 0xdead  # ans: $8=0xdead0000
	
