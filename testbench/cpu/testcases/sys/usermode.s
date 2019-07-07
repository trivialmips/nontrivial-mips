	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	# setup cp0
	la $1, 0x80001000   # ans: skip
	                    # ans: $1=0x80001000
	mtc0 $1, $15, 1     # ebase
	mtc0 $0, $10        # entry_hi.ASID = 0
	mtc0 $0, $12        # status.bev = 0

    la $1, 0x01230100   # ans: skip
	                    # ans: $1=0x01230100
	jr $1
	ori $2, $0, 0x1111  # ans: $2=0x00001111
	# TLB miss
	# ans: $8=0x00000001
	# ans: skip
	# ans: $4=0x01230002
	# ans: skip
	# ans: $4=0x00000012
	# ans: $10=0x0000face

	.org 0x100
usermode:
	ori $1, $0, 0x2333  # ans: $1=0x00002333
	syscall
	# ans: skip
	# ans: skip
	# ans: $11=0x00000fac
	ori $2, $0, 0x3222  # ans: $2=0x00003222

loop:
	b loop
	nop

	.org 0x1000          # must be 4K alignment
_exception_vector:
	addi $8, $8, 1
	mtc0 $0, $3         # entry_lo1
	la   $4, 0x01230002 # VPN2=0x01230, D=0, V=1
	mtc0 $4, $2         # entry_lo0
	mtc0 $8, $0         # index
	tlbwi
	mfc0 $4, $12        # status
	ori  $4, $4, 0x10   # usermode
	mtc0 $4, $12
	ori  $10, 0xface
	eret
	
	.org 0x1180
	mfc0  $4, $14       # EPC
	addi  $4, $4, 0x4      
	mtc0  $4, $14
	ori   $11, $0, 0x0fac
	eret
