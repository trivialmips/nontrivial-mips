	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	ori $1, $0, 0xf000  # ans: $1=0x0000f000
	j   j1
	ori $1, $1, 0x0f00  # ans: $1=0x0000ff00
	ori $1, $1, 0x00f0  # not reached
	ori $1, $1, 0x000f  # not reached

	.org 0x20
j1:
	ori $1, $1, 0x0010  # ans: $1=0x0000ff10
	ori $3, $0, 0x0005  # ans: $3=0x00000005
	jal j_with_link31   # ans: skip
	nop
	jr  $5
	nop
	# ans: $2=0x00000001
	# ans: skip
	# ans: $2=0x00000003
	# ans: $2=0x00000005

j2:
	bne $2, $3, j3
	nop
	bgezal $2, j3 # ans: skip
	# ans: $2=0x80000000
	nop
	sra    $2, 0x1 # ans: $2=0xc0000000
	bltzal $2, j3  # ans: skip
	# ans: $2=0x80000000
	nop
	bgezal $2, j3 # ans: skip
	nop
	bgez $2, j4
	ori $2, $0, 0x0000 # ans: $2=0x00000000
	jr $31
	nop
	# ans: $2=0x00000000

j4:
	bltz $2, j3  # no jump
	nop
	bne $2, $1, j4
	ori $2, $1, 0x0000  # ans: $2=0x0000ff10
	# ans: $2=0x0000ff10

	blez $2, j4
	lui $2, 0x0000  # ans: $2=0x00000000
	blez $2, j5
	nop
	ori $2, $2, 0xffac

j5:
	bgtz $2, j5
	lui $2, 0x0fff  # ans: $2=0x0fff0000
j6:
	bgtz $2, j6
	lui $2, 0x0000  # ans: $2=0x00000000
	# ans: $2=0x00000000
	lui $3, 0xffff # ans: $3=0xffff0000
# [END]
	nop

j3:
	lui $2, 0x8000
	jr $31
	nop

j_with_link31:
	addi $2, $2, 0x0001
	jalr $5, $31
	nop
	addi $2, $2, 0x0002
	beq  $2, $3, j2
	nop
	jr  $5
	nop
