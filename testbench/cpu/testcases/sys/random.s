	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	mfc0  $1, $1   # ans: $1=0x0000000f
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000000
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000001
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000002
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000003
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000004
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000005
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000006
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000007
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000008
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000009
	tlbwr
	mfc0  $1, $1   # ans: $1=0x0000000a
	tlbwr
	mfc0  $1, $1   # ans: $1=0x0000000b
	tlbwr
	mfc0  $1, $1   # ans: $1=0x0000000c
	tlbwr
	mfc0  $1, $1   # ans: $1=0x0000000d
	tlbwr
	mfc0  $1, $1   # ans: $1=0x0000000e
	tlbwr
	mfc0  $1, $1   # ans: $1=0x0000000f
	tlbwr
	mfc0  $1, $1   # ans: $1=0x00000000
