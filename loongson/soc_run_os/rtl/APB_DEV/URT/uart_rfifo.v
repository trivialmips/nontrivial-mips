/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

`include "uart_defines.h"

module uart_rfifo (clk, 
    wb_rst_i, data_in, data_out,
    push, 
    pop,   
    overrun,
    count,
    error_bit,
    fifo_reset,
    reset_status
);

parameter fifo_width     = `UART_FIFO_WIDTH;
parameter fifo_depth     = `UART_FIFO_DEPTH;
parameter fifo_pointer_w = `UART_FIFO_POINTER_W;
parameter fifo_counter_w = `UART_FIFO_COUNTER_W;

input	clk;
input	wb_rst_i;
input	push;
input	pop;
input	[fifo_width-1:0]	data_in;
input	fifo_reset;
input   reset_status;

output	[fifo_width-1:0]	data_out;
output	overrun;
output	[fifo_counter_w-1:0]	count;
output	error_bit;

wire	[fifo_width-1:0]	data_out;
wire    [7:0]            data8_out;
reg	    [2:0]	         fifo[fifo_depth-1:0];

reg	[fifo_pointer_w-1:0]	top;
reg	[fifo_pointer_w-1:0]	bottom;

reg	[fifo_counter_w-1:0]	count;
reg	overrun;

wire    [fifo_pointer_w-1:0] top_plus_1 = top + 1'b1;

raminfr #(fifo_pointer_w,8,fifo_depth) rfifo (.clk(clk), 
    .we(push), 
    .a(top), 
    .dpra(bottom), 
    .di(data_in[fifo_width-1:fifo_width-8]), 
    .dpo(data8_out)
); 

always @(posedge clk) 
begin
	if (wb_rst_i)
	begin
		top	<= 0;
		bottom	<= 1'b0;
		count	<= 0;
		fifo[0] <= 0;
		fifo[1] <= 0;
		fifo[2] <= 0;
		fifo[3] <= 0;
		fifo[4] <= 0;
		fifo[5] <= 0;
		fifo[6] <= 0;
		fifo[7] <= 0;
		fifo[8] <= 0;
		fifo[9] <= 0;
		fifo[10]<= 0;
		fifo[11]<= 0;
		fifo[12]<= 0;
		fifo[13]<= 0;
		fifo[14]<= 0;
		fifo[15]<= 0;
	end
	else
	if (fifo_reset) begin
		top	<= 0;
		bottom	<= 1'b0;
		count	<= 0;
		fifo[0] <= 0;
		fifo[1] <= 0;
		fifo[2] <= 0;
		fifo[3] <= 0;
		fifo[4] <= 0;
		fifo[5] <= 0;
		fifo[6] <= 0;
		fifo[7] <= 0;
		fifo[8] <= 0;
		fifo[9] <= 0;
		fifo[10]<= 0;
		fifo[11]<= 0;
		fifo[12]<= 0;
		fifo[13]<= 0;
		fifo[14]<= 0;
		fifo[15]<= 0;
	end
        else
	begin
		case ({push, pop})
		2'b10 : if (count<fifo_depth)  
			begin
				top       <= top_plus_1;
				fifo[top] <= data_in[2:0];
				count     <= count + 1'b1;
			end
		2'b01 : if(count>0)
			begin
                                fifo[bottom] <= 0;
				bottom    <= bottom + 1'b1;
				count	  <= count - 1'b1;
			end
		2'b11 : begin
				bottom    <= bottom + 1'b1;
				top       <= top_plus_1;
				fifo[top] <= data_in[2:0];
		        end
                default: ;
	        endcase
        end
end   

always @(posedge clk) 
begin
  if (wb_rst_i)
    overrun   <= 1'b0;
  else
  if(fifo_reset | reset_status) 
    overrun   <= 1'b0;
  else
  if(push & ~pop & (count==fifo_depth))
    overrun   <= 1'b1;
end   

assign data_out = {data8_out,fifo[bottom]};

wire	[2:0]	word0 = fifo[0];
wire	[2:0]	word1 = fifo[1];
wire	[2:0]	word2 = fifo[2];
wire	[2:0]	word3 = fifo[3];
wire	[2:0]	word4 = fifo[4];
wire	[2:0]	word5 = fifo[5];
wire	[2:0]	word6 = fifo[6];
wire	[2:0]	word7 = fifo[7];

wire	[2:0]	word8 = fifo[8];
wire	[2:0]	word9 = fifo[9];
wire	[2:0]	word10 = fifo[10];
wire	[2:0]	word11 = fifo[11];
wire	[2:0]	word12 = fifo[12];
wire	[2:0]	word13 = fifo[13];
wire	[2:0]	word14 = fifo[14];
wire	[2:0]	word15 = fifo[15];

assign	error_bit = |(word0[2:0]  | word1[2:0]  | word2[2:0]  | word3[2:0]  |
            		      word4[2:0]  | word5[2:0]  | word6[2:0]  | word7[2:0]  |
            		      word8[2:0]  | word9[2:0]  | word10[2:0] | word11[2:0] |
            		      word12[2:0] | word13[2:0] | word14[2:0] | word15[2:0] );

endmodule
