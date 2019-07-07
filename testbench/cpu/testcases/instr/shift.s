	.org 0x0
	.global _start
	.set noat
_start:
	lui $1, 0x8040      # ans: $1=0x80400000
	ori $1, 0x4040      # ans: $1=0x80404040
	lui $2, 0x0040      # ans: $2=0x00400000
	ori $2, 0x4040      # ans: $2=0x00404040
	ori $5, 0xff04      # ans: $5=0x0000ff04

	sllv $2, $2, $5     # ans: $2=0x04040400
	sll  $2, $2, 8      # ans: $2=0x04040000
	srl  $3, $1, 8      # ans: $3=0x00804040
	srlv $3, $3, $5     # ans: $3=0x00080404
	sra  $4, $1, 8      # ans: $4=0xff804040
	srav $4, $4, $5     # ans: $4=0xfff80404
