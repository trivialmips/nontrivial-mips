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

`timescale 1ns/10ps

`define V_UART_FIFO_COUNTER_W    5
`define V_UART_FIFO_WIDTH        8
`define V_UART_LC_PE             3
`define V_UART_LC_EP             4
`define V_UART_LC_SP             5
`define V_UART_LC_SB             2
`define V_UART_LC_BITS           1:0
`define V_UART_LC_BC             6
`define V_UART_FIFO_DEPTH        16
`define V_UART_FIFO_POINTER_W    4

module uart_dev
(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx,
    output wire        tx
);
parameter     uart_number=0;
parameter     STRLEN = 80;

    wire [7:0]  data;
    wire        hwrite;
    wire        hready;
    wire [1:0]  htrans;
    wire [31:0] haddr;
    wire        hclk;
    wire        apb_clk;
    wire        gpio;

    assign data    = 8'h0;
    assign hwrite  = 1'b0;
    assign hready  = 1'b0;
    assign htrans  = 2'b0;
    assign haddr   = 32'h0;
    assign hclk    = clk;
    assign apb_clk = clk;
    assign gpio    = 1'b1;

   wire   uart_beh_reset;

   reg [7:0]     buffer[STRLEN:0];
   wire [8*STRLEN-1:0] outbuf;

   reg [7:0]     byte_in;
   reg [7:0]     ptr;
   integer       i;
   wire tx_mid;
   assign #1 tx= tx_mid;
   assign uart_beh_reset = !rst_n;
   initial
   begin
      while(rx !== 1'b1) @(rx);
      forever begin
        byte_in = 8'h20;
        while(rx != 1'b0) @(rx);
        repeat(8) @(posedge clk);
        for ( i=0; i<8; i=i+1 ) begin
           repeat(16) @(posedge clk);
           byte_in[i] = rx;
        end
        repeat(16) @(posedge clk);
        push(byte_in);
      end
   end

   reg [31:0] haddr_d1;
   reg        hwrite_d1;
   always @(posedge hclk) begin
      haddr_d1 <= haddr;
      hwrite_d1<= hwrite && hready && htrans[1];
      if (haddr_d1 == 32'h1f00_03f8 && hwrite_d1) begin
        push(data);
      end
   end

   initial #100
     begin:init_buffer
        for (ptr = 8'h00; ptr < STRLEN; ptr = ptr + 1)
          begin
             buffer[ptr] = 8'h20;
          end
        ptr = 8'h00;
     end

   assign outbuf[639:0] = { buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], buffer[5], buffer[6], buffer[7],
                            buffer[8], buffer[9], buffer[10],buffer[11],buffer[12],buffer[13],buffer[14],buffer[15],
                            buffer[16],buffer[17],buffer[18],buffer[19],buffer[20],buffer[21],buffer[22],buffer[23],
                            buffer[24],buffer[25],buffer[26],buffer[27],buffer[28],buffer[29],buffer[30],buffer[31],
                            buffer[32],buffer[33],buffer[34],buffer[35],buffer[36],buffer[37],buffer[38],buffer[39],
                            buffer[40],buffer[41],buffer[42],buffer[43],buffer[44],buffer[45],buffer[46],buffer[47],
                            buffer[48],buffer[49],buffer[50],buffer[51],buffer[52],buffer[53],buffer[54],buffer[55],
                            buffer[56],buffer[57],buffer[58],buffer[59],buffer[60],buffer[61],buffer[62],buffer[63],
                            buffer[64],buffer[65],buffer[66],buffer[67],buffer[68],buffer[69],buffer[70],buffer[71],
                            buffer[72],buffer[73],buffer[74],buffer[75],buffer[76],buffer[77],buffer[78],buffer[79]};

         
   task push;
      input [7:0] data;
      begin
      buffer[ptr] = (data[7:0]==8'h0D)? 8'h0A : data[7:0];
      ptr = ptr + 1;
      if (data[7:0] == 8'h0A || data[7:0] == 8'h0D)
        begin
           print;
           ptr = 8'h00;
        end
      else if (ptr == STRLEN)
        begin
           print;
           ptr = 8'h00;
        end
      end
   endtask

   task print;
      begin
         $display("[%t]:[uart%1x]: %s", $time, uart_number,outbuf);
         if (outbuf[639:576] == "GouSheng") $finish;
         for (ptr =  8'h00; ptr < STRLEN; ptr = ptr + 1)
           begin
              buffer[ptr] = 8'h20;
           end
      end
   endtask
   
   reg         uart_push;
   reg [7:0]   uart_tx_data;
   wire [2:0]  uart_tx_state;

   initial
     begin
         begin
         #1000000;
         // #250000;
         wait(gpio);
         if (uart_number == 1) #200000;
         //$display("[%t]:[uart%1x_output]: SEND STRING \"d4a000000010 \"", $time,uart_number); 
         uart_send_multiple("d4a000000010 ", 32'd13);
         // uart_send_multiple("gb", 32'd2);
         end
     end

   uart_transmitter_v ut( .clk    (apb_clk       ),
                      .wb_rst_i   (uart_beh_reset),
                      .lcr        (8'h3          ),
                      .tf_push    (uart_push     ),
                      .wb_dat_i   (uart_tx_data  ),
                      .enable     (1'b1          ),
                      .stx_pad_o  (tx_mid        ),
                      .tstate     (uart_tx_state ),
                      .tf_count   (              ),
                      .tx_reset   (uart_beh_reset),
                      .lsr_mask   (1'b0          )
                      );
                      
   task uart_send_multiple;
     input [8*80-1: 0] uart_string;
     input [31:0]  len;
     integer send_multi_i;
     begin
        for (send_multi_i=len-1; send_multi_i >=0; send_multi_i = send_multi_i-1) begin
            uart_send({uart_string[send_multi_i*8 + 7],
                       uart_string[send_multi_i*8 + 6],
                       uart_string[send_multi_i*8 + 5],
                       uart_string[send_multi_i*8 + 4],
                       uart_string[send_multi_i*8 + 3],
                       uart_string[send_multi_i*8 + 2],
                       uart_string[send_multi_i*8 + 1],
                       uart_string[send_multi_i*8 + 0]});
        end
     end
   endtask
   task uart_send;
     input [7:0] data;
     begin
      uart_tx_data = data;
      @(posedge clk);
      uart_push = 1'b1;
      @(posedge clk);
      uart_push = 1'b0;
      repeat (3) @(posedge clk);
      while(uart_tx_state != 3'b001)
        @uart_tx_state;
     end
   endtask


endmodule 

module uart_transmitter_v (clk, wb_rst_i, lcr, tf_push, wb_dat_i, enable,	stx_pad_o, tstate, tf_count, tx_reset, lsr_mask);

input 		clk;
input 		wb_rst_i;
input [7:0] 		lcr;
input 		tf_push;
input [7:0] 		wb_dat_i;
input 		enable;
input 		tx_reset;
input 		lsr_mask; 
output 		stx_pad_o;
output [2:0] 		tstate;
output [`V_UART_FIFO_COUNTER_W-1:0] 	tf_count;

reg [2:0]   tstate;
reg [4:0]   counter;
reg [2:0]   bit_counter;
reg [6:0]   shift_out;
reg 		stx_o_tmp;
reg 		parity_xor;
reg 		tf_pop;
reg 		bit_out;

wire [`V_UART_FIFO_WIDTH-1:0] 			tf_data_in;
wire [`V_UART_FIFO_WIDTH-1:0] 			tf_data_out;
wire tf_push;
wire tf_overrun;
wire [`V_UART_FIFO_COUNTER_W-1:0]tf_count;

assign 	tf_data_in = wb_dat_i;

uart_tfifo_v fifo_tx(
    .clk         (clk        ), 
    .wb_rst_i    (wb_rst_i   ),
    .data_in     (tf_data_in ),
    .data_out    (tf_data_out),
    .push        (tf_push    ),
    .pop         (tf_pop     ),
    .overrun     (tf_overrun ),
    .count       (tf_count   ),
    .fifo_reset  (tx_reset   ),
    .reset_status(lsr_mask   )
);

parameter s_idle        = 3'd0;
parameter s_send_start  = 3'd1;
parameter s_send_byte   = 3'd2;
parameter s_send_parity = 3'd3;
parameter s_send_stop   = 3'd4;
parameter s_pop_byte    = 3'd5;

always @(posedge clk )
begin
  if (wb_rst_i)
  begin
	tstate      <= s_idle;
	stx_o_tmp   <= 1'b1;
	counter     <= 5'b0;
	shift_out   <= 7'b0;
	bit_out     <= 1'b0;
	parity_xor  <= 1'b0;
	tf_pop      <= 1'b0;
	bit_counter <= 3'b0;
  end
  else
  if (enable)
  begin
	case (tstate)
	s_idle	 :if (~|tf_count) 
	begin
	  tstate    <= s_idle;
	  stx_o_tmp <= 1'b1;
	end
	else begin
	  tf_pop    <= 1'b0;
	  stx_o_tmp <= 1'b1;
	  tstate    <= s_pop_byte;
	end
	s_pop_byte :	begin
	  tf_pop <= 1'b1;
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
	    if (~lcr[`V_UART_LC_PE]) begin
	       tstate <= s_send_stop;
	    end
	    else begin
	      case ({lcr[`V_UART_LC_EP],lcr[`V_UART_LC_SP]})
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
		       tstate  <= s_send_stop;
	      end
	      else     counter <= counter - 1'b1;
	      stx_o_tmp <= bit_out;
	  end
	  s_send_stop :  begin
	      if (~|counter) begin
		  casex ({lcr[`V_UART_LC_SB],lcr[`V_UART_LC_BITS]})
  		  3'b0xx:	  counter <= 5'b01101;
  		  3'b100:	  counter <= 5'b10101;
  		  default:	 counter  <= 5'b11101;
		  endcase
	      end
	      else if (counter == 5'b00001) begin
		       counter <= 0;
		       tstate  <= s_idle;
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

assign stx_pad_o = lcr[`V_UART_LC_BC] ? 1'b0 : stx_o_tmp; 
	
endmodule

module uart_tfifo_v (clk, 
    wb_rst_i, data_in, data_out,
    push, 
    pop,   

    overrun,
    count,
    fifo_reset,
    reset_status
);


parameter fifo_width     = `V_UART_FIFO_WIDTH;
parameter fifo_depth     = `V_UART_FIFO_DEPTH;
parameter fifo_pointer_w = `V_UART_FIFO_POINTER_W;
parameter fifo_counter_w = `V_UART_FIFO_COUNTER_W;

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

raminfr_v #(fifo_pointer_w,fifo_width,fifo_depth) tfifo (.clk(clk), 
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

module raminfr_v(clk, we, a, dpra, di, dpo); 

parameter addr_width = 4;
parameter data_width = 8;
parameter depth = 16;

input clk;   
input we;   
input  [addr_width-1:0] a;   
input  [addr_width-1:0] dpra;   
input  [data_width-1:0] di;   
output [data_width-1:0] dpo;   
reg    [data_width-1:0] ram [depth-1:0]; 

wire   [data_width-1:0] di;   
wire   [addr_width-1:0] a;   
wire   [addr_width-1:0] dpra;   
 
always @(posedge clk) begin
    if (we)   
      ram[a] <= di;   
end   
reg    [data_width-1:0] dpo;

always @(posedge clk)
    dpo <= ram[dpra];

endmodule 
