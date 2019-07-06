	.org 0x0
	.global _start
	.set noat
_start:
    # enable the interrupt
	mfc0 $1, $12        # ans: skip
	ori $1, $1, 0xff01  # ans: skip
	mtc0 $1, $12

	# use the special interrupt vector
	mfc0 $1, $13      # ans: skip
	lui $2, 0x0080    # ans: $2=0x00800000
	or $1, $2, $1     # ans: skip
	mtc0 $1, $13

	ori $3, $0, 0x0000 # ans: $3=0x00000000
	ori $2, $0, 0x1111 # ans: $2=0x00001111

_wait_int:
	bne $2, $3, _wait_int
	nop
	# ans: $3=0x00001111
	# ans: skip
	# ans: skip
	# ans: skip
	# ans: skip
	# ans: $29=0x00000000

	ori $1, $0, 0xdead  # ans: $1=0x0000dead

.org 0x400
	ori $3, $0, 0x1111
	mfc0 $30, $14       # skip
	addi $30, $30, 0x4  # skip
	mtc0 $30, $14
	mfc0 $29, $13       # skip
	andi $29, $29, 0x007c  # cause.exc_code, skip
	srl $29, $29, 2     # check
	eret
