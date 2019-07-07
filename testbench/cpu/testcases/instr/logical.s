	.org 0x0
	.global _start
	.set noat
_start:
	lui $1, 0xf00f      # ans: $1=0xf00f0000
	ori $2, $1, 0xf000  # ans: $2=0xf00ff000
	and $3, $1, $2      # ans: $3=0xf00f0000
	xor $4, $1, $2      # ans: $4=0x0000f000
	nor $5, $3, $4      # ans: $5=0x0ff00fff
	or  $6, $5, $4      # ans: $6=0x0ff0ffff
	andi $6, $6, 0xff00 # ans: $6=0x0000ff00
	xori $6, $6, 0x0f0f # ans: $6=0x0000f00f
