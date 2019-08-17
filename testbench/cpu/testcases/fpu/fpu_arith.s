	.org 0x0
	.global _start
	.set noat
_start:
	# 2.3
	la $1, 0x40133333 # ans: skip
	                  # ans: $1=0x40133333
	# -4.7
	la $2, 0xc0966666 # ans: skip
	                  # ans: $2=0xc0966666
	mtc1 $1, $f1
	mtc1 $2, $f2
	add.s $f3, $f1, $f2
	sub.s $f4, $f1, $f2
	mul.s $f5, $f1, $f2
	div.s $f6, $f1, $f2
	sqrt.s $f7, $f1
	abs.s $f8, $f2
	neg.s $f9, $f2
	mfc1 $3, $f3   # ans: $3=0xc0199999
	mfc1 $4, $f4   # ans: $4=0x40e00000
	mfc1 $5, $f5   # ans: $5=0xc12cf5c2
	mfc1 $6, $f6   # ans: $6=0xbefa8d9e
	mfc1 $7, $f7   # ans: $7=0x3fc21f22
	mfc1 $8, $f8   # ans: $8=0x40966666
	mfc1 $9, $f9   # ans: $9=0x40966666

	add.s $f3, $f1, $f2
	mul.s $f3, $f3, $f3
	mul.s $f3, $f3, $f3
	div.s $f3, $f3, $f1
	sqrt.s $f3, $f3
	mfc1 $3, $f3   # ans: $3=0x407312f2

	round.w.s $f3, $f1
	trunc.w.s $f4, $f1
	floor.w.s $f5, $f1
	ceil.w.s  $f6, $f1
	mfc1 $3, $f3    # ans: $3=0x00000002
	mfc1 $4, $f4    # ans: $4=0x00000002
	mfc1 $5, $f5    # ans: $5=0x00000002
	mfc1 $6, $f6    # ans: $6=0x00000003

	round.w.s $f3, $f2
	trunc.w.s $f4, $f2
	floor.w.s $f5, $f2
	ceil.w.s  $f6, $f2
	mfc1 $3, $f3    # ans: $3=0xfffffffb
	mfc1 $4, $f4    # ans: $4=0xfffffffc
	mfc1 $5, $f5    # ans: $5=0xfffffffb
	mfc1 $6, $f6    # ans: $6=0xfffffffc

	ctc1 $0, $31  # set round mode
	cvt.w.s $f3, $f1
	mfc1 $3, $f3    # ans: $3=0x00000002
	cvt.s.w $f3, $f3
	mfc1 $3, $f3    # ans: $3=0x40000000

	# 0.3
	la $1, 0x3e99999a # ans: skip
	                  # ans: $1=0x3e99999a
	mtc1 $1, $f1
	cvt.w.s $f4, $f1
	cvt.s.w $f2, $f4
	mfc1 $1, $f4     # ans: $1=0x00000000
	mfc1 $2, $f2     # ans: $2=0x00000000

	# 0.3
	la $1, 0x3e99999a # ans: skip
	                  # ans: $1=0x3e99999a
	mtc1 $1, $f1
	round.w.s $f3, $f1
	trunc.w.s $f4, $f1
	floor.w.s $f5, $f1
	ceil.w.s  $f6, $f1
	mfc1 $3, $f3    # ans: $3=0x00000000
	mfc1 $4, $f4    # ans: $4=0x00000000
	mfc1 $5, $f5    # ans: $5=0x00000000
	mfc1 $6, $f6    # ans: $6=0x00000001

	# -0.6
	la $1, 0xbf19999a # ans: skip
	                  # ans: $1=0xbf19999a
	mtc1 $1, $f1
	round.w.s $f3, $f1
	trunc.w.s $f4, $f1
	floor.w.s $f5, $f1
	ceil.w.s  $f6, $f1
	mfc1 $3, $f3    # ans: $3=0xffffffff
	mfc1 $4, $f4    # ans: $4=0x00000000
	mfc1 $5, $f5    # ans: $5=0xffffffff
	mfc1 $6, $f6    # ans: $6=0x00000000
