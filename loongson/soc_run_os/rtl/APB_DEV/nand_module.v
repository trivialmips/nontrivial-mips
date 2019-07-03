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

module nand_module
(
nand_type  ,

clk,
rst_n,

apb_psel,
apb_enab,
apb_rw,
apb_addr,
apb_datai,
apb_datao,
apb_ack,

nand_dma_req_o,
nand_dma_ack_i,

nand_ce    ,
nand_dat_i ,
nand_dat_o ,
nand_dat_oe,
nand_ale   ,
nand_cle   ,
nand_wr    ,	    
nand_rd    ,
nand_rdy   ,

nand_int   

);
input        [1:0]nand_type;
input        clk;
input        rst_n;
input        apb_psel;
input        apb_enab;
input        apb_rw;
input [19:0] apb_addr;
input [31:0] apb_datai;
output[31:0] apb_datao;
output       apb_ack;

output       nand_dma_req_o;
input        nand_dma_ack_i;

output [3:0] nand_ce;
input  [7:0] nand_dat_i ;
output [7:0] nand_dat_o ;
output       nand_dat_oe;
output       nand_ale;
output       nand_cle;
output       nand_wr;
output       nand_rd;
input  [3:0] nand_rdy;
output       nand_int;

wire         psel;
wire         penable;
wire  [10:0] paddr;
wire         pwr;
assign apb_ack      = apb_enab;
assign psel         = apb_psel; 
assign penable      = apb_enab; 
assign paddr        = apb_addr[10:0];
assign pwr          = apb_rw;

reg  [3:0] nand_iordy_r0;
reg  [3:0] nand_iordy_r1;
always @(posedge clk) begin
   nand_iordy_r0 <= nand_rdy;
   nand_iordy_r1 <= nand_iordy_r0;
end
reg [1:0]  nand_type_r1;
reg [1:0]  nand_type_r2;

always @(posedge clk) 
if(~rst_n)begin
   nand_type_r1 <= nand_type;
   nand_type_r2 <= nand_type_r1;
end

NAND_top NAND
(
.nand_type      (nand_type_r2       ),
.pclk           (clk                ),
.prst_          (rst_n              ),
.psel           (psel               ),
.penable        (penable            ),
.pwrite         (pwr                ),
.ADDR           (paddr              ),
.DAT_I          (apb_datai          ),
.DAT_O          (apb_datao          ),

.NAND_CE_o      (nand_ce            ),
.NAND_REQ   	(nand_dma_req_o     ),
.NAND_I         (nand_dat_i         ),
.NAND_O         (nand_dat_o         ),
.NAND_EN_       (nand_dat_oe        ),
.NAND_ALE       (nand_ale           ),
.NAND_CLE       (nand_cle           ),
.NAND_RD_       (nand_rd            ),
.NAND_WR_       (nand_wr            ),
.NAND_IORDY_i   (nand_iordy_r1      ),

.nand_int       (nand_int           )
);
endmodule
