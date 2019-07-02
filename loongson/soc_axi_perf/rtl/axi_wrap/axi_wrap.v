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

module axi_wrap(
  input         m_aclk,
  input         m_aresetn,
  //ar
  input  [3 :0] m_arid   ,
  input  [31:0] m_araddr ,
  input  [3 :0] m_arlen  ,
  input  [2 :0] m_arsize ,
  input  [1 :0] m_arburst,
  input  [1 :0] m_arlock ,
  input  [3 :0] m_arcache,
  input  [2 :0] m_arprot ,
  input         m_arvalid,
  output        m_arready,
  //r
  output [3 :0] m_rid    ,
  output [31:0] m_rdata  ,
  output [1 :0] m_rresp  ,
  output        m_rlast  ,
  output        m_rvalid ,
  input         m_rready ,
  //aw
  input  [3 :0] m_awid   ,
  input  [31:0] m_awaddr ,
  input  [3 :0] m_awlen  ,
  input  [2 :0] m_awsize ,
  input  [1 :0] m_awburst,
  input  [1 :0] m_awlock ,
  input  [3 :0] m_awcache,
  input  [2 :0] m_awprot ,
  input         m_awvalid,
  output        m_awready,
  //w
  input  [3 :0] m_wid    ,
  input  [31:0] m_wdata  ,
  input  [3 :0] m_wstrb  ,
  input         m_wlast  ,
  input         m_wvalid ,
  output        m_wready ,
  //b
  output [3 :0] m_bid    ,
  output [1 :0] m_bresp  ,
  output        m_bvalid ,
  input         m_bready ,

  output        s_aclk,
  output        s_aresetn,
  //ar
  output [3 :0] s_arid   ,
  output [31:0] s_araddr ,
  output [3 :0] s_arlen  ,
  output [2 :0] s_arsize ,
  output [1 :0] s_arburst,
  output [1 :0] s_arlock ,
  output [3 :0] s_arcache,
  output [2 :0] s_arprot ,
  output        s_arvalid,
  input         s_arready,
  //r
  input  [3 :0] s_rid    ,
  input  [31:0] s_rdata  ,
  input  [1 :0] s_rresp  ,
  input         s_rlast  ,
  input         s_rvalid ,
  output        s_rready ,
  //aw
  output [3 :0] s_awid   ,
  output [31:0] s_awaddr ,
  output [3 :0] s_awlen  ,
  output [2 :0] s_awsize ,
  output [1 :0] s_awburst,
  output [1 :0] s_awlock ,
  output [3 :0] s_awcache,
  output [2 :0] s_awprot ,
  output        s_awvalid,
  input         s_awready,
  //w
  output [3 :0] s_wid    ,
  output [31:0] s_wdata  ,
  output [3 :0] s_wstrb  ,
  output        s_wlast  ,
  output        s_wvalid ,
  input         s_wready ,
  //b
  input  [3 :0] s_bid    ,
  input  [1 :0] s_bresp  ,
  input         s_bvalid ,
  output        s_bready  
);
assign s_aclk    = m_aclk   ;
assign s_aresetn = m_aresetn;
//ar
assign s_arid    = m_arid   ;
assign s_araddr  = m_araddr ;
assign s_arlen   = m_arlen  ;
assign s_arsize  = m_arsize ;
assign s_arburst = m_arburst;
assign s_arlock  = m_arlock ;
assign s_arcache = m_arcache;
assign s_arprot  = m_arprot ;
assign s_arvalid = m_arvalid;
assign m_arready = s_arready;
//r
assign m_rid    = m_rvalid ? s_rid   :  4'd0 ;
assign m_rdata  = m_rvalid ? s_rdata : 32'd0 ;
assign m_rresp  = m_rvalid ? s_rresp :  2'd0 ;
assign m_rlast  = m_rvalid ? s_rlast :  1'd0 ;
assign m_rvalid = s_rvalid;
assign s_rready = m_rready;
//aw
assign s_awid    = m_awid   ;
assign s_awaddr  = m_awaddr ;
assign s_awlen   = m_awlen  ;
assign s_awsize  = m_awsize ;
assign s_awburst = m_awburst;
assign s_awlock  = m_awlock ;
assign s_awcache = m_awcache;
assign s_awprot  = m_awprot ;
assign s_awvalid = m_awvalid;
assign m_awready = s_awready;
//w
assign s_wid    = m_wid    ;
assign s_wdata  = m_wdata  ;
assign s_wstrb  = m_wstrb  ;
assign s_wlast  = m_wlast  ;
assign s_wvalid = m_wvalid ;
assign m_wready = s_wready ;
//b
assign m_bid    = m_bvalid ? s_bid   : 4'd0 ;
assign m_bresp  = m_bvalid ? s_bresp : 2'd0 ;
assign m_bvalid = s_bvalid ;
assign s_bready = m_bready ;
endmodule
