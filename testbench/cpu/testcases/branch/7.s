	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
	la $20, j1  # ans: skip
	            # ans: skip
	lui    $5, 0x8000 # ans: $5=0x80000000
	nop
	b j2
	nop

	.org 0x100
j2:
	addiu  $1, $1, 1  # ans: $1=0x00000001
	# cache miss
	lw     $7, 0x100($5)  # ans: $7=0x00000000
	nop
	nop
	nop
	jr $20    # load-related (D$) on unaligned branch, mispredict
	addiu  $3, $7, 0x0010  # ans: $3=0x00000010

	.org 0x200
j1:
	addiu $3, $3, 1 # ans: $3=0x00000011
	addiu $3, $3, 1 # ans: $3=0x00000012
	lui $4, 0xdead # ans: $4=0xdead0000
