#! /usr/bin/python3

import sys

asm_file = sys.argv[1]
out_file = sys.argv[2]

cf_start = False
f_out = open(out_file, 'w')
f_in  = open(asm_file, 'r')
for line in f_in:
    line = line.strip();
    if line.startswith('#'):
        line = line[1:].strip()

        if line == '%BEGIN CONTROLFLOW%':
            cf_start = True
        elif line == '%END CONTROLFLOW%':
            cf_start = False
        elif cf_start:
            f_out.write(line + '\n')
f_in.close()
f_out.close()
