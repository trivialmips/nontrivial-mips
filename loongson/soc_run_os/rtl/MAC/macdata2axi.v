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

module MACDATA2AXI (
  maclk               ,   
  maresetn            ,

  awid_o              ,
  awaddr_o            ,
  awlen_o             ,
  awsize_o            ,
  awburst_o           ,
  awlock_o            ,
  awcache_o           ,
  awprot_o            ,
  awvalid_o           ,
  awready_i           ,
  wid_o               ,
  wdata_o             ,
  wstrb_o             ,
  wlast_o             ,
  wvalid_o            ,
  wready_i            ,
  bid_i               ,
  bresp_i             ,
  bvalid_i            ,
  bready_o            ,
  arid_o              ,
  araddr_o            ,
  arlen_o             ,
  arsize_o            ,
  arburst_o           ,
  arlock_o            ,
  arcache_o           ,
  arprot_o            ,
  arvalid_o           ,
  arready_i           ,
  rid_i               ,
  rdata_i             ,
  rresp_i             ,
  rlast_i             ,
  rvalid_i            ,
  rready_o            ,
  datareq             , 
  datareqc            , 
  datarw              , 
  dataeob             , 
  dataeobc            , 
  dataaddr            , 
  datao               , 
  dataack             , 
  datai
  );

  parameter MAXIDATAWIDTH     = 32;
  parameter MAXIADDRESSWIDTH  = 32;
  parameter MACDATAWIDTH      = 32;
  parameter MACADDRESSWIDTH   = 32;


input maclk;
input maresetn;
output  [  3:0] awid_o              ;
output  [ 31:0] awaddr_o            ;
output  [  3:0] awlen_o             ;
output  [  2:0] awsize_o            ;
output  [  1:0] awburst_o           ;
output  [  1:0] awlock_o            ;
output  [  3:0] awcache_o           ;
output  [  2:0] awprot_o            ;
output          awvalid_o           ;
input           awready_i           ;
output  [  3:0] wid_o               ;
output  [ 31:0] wdata_o             ;
output  [  3:0] wstrb_o             ;
output          wlast_o             ;
output          wvalid_o            ;
input           wready_i            ;
input   [  3:0] bid_i               ;
input   [  1:0] bresp_i             ;
input           bvalid_i            ;
output          bready_o            ;
output  [  3:0] arid_o              ;
output  [ 31:0] araddr_o            ;
output  [  3:0] arlen_o             ;
output  [  2:0] arsize_o            ;
output  [  1:0] arburst_o           ;
output  [  1:0] arlock_o            ;
output  [  3:0] arcache_o           ;
output  [  2:0] arprot_o            ;
output          arvalid_o           ;
input           arready_i           ;
input   [  3:0] rid_i               ;
input   [ 31:0] rdata_i             ;
input   [  1:0] rresp_i             ;
input           rlast_i             ;
input           rvalid_i            ;
output          rready_o            ;                 


input     datareq; 
input     datareqc; 
input     datarw; 
input     dataeob; 
input     dataeobc; 
input     [MACADDRESSWIDTH - 1:0] dataaddr; 
input     [MACDATAWIDTH - 1:0] datao; 
output    dataack; 
wire      dataack;
output    [MACDATAWIDTH - 1:0] datai; 
wire      [MACDATAWIDTH - 1:0] datai;


assign arid_o           = 4'h1;
assign arsize_o         = 3'b010;
assign arlen_o          = 4'b0000;
assign arburst_o        = 2'b01;
assign arlock_o         = 2'b00;
assign arcache_o        = 4'b0000;
assign arprot_o         = 3'b110;

reg isWriting;
reg isReading;

always @(posedge maclk)
begin
   if (!maresetn || (wlast_o && wvalid_o && wready_i))
   begin
      isWriting <= 1'b0;
   end
   else if (awvalid_o && awready_i)
   begin
      isWriting <= 1'b1;
   end
end

always @(posedge maclk)
begin
   if (!maresetn || (rlast_i && rvalid_i && rready_o))
   begin
      isReading <= 1'b0;
   end
   else if (arvalid_o && arready_i)
   begin
      isReading <= 1'b1;
   end
end

reg  [MACADDRESSWIDTH-1:0] dataAddr_c_r;
wire [MACADDRESSWIDTH-1:0] dataAddr_c;
wire dataAddr_sel;
reg dataReq_r;

always @(posedge maclk)
begin
   dataReq_r  <= datareq;
end

wire dataAddr_c_r_en;
assign dataAddr_c_r_en = (awvalid_o & awready_i) |
                         (arvalid_o & arready_i);
always @(posedge maclk)
begin
   if (!maresetn)
   begin
      dataAddr_c_r <= 32'd0;
   end
   else if ( dataAddr_c_r_en)
   begin
      dataAddr_c_r <= dataAddr_c;
   end
end

assign dataAddr_sel = datareq & (~dataReq_r | dataeob); 
assign dataAddr_c = dataAddr_sel ? dataaddr : dataAddr_c_r+3'b100; 

wire   arvalid;
assign arvalid = datareq & datarw & ~isWriting & ~isReading;

assign araddr_o     = dataAddr_c;
assign arvalid_o    = arvalid;

assign rready_o = 1'b1;
assign datai    = rdata_i;
wire readDataAck;
assign readDataAck  = rvalid_i & rready_o;

assign awid_o           = 4'h1;
assign awsize_o         = 3'b010;
assign awlen_o          = 4'b0000;
assign awburst_o        = 2'b01;
assign awlock_o         = 2'b00;
assign awcache_o        = 4'b0000;
assign awprot_o         = 3'b110;

wire   awvalid;
assign awvalid = datareq & ~datarw & ~isWriting & ~isReading;

assign awvalid_o = awvalid;
assign awaddr_o  = dataAddr_c;

wire        wvalid;
assign  wid_o       = 4'h1;
assign  wlast_o     = 1'b1;
assign  wdata_o     = datao;
assign  wstrb_o     = 4'b1111;

assign wvalid = (awvalid_o & awready_i) | isWriting;
assign  wvalid_o    = wvalid;

wire writeDataAck;
assign writeDataAck = wvalid & wready_i;

assign  bready_o    = 1'b1;

assign  dataack    = readDataAck |  writeDataAck;

endmodule
