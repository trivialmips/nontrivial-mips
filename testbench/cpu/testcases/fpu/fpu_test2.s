	.org 0x0
	.global _start
	.set noreorder
	.set nomacro
	.set noat
_start:
	la      $23, 0x80000000  # ans: $23=0x80000000
	la      $1, 0x3e4ccccd   # ans: skip
							 # ans: $1=0x3e4ccccd
	sw      $1, 9084($23)    # ans: skip
	la      $1, 0x447a0000   # ans: $1=0x447a0000
	sw      $1, 9088($23)    # ans: skip
	la      $1, 0x3f000000   # ans: $1=0x3f000000
	mtc1    $1, $f20         # ans: skip
	la      $1, 0x3f800000   # ans: $1=0x3f800000
	mtc1    $1, $f21         # ans: skip
	jal po # ans: skip
	nop

# 104, wrong
# f0 = 0.2, f1 = 1000, f21 = zoom, f20 = moveX
po:
	lwc1	$f0,9084($23)  # ans: $f0=0x3e4ccccd
	lwc1	$f1,9088($23)  # ans: $f1=0x447a0000
	div.s	$f0,$f0,$f21   # ans: $f0=0x3e4ccccd
	lui	    $3,0x1000      # ans: skip
	addiu	$3,$3,8824     # ans: skip
	sub.s	$f20,$f20,$f0  # ans: $f20=0x3e99999a
	mul.s	$f2,$f20,$f1   # ans: $f2=0x43960000
	sub.s	$f0,$f20,$f0   # ans: $f0=0x3dccccce
	mul.s	$f0,$f0,$f1    # ans: $f0=0x42c80001
	cvt.w.s	$f1,$f2        # ans: $f1=0x0000012c
	cvt.w.s	$f0,$f0        # ans: $f0=0x00000064
	nop
	mfc1	$11,$f1  # ans: $11=0x0000012c
	mfc1	$12,$f0  # ans: $12=0x00000064
