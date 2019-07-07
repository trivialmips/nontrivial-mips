	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	# exception outside delayslot
	ori $1, $0, 0x7000
	teqi $1, 0x7f00
	ori $1, $1, 0x0f00
	teqi $1, 0x7f00
	ori $1, $1, 0x00f0

	# exception inside delayslot
	mfhi $1
	j _jump
	teqi $1, 0x0000
	ori $1, 0xf000  # not reached

_jump:
	ori $1, 0x0f00

	.org 0x380    # exception handler
	ori $1, $1, 0x000f
	eret

# ans: $1=0x00007000
# ans: $1=0x00007f00
# ans: $1=0x00007f0f
# ans: $1=0x00007fff

# ans: $1=0x00000000
# ans: $1=0x0000000f
# ans: $1=0x00000f0f
