#include <stdio.h>
#include <stdlib.h>

int main(void)
{
	FILE *in;
	FILE *out;
	FILE *out0, *out1, *out2, *out3;
	FILE *out4, *out5, *out6, *out7;

	int i,j,k;
	unsigned char mem[32];

        in = fopen("test.bin", "rb");
	out = fopen("flash.vlog", "w");

	fprintf(out, "  @00\n");
	while(!feof(in)) {
	    if(fread(mem,1,4,in)!=4) {
	        fprintf(out, "  %02x %02x %02x %02x\n", mem[0], mem[1],	mem[2], mem[3]);
		break;
	     }
	    fprintf(out, "  %02x %02x %02x %02x\n", mem[0], mem[1], mem[2],mem[3]);
        }
	fclose(in);
	fclose(out);

    return 0;
}
