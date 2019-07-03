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

module MACCSR2AXI (
  saclk         ,
  saresetn      ,
  awid_i       ,
  awaddr_i     ,
  awlen_i      ,
  awsize_i     ,
  awburst_i    ,
  awlock_i     ,
  awcache_i    ,
  awprot_i     ,
  awvalid_i    ,
  awready_o    ,   
  wid_i        ,
  wdata_i      ,
  wstrb_i      ,
  wlast_i      ,
  wvalid_i     ,
  wready_o     ,
  bid_o        ,
  bresp_o      ,
  bvalid_o     ,
  bready_i     ,
  arid_i       ,
  araddr_i     ,
  arlen_i      ,
  arsize_i     ,
  arburst_i    ,
  arlock_i     ,
  arcache_i    ,
  arprot_i     ,
  arvalid_i    ,
  arready_o    ,
  rid_o        ,
  rdata_o      ,
  rresp_o      ,
  rlast_o      ,
  rvalid_o     ,
  rready_i     ,                 

  rstcsr        ,
  csrack        ,
  csrdatao      ,
  csrreq        ,
  csrrw         ,
  csrbe         ,
  csrdatai      ,
  csraddr
  );


  parameter SAXIDATAWIDTH     = 32;
  parameter SAXIADDRESSWIDTH  = 32;
  parameter CSRDATAWIDTH      = 32;
  parameter CSRADDRESSWIDTH   = 8;


    
  input     saclk;
  input     saresetn;
  input   [  3:0]   awid_i              ;
  input   [ 31:0]   awaddr_i            ;
  input   [  3:0]   awlen_i             ;
  input   [  2:0]   awsize_i            ;
  input   [  1:0]   awburst_i           ;
  input   [  1:0]   awlock_i            ;
  input   [  3:0]   awcache_i           ;
  input   [  2:0]   awprot_i            ;
  input             awvalid_i           ;
  output            awready_o           ;
  input   [  3:0]   wid_i               ;
  input   [ 31:0]   wdata_i             ;
  input   [  3:0]   wstrb_i             ;
  input             wlast_i             ;
  input             wvalid_i            ;
  output            wready_o            ;
  output  [  3:0]   bid_o               ;
  output  [  1:0]   bresp_o             ;
  output            bvalid_o            ;
  input             bready_i            ;
  input   [  3:0]   arid_i              ;
  input   [ 31:0]   araddr_i            ;
  input   [  3:0]   arlen_i             ;
  input   [  2:0]   arsize_i            ;
  input   [  1:0]   arburst_i           ;
  input   [  1:0]   arlock_i            ;
  input   [  3:0]   arcache_i           ;
  input   [  2:0]   arprot_i            ;
  input             arvalid_i           ;
  output            arready_o           ;
  output  [  3:0]   rid_o               ;
  output  [ 31:0]   rdata_o             ;
  output  [  1:0]   rresp_o             ;
  output            rlast_o             ;
  output            rvalid_o            ;
  input             rready_i            ;                 

    
  output    rstcsr; 
  wire      rstcsr;
  input     csrack; 
  input     [CSRDATAWIDTH - 1:0] csrdatao; 
  output    csrreq; 
  wire      csrreq;
  output    csrrw; 
  wire      csrrw;
  output    [CSRDATAWIDTH / 8 - 1:0] csrbe; 
  wire      [CSRDATAWIDTH / 8 - 1:0] csrbe;
  output    [CSRDATAWIDTH - 1:0] csrdatai; 
  wire      [CSRDATAWIDTH - 1:0] csrdatai;
  output    [CSRADDRESSWIDTH - 1:0] csraddr; 
  wire      [CSRADDRESSWIDTH - 1:0] csraddr;


reg isWriting;
reg isReading;
wire awready;
wire arready;
wire wvalid;
wire wlast;
wire wready;
wire rvalid;
wire rlast;
wire rready;

assign wvalid = wvalid_i;
assign wlast  = wlast_i;

always @(posedge saclk)
begin
   if (!saresetn || (wlast && wvalid && wready))
   begin
      isWriting <= 1'b0;
   end
   else if (awvalid_i && awready)
   begin
      isWriting <= 1'b1;
   end
end
always @(posedge saclk)
begin
   if (!saresetn || (rlast && rvalid && rready))
   begin
      isReading <= 1'b0;
   end
   else if (arvalid_i && arready)
   begin
      isReading <= 1'b1;
   end
end 

wire        arvalid; 
wire        rd_valid;
wire [1:0]  rresp;
wire [31:0] rdata;
reg [31:0]  rd_addr;
reg [3:0]   rid;
reg [2:0]   rd_size;


assign  arvalid = arvalid_i;
assign  rd_valid = arvalid & arready;
assign  rready = rready_i;
assign  rresp = 2'b00;

always @(posedge saclk)
    if(rd_valid) begin
        rid       <= arid_i;
    end

always @(posedge saclk)
begin
    if(!saresetn) begin
        rd_addr <= 32'h0;
    end 
    else if (rd_valid) begin
        rd_addr <= araddr_i;
    end
end

assign arready = csrack  & !isWriting & !isReading;
assign rvalid = csrrw & csrack;
assign rlast = 1'b1;
assign rdata = csrdatao;

reg [31:0]  wr_addr;
wire        wr_valid;
wire [3:0]  wr_strb;
wire        awvalid;
wire        bready;

assign awvalid = awvalid_i;
assign awready = csrack & !isWriting & !isReading;
assign wready = !csrrw && csrack;
assign bready = bready_i;
assign wr_strb = {4{wvalid}} & wstrb_i;
assign wr_valid = awvalid & awready;


always @(posedge saclk)
begin
    if(!saresetn) begin
        wr_addr <= 32'h0;
    end
    else if (wr_valid) begin
        wr_addr <= awaddr_i;
    end
end


wire w_resp_valid;
reg  w_resp_valid_r;
reg[3:0] bid_r;
assign w_resp_valid = wvalid & wlast & wready;
always @(posedge saclk)
     if(!saresetn) begin
       w_resp_valid_r <= 1'b0;
       bid_r          <= 4'b0;
     end
     else if(w_resp_valid) begin
        w_resp_valid_r <= 1'b1;
        bid_r          <= wid_i;
     end
     else if(bready) begin
       w_resp_valid_r <= 1'b0;
     end

wire [1:0] bresp  = 2'b00; 
wire [3:0] bid    = bid_r;
wire  bvalid = w_resp_valid_r;

assign csrdatai = wdata_i;

assign csrbe = wr_strb;

assign csraddr = csrrw ? rd_addr[7:0]: wr_addr[7:0];

assign csrreq = isWriting | isReading;

assign csrrw = isReading;

assign rstcsr = ~saresetn;

assign awready_o = awready;
assign wready_o = wready;

assign bid_o = bid;
assign bresp_o = bresp;
assign bvalid_o = bvalid;

assign arready_o = arready;
assign rid_o = rid;
assign rdata_o = rdata;
assign rresp_o = rresp;
assign rlast_o = rlast;
assign rvalid_o = rvalid;

endmodule
