	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	lui $s0, 0xa000        # ans: skip
	ori $s0, $s0, 0x1000   # ans: $16=0xa0001000

	lui $1, 0x1234         # ans: skip
	ori $1, $1, 0x5678     # ans: $1=0x12345678

	sw $1, 0x0($s0)    # ans: [0x1000]=0x12345678
	sw $s0, 0x4($s0)   # ans: [0x1004]=0xa0001000

	# ===== Test unaligned address =====
	sw $1, 0x3($s0)    # ans: [exc_code]=0x05
	sw $1, 0x2($s0)    # ans: [exc_code]=0x05
	lw $1, 0x2($s0)    # ans: [exc_code]=0x04
	mfc0 $8, $8        # ans: $8=0xa0001002
	sw $1, 0x1($s0)    # ans: [exc_code]=0x05
	lw $1, 0x1($s0)    # ans: [exc_code]=0x04
	lw $1, 0x3($s0)    # ans: [exc_code]=0x04

	sh $1, 0x1($s0)    # ans: [exc_code]=0x05
	mfc0 $8, $8        # ans: $8=0xa0001001
	lh $1, 0x1($s0)    # ans: [exc_code]=0x04
	mfc0 $8, $8        # ans: $8=0xa0001001
	lhu $1, 0x3($s0)   # ans: [exc_code]=0x04
	mfc0 $8, $8        # ans: $8=0xa0001003

	ll $1, 0x1($s0)    # ans: [exc_code]=0x04
	mfc0 $8, $8        # ans: $8=0xa0001001
	sc $3, 0x0($s0)    # ans: $3=0x00000000

	ll $3, 0x0($s0)    # ans: $3=0x12345678
	sc $4, 0x1($s0)    # ans: [exc_code]=0x05
	sc $4, 0x0($s0)    # ans: $4=0x00000000

	# ===== Test SYSCALL/BREAK =====
	syscall   # ans: [exc_code]=0x08
	break     # ans: [exc_code]=0x09

	# ===== Test trap =====
	teq $0, $0  # ans: [exc_code]=0x0d

	# ===== Test overflow =====
	lui $1, 0x7fff  # ans: $1=0x7fff0000
	add $1, $1, $1  # ans: [exc_code]=0x0c
	ori $1, $1, 0x0000 # ans: $1=0x7fff0000

	# ===== Test TLB invalid =====
	ori $1, $0, 0x0000 # ans: $1=0x00000000
	sw $1, 0x0($1)     # ans: [exc_code]=0x03
	mfc0 $8, $8        # ans: $8=0x00000000
	lw $1, 0x0($1)     # ans: [exc_code]=0x02

	# ===== Test TLB miss =====
	ori $1, $0, 0x1000 # ans: $1=0x00001000
	sw $1, 0x0($1)     # ans: [exc_code]=0x03
	mfc0 $8, $8        # ans: $8=0x00001000
	lw $1, 0x0($1)     # ans: [exc_code]=0x02

	# ===== Test TLB modification =====
	mtc0 $0, $0
	tlbr
	ori $1, $0, 0x0003   # ans: $1=0x00000003
	ssnop
	ssnop
	ssnop
	mtc0 $1, $2
	mtc0 $1, $3
	tlbwi
	ssnop
	ssnop
	ssnop
	ori $1, $0, 0x0000 # ans: $1=0x00000000
	sw $1, 0x0($1)     # ans: [exc_code]=0x01
	lw $1, 0x0($1)     # ans: $1=0x00000000

	ori $5, $0, 0xdead  # ans: $5=0x0000dead

.org 0x200
	# exception handler for TLBL/TLBS
	# return to next instruction
	mfc0 $30, $14       # skip
	addi $30, $30, 0x4  # skip
	mtc0 $30, $14
	mfc0 $29, $13       # skip
	andi $29, $29, 0x007c  # cause.exc_code, skip
	srl $29, $29, 2     # check
	eret

.org 0x380
	# exception handler
	# return to next instruction
	mfc0 $30, $14       # skip
	addi $30, $30, 0x4  # skip
	mtc0 $30, $14
	mfc0 $29, $13       # skip
	andi $29, $29, 0x007c  # cause.exc_code, skip
	srl $29, $29, 2     # check
	eret
