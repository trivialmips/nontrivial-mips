	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	ori $1, $0, 0x0001  # ans: $1=0x00000001
	ori $2, $0, 0x0002  # ans: $2=0x00000002
	ori $3, $0, 0x0003  # ans: $3=0x00000003
	mfc0 $9, $11        # ans: $9=0x00000000

	b j1
	mtc0 $1, $11
	nop

j1:
	b j2
	mfc0 $9, $11        # ans: $9=0x00000001

.org 0x60
j2:
	b j3
	mtc0 $2, $11

.org 0x80
j3:
	bnez $0, j1
	mfc0 $8, $11        # ans: $8=0x00000002
	b j4
	mtc0 $3, $11
	mtc0 $1, $11

j4:
	b j3
	mfc0 $9, $11        # ans: $9=0x00000003

# ans: $8=0x00000003
# ans: $9=0x00000003
