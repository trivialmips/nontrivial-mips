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
	syscall
	lui $3, 0xdf 
	lui $3, 0xe0
	b j1
	nop

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
	#	syscall
	# ans: [exc_code]=0x08
	# ans: $3=0x00df0000
	# ans: $3=0x00e00000

	.org 0x200
j1:
	addiu $3, $3, 1 # ans: $3=0x00e00001
	addiu $3, $3, 1 # ans: $3=0x00e00002
	lui $4, 0xdead # ans: $4=0xdead0000

.org 0x380
	# exception handler
	# return to next instruction
	mfc0 $30, $14       # skip
	addi $30, $30, 0x8  # skip
	mtc0 $30, $14
	mfc0 $29, $13       # skip
	andi $29, $29, 0x007c  # cause.exc_code, skip
	srl $29, $29, 2     # check
	eret
