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

`define  DMA_ORDERSIZE               32
`define  DMA_WORDSIZE                32
`include "config.h"
`define   WRITE_LENGTH 16 
`define   READ_LENGTH 16 
module dma_master(
               clk,
               rst_n,
               arid, araddr, arlen ,arsize, arburst, arlock, arcache, arprot, arvalid, arready,
               rid , rdata , rresp ,rlast , rvalid , rready,
               awid, awaddr, awlen ,awsize, awburst, awlock, awcache, awprot, awvalid, awready,
               wid , wdata , wstrb ,wlast , wvalid , wready,
               bid , bresp , bvalid,bready, 
               dma_int, order_addr_in,dma_req_in,dma_ack_out,
               finish_read_order, write_dma_end,dma_gnt,
               apb_valid_req,apb_psel, apb_penable, apb_rw, apb_addr,apb_rdata,apb_wdata
               );
input                       clk;
input                       rst_n;
input                       dma_gnt;

output [`LID         -1 :0] awid;
output [`Lawaddr     -1 :0] awaddr;
output [`Lawlen      -1 :0] awlen;
output [`Lawsize     -1 :0] awsize;
output [`Lawburst    -1 :0] awburst;
output [`Lawlock     -1 :0] awlock;
output [`Lawcache    -1 :0] awcache;
output [`Lawprot     -1 :0] awprot;
output                      awvalid;
input                       awready;
output [`LID         -1 :0] wid;
output [64           -1 :0] wdata;
output [8            -1 :0] wstrb;
output                      wlast;
output                      wvalid;
input                       wready;
input  [`LID         -1 :0] bid;
input  [`Lbresp      -1 :0] bresp;
input                       bvalid;
output                      bready;
output [`LID         -1 :0] arid;
output [`Laraddr     -1 :0] araddr;
output [`Larlen      -1 :0] arlen;
output [`Larsize     -1 :0] arsize;
output [`Larburst    -1 :0] arburst;
output [`Larlock     -1 :0] arlock;
output [`Larcache    -1 :0] arcache;
output [`Larprot     -1 :0] arprot;
output                      arvalid;
input                       arready;
input  [`LID         -1 :0] rid;
input  [64           -1 :0] rdata;
input  [`Lrresp      -1 :0] rresp;
input                       rlast;
input                       rvalid;
output                      rready;

output                      dma_int;
output                      dma_ack_out;
input [31:0]                order_addr_in;
input                       dma_req_in;
output                      finish_read_order;
output                      write_dma_end;

output                      apb_psel; 
output                      apb_valid_req; 
output                      apb_penable;
output                      apb_rw; 
output [31:0]               apb_addr;
input  [31:0]               apb_rdata;
output [31:0]               apb_wdata;

wire read_idle;
wire read_ready;
wire get_order;
wire read_order;
wire finish_read_order;
wire r_ddr_wait;
wire read_ddr;
wire read_ddr_end;
wire read_dev;
wire read_dev_end;
wire read_step_end;
wire write_idle;
wire write_ready;
wire w_ddr_wait;
wire write_ddr;
wire write_ddr_end;
wire w_dma_wait;
wire write_dma;
wire write_dma_end ;
wire write_step_end;
wire rresp_ok = (rresp==2'h0); 
wire bresp_ok = (bresp==2'h0);

wire dma_start;
wire dma_stop;
wire ask_valid;
wire [31:0] ask_addr;
wire [ 1:0] device_num_tmp;
assign device_num_tmp = order_addr_in[1:0];                 
assign ask_valid      = order_addr_in[2] ; 
assign dma_start      = order_addr_in[3] ; 
assign dma_stop       = order_addr_in[4] & 
                        (read_ddr_end  | read_dev_end  | read_step_end  | read_idle ) & 
                        (write_ddr_end | write_dma_end | write_step_end | write_idle);
assign ask_addr       = {order_addr_in[31:5], 5'h0};                 

reg [ 3:0]                dma_read_state; 
reg [ 3:0]                dma_write_state; 
reg [31:0]                count_length;
reg [ 4:0]                count_fifo_r;
reg [ 4:0]                count_fifo_w;
reg [ 5:0]                count_fifo;
reg [31:0]                mem [31:0];
reg                       dma_r_w;
reg [31:0]                dma_order_addr;
reg [31:0]                dma_mem_addr;
reg [31:0]                dma_dev_addr;
reg [31:0]                dma_length;
reg [31:0]                dma_step_length;
reg [31:0]                dma_step_times;
reg [31:0]                dma_state_reg;
reg                       dma_get_order;

wire [31:0]mem0  = mem[0];
wire [31:0]mem1  = mem[1];
wire [31:0]mem2  = mem[2];
wire [31:0]mem3  = mem[3];
wire [31:0]mem4  = mem[4];
wire [31:0]mem5  = mem[5];
wire [31:0]mem6  = mem[6];
wire [31:0]mem7  = mem[7];
wire [31:0]mem8  = mem[8];
wire [31:0]mem9  = mem[9];
wire [31:0]mem10 = mem[10];
wire [31:0]mem11 = mem[11];
wire [31:0]mem12 = mem[12];
wire [31:0]mem13 = mem[13];
wire [31:0]mem14 = mem[14];
wire [31:0]mem15 = mem[15];
wire [31:0]mem16 = mem[16];
wire [31:0]mem17 = mem[17];
wire [31:0]mem18 = mem[18];
wire [31:0]mem19 = mem[19];
wire [31:0]mem20 = mem[20];
wire [31:0]mem21 = mem[21];
wire [31:0]mem22 = mem[22];
wire [31:0]mem23 = mem[23];
wire [31:0]mem24 = mem[24];
wire [31:0]mem25 = mem[25];
wire [31:0]mem26 = mem[26];
wire [31:0]mem27 = mem[27];
wire [31:0]mem28 = mem[28];
wire [31:0]mem29 = mem[29];
wire [31:0]mem30 = mem[30];
wire [31:0]mem31 = mem[31];

wire                      dma_order_en;
wire[ 3:0]                dma_next_read_state;
wire[ 3:0]                dma_next_write_state;
wire[31:0]                count_obj;
wire                      dma_single_trans_over;
wire                      dma_trans_over;
wire                      dma_state_change_en;
wire                      dma_int_mask;

assign dma_int_mask = dma_state_reg[0];
assign dma_int      = dma_state_reg[1];
assign dma_order_en = dma_order_addr[0];

reg dma_req_in_reg_1, dma_req_in_reg_2;
reg dma_req_r;
reg dma_req;
always @(posedge clk)begin
    if (~rst_n) begin
        dma_req_in_reg_1 <= 1'b0;
        dma_req_in_reg_2 <= 1'b0;
    end else begin
        dma_req_in_reg_1 <= dma_req_in;
        dma_req_in_reg_2 <= dma_req_in_reg_1;
    end 
end
always @(posedge clk)begin
    if (~rst_n)
        dma_req_r <= 1'b0;
    else
        dma_req_r <= dma_req_in_reg_2;
end
always @(posedge clk)begin
    if (~rst_n)
        dma_req   <= 1'b0;
    else if (dma_ack_out | !dma_req_in_reg_2)
        dma_req   <= 1'b0;
    else if (~dma_req_r & dma_req_in_reg_2)
        dma_req   <= 1'b1;
end

parameter  READ_IDLE            = 4'h0;
parameter  READ_READY           = 4'h1;
parameter  GET_ORDER            = 4'h2;
parameter  READ_ORDER           = 4'h3;
parameter  FINISH_READ_ORDER    = 4'h4;
parameter  R_DDR_WAIT           = 4'h5;
parameter  READ_DDR             = 4'h6;
parameter  READ_DDR_END         = 4'h7;
parameter  READ_DEV             = 4'h8;
parameter  READ_DEV_END         = 4'h9;
parameter  READ_STEP_END        = 4'ha;

assign read_idle                = dma_read_state==READ_IDLE;
assign read_ready               = dma_read_state==READ_READY;
assign get_order                = dma_read_state==GET_ORDER;
assign read_order               = dma_read_state==READ_ORDER;
assign finish_read_order        = dma_read_state==FINISH_READ_ORDER;
assign r_ddr_wait               = dma_read_state==R_DDR_WAIT;
assign read_ddr                 = dma_read_state==READ_DDR;
assign read_ddr_end             = dma_read_state==READ_DDR_END;
assign read_dev                 = dma_read_state==READ_DEV;
assign read_dev_end             = dma_read_state==READ_DEV_END;
assign read_step_end            = dma_read_state==READ_STEP_END;

assign dma_single_trans_over = (write_step_end | read_step_end & (count_fifo==0)) & (count_length==32'b0) & (dma_step_times==32'b1) ? 1'b1 : 1'b0;
assign dma_trans_over        = dma_single_trans_over & !dma_order_en;
reg dma_trans_over_reg;
always @(posedge clk)begin
    if(!rst_n)
        dma_trans_over_reg <= 1'b0;
    else if(dma_trans_over)
        dma_trans_over_reg <= 1'b1;
    else if((read_idle & write_idle) & dma_start)
        dma_trans_over_reg <= 1'b0;
end

wire [5:0] num_fifo;
wire read_ddr_again  = !dma_get_order &  dma_r_w & (count_fifo <= `READ_LENGTH) & (count_length!=0) & (num_fifo >6'h0); 
wire read_dev_again  = !dma_get_order & !dma_r_w & dma_req & (count_fifo < 6'h20);

assign dma_next_read_state  = read_idle         ? (dma_start ? READ_READY : READ_IDLE) :
                              read_ready        ? (dma_get_order ? GET_ORDER : read_ddr_again ? R_DDR_WAIT : read_dev_again ? READ_DEV : READ_READY) :
                              get_order         ? (arready ? READ_ORDER : GET_ORDER) :   
                              read_order        ? (rvalid & rlast & rready & rresp_ok ? FINISH_READ_ORDER : READ_ORDER) : 
                              finish_read_order ?  READ_READY : 
                              r_ddr_wait        ? (arready ? READ_DDR : R_DDR_WAIT) :
                              read_ddr          ? (rvalid & rready & rlast & rresp_ok ? READ_DDR_END : READ_DDR) :
                              read_ddr_end      ? ((count_length==0) ? READ_STEP_END : read_ddr_again ? R_DDR_WAIT : READ_DDR_END) :
                              read_step_end     ? ((dma_trans_over | dma_stop) ? READ_IDLE : dma_get_order ? GET_ORDER : read_ddr_again ? R_DDR_WAIT : READ_STEP_END) :
                              read_dev          ? ((dma_trans_over | dma_stop) ? READ_IDLE : dma_get_order ? GET_ORDER : apb_penable ? READ_DEV_END : READ_DEV) :
                              read_dev_end      ? ((dma_trans_over | dma_stop) ? READ_IDLE : dma_get_order ? GET_ORDER : read_dev_again ? READ_DEV : READ_DEV_END) : READ_IDLE;


reg [1:0]arb_write_op;
wire aw_empty     = (arb_write_op==2'b01) & write_ddr_end || (arb_write_op==2'b00) & write_dma_end || (arb_write_op==2'b11); 
wire write_ddr_ok = ((count_fifo >= `WRITE_LENGTH) | (count_fifo >= count_length)) & (count_length!=0);
always @(posedge clk)begin
    if(!rst_n | dma_stop)
        arb_write_op <= 2'b11;
    else if(ask_valid & aw_empty & (arb_write_op!=0))
        arb_write_op <= 2'b00;
    else if(!dma_r_w & write_ddr_ok & aw_empty)
        arb_write_op <= 2'b01;
    else if(aw_empty)
        arb_write_op <= 2'b11;
end

wire write_ddr_again = !dma_get_order & (arb_write_op==2'b01) & write_ddr_ok;
wire write_dma_again = !dma_get_order & (arb_write_op==2'b00); 

parameter  WRITE_IDLE           = 4'h0;
parameter  W_DDR_WAIT           = 4'h1;
parameter  WRITE_DDR            = 4'h2;
parameter  WRITE_DDR_END        = 4'h3;
parameter  W_DMA_WAIT           = 4'h4;
parameter  WRITE_DMA            = 4'h5;
parameter  WRITE_DMA_END        = 4'h6;
parameter  WRITE_STEP_END       = 4'h7;
assign write_idle               = dma_write_state==WRITE_IDLE;
assign w_ddr_wait               = dma_write_state==W_DDR_WAIT;
assign write_ddr                = dma_write_state==WRITE_DDR;
assign write_ddr_end            = dma_write_state==WRITE_DDR_END;
assign w_dma_wait               = dma_write_state==W_DMA_WAIT;
assign write_dma                = dma_write_state==WRITE_DMA;
assign write_dma_end            = dma_write_state==WRITE_DMA_END;
assign write_step_end           = dma_write_state==WRITE_STEP_END;
reg    awvalid_dma;
assign dma_next_write_state = write_idle          ? (write_dma_again ? W_DMA_WAIT : write_ddr_again ? W_DDR_WAIT : WRITE_IDLE) :
                              w_ddr_wait          ? (awready ? WRITE_DDR : W_DDR_WAIT) :
                              write_ddr           ? (bvalid & bresp_ok & bready ? WRITE_DDR_END : WRITE_DDR) :
                              write_ddr_end       ? (write_dma_again ? W_DMA_WAIT : (count_length==0) ? WRITE_STEP_END : write_ddr_again ? W_DDR_WAIT : WRITE_DDR_END):
                              w_dma_wait          ? (awvalid_dma & awready ? WRITE_DMA : W_DMA_WAIT) :
                              write_dma           ? (bvalid & bresp_ok & bready ? WRITE_DMA_END : WRITE_DMA) :
                              write_dma_end       ? (dma_r_w ? WRITE_IDLE : (count_length==0) ? WRITE_STEP_END : write_ddr_again ? W_DDR_WAIT : WRITE_DMA_END) :
                              write_step_end      ? ((dma_trans_over | dma_stop | (count_length==0)&(dma_step_times==32'h1)) ? WRITE_IDLE :
                                                    write_dma_again ? W_DMA_WAIT : write_ddr_again ? W_DDR_WAIT : WRITE_STEP_END) : WRITE_IDLE;

wire [1:0] ac97_mod = dma_dev_addr[29:28];
wire byte_mod = (ac97_mod == 2'b00);
wire half_mod = (ac97_mod == 2'b01);
wire word_mod = (ac97_mod == 2'b10);
wire [31:0] mem_0          = mem[count_fifo_w];
wire [31:0] mem_1          = mem[count_fifo_w+1];
wire [31:0] wdata_tmp0_tmp = byte_mod ? {mem_1[23:16], mem_1[7 :0], mem_0[23:16], mem_0[7 :0]} : half_mod ? {mem_1[15: 0], mem_0[15: 0]} : mem_0;
wire [31:0] wdata_tmp1_tmp = byte_mod ? {mem_1[31:24], mem_1[15:8], mem_0[31:24], mem_0[15:8]} : half_mod ? {mem_1[31:16], mem_0[31:16]} : mem_1;
wire [31:0] wdata_tmp0     = dma_dev_addr[30] ? wdata_tmp0_tmp : mem_0;
wire [31:0] wdata_tmp1     = dma_dev_addr[30] ? wdata_tmp1_tmp : mem_0;
reg  [32:0] reg_ac97;
wire write_dev_ok = ((dma_dev_addr[31:30]==2'b11) ? (reg_ac97[32] | (count_fifo>=6'h2)) : (count_fifo>=6'h1)) & dma_req & dma_r_w;
always@(posedge clk)begin
    if(!rst_n)
        reg_ac97     <= 33'h0;
    else if(apb_penable & dma_dev_addr[31] & !reg_ac97[32])
        reg_ac97     <= {1'b1, wdata_tmp1};
    else if(apb_penable & reg_ac97[32])
        reg_ac97[32] <= 1'b0;
end

reg arvalid_dev;
always @(posedge clk)begin
    if(!rst_n)
        arvalid_dev <= 1'b0;
    else if(arvalid_dev & apb_penable)
        arvalid_dev <= 1'b0;
    else if((read_dev & !dma_get_order | read_dev_end) & read_dev_again)
        arvalid_dev <= 1'b1;
end

reg awvalid_dev;
always @(posedge clk)begin
    if(!rst_n)
        awvalid_dev <= 1'b0;
    else if(awvalid_dev & apb_penable)
        awvalid_dev <= 1'b0;
    else if(write_dev_ok)
        awvalid_dev <= 1'b1;
end
assign dma_ack_out = apb_psel;  

assign dma_state_change_en  = (dma_read_state !=dma_next_read_state) | (dma_write_state!=dma_next_write_state);
always@(posedge clk)begin
    if(!rst_n | dma_trans_over | dma_stop)begin
        dma_read_state  <= READ_IDLE;
        dma_write_state <= WRITE_IDLE;
    end else if(dma_state_change_en)begin
        dma_read_state  <= dma_next_read_state;
        dma_write_state <= dma_next_write_state;
    end
end

always@(posedge clk)begin
    if(~rst_n | finish_read_order | dma_stop)
        dma_get_order <= 1'b0;
    else if((read_idle & write_idle) & dma_start | dma_single_trans_over & dma_order_en)
        dma_get_order <= 1'b1;
end

wire [2:0] size_tmp   = read_ddr ? arsize : awsize; 
wire [1:0] read_size  = read_dev ? 2'h1 : (arsize==3'h3) ? 2'h2 : 2'h1;                              
wire [1:0] write_size = awvalid_dev ? (((dma_dev_addr[31:30]==2'b11) & (count_fifo>32'h1)) ? 2'h2 : 2'h1) : (awsize==3'h3) ? 2'h2 : 2'h1; 

always@(posedge clk)begin
    if(~rst_n)
        count_length <= 32'b0;             
    else if (dma_stop)
        count_length <= 32'b0;    
    else if(finish_read_order)
        count_length <= dma_length;    
    else if(dma_get_order)
        count_length <= `DMA_ORDERSIZE;    
    else if(((read_ddr_end | write_ddr_end) & count_length==32'b0) & (dma_step_times > 32'h1))
        count_length <= dma_length;
    else if(read_ddr & rvalid & rready & rresp_ok | write_ddr & wvalid & wready)
        count_length <= count_length - ((size_tmp==3'h3) ? 2'h2 : 2'h1);
end

reg [4:0] read_num;
reg [4:0] write_num;
always@(posedge clk)begin
    if(~rst_n | dma_single_trans_over | dma_stop)begin
        count_fifo_r <= 5'h0;
        read_num     <= 5'h0;
    end else if(read_ddr & rvalid & rready & rresp_ok | read_dev & apb_penable)begin
        count_fifo_r <= count_fifo_r + read_size;
        read_num     <= read_ddr ? (rlast ? 5'h0 : read_num + 1'b1) : read_num;
    end
end
always@(posedge clk)begin
    if(~rst_n | dma_single_trans_over | dma_stop)begin
        count_fifo_w <= 5'h0;
        write_num    <= 5'h0;
    end else if(write_ddr & wvalid & wready | awvalid_dev & apb_penable & !reg_ac97[32])begin
        count_fifo_w <= count_fifo_w + write_size;
        write_num    <= write_ddr ? (wlast ? 5'h0 : write_num + 1'b1) : write_num;
    end
end

reg write_dma_to_ddr;
reg [1:0]dma_num;

always@(posedge clk)begin
    if(~rst_n)begin
        dma_num          <= 2'h0;
        write_dma_to_ddr <= 1'h0;
end
    else if(write_dma & wvalid & wready)begin
        dma_num          <= dma_num + 1'b1;
        write_dma_to_ddr <= !write_dma_to_ddr;
end
end

wire [1:0] fifo_read_add  = {2{(read_ddr  & rvalid & rready | read_dev  & apb_penable)}} & read_size;
wire [1:0] fifo_write_sum = {2{(write_ddr & wvalid & wready | awvalid_dev & apb_penable & !reg_ac97[32])}} & write_size;
always@(posedge clk)begin
    if(~rst_n | dma_single_trans_over | dma_stop)
        count_fifo   <= 6'h0;
    else 
        count_fifo   <= count_fifo + fifo_read_add - fifo_write_sum;
end

reg arvalid_dma;
wire [31:0] araddr_dma;
wire [3 :0] arlen_dma;
wire [2 :0] arsize_dma;
reg getting_dma;
always @(posedge clk)begin
    if(!rst_n)begin
        arvalid_dma <= 1'b0;
        getting_dma <= 1'b0;
    end else if(arvalid_dma & arready)
        arvalid_dma <= 1'b0;
    else if(dma_get_order & !getting_dma)begin
        arvalid_dma <= 1'b1;
        getting_dma <= 1'b1;
    end else if(finish_read_order | dma_stop)
        getting_dma <= 1'b0;
end
assign araddr_dma  = (dma_start & dma_get_order) ? ask_addr : {dma_order_addr[31:5], 5'h0};
assign arlen_dma   = 4'h3;
assign arsize_dma  = 3'h3;

wire [2:0] arsize_ddr_tmp;
wire [3:0] arlen_ddr_tmp;
wire [5:0] left_fifo = `DMA_WORDSIZE - count_fifo;
wire       enough_8;
assign num_fifo  = (count_length >= left_fifo) ? left_fifo : count_length;
wire [3:0] arlen_tmp = (num_fifo >= 6'h10) ? 4'hf : (num_fifo-1'b1);  
assign enough_8 = (num_fifo >= 6'h2);
assign arsize_ddr_tmp = (dma_mem_addr[2:0]==3'h0) & enough_8 ? 3'h3 : 3'h2; 
assign arlen_ddr_tmp  = (dma_mem_addr[2:0]==3'h0) & enough_8 ? (num_fifo[5] ? 4'hf : (num_fifo[5:1]-1'b1)): arlen_tmp; 

reg        arvalid_ddr;
reg [31:0] araddr_ddr;
reg [3 :0] arlen_ddr;
reg [2: 0] arsize_ddr;
always @(posedge clk)begin
    if(!rst_n)
        arvalid_ddr <= 1'b0;
    else if(arready & arvalid_ddr)
        arvalid_ddr <= 1'b0;
    else if((read_ready & !dma_get_order | read_ddr_end | read_step_end) & read_ddr_again & !dma_stop)
        arvalid_ddr <= 1'b1;
end

always @(posedge clk)begin
    if(!rst_n)
        begin
        araddr_ddr <= 32'b0;
        arsize_ddr <= 3'b0;
        arlen_ddr  <= 4'b0;
        end
    else if((read_ready & !dma_get_order | read_ddr_end | read_step_end) & read_ddr_again)begin
        araddr_ddr  <= dma_mem_addr;
        arsize_ddr  <= arsize_ddr_tmp;
        arlen_ddr   <= arlen_ddr_tmp;
    end
end

assign arvalid = dma_get_order ? arvalid_dma  : dma_r_w ? arvalid_ddr  : 1'b0;
assign araddr  = dma_get_order ? {32'h0, araddr_dma} : {32'h0, araddr_ddr};
assign arsize  = dma_get_order ? arsize_dma   : arsize_ddr;
assign arlen   = dma_get_order ? arlen_dma    : arlen_ddr;
assign arid    = dma_get_order ? {4'h0, 4'h1} : {4'h0, 4'h2};
assign arburst = 2'h1;
assign arlock  = 2'h0;
assign arprot  = 3'h0;
assign arcache = 4'h0;
assign rready  = 1'h1;

wire[31:0] count_sou;
assign count_sou = araddr_ddr + {read_num, 2'h0};
wire [31:0]read_data_word = !count_sou[2] ? rdata[31:0] : rdata[63:32]; 
                            
integer i;
always@(posedge clk)
begin
    if(~rst_n | dma_stop | dma_single_trans_over)
        begin
            for(i=0;i<=31;i=i+1) mem[i] <= 32'b0;
        end
    else if(read_ddr & rvalid & rready & rresp_ok & arsize==3'h2)
        mem[count_fifo_r] <= read_data_word;
    else if(read_ddr & rvalid & rready & rresp_ok & arsize==3'h3)
         {mem[count_fifo_r+1], mem[count_fifo_r]} <= rdata;
    else if(read_dev & apb_penable) 
         mem[count_fifo_r] <= apb_rdata;
end

reg [1:0]reg_num;
always@(posedge clk)begin
    if(~rst_n | dma_stop)begin
        dma_r_w        <= 1'b0;
        dma_order_addr <= 32'b0;
        dma_mem_addr   <= 32'b0;
        dma_dev_addr   <= 32'b0;
        dma_length     <= 32'b0;
        dma_step_length<= 32'b0;
        dma_step_times <= 32'b0;
        reg_num        <= 2'b0;
    end 
    else begin
        if(read_ddr & rvalid & rready & rresp_ok | write_ddr & wvalid & wready)
            dma_mem_addr   <= dma_mem_addr + ((size_tmp==3'h3) ? 4'h8 : 3'h4); 
        else if((write_ddr_end | read_ddr_end) & (count_length==32'b0) & dma_step_times>32'b1)begin
            dma_step_times <= dma_step_times - 1;
            dma_mem_addr   <= dma_mem_addr + {dma_step_length, 2'h0};
        end else if(read_order & rvalid & rready & rresp_ok & (reg_num==2'h0))begin
            dma_order_addr <= rdata[31 : 0];
            dma_mem_addr   <= rdata[63 :32];
            reg_num        <= reg_num + 1'b1;
        end else if(read_order & rvalid & rready & rresp_ok & (reg_num==2'h1))begin
            dma_dev_addr   <= rdata[31 : 0];
            dma_length     <= rdata[63 :32];
            reg_num        <= reg_num + 1'b1;
        end else if(read_order & rvalid & rready & rresp_ok & (reg_num==2'h2))begin
            dma_step_length<= rdata[31: 0];
            dma_step_times <= rdata[63:32];
            reg_num        <= reg_num + 1'b1;
        end else if(read_order & rvalid & rready & rresp_ok & rlast)begin
            dma_r_w        <= rdata[12];
            reg_num        <= 2'b0;
        end
    end        
end

reg     dma_int_en;
reg     dma_int_i;
always@(posedge clk)begin
    if(~rst_n)
        dma_state_reg  <= 32'b0;
   else if(read_order & rvalid & rready & rresp_ok & rlast)
        dma_state_reg  <= rdata[31:0];
   else if(dma_start == 1'b1)
        dma_state_reg[1] <= 1'b0;
   else if(dma_int_i & dma_int_en)
        dma_state_reg[1] <= 1'b1;
   else if(dma_state_reg[1])
        dma_state_reg[1] <= 1'b0;
end

reg dma_int_tmp;
always@(posedge clk)
begin
    if(!rst_n)
       dma_int_i <= 1'b0;
    else if(dma_single_trans_over & dma_int_mask & !dma_int_i)
       dma_int_i <= 1'b1;
    else if(dma_int_i & dma_int_en)
        dma_int_i <= 1'b0;
end

always@(posedge clk)
begin
    if(!rst_n)
        dma_int_tmp <= 1'b0;
    else 
        dma_int_tmp <= dma_int_i;
end
always@(posedge clk)
begin
    if(!rst_n)
       dma_int_en <= 1'b1;
    else if(dma_int_tmp & dma_int_en)
       dma_int_en <= 1'b0;
    else if(!dma_int_i)
       dma_int_en <= 1'b1;
end

wire [5:0] write_length;
wire       enough_8_1;
wire [2:0] awsize_ddr_tmp;
wire [3:0] awlen_ddr_tmp;
wire [3:0] awlen_tmp;
assign write_length   = (count_fifo >= count_length) ? count_length[5:0] : count_fifo;
assign enough_8_1     = (write_length >= 3'h2);
assign awlen_tmp      = (write_length >= 5'h10) ? 4'hf : (write_length - 1'b1);  
assign awsize_ddr_tmp = (dma_mem_addr[2:0]==3'h0) & enough_8_1 ? 3'h3 : 3'h2; 
assign awlen_ddr_tmp  = (dma_mem_addr[2:0]==3'h0) & enough_8_1 ? (write_length[5]? 4'hf : (write_length[5:1] - 1'b1)) : awlen_tmp; 
reg        awvalid_ddr;
reg [31:0] awaddr_ddr;
reg [3 :0] awlen_ddr;
reg [2 :0] awsize_ddr;
reg        wvalid_ddr;
always @(posedge clk)begin
    if(!rst_n)
        awvalid_ddr <= 1'b0;
    else if(awvalid_ddr & awready)
        awvalid_ddr <= 1'b0;
    else if(write_ddr_again & !write_dma_again & (write_idle | write_ddr_end | write_dma_end | write_step_end) & !dma_stop)
        awvalid_ddr <= 1'b1;
end
always @(posedge clk)begin
    if(!rst_n)
        begin
        awaddr_ddr <= 32'b0;
        awsize_ddr <= 3'b0;
        awlen_ddr  <= 4'b0;
        end
    else if(write_ddr)begin
        awaddr_ddr <= awaddr_ddr;
        awsize_ddr <= awsize_ddr;
        awlen_ddr  <= awlen_ddr;
    end else if(write_ddr_again & !write_dma_again & (write_idle | write_ddr_end | write_dma_end | write_step_end))begin
        awaddr_ddr <= dma_mem_addr;
        awsize_ddr <= awsize_ddr_tmp; 
        awlen_ddr  <= awlen_ddr_tmp;
    end
end
always @(posedge clk)begin
    if(!rst_n)
        wvalid_ddr <= 1'b0;
    else if (awvalid_ddr & awready)begin
        wvalid_ddr <= 1'b1;
    end    
    else if(write_ddr & wvalid & wready)begin
        wvalid_ddr <= !wlast;
    end
end
assign count_obj = awaddr_ddr + {write_num, 2'h0};
wire [63:0] wdata_word = !count_obj[2] ? {32'h0, mem[count_fifo_w]} : {mem[count_fifo_w], 32'h0};
wire [7 :0] wstrb_word = !count_obj[2] ? 8'h0f : 8'hf0; 
wire [63:0] wdata_64   = {mem[count_fifo_w+1], mem[count_fifo_w]};
wire [63:0] wdata_ddr;
wire [15:0] wstrb_ddr;
wire         wlast_ddr;
assign wdata_ddr = (awsize_ddr==3'h2) ? wdata_word : wdata_64;
assign wstrb_ddr = (awsize_ddr==3'h2) ? wstrb_word : 8'hff;
assign wlast_ddr = (write_num==awlen_ddr); 

reg               wvalid_dma;
wire [31:0]       awaddr_dma;
wire [3 :0]       awlen_dma;
wire [2 :0]       awsize_dma;
wire [63:0]       wdata_dma;
wire [15 :0]      wstrb_dma;
wire              wlast_dma;
always @(posedge clk)begin
    if(!rst_n)
        awvalid_dma   <= 1'b0;
    else if(awvalid_dma & awready)
        awvalid_dma   <= 1'b0;
    else if(write_dma_again & !dma_stop & w_dma_wait)
        awvalid_dma   <= 1'b1;
end
always @(posedge clk)begin
    if(!rst_n)
        wvalid_dma    <= 1'b0;
    else if (awvalid_dma & awready)
        wvalid_dma    <= 1'b1;
    else if(write_dma & wvalid & wready)
        wvalid_dma    <= !wlast;
end

wire [63:0] dma_data0;
wire [63:0] dma_data1;
wire [63:0] dma_data2;
wire [63:0] dma_data3;
wire [31:0] dma_state_tmp = {19'h0, dma_r_w, dma_write_state, dma_read_state, dma_trans_over_reg, 
                             dma_single_trans_over, dma_int, dma_int_mask};

assign dma_data0 = {dma_mem_addr,   dma_order_addr };
assign dma_data1 = {dma_length,     dma_dev_addr   };
assign dma_data2 = {dma_step_times, dma_step_length};
assign dma_data3 = {32'h0,          dma_state_tmp  };

assign awaddr_dma  = ask_addr;  
assign awlen_dma   = 4'h3;
assign awsize_dma  = 3'h3;

assign wlast_dma  = (dma_num== 2'h3); 
assign wdata_dma  = (dma_num==2'h0) ? dma_data0 : (dma_num==2'h1) ? dma_data1 : (dma_num==2'h2) ? dma_data2 : dma_data3;
assign wstrb_dma  = (dma_num!=2'h3) ? 8'hff : 8'h0f;

assign awvalid = awvalid_dma | awvalid_ddr ;
assign awaddr  = awvalid_dma ? {32'h0, awaddr_dma} : {32'h0, awaddr_ddr};
assign awlen   = awvalid_dma ? awlen_dma  : awlen_ddr;
assign awsize  = awvalid_dma ? awsize_dma : awsize_ddr; 
assign awid    = awvalid_dma ? {4'h0, 4'h1} : {4'h0, 4'h2};
assign awburst = 2'h1; 
assign awlock  = 2'h0; 
assign awprot  = 3'h0; 
assign awcache = 4'h0; 
assign wvalid  = wvalid_dma | wvalid_ddr ;
assign wid     = wvalid_dma ? {4'h0, 4'h1} :  {4'h0, 4'h2};
assign wdata   = wvalid_dma ? wdata_dma :  wdata_ddr;
assign wstrb   = wvalid_dma ? wstrb_dma :  wstrb_ddr;
assign wlast   = wvalid_dma ? wlast_dma :  wlast_ddr;
assign bready  = 1'b1;

wire apb_valid_req;
reg  apb_psel;
reg  apb_penable;
reg  apb_rw;
wire [31:0]apb_addr;
wire [31:0]apb_wdata;
assign apb_valid_req = arvalid_dev || awvalid_dev ;
assign apb_addr = dma_dev_addr[31] ? (reg_ac97[32] ? {24'h1fe600, dma_dev_addr[15:8]} :{24'h1fe600, dma_dev_addr[7:0]}) : dma_dev_addr; 
assign apb_wdata= reg_ac97[32] ? reg_ac97[31:0] : wdata_tmp0;
always@(posedge clk)
begin
        if(~rst_n)begin
                apb_psel<= 1'b0;
                apb_penable <= 1'b0;
                apb_rw <= 1'b0;
        end
        else begin
                if(dma_gnt) begin
                        if(apb_penable)begin
                               apb_psel <= 1'b0;
                               apb_rw   <= 1'b0;
                               apb_penable <= 1'b0;
                        end else if(arvalid_dev | awvalid_dev) begin
                               apb_psel <= 1'b1;
                               apb_rw   <= awvalid_dev ;
                               apb_penable <= apb_psel;
                        end else
                               apb_penable <= apb_psel;
                 end else begin
                        apb_psel<= 1'b0;
                        apb_penable <= 1'b0;
                        apb_rw <= 1'b0;
                 end
        end
end

endmodule
