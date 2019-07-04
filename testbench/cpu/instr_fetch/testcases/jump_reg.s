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
	j _start
	nop

# %BEGIN CONTROLFLOW%
# 0 None
# 1 JumpReg 5 1
# 2 None
# 5 JumpReg 8 1
# 6 None
# 8 None
# 9 None
# 10 JumpImm
# 11 None
# 0 None
# 1 JumpReg 5 0
# 2 None
# 5 JumpReg 8 0
# 6 None
# 8 None
# 9 None
# 10 JumpImm
# 11 None
# 0 None
# 1 JumpReg 5 0
# 2 None
# 5 JumpReg 8 0
# 6 None
# 8 None
# 9 None
# %END CONTROLFLOW%
