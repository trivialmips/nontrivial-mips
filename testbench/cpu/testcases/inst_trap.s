	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	ori $1, $0, 0x1000  # ans: $1=0x00001000
	ori $2, $0, 0x1000  # ans: $2=0x00001000
	teq $1, $2
	# ans: skip
	# ans: skip
	ori $1, $1, 0x0110  # ans: $1=0x00001110
	teq $1, $2

	ori $1, $1, 0x0000  # ans: $1=0x00001110
	tne $1, $2
	# ans: skip
	# ans: skip

	tnei $2, 0x1110
	# ans: skip
	# ans: skip

	lui  $1, 0xffff  # ans: $1=0xffff0000
	ori  $1, 0x8000  # ans: $1=0xffff8000
	teqi $1, 0x8000  # test signed-ext
	# ans: skip
	# ans: skip

	ori $2, $0, 0x4000  # ans: $2=0x00004000
	tge $2, $1
	# ans: skip
	# ans: skip

	tgeu $2, $1
	ori $1, $1, 0x0000  # ans: $1=0xffff8000

	tgei $1, 0xf000
	ori $1, $1, 0x0000  # ans: $1=0xffff8000

	tgeiu $2, 0x0000   
	# ans: skip
	# ans: skip

	tgeiu $4, 0x0000   
	# ans: skip
	# ans: skip

	tlt $1, 0x0000
	# ans: skip
	# ans: skip

	tltu $1, 0x0000
	ori $1, $1, 0xf000  # ans: $1=0xfffff000

	tltiu $2, 0x7fff 
	# ans: skip
	# ans: skip

	tlti $1, 0xffff
	# ans: skip
	# ans: skip

.org 0x380
	# exception handler
	mfc0 $30, $14
	addi $30, $30, 0x4
	mtc0 $30, $14
	eret
