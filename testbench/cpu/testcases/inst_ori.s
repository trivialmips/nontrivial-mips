	.org 0x0
	.global _start
	.set noat
_start:
	ori $1, $1, 0x8000  # ans: $1=0x00008000
	ori $1, $1, 0x0800  # ans: $1=0x00008800
	ori $1, $1, 0x0080  # ans: $1=0x00008880
	ori $1, $1, 0x0008  # ans: $1=0x00008888
	ori $1, $1, 0x1000  # ans: $1=0x00009888
	ori $1, $1, 0x0100  # ans: $1=0x00009988
	ori $1, $1, 0x0010  # ans: $1=0x00009998
	ori $1, $1, 0x0001  # ans: $1=0x00009999
