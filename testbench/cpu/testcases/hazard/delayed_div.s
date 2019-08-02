	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	lui $4, 0xffff      # ans: skip
	ori $4, $4, 0xfff1  # ans: $4=0xfffffff1
	ori $5, $0, 0x0011  # ans: $5=0x00000011
	b do
	nop
	nop
	nop
	nop
fetch_result:
	lui $9, 0xdead

do_div:
	b fetch_result
	mfhi $3

do:
	b do_div
	div   $zero, $4, $5  # ans: $hilo=0xfffffff100000000
	break 0x07

# ans: $3=0xfffffff1
# ans: $9=0xdead0000
