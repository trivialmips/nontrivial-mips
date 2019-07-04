	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
	nop
	jr $0
	nop
	nop
	nop
	jr $0
	nop
	nop
	nop
	nop
	nop
	nop

# %BEGIN CONTROLFLOW%
# 0 None
# 1 JumpReg 5
# 2 None
# 5 JumpReg 8
# 6 None
# 8 None
# 9 None
# 10 None
# 11 None
# %END CONTROLFLOW%
