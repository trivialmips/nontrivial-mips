	.org 0x0
	.global _start
	.set noat
_start:
	lui $1, 0xf00f      # ans: $1=0xf00f0000
	lui $2, 0x5555      # ans: $2=0x55550000
	ori $3, $2, 0xaaaa  # ans: $3=0x5555aaaa

	movz $3, $1, $3     # not moved
	ori  $3, $3, 0x0000 # ans: $3=0x5555aaaa

	movz $3, $1, $0     # ans: $3=0xf00f0000

	movn $3, $2, $2     # ans: $3=0x55550000
	movn $3, $1, $0     # not moved
	ori  $3, $3, 0x0000 # ans: $3=0x55550000

	lui $3, 0xffac      # ans: $3=0xffac0000
	mthi $3   # ans: $hilo=0xffac000000000000
	mthi $2   # ans: $hilo=0x5555000000000000
	mthi $1   # ans: $hilo=0xf00f000000000000
	mfhi $4   # ans: $4=0xf00f0000

	mtlo $1   # ans: $hilo=0xf00f0000f00f0000
	mtlo $2   # ans: $hilo=0xf00f000055550000
	mtlo $3   # ans: $hilo=0xf00f0000ffac0000
	mflo $5   # ans: $5=0xffac0000
	mfhi $5   # ans: $5=0xf00f0000
