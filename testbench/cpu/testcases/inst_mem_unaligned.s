   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
	lui $s0, 0xa000      # ans: $16=0xa0000000
    ori $s0, $s0, 0x1000 # ans: $16=0xa0001000
    lui $2, 0x1234       # ans: $2=0x12340000
    ori $2, $2, 0x5678   # ans: $2=0x12345678

    sb $2, 0($s0)        # ans: [0x1000]=0x00000078

    lui $3, 0x0d1c       # ans: $3=0x0d1c0000
    ori $3, $3, 0x2b3a   # ans: $3=0x0d1c2b3a
    sw $3, 0($s0)        # ans: [0x1000]=0x0d1c2b3a

    or  $4, $0, $2       # ans: $4=0x12345678
    lwl $4, 0($s0)       # ans: $4=0x3a345678
    or  $4, $0, $2       # ans: $4=0x12345678
    lwl $4, 1($s0)       # ans: $4=0x2b3a5678
    or  $4, $0, $2       # ans: $4=0x12345678
    lwl $4, 2($s0)       # ans: $4=0x1c2b3a78
    or  $4, $0, $2       # ans: $4=0x12345678
    lwl $4, 3($s0)       # ans: $4=0x0d1c2b3a

    ori $4, $0, 0        # ans: $4=0x00000000

    or  $4, $0, $2       # ans: $4=0x12345678
    lwr $4, 0($s0)       # ans: $4=0x0d1c2b3a
    or  $4, $0, $2       # ans: $4=0x12345678
    lwr $4, 1($s0)       # ans: $4=0x120d1c2b
    or  $4, $0, $2       # ans: $4=0x12345678
    lwr $4, 2($s0)       # ans: $4=0x12340d1c
    or  $4, $0, $2       # ans: $4=0x12345678
    lwr $4, 3($s0)       # ans: $4=0x1234560d

    sw  $2, 0($s0)       # ans: [0x1000]=0x12345678
    swl $3, 0($s0)       # ans: [0x1000]=0x1234560d
    sw  $2, 0($s0)       # ans: [0x1000]=0x12345678
    swl $3, 1($s0)       # ans: [0x1000]=0x12340d1c
    sw  $2, 4($s0)       # ans: [0x1004]=0x12345678
    swl $3, 6($s0)       # ans: [0x1004]=0x120d1c2b
    sw  $2, 4($s0)       # ans: [0x1004]=0x12345678
    swl $3, 7($s0)       # ans: [0x1004]=0x0d1c2b3a

    sw  $2, 0($s0)       # ans: [0x1000]=0x12345678
    swr $3, 3($s0)       # ans: [0x1000]=0x3a345678
    sw  $2, 0($s0)       # ans: [0x1000]=0x12345678
    swr $3, 2($s0)       # ans: [0x1000]=0x2b3a5678
    sw  $2, 0($s0)       # ans: [0x1000]=0x12345678
    swr $3, 1($s0)       # ans: [0x1000]=0x1c2b3a78
    sw  $2, 0($s0)       # ans: [0x1000]=0x12345678
    swr $3, 0($s0)       # ans: [0x1000]=0x0d1c2b3a

	ori $1, $0, 0        # ans: $1=0x00000000
