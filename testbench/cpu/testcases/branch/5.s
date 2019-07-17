	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
	la $20, j1  # ans: skip
	            # ans: skip
	b j2
	nop

	.org 0x100
j2:
	addiu  $1, $1, 1  # ans: $1=0x00000001
	addiu  $2, $2, 2  # ans: $2=0x00000002
	lui    $5, 0x8000 # ans: $5=0x80000000
	# cache miss
	lw     $7, 0x100($5)  # ans: $7=0x00000000
	# cache miss
	lw     $6, 0($5)      # ans: $6=0x00000000
	jr $20    # load-related on unaligned branch, mispredict
	addiu  $3, $6, 0x0010  # ans: $3=0x00000010

	.org 0x200
j1:
	addiu $3, $3, 1 # ans: $3=0x00000011
	addiu $3, $3, 1 # ans: $3=0x00000012
	lui $4, 0xdead # ans: $4=0xdead0000
