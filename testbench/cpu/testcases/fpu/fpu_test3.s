	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	la      $23, 0x80000000  # ans: $23=0x80000000
	la      $1, 0x3e4ccccd   # ans: skip
							 # ans: $1=0x3e4ccccd
	sw      $1, 4($23)    # ans: skip
	la      $1, 0x447a0000   # ans: $1=0x447a0000
	sw      $1, 8($23)    # ans: skip
	la      $1, 0x3f000000   # ans: $1=0x3f000000
	mtc1    $1, $f20        
	la      $1, 0x3f800000   # ans: $1=0x3f800000
	mtc1    $1, $f21       

	# setup cp0
	la $29, 0x01230000  # ans: $29=0x01230000
	mtc0 $0, $10        # entry_hi.ASID = 0

	b po 
	nop

# 104, wrong
# f0 = 0.2, f1 = 1000, f21 = zoom, f20 = moveX
po:
	lwc1	$f0,4($23)
	# TLB miss
	# ans: $8=0x00000001
	# ans: skip 
	# ans: $4=0x01230002
	# ans: $10=0x0000face
	lwc1	$f1,8($29)
	div.s	$f0,$f0,$f21
	lui	    $3,0x1000  # ans: skip
	addiu	$3,$3,8824  # ans: skip
	sub.s	$f20,$f20,$f0
	mul.s	$f2,$f20,$f1
	sub.s	$f0,$f20,$f0
	mul.s	$f0,$f0,$f1
	cfc1	$5,$31  # ans: skip
	cfc1	$5,$31  # ans: skip
	nop
	ori	    $8,$5,0x3  # ans: skip
	xori	$8,$8,0x2  # ans: skip
	ctc1	$8,$31
	nop
	cvt.w.s	$f1,$f2
	ctc1	$5,$31
	nop
	cfc1	$5,$31  # ans: skip
	cfc1	$5,$31  # ans: skip
	nop
	ori	    $8,$5,0x3  # ans: skip
	xori	$8,$8,0x2  # ans: skip
	ctc1	$8,$31
	nop
	cvt.w.s	$f0,$f0
	ctc1	$5,$31
	nop
	mfc1	$11,$f1  # ans: $11=0x0000012c
	mfc1	$12,$f0  # ans: $12=0x00000064
	.org 0x200      
_exception_vector:
	addi $8, $8, 1
	mtc0 $0, $3         # entry_lo1
	la   $4, 0x01230002 # VPN2=0x01230, D=0, V=1
	mtc0 $4, $2         # entry_lo0
	mtc0 $8, $0         # index
	tlbwi
	ori  $10, 0xface
	eret
