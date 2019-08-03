	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
	lui $21, 0x8000    # ans: skip
	la $20, j1  # ans: skip
	            # ans: skip
	or $20, $20, $21 # ans: skip
	jal j2      # ans: skip
	nop
	jr $20
	lui $3, 0xde
	lui $3, 0xdf  # not exec
	lui $3, 0xe0  # not exec

	.org 0x100
j2:
	addiu  $1, $1, 1  # ans: $1=0x00000001
	addiu  $2, $2, 2  # ans: $2=0x00000002
	lui    $5, 0x8000 # ans: $5=0x80000000
	nop  # unalign branch
	nop
	nop
	jr $31
	ori   $3, $0, 0x0010  # ans: $3=0x00000010

	#   jr $20    [ mispredict w/o stall ]
	#	addiu $3, $3, 1
	# ans: $3=0x00de0000

	.org 0x200
j1:
	addiu $3, $3, 1 # ans: $3=0x00de0001
	addiu $3, $3, 1 # ans: $3=0x00de0002
	lui $4, 0xdead # ans: $4=0xdead0000
