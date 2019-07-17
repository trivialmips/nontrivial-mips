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
	addiu $3, $3, 1

	.org 0x100
j2:
	addiu  $1, $1, 1  # ans: $1=0x00000001
	addiu  $2, $2, 2  # ans: $2=0x00000002
	addiu  $1, $1, 1  # ans: $1=0x00000002
	addiu  $2, $2, 2  # ans: $2=0x00000004
	addiu  $1, $1, 1  # ans: $1=0x00000003
	addiu  $2, $2, 2  # ans: $2=0x00000006
	addiu  $1, $1, 1  # ans: $1=0x00000004
	addiu  $2, $2, 2  # ans: $2=0x00000008
	addiu  $1, $1, 1  # ans: $1=0x00000005
	addiu  $2, $2, 2  # ans: $2=0x0000000a
	addiu  $1, $1, 1  # ans: $1=0x00000006
	addiu  $2, $2, 2  # ans: $2=0x0000000c
	nop  # unalign branch
	jr $31
	ori   $3, $0, 0x0010  # ans: $3=0x00000010

	#   jr $20, mispredict
	#	addiu $3, $3, 1
	# ans: $3=0x00000011

	.org 0x200
j1:
	addiu $3, $3, 1 # ans: $3=0x00000012
	addiu $3, $3, 1 # ans: $3=0x00000013
	lui $4, 0xdead # ans: $4=0xdead0000
