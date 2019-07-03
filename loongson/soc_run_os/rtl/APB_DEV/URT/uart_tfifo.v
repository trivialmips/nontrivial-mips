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

module uart_tfifo (clk, 
    wb_rst_i, data_in, data_out,
    push, 
    pop,   
    overrun,
    count,
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

wire	[fifo_width-1:0]	data_out;

reg	[fifo_pointer_w-1:0]	top;
reg	[fifo_pointer_w-1:0]	bottom;

reg	[fifo_counter_w-1:0]	count;
reg			     overrun;
wire    [fifo_pointer_w-1:0] top_plus_1 = top + 1'b1;

raminfr #(fifo_pointer_w,fifo_width,fifo_depth) tfifo (.clk(clk), 
    .we(push), 
    .a(top), 
    .dpra(bottom), 
    .di(data_in), 
    .dpo(data_out)
); 


always @(posedge clk) 
begin
	if (wb_rst_i)
	begin
		top		<= 0;
		bottom		<= 1'b0;
		count		<= 0;
	end
	else
	if (fifo_reset) begin
		top		<= 0;
		bottom		<= 1'b0;
		count		<= 0;
	end
        else
	begin
		case ({push, pop})
		2'b10 : if (count<fifo_depth)  
			begin
				top       <= top_plus_1;
				count     <= count + 1'b1;
			end
		2'b01 : if(count>0)
			begin
				bottom    <= bottom + 1'b1;
				count	  <= count - 1'b1;
			end
		2'b11 : begin
				bottom    <= bottom + 1'b1;
				top       <= top_plus_1;
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
  if(push & (count==fifo_depth))
    overrun   <= 1'b1;
end   

endmodule
