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

module uart_receiver (clk, wb_rst_i, lcr, rf_pop, srx_pad_i, enable, 
                      counter_t, rf_count, rf_data_out, rf_error_bit, 
                      rf_overrun, rx_reset, lsr_mask, rstate, rf_push_pulse);

input        clk;
input        wb_rst_i;
input  [7:0] lcr;
input        rf_pop;
input        srx_pad_i;
input        enable;
input        rx_reset;
input        lsr_mask;

output [9:0] counter_t;
output [`UART_FIFO_COUNTER_W-1:0]	rf_count;
output [`UART_FIFO_REC_WIDTH-1:0]	rf_data_out;
output       rf_overrun;
output       rf_error_bit;
output [3:0] rstate;
output       rf_push_pulse;

reg    [3:0] rstate;
reg    [3:0] rcounter16;
reg    [2:0] rbit_counter;
reg    [7:0] rshift;			
reg          rparity; 		
reg          rparity_error;
reg          rframing_error;		
reg          rbit_in;
reg          rparity_xor;
reg    [7:0] counter_b;	
reg          rf_push_q;

reg [`UART_FIFO_REC_WIDTH-1:0] rf_data_in;
wire[`UART_FIFO_REC_WIDTH-1:0] rf_data_out;
wire         rf_push_pulse;
reg          rf_push;
wire         rf_pop;
wire         rf_overrun;
wire[`UART_FIFO_COUNTER_W-1:0] rf_count;
wire         rf_error_bit; 
wire         break_error = (counter_b == 0);

uart_rfifo #(`UART_FIFO_REC_WIDTH) fifo_rx(
        .clk         ( clk		      ), 
        .wb_rst_i    ( wb_rst_i	    ),
        .data_in     ( rf_data_in	  ),
        .data_out    ( rf_data_out	),
        .push        ( rf_push_pulse),
        .pop         ( rf_pop		    ),
        .overrun     ( rf_overrun	  ),
        .count       ( rf_count	    ),
        .error_bit   ( rf_error_bit	),
        .fifo_reset  ( rx_reset	    ),
        .reset_status( lsr_mask     )
);

wire       rcounter16_eq_7 = (rcounter16 == 4'd7);
wire       rcounter16_eq_0 = (rcounter16 == 4'd0);
wire       rcounter16_eq_1 = (rcounter16 == 4'd1);

wire [3:0] rcounter16_minus_1 = rcounter16 - 1'b1;

parameter  sr_idle         = 4'd0;
parameter  sr_rec_start 	 = 4'd1;
parameter  sr_rec_bit      = 4'd2;
parameter  sr_rec_parity   = 4'd3;
parameter  sr_rec_stop     = 4'd4;
parameter  sr_check_parity = 4'd5;
parameter  sr_rec_prepare  = 4'd6;
parameter  sr_end_bit      = 4'd7;
parameter  sr_ca_lc_parity = 4'd8;
parameter  sr_wait1        = 4'd9;
parameter  sr_push         = 4'd10;


always @(posedge clk ) begin
        if (wb_rst_i) begin
                rstate 			<= sr_idle;
                rbit_in 				<= 1'b0;
                rcounter16 			<= 0;
                rbit_counter 		<= 0;
                rparity_xor 		<= 1'b0;
                rframing_error 	<= 1'b0;
                rparity_error 		<= 1'b0;
                rparity 				<= 1'b0;
                rshift 				<= 0;
                rf_push 				<= 1'b0;
                rf_data_in 			<= 0;
        end 
        else if (enable) begin
	        case (rstate)
	        sr_idle      : begin
                        rf_push  	 <= 1'b0;
                        rf_data_in <= 0;
                        rcounter16 <= 4'b1110;
                        if (srx_pad_i==1'b0 & ~break_error) begin   
                                rstate <= sr_rec_start;
                        end
                end
	        sr_rec_start :	begin
                        rf_push    <= 1'b0;
                        if (rcounter16_eq_7)           
                                if (srx_pad_i==1'b1)   
                                        rstate <= sr_idle;
                                else                   
                                        rstate <= sr_rec_prepare;
			else rstate<=rstate;		
                        rcounter16 <= rcounter16_minus_1;
                end
                sr_rec_prepare: begin
                        case (lcr[1:0])  
                        2'b00 : rbit_counter <= 3'b100;
                        2'b01 : rbit_counter <= 3'b101;
                        2'b10 : rbit_counter <= 3'b110;
				                2'b11 : rbit_counter <= 3'b111;
                        endcase
                        if (rcounter16_eq_0) begin
                                rstate		   <= sr_rec_bit;
                                rcounter16   <= 4'b1110;
                                rshift		   <= 0;
                        end
                        else
                                rstate       <= sr_rec_prepare;
                                rcounter16   <= rcounter16_minus_1;
                end
                sr_rec_bit    :	begin
                        if (rcounter16_eq_0) rstate <= sr_end_bit;
                        if (rcounter16_eq_7) 
                                case (lcr[1:0])  
                                2'b00 : rshift[4:0]  <= {srx_pad_i, rshift[4:1]};
                                2'b01 : rshift[5:0]  <= {srx_pad_i, rshift[5:1]};
                                2'b10 : rshift[6:0]  <= {srx_pad_i, rshift[6:1]};
                                2'b11 : rshift[7:0]  <= {srx_pad_i, rshift[7:1]};
                                endcase
                        rcounter16 <= rcounter16_minus_1;
                end
                sr_end_bit    : begin
                        if (rbit_counter==3'b0) 
                        if (lcr[`UART_LC_PE]) 
                                rstate       <= sr_rec_parity;
                        else begin
                                rstate       <= sr_rec_stop;
                                rparity_error<= 1'b0;  
                        end
                        else begin	
                                rstate       <= sr_rec_bit;
                                rbit_counter <= rbit_counter - 1'b1;
                        end
                        rcounter16 <= 4'b1110;
                end
                sr_rec_parity : begin
                        if (rcounter16_eq_7) begin	
                                rparity <= srx_pad_i;
                        	       rstate <= sr_ca_lc_parity;
                        end
                        rcounter16 <= rcounter16_minus_1;
                end
                sr_ca_lc_parity:begin    
                        rcounter16  <= rcounter16_minus_1;
                        rparity_xor <= ^{rshift,rparity}; 
                        rstate      <= sr_check_parity;
                end
                sr_check_parity: begin	  
                        case ({lcr[`UART_LC_EP],lcr[`UART_LC_SP]})
                        2'b00: rparity_error <=  rparity_xor == 0;  
                        2'b01: rparity_error <= ~rparity;      
                        2'b10: rparity_error <=  rparity_xor == 1;   
                        2'b11: rparity_error <=  rparity;	  
                        endcase
                        rcounter16 <= rcounter16_minus_1;
                        rstate     <= sr_wait1;
                end
                sr_wait1       : 
                        if (rcounter16_eq_0) begin
                                rstate       <= sr_rec_stop;
                                rcounter16   <= 4'b1110;
                        end
			                  else    rcounter16 <= rcounter16_minus_1;
                sr_rec_stop    : begin
                        if (rcounter16_eq_7) begin	
                                rframing_error <= !srx_pad_i; 
                                rstate         <= sr_push;
                        end
                        rcounter16 <= rcounter16_minus_1;
                end
                sr_push        : begin
                        if(srx_pad_i | break_error) begin
                                if(break_error)
                                        rf_data_in 	<= {8'b0, 3'b100}; 
                                else
                                        rf_data_in  <= {rshift, 1'b0, rparity_error, rframing_error};
                                rf_push     <= 1'b1;
                                rstate      <= sr_idle;
                        end
                        else if(~rframing_error) begin  
                                rf_data_in  <= {rshift, 1'b0, rparity_error, rframing_error};
                                rf_push     <= 1'b1;
                                rcounter16  <= 4'b1110;
                                rstate      <= sr_rec_start;
                        end
                
                end
                default        : rstate <= sr_idle;
                endcase
        end  
end 

always @ (posedge clk ) begin
        if(wb_rst_i) rf_push_q <= 0;
        else         rf_push_q <= rf_push;
end

assign rf_push_pulse = rf_push & ~rf_push_q;


reg    [9:0] toc_value; 

always @(lcr)
        case (lcr[3:0])
        4'b0000	                            : toc_value = 447; 
        4'b0100                             : toc_value = 479; 
        4'b0001,	4'b1000                    : toc_value = 511; 
        4'b1100                             : toc_value = 543; 
        4'b0010, 4'b0101, 4'b1001           : toc_value = 575; 
        4'b0011, 4'b0110, 4'b1010, 4'b1101	 : toc_value = 639; 
        4'b0111, 4'b1011, 4'b1110	          : toc_value = 703; 
        4'b1111                             : toc_value = 767; 
        endcase 

wire [7:0] 	 brc_value; 
assign       brc_value = toc_value[9:2]; 

always @(posedge clk ) begin
        if (wb_rst_i)       counter_b <= 8'd159;
        else if (srx_pad_i) counter_b <= brc_value; 
        else if (enable & counter_b != 8'b0)            
                counter_b <= counter_b - 1;  
end 


reg	[9:0]	counter_t;	

always @(posedge clk ) begin
        if (wb_rst_i) counter_t <= 10'd639; 
        else if(rf_push_pulse || rf_pop || rf_count == 0) 
                counter_t <= toc_value;
        else if (enable && counter_t != 10'b0)  
                counter_t <= counter_t - 1;		
end

endmodule

