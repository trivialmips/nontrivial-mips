	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
    lui $5, 0xa000        # ans: $5=0xa0000000
	ori $5, $5, 0x1000    # ans: $5=0xa0001000
	ori $1, $0, 0x1234    # ans: $1=0x00001234
	sw  $1, 0x0($5)       # ans: [0x1000]=0x00001234
	ori $2, $0, 0x5678    # ans: $2=0x00005678

	# SC without LL
	sc  $2, 0x0($5)       # ans: $2=0x00000000
	lw  $2, 0x0($5)       # ans: $2=0x00001234

	# atomic LL/SC
	ori $2, $0, 0x0000    # ans: $2=0x00000000
	ll  $2, 0x0($5)       # ans: $2=0x00001234
	addi $2, $2, 1        # ans: $2=0x00001235
	ori $3, $2, 0x0000    # ans: $3=0x00001235
	sc  $2, 0x0($5)       # ans: skip
	                      # ans: skip
	ori $9, $2, 0         # ans: $9=0x00000001
	lw  $2, 0x0($5)       # ans: $2=0x00001235

	ll $4, 0x0($5)        # ans: $4=0x00001235
	sc $4, 0x4($5)        # ans: skip
                          # ans: skip
	ori $9, $4, 0         # ans: $9=0x00000001

	# broken LL/SC
	ll  $1, 0x0($5)       # ans: $1=0x00001235
	addi $1, $1, 1        # ans: $1=0x00001236
	teq $1, $1
	# ans: skip
	# ans: skip
	sc  $1, 0x0($5)       # ans: $1=0x00000000
	lw  $1, 0x0($5)       # ans: $1=0x00001235

.org 0x380
	# exception handler
	mfc0 $30, $14
	addi $30, $30, 0x4
	mtc0 $30, $14
	eret
