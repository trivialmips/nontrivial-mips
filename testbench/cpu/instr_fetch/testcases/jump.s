	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
	nop
	j dest_1
	nop
	nop
	nop
dest_1:
	j dest_2
	nop
	nop
dest_2:
	nop

# %BEGIN CONTROLFLOW%
# 1,None
# 2,JumpImm
# 3,None
# 6,JumpImm
# 7,None
# 9,None
# %END CONTROLFLOW%
