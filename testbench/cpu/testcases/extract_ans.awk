BEGIN { cyc = 5 }
match($1, /\[\+([0-9]*)\](.*)/, g) { cyc += g[1]; print "["cyc"]"g[2] }
match($1, /\[exc_code\]=0x([0-9abcdef]{2})/, g) { print "skip\nskip\nskip\nskip\n$29=0x000000"g[1] }
/^((\[0x[0-9abcdef]{4}\])|\$|skip)/ { print $1 }
