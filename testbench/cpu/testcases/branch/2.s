	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
	la $20, j1  # ans: skip
	            # ans: skip
	jal j2      # ans: skip
	nop
	jr $20
	lui $3, 0xde

	.org 0x100
j2:
	addiu  $1, $1, 1  # ans: $1=0x00000001
	addiu  $2, $2, 2  # ans: $2=0x00000002
	lui    $5, 0x8000 # ans: $5=0x80000000
	nop  # unalign branch
	# cache miss
	sw     $1, 0x100($5)  # ans: [0x0100]=0x00000001
	# cache miss
	sw     $2, 0($5)      # ans: [0x0000]=0x00000002
	jr $31
	ori   $3, $0, 0x0010  # ans: $3=0x00000010

	#   jr $20    [ mispredict on memory stall ]
	#	addiu $3, $3, 1
	# ans: $3=0x00de00

	.org 0x200
j1:
	addiu $3, $3, 1 # ans: $3=0x00de0012
	addiu $3, $3, 1 # ans: $3=0x00de0013
	lui $4, 0xdead # ans: $4=0xdead0000
