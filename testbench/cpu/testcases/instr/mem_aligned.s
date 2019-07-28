	.org 0x0
	.global _start
	.set noat
_start:
	lui $s0, 0xa000      # ans: $16=0xa0000000
    ori $s0, $s0, 0x1000 # ans: $16=0xa0001000
	ori  $2, $0, 0x0001  # ans: $2=0x00000001
	lui  $4, 0xa000      # ans: $4=0xa0000000
	ori  $4, $4, 0x1004  # ans: $4=0xa0001004
	ori  $1, $0, 0xff00  # ans: $1=0x0000ff00
	sw   $4, 0xc($s0)    # ans: [0x100c]=0xa0001004
	sw   $1, 0x4($s0)    # ans: [0x1004]=0x0000ff00

	# not-load-related
	lw   $2, 0x4($4)    # ans: $2=0x00000000

	# load-related (arithmetic after load)
	lw   $2, 0x0($4)    # ans: $2=0x0000ff00
	ori  $2, $2, 0x0001 # ans: $2=0x0000ff01

	# load-related (store after load)
	lw   $1, 0x4($s0)    # ans: $1=0x0000ff00
	sw   $1, 0x8($s0)    # ans: [0x1008]=0x0000ff00
	lw   $3, 0x8($s0)    # ans: $3=0x0000ff00

	# load-related (branch after load)
	lw   $5, 0xc($s0)    # ans: $5=0xa0001004
	beq  $5, $4, j0 
	nop

	ori $9, $0, 0       # skip
j0:
	lui $1, 0xccdd      # ans: $1=0xccdd0000
	ori $1, $1, 0xffaa  # ans: $1=0xccddffaa
	sb  $1, 0x4($s0)    # ans: skip
	srl $1, $1, 8       # ans: skip
	sb  $1, 0x6($s0)    # ans: skip
	srl $1, $1, 8       # ans: skip
	sb  $1, 0x7($s0)    # ans: skip
	srl $1, $1, 8       # ans: skip
	sb  $1, 0x5($s0)    # ans: skip

	lw  $9, 0x4($s0)    # ans: $9=0xddffccaa

	lbu $1, 0x6($s0)    # ans: $1=0x000000ff
	lb  $1, 0x6($s0)    # ans: $1=0xffffffff

	ori $3, $0, 0x8122  # ans: skip
	sh  $3, 0x4($s0)    # ans: skip
	lh  $3, 0x4($s0)    # ans: $3=0xffff8122
	lhu $3, 0x4($s0)    # ans: $3=0x00008122
	lw  $10, 0x4($s0)   # ans: $10=0xddff8122

	ori $3, $0, 0xfb57  # ans: skip
	sh  $3, 0x6($s0)    # ans: skip
	lhu $3, 0x6($s0)    # ans: $3=0x0000fb57
	lh  $3, 0x6($s0)    # ans: $3=0xfffffb57
	lw  $10, 0x4($s0)   # ans: $10=0xfb578122
