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

module uart_transmitter (clk, wb_rst_i, lcr, tf_push, wb_dat_i, 
                         enable,stx_pad_o, tstate, tf_count, tx_reset, lsr_mask,
                         usart_t0,srx_pad_i,repeat_time,max_repeat_time,current_finish,
                         usart_mode,tx2rx_en);

input 		clk;
input 		wb_rst_i;
input [7:0] 	lcr;
input 		tf_push;
input [7:0] 	wb_dat_i;
input 		enable;
input 		tx_reset;
input 		lsr_mask; 
input           usart_mode; 
input           usart_t0,srx_pad_i;
input [2:0]     repeat_time;
output          current_finish; 
output          max_repeat_time;

output          tx2rx_en;
reg             tx2rx_en;
output 		stx_pad_o;
output [2:0] 		tstate;
output [`UART_FIFO_COUNTER_W-1:0] 	tf_count;

reg [2:0] 		tstate;
reg [4:0] 		counter;
reg [2:0] 		bit_counter;   
reg [6:0] 		shift_out;	    
reg 		stx_o_tmp;
reg 		parity_xor;    
reg 		tf_pop;
reg 		bit_out;
reg             tx_error;
reg [2:0]       error_time;

wire [`UART_FIFO_WIDTH-1:0] 			tf_data_in;
wire [`UART_FIFO_WIDTH-1:0] 			tf_data_out;
wire tf_push;
wire tf_overrun;
wire [`UART_FIFO_COUNTER_W-1:0]tf_count;

assign 	tf_data_in = wb_dat_i;

uart_tfifo fifo_tx(	
    .clk     ( clk         ), 
    .wb_rst_i(	wb_rst_i	   ),
    .data_in (	tf_data_in	 ),
    .data_out(	tf_data_out	),
    .push    (	tf_push     ),
    .pop     (	tf_pop	     ),
    .overrun (	tf_overrun	 ),
    .count   (	tf_count	   ),
    .fifo_reset  (	tx_reset),
    .reset_status(lsr_mask )
);

parameter s_idle        = 3'd0;
parameter s_send_start  = 3'd1;
parameter s_send_byte   = 3'd2;
parameter s_send_parity = 3'd3;
parameter s_send_stop   = 3'd4;
parameter s_pop_byte    = 3'd5;
parameter s_send_guard1 = 3'd6;
reg [7:0]tf_data_bak;

wire max_repeat_time = (error_time==(repeat_time+1'b1)) & usart_mode & usart_t0;

always @(posedge clk )
begin
  if (wb_rst_i)
  begin
        tx_error    <= 1'b0;
        error_time  <= 3'b0;
	tstate      <= s_idle;
	stx_o_tmp   <= 1'b1;
	counter     <= 5'b0;
	shift_out   <= 7'b0;
	bit_out     <= 1'b0;
	parity_xor  <= 1'b0;
	tf_pop      <= 1'b0;
	bit_counter <= 3'b0;
        tx2rx_en    <= 1'b0;
        tf_data_bak <= 8'h0;
  end
  else
  if (enable)
  begin
	case (tstate)
	s_idle	 :if ((~|tf_count)&(error_time==(repeat_time+1'b1)||~tx_error||~usart_mode)) 
	begin
	  tstate    <= s_idle;
	  stx_o_tmp <= 1'b1;
          tx_error  <= 1'b0;
	end
	else begin
	  tf_pop    <= 1'b0;
	  stx_o_tmp <= 1'b1;
	  tstate    <= s_pop_byte;
	end
	s_pop_byte :	begin

          if(tx_error&(error_time !=(repeat_time+1'b1)))
           begin
	    tf_pop <= 1'b0;
	     case (lcr[1:0])
	     2'b00 : begin
	             bit_counter <= 3'b100;
	             parity_xor  <= ^tf_data_bak[4:0];
	     end
	     2'b01 : begin
	             bit_counter <= 3'b101;
	             parity_xor  <= ^tf_data_bak[5:0];
	     end
	     2'b10 : begin
	             bit_counter <= 3'b110;
	             parity_xor  <= ^tf_data_bak[6:0];
	     end
	     2'b11 : begin
	             bit_counter <= 3'b111;
	             parity_xor  <= ^tf_data_bak[7:0];
	     end
	     endcase
	     {shift_out[6:0], bit_out} <= tf_data_bak;
          end
        else begin
	    tf_pop     <= 1'b1;
            error_time <= 3'h0;
	  case (lcr[1:0])  
	  2'b00 : begin
		  bit_counter <= 3'b100;
		  parity_xor  <= ^tf_data_out[4:0];
	  end
	  2'b01 : begin
	          bit_counter <= 3'b101;
		  parity_xor  <= ^tf_data_out[5:0];
	  end
	  2'b10 : begin
	          bit_counter <= 3'b110;
		  parity_xor  <= ^tf_data_out[6:0];
	  end
	  2'b11 : begin
		  bit_counter <= 3'b111;
		  parity_xor  <= ^tf_data_out[7:0];
	  end
	  endcase
	  {shift_out[6:0], bit_out} <= tf_data_out;
          tf_data_bak <= tf_data_out;
           end
	  tstate <= s_send_start;
	end
	s_send_start :	begin
	  tf_pop <= 1'b0;
	  if (~|counter)
	     counter <= 5'b01111;
	  else if (counter == 5'b00001)
	  begin
	    counter <= 0;
	    tstate  <= s_send_byte;
	  end
	  else
	    counter <= counter - 1'b1;
	  stx_o_tmp <= 1'b0;
	end
	s_send_byte :	begin
	  if (~|counter)
	     counter <= 5'b01111;
	  else if (counter == 5'b00001)
	  begin
	    if (bit_counter > 3'b0) begin
		bit_counter <= bit_counter - 1'b1;
		{shift_out[5:0],bit_out  } <= {shift_out[6:1], shift_out[0]};
		tstate <= s_send_byte;
	    end
	    else   
	    if (~lcr[`UART_LC_PE]) begin
	       tstate <= s_send_stop;
	    end
	    else begin
	      case ({lcr[`UART_LC_EP],lcr[`UART_LC_SP]})
	      2'b00:	bit_out <= ~parity_xor;
	      2'b01:	bit_out <= 1'b1;
	      2'b10:	bit_out <= parity_xor;
	      2'b11:	bit_out <= 1'b0;
	      endcase
	      tstate <= s_send_parity;
	    end
	    counter <= 0;
	  end
	  else  counter <= counter - 1'b1;
	  stx_o_tmp <= bit_out; 
	  end
	  s_send_parity :	begin
	      if (~|counter) counter <= 5'b01111;
	      else if (counter == 5'b00001) begin
		       counter <= 4'b0;
                       tstate  <= usart_mode ?  s_send_guard1 : s_send_stop; 
	      end
	      else     counter <= counter - 1'b1;
	      stx_o_tmp <= bit_out;
	  end
	  s_send_stop :  begin
	      if (~|counter) begin
                  if(usart_t0)
  		       counter <= tx_error ? 5'b11101 : 5'b01101;     
		  else
                  casex ({lcr[`UART_LC_SB],lcr[`UART_LC_BITS]})
  		  3'b0xx:	  counter <= 5'b01101;     
  		  3'b100:	  counter <= 5'b10101;     
  		  default:	  counter <= 5'b11101;     
		  endcase
	      end
	      else if (counter == 5'b00001) begin
		       counter <= 5'b0;
                       tx2rx_en<= 1'b0;
		       tstate  <= s_idle;
	      end
	      else     counter <= counter - 1'b1;
	      stx_o_tmp <= 1'b1;
	  end
         s_send_guard1:begin 
	      if (~|counter) begin
                     tx2rx_en <= 1'b1;
	             counter  <= usart_t0 ? 5'b01111:5'b01101;
	      end
	      else if (counter == 5'b00001) begin
		       counter   <= 5'b0;
                       tx_error  <= !srx_pad_i;
                       error_time<= error_time + !srx_pad_i;
                       tx2rx_en  <= usart_t0 ? 1'b1        : 1'b0;
		       tstate    <= usart_t0 ? s_send_stop : s_idle;
	      end
	      else     counter <= counter - 1'b1;
	      stx_o_tmp <= 1'b1;
	  end
          default : 
		       tstate <= s_idle;
	  endcase
  end 
  else    tf_pop <= 1'b0;  
end 

assign stx_pad_o = lcr[`UART_LC_BC] ? 1'b0 : stx_o_tmp;    
assign current_finish = usart_mode ? ( (tstate==3'b0)&(tx_error & (error_time ==repeat_time+1'b1) |~tx_error) ) : 1'b1;
	
endmodule
