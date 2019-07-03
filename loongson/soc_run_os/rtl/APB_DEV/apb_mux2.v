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

`define APB_DEV0  6'h10
`define APB_DEV1  6'h1e
module apb_mux2 (
clk,
rst_n,
apb_ack_cpu,
apb_rw_cpu,
apb_psel_cpu,
apb_enab_cpu,
apb_addr_cpu,
apb_datai_cpu,
apb_datao_cpu,
apb_high_24b_rd,
apb_high_24b_wr,
apb_word_trans_cpu,

apb_ready_dma,
apb_rw_dma,
apb_psel_dma,
apb_enab_dma,
apb_addr_dma,
apb_wdata_dma,
apb_rdata_dma,
apb_valid_dma,
apb_valid_cpu,
dma_grant,

apb0_req,
apb0_ack,
apb0_rw,
apb0_psel,
apb0_enab,
apb0_addr,
apb0_datai,
apb0_datao,

apb1_req,
apb1_ack,
apb1_rw,
apb1_psel,
apb1_enab,
apb1_addr,
apb1_datai,
apb1_datao
);

parameter ADDR_APB = 20,
          DATA_APB = 8,
          DATA_APB_32 = 32;
input                   clk,rst_n;
output                  apb_ready_dma;
input                   apb_rw_dma;
input                   apb_psel_dma;
input                   apb_enab_dma;
input [ADDR_APB-1:0]    apb_addr_dma;
input [31:0]            apb_wdata_dma;
output[31:0]            apb_rdata_dma;
output                  dma_grant;
input                   apb_valid_dma;
input                   apb_valid_cpu;

output                  apb_ack_cpu;
input                   apb_rw_cpu;
input                   apb_psel_cpu;
input                   apb_enab_cpu;
input [ADDR_APB-1:0]    apb_addr_cpu;
input [DATA_APB-1:0]    apb_datai_cpu;
output[DATA_APB-1:0]    apb_datao_cpu;
output [23:0]           apb_high_24b_rd;
input [23:0]            apb_high_24b_wr;

output                  apb_word_trans_cpu;
output                  apb0_req;
input                   apb0_ack;
output                  apb0_rw;
output                  apb0_psel;
output                  apb0_enab;
output[ADDR_APB-1:0]    apb0_addr;
output[DATA_APB-1:0]    apb0_datai;
input [DATA_APB-1:0]    apb0_datao;

output                  apb1_req;
input                   apb1_ack;
output                  apb1_rw;
output                  apb1_psel;
output                  apb1_enab;
output[ADDR_APB-1:0]    apb1_addr;
output[31:0]            apb1_datai;
input [31:0]            apb1_datao;

wire                    apb_ack; 
wire                    apb_rw;
wire                    apb_psel;
wire                    apb_enab;
wire [ADDR_APB-1:0]     apb_addr;
wire [DATA_APB-1:0]     apb_datai;
wire [23:0]high_24b_wr;
wire [23:0]high_24b_rd;
wire [7:0]apb_datao ;
wire dma_grant;

arb_2_1 arb_2_1(.clk(clk), .rst_n(rst_n), .valid0(apb_valid_cpu), .valid1(apb_valid_dma), .dma_grant(dma_grant));

assign apb_addr         = dma_grant ? apb_addr_dma:apb_addr_cpu; 
assign apb_rw           = dma_grant ? apb_rw_dma:apb_rw_cpu; 
assign apb_psel         = dma_grant ? apb_psel_dma:apb_psel_cpu; 
assign apb_enab         = dma_grant ? apb_enab_dma:apb_enab_cpu; 
assign apb_datai        = dma_grant ? apb_wdata_dma[7:0]:apb_datai_cpu; 
assign high_24b_wr      = dma_grant ? apb_wdata_dma[31:8]:apb_high_24b_wr;  
assign high_24b_rd      = apb1_req  ? apb1_datao[31:8] :  24'h0;

assign apb_word_trans_cpu = dma_grant  ? 1'h0: apb1_req;

assign apb_high_24b_rd    = dma_grant  ? 24'h0: high_24b_rd;
assign apb_datao_cpu      = dma_grant  ? 8'h0:  apb_datao;
assign apb_rdata_dma      = dma_grant  ? {high_24b_rd,apb_datao }:32'h0;
assign apb_ack_cpu        = ~dma_grant & apb_ack;
assign apb_ready_dma      = dma_grant  & apb_ack;

assign apb0_req =  (apb_addr[ADDR_APB-1:14] ==`APB_DEV0);
assign apb1_req = (apb_addr[ADDR_APB-1:14] ==`APB_DEV1);

assign apb0_psel = apb_psel && apb0_req ;
assign apb1_psel = apb_psel && apb1_req;

assign apb0_enab = apb_enab && apb0_req ;
assign apb1_enab = apb_enab && apb1_req;

assign apb_ack = apb0_req ? apb0_ack : 
                 apb1_req ? apb1_ack : 
                 1'b0;

assign apb_datao = apb0_req ? apb0_datao : 
                   apb1_req ? apb1_datao[7:0] : 
                   8'b0;



assign apb0_addr  = apb_addr;
assign apb0_datai = apb_datai;
assign apb0_rw    = apb_rw;

assign apb1_addr  = apb_addr;
assign apb1_datai = {high_24b_wr,apb_datai};
assign apb1_rw    = apb_rw;

endmodule

module arb_2_1( clk, rst_n,  valid0, valid1, dma_grant);
input   clk;
input   rst_n;
input valid0;
input valid1;
output dma_grant;
reg dma_grant; 

always @(posedge clk)
  if(~rst_n)
    dma_grant<= 1'b0;
  else if(valid0&&~valid1)
    dma_grant<= 1'b0;
  else if(valid1&&~valid0)
    dma_grant<= 1'b1;
  else if(valid0&&valid1&&~dma_grant)
    dma_grant<= 1'b0;
  else if(valid0&&valid1&&dma_grant)
    dma_grant<= 1'b1;
  else dma_grant<= 1'b0;

endmodule
