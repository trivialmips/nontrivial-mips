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

`define SLV_MUX_5
`define SLV_MUX_NUM  5
`include "config.h"
module axi_slave_mux(
spi_boot,
axi_s_aclk,
axi_s_awid,
axi_s_awaddr,
axi_s_awlen,
axi_s_awsize,
axi_s_awburst,
axi_s_awlock,
axi_s_awcache,
axi_s_awprot,
axi_s_awvalid,
axi_s_awready,
axi_s_wready,
axi_s_wid,
axi_s_wdata,
axi_s_wstrb,
axi_s_wlast,
axi_s_wvalid,
axi_s_bid,
axi_s_bresp,
axi_s_bvalid,
axi_s_bready,
axi_s_arid,
axi_s_araddr,
axi_s_arlen,
axi_s_arsize,
axi_s_arburst,
axi_s_arlock,
axi_s_arcache,
axi_s_arprot,
axi_s_arvalid,
axi_s_arready,
axi_s_rready,
axi_s_rid,
axi_s_rdata,
axi_s_rresp,
axi_s_rlast,
axi_s_rvalid,

s0_awid,
s0_awaddr,
s0_awlen,
s0_awsize,
s0_awburst,
s0_awlock,
s0_awcache,
s0_awprot,
s0_awvalid,
s0_awready,
s0_wid,
s0_wdata,
s0_wstrb,
s0_wlast,
s0_wvalid,
s0_wready,
s0_bid,
s0_bresp,
s0_bvalid,
s0_bready,
s0_arid,
s0_araddr,
s0_arlen,
s0_arsize,
s0_arburst,
s0_arlock,
s0_arcache,
s0_arprot,
s0_arvalid,
s0_arready,
s0_rid,
s0_rdata,
s0_rresp,
s0_rlast,
s0_rvalid,
s0_rready,

s1_awid,
s1_awaddr,
s1_awlen,
s1_awsize,
s1_awburst,
s1_awlock,
s1_awcache,
s1_awprot,
s1_awvalid,
s1_awready,
s1_wid,
s1_wdata,
s1_wstrb,
s1_wlast,
s1_wvalid,
s1_wready,
s1_bid,
s1_bresp,
s1_bvalid,
s1_bready,
s1_arid,
s1_araddr,
s1_arlen,
s1_arsize,
s1_arburst,
s1_arlock,
s1_arcache,
s1_arprot,
s1_arvalid,
s1_arready,
s1_rid,
s1_rdata,
s1_rresp,
s1_rlast,
s1_rvalid,
s1_rready,

s2_awid,
s2_awaddr,
s2_awlen,
s2_awsize,
s2_awburst,
s2_awlock,
s2_awcache,
s2_awprot,
s2_awvalid,
s2_awready,
s2_wid,
s2_wdata,
s2_wstrb,
s2_wlast,
s2_wvalid,
s2_wready,
s2_bid,
s2_bresp,
s2_bvalid,
s2_bready,
s2_arid,
s2_araddr,
s2_arlen,
s2_arsize,
s2_arburst,
s2_arlock,
s2_arcache,
s2_arprot,
s2_arvalid,
s2_arready,
s2_rid,
s2_rdata,
s2_rresp,
s2_rlast,
s2_rvalid,
s2_rready,
s3_awid,
s3_awaddr,
s3_awlen,
s3_awsize,
s3_awburst,
s3_awlock,
s3_awcache,
s3_awprot,
s3_awvalid,
s3_awready,
s3_wid,
s3_wdata,
s3_wstrb,
s3_wlast,
s3_wvalid,
s3_wready,
s3_bid,
s3_bresp,
s3_bvalid,
s3_bready,
s3_arid,
s3_araddr,
s3_arlen,
s3_arsize,
s3_arburst,
s3_arlock,
s3_arcache,
s3_arprot,
s3_arvalid,
s3_arready,
s3_rid,
s3_rdata,
s3_rresp,
s3_rlast,
s3_rvalid,
s3_rready,
s4_awid,
s4_awaddr,
s4_awlen,
s4_awsize,
s4_awburst,
s4_awlock,
s4_awcache,
s4_awprot,
s4_awvalid,
s4_awready,
s4_wid,
s4_wdata,
s4_wstrb,
s4_wlast,
s4_wvalid,
s4_wready,
s4_bid,
s4_bresp,
s4_bvalid,
s4_bready,
s4_arid,
s4_araddr,
s4_arlen,
s4_arsize,
s4_arburst,
s4_arlock,
s4_arcache,
s4_arprot,
s4_arvalid,
s4_arready,
s4_rid,
s4_rdata,
s4_rresp,
s4_rlast,
s4_rvalid,
s4_rready,

axi_s_aresetn
);

input               spi_boot;
input               axi_s_aclk;
input               axi_s_aresetn;

input  [`LID         -1 :0] axi_s_awid;
input  [`Lawaddr     -1 :0] axi_s_awaddr;
input  [`Lawlen      -1 :0] axi_s_awlen;
input  [`Lawsize     -1 :0] axi_s_awsize;
input  [`Lawburst    -1 :0] axi_s_awburst;
input  [`Lawlock     -1 :0] axi_s_awlock;
input  [`Lawcache    -1 :0] axi_s_awcache;
input  [`Lawprot     -1 :0] axi_s_awprot;
input                       axi_s_awvalid;
output                      axi_s_awready;
input  [`LID         -1 :0] axi_s_wid;
input  [`Lwdata      -1 :0] axi_s_wdata;
input  [`Lwstrb      -1 :0] axi_s_wstrb;
input                       axi_s_wlast;
input                       axi_s_wvalid;
output                      axi_s_wready;
output [`LID         -1 :0] axi_s_bid;
output [`Lbresp      -1 :0] axi_s_bresp;
output                      axi_s_bvalid;
input                       axi_s_bready;
input  [`LID         -1 :0] axi_s_arid;
input  [`Laraddr     -1 :0] axi_s_araddr;
input  [`Larlen      -1 :0] axi_s_arlen;
input  [`Larsize     -1 :0] axi_s_arsize;
input  [`Larburst    -1 :0] axi_s_arburst;
input  [`Larlock     -1 :0] axi_s_arlock;
input  [`Larcache    -1 :0] axi_s_arcache;
input  [`Larprot     -1 :0] axi_s_arprot;
input                       axi_s_arvalid;
output                      axi_s_arready;
output [`LID         -1 :0] axi_s_rid;
output [`Lrdata      -1 :0] axi_s_rdata;
output [`Lrresp      -1 :0] axi_s_rresp;
output                      axi_s_rlast;
output                      axi_s_rvalid;
input                       axi_s_rready;




output [`LID         -1 :0] s0_awid;
output [`Lawaddr     -1 :0] s0_awaddr;
output [`Lawlen      -1 :0] s0_awlen;
output [`Lawsize     -1 :0] s0_awsize;
output [`Lawburst    -1 :0] s0_awburst;
output [`Lawlock     -1 :0] s0_awlock;
output [`Lawcache    -1 :0] s0_awcache;
output [`Lawprot     -1 :0] s0_awprot;
output                      s0_awvalid;
input                       s0_awready;
output [`LID         -1 :0] s0_wid;
output [`Lwdata      -1 :0] s0_wdata;
output [`Lwstrb      -1 :0] s0_wstrb;
output                      s0_wlast;
output                      s0_wvalid;
input                       s0_wready;
input  [`LID         -1 :0] s0_bid;
input  [`Lbresp      -1 :0] s0_bresp;
input                       s0_bvalid;
output                      s0_bready;
output [`LID         -1 :0] s0_arid;
output [`Laraddr     -1 :0] s0_araddr;
output [`Larlen      -1 :0] s0_arlen;
output [`Larsize     -1 :0] s0_arsize;
output [`Larburst    -1 :0] s0_arburst;
output [`Larlock     -1 :0] s0_arlock;
output [`Larcache    -1 :0] s0_arcache;
output [`Larprot     -1 :0] s0_arprot;
output                      s0_arvalid;
input                       s0_arready;
input  [`LID         -1 :0] s0_rid;
input  [`Lrdata      -1 :0] s0_rdata;
input  [`Lrresp      -1 :0] s0_rresp;
input                       s0_rlast;
input                       s0_rvalid;
output                      s0_rready;

output [`LID         -1 :0] s1_awid;
output [`Lawaddr     -1 :0] s1_awaddr;
output [`Lawlen      -1 :0] s1_awlen;
output [`Lawsize     -1 :0] s1_awsize;
output [`Lawburst    -1 :0] s1_awburst;
output [`Lawlock     -1 :0] s1_awlock;
output [`Lawcache    -1 :0] s1_awcache;
output [`Lawprot     -1 :0] s1_awprot;
output                      s1_awvalid;
input                       s1_awready;
output [`LID         -1 :0] s1_wid;
output [`Lwdata      -1 :0] s1_wdata;
output [`Lwstrb      -1 :0] s1_wstrb;
output                      s1_wlast;
output                      s1_wvalid;
input                       s1_wready;
input  [`LID         -1 :0] s1_bid;
input  [`Lbresp      -1 :0] s1_bresp;
input                       s1_bvalid;
output                      s1_bready;
output [`LID         -1 :0] s1_arid;
output [`Laraddr     -1 :0] s1_araddr;
output [`Larlen      -1 :0] s1_arlen;
output [`Larsize     -1 :0] s1_arsize;
output [`Larburst    -1 :0] s1_arburst;
output [`Larlock     -1 :0] s1_arlock;
output [`Larcache    -1 :0] s1_arcache;
output [`Larprot     -1 :0] s1_arprot;
output                      s1_arvalid;
input                       s1_arready;
input  [`LID         -1 :0] s1_rid;
input  [`Lrdata      -1 :0] s1_rdata;
input  [`Lrresp      -1 :0] s1_rresp;
input                       s1_rlast;
input                       s1_rvalid;
output                      s1_rready;


output [`LID         -1 :0] s2_awid;
output [`Lawaddr     -1 :0] s2_awaddr;
output [`Lawlen      -1 :0] s2_awlen;
output [`Lawsize     -1 :0] s2_awsize;
output [`Lawburst    -1 :0] s2_awburst;
output [`Lawlock     -1 :0] s2_awlock;
output [`Lawcache    -1 :0] s2_awcache;
output [`Lawprot     -1 :0] s2_awprot;
output                      s2_awvalid;
input                       s2_awready;
output [`LID         -1 :0] s2_wid;
output [`Lwdata      -1 :0] s2_wdata;
output [`Lwstrb      -1 :0] s2_wstrb;
output                      s2_wlast;
output                      s2_wvalid;
input                       s2_wready;
input  [`LID         -1 :0] s2_bid;
input  [`Lbresp      -1 :0] s2_bresp;
input                       s2_bvalid;
output                      s2_bready;
output [`LID         -1 :0] s2_arid;
output [`Laraddr     -1 :0] s2_araddr;
output [`Larlen      -1 :0] s2_arlen;
output [`Larsize     -1 :0] s2_arsize;
output [`Larburst    -1 :0] s2_arburst;
output [`Larlock     -1 :0] s2_arlock;
output [`Larcache    -1 :0] s2_arcache;
output [`Larprot     -1 :0] s2_arprot;
output                      s2_arvalid;
input                       s2_arready;
input  [`LID         -1 :0] s2_rid;
input  [`Lrdata      -1 :0] s2_rdata;
input  [`Lrresp      -1 :0] s2_rresp;
input                       s2_rlast;
input                       s2_rvalid;
output                      s2_rready;

output [`LID         -1 :0] s3_awid;
output [`Lawaddr     -1 :0] s3_awaddr;
output [`Lawlen      -1 :0] s3_awlen;
output [`Lawsize     -1 :0] s3_awsize;
output [`Lawburst    -1 :0] s3_awburst;
output [`Lawlock     -1 :0] s3_awlock;
output [`Lawcache    -1 :0] s3_awcache;
output [`Lawprot     -1 :0] s3_awprot;
output                      s3_awvalid;
input                       s3_awready;
output [`LID         -1 :0] s3_wid;
output [`Lwdata      -1 :0] s3_wdata;
output [`Lwstrb      -1 :0] s3_wstrb;
output                      s3_wlast;
output                      s3_wvalid;
input                       s3_wready;
input  [`LID         -1 :0] s3_bid;
input  [`Lbresp      -1 :0] s3_bresp;
input                       s3_bvalid;
output                      s3_bready;
output [`LID         -1 :0] s3_arid;
output [`Laraddr     -1 :0] s3_araddr;
output [`Larlen      -1 :0] s3_arlen;
output [`Larsize     -1 :0] s3_arsize;
output [`Larburst    -1 :0] s3_arburst;
output [`Larlock     -1 :0] s3_arlock;
output [`Larcache    -1 :0] s3_arcache;
output [`Larprot     -1 :0] s3_arprot;
output                      s3_arvalid;
input                       s3_arready;
input  [`LID         -1 :0] s3_rid;
input  [`Lrdata      -1 :0] s3_rdata;
input  [`Lrresp      -1 :0] s3_rresp;
input                       s3_rlast;
input                       s3_rvalid;
output                      s3_rready;


output [`LID         -1 :0] s4_awid;
output [`Lawaddr     -1 :0] s4_awaddr;
output [`Lawlen      -1 :0] s4_awlen;
output [`Lawsize     -1 :0] s4_awsize;
output [`Lawburst    -1 :0] s4_awburst;
output [`Lawlock     -1 :0] s4_awlock;
output [`Lawcache    -1 :0] s4_awcache;
output [`Lawprot     -1 :0] s4_awprot;
output                      s4_awvalid;
input                       s4_awready;
output [`LID         -1 :0] s4_wid;
output [`Lwdata      -1 :0] s4_wdata;
output [`Lwstrb      -1 :0] s4_wstrb;
output                      s4_wlast;
output                      s4_wvalid;
input                       s4_wready;
input  [`LID         -1 :0] s4_bid;
input  [`Lbresp      -1 :0] s4_bresp;
input                       s4_bvalid;
output                      s4_bready;
output [`LID         -1 :0] s4_arid;
output [`Laraddr     -1 :0] s4_araddr;
output [`Larlen      -1 :0] s4_arlen;
output [`Larsize     -1 :0] s4_arsize;
output [`Larburst    -1 :0] s4_arburst;
output [`Larlock     -1 :0] s4_arlock;
output [`Larcache    -1 :0] s4_arcache;
output [`Larprot     -1 :0] s4_arprot;
output                      s4_arvalid;
input                       s4_arready;
input  [`LID         -1 :0] s4_rid;
input  [`Lrdata      -1 :0] s4_rdata;
input  [`Lrresp      -1 :0] s4_rresp;
input                       s4_rlast;
input                       s4_rvalid;
output                      s4_rready;

wire                clk;
wire                rst_n;


reg [`LID -1:0]   axi_s_rid;
reg [`Lrdata-1:0]axi_s_rdata; 
reg [1:0]axi_s_rresp; 
reg axi_s_rlast; 
reg axi_s_rvalid; 
reg axi_s_arready; 

reg [`SLV_MUX_NUM-1:0]wr_data_s_hit;

wire [`SLV_MUX_NUM-1:0]rd_addr_hit;
wire [`SLV_MUX_NUM-1:0]wr_addr_hit;
reg [`SLV_MUX_NUM-1:0]wr_resp_s_hit ;

wire [`SLV_MUX_NUM-1:0]s_awready  ;
wire [`SLV_MUX_NUM-1:0]s_wready   ;
wire [`SLV_MUX_NUM-1:0]s_bvalid   ;
wire [`SLV_MUX_NUM-1:0]s_arready  ;
wire [`SLV_MUX_NUM-1:0]s_rlast    ;
wire [`SLV_MUX_NUM-1:0]s_rvalid   ;

wire [`LID -1:0]   s_bid      [`SLV_MUX_NUM-1:0];
wire [1:0]         s_bresp    [`SLV_MUX_NUM-1:0];
wire [`LID -1:0]   s_rid      [`SLV_MUX_NUM-1:0];
wire [`Lrdata-1:0] s_rdata    [`SLV_MUX_NUM-1:0];
wire [1:0]         s_rresp    [`SLV_MUX_NUM-1:0];

wire s0_awvalid          ;
wire s0_wvalid           ;
wire s0_bready           ;
wire s0_arvalid          ;
wire s0_rready           ;


assign s0_awid    = axi_s_awid; 
assign s0_awaddr  = axi_s_awaddr;
assign s0_awlen   = axi_s_awlen;
assign s0_awsize  = axi_s_awsize;
assign s0_awburst = axi_s_awburst;
assign s0_awlock  = axi_s_awlock;
assign s0_awcache = axi_s_awcache;
assign s0_awprot  = axi_s_awprot;
assign s0_wid     = axi_s_wid; 
assign s0_wdata   = axi_s_wdata;
assign s0_wstrb   = axi_s_wstrb;
assign s0_wlast   = axi_s_wlast;
assign s0_arid    = axi_s_arid; 
assign s0_araddr  = axi_s_araddr;
assign s0_arlen   = axi_s_arlen;
assign s0_arsize  = axi_s_arsize;
assign s0_arburst = axi_s_arburst;
assign s0_arlock  = axi_s_arlock;
assign s0_arcache = axi_s_arcache;
assign s0_arprot  = axi_s_arprot;

wire s1_awvalid          ;
wire s1_wvalid           ;
wire s1_bready           ;
wire s1_arvalid          ;
wire s1_rready           ;

assign s1_awid    = axi_s_awid; 
assign s1_awaddr  = axi_s_awaddr;
assign s1_awlen   = axi_s_awlen;
assign s1_awsize  = axi_s_awsize;
assign s1_awburst = axi_s_awburst;
assign s1_awlock  = axi_s_awlock;
assign s1_awcache = axi_s_awcache;
assign s1_awprot  = axi_s_awprot;
assign s1_wid     = axi_s_wid; 
assign s1_wdata   = axi_s_wdata;
assign s1_wstrb   = axi_s_wstrb;
assign s1_wlast   = axi_s_wlast;
assign s1_arid    = axi_s_arid; 
assign s1_araddr  = axi_s_araddr;
assign s1_arlen   = axi_s_arlen;
assign s1_arsize  = axi_s_arsize;
assign s1_arburst = axi_s_arburst;
assign s1_arlock  = axi_s_arlock;
assign s1_arcache = axi_s_arcache;
assign s1_arprot  = axi_s_arprot;

wire s2_awvalid          ;
wire s2_wvalid           ;
wire s2_bready           ;
wire s2_arvalid          ;
wire s2_rready           ;
assign s2_awid    = axi_s_awid; 
assign s2_awaddr  = axi_s_awaddr;
assign s2_awlen   = axi_s_awlen;
assign s2_awsize  = axi_s_awsize;
assign s2_awburst = axi_s_awburst;
assign s2_awlock  = axi_s_awlock;
assign s2_awcache = axi_s_awcache;
assign s2_awprot  = axi_s_awprot;
assign s2_wid     = axi_s_wid; 
assign s2_wdata   = axi_s_wdata;
assign s2_wstrb   = axi_s_wstrb;
assign s2_wlast   = axi_s_wlast;
assign s2_arid    = axi_s_arid; 
assign s2_araddr  = axi_s_araddr;
assign s2_arlen   = axi_s_arlen;
assign s2_arsize  = axi_s_arsize;
assign s2_arburst = axi_s_arburst;
assign s2_arlock  = axi_s_arlock;
assign s2_arcache = axi_s_arcache;
assign s2_arprot  = axi_s_arprot;
wire s3_awvalid          ;
wire s3_wvalid           ;
wire s3_bready           ;
wire s3_arvalid          ;
wire s3_rready           ;
assign s3_awid    = axi_s_awid; 
assign s3_awaddr  = axi_s_awaddr;
assign s3_awlen   = axi_s_awlen;
assign s3_awsize  = axi_s_awsize;
assign s3_awburst = axi_s_awburst;
assign s3_awlock  = axi_s_awlock;
assign s3_awcache = axi_s_awcache;
assign s3_awprot  = axi_s_awprot;
assign s3_wid     = axi_s_wid; 
assign s3_wdata   = axi_s_wdata;
assign s3_wstrb   = axi_s_wstrb;
assign s3_wlast   = axi_s_wlast;
assign s3_arid    = axi_s_arid; 
assign s3_araddr  = axi_s_araddr;
assign s3_arlen   = axi_s_arlen;
assign s3_arsize  = axi_s_arsize;
assign s3_arburst = axi_s_arburst;
assign s3_arlock  = axi_s_arlock;
assign s3_arcache = axi_s_arcache;
assign s3_arprot  = axi_s_arprot;
wire s4_awvalid          ;
wire s4_wvalid           ;
wire s4_bready           ;
wire s4_arvalid          ;
wire s4_rready           ;
assign s4_awid    = axi_s_awid; 
assign s4_awaddr  = axi_s_awaddr;
assign s4_awlen   = axi_s_awlen;
assign s4_awsize  = axi_s_awsize;
assign s4_awburst = axi_s_awburst;
assign s4_awlock  = axi_s_awlock;
assign s4_awcache = axi_s_awcache;
assign s4_awprot  = axi_s_awprot;
assign s4_wid     = axi_s_wid; 
assign s4_wdata   = axi_s_wdata;
assign s4_wstrb   = axi_s_wstrb;
assign s4_wlast   = axi_s_wlast;
assign s4_arid    = axi_s_arid; 
assign s4_araddr  = axi_s_araddr;
assign s4_arlen   = axi_s_arlen;
assign s4_arsize  = axi_s_arsize;
assign s4_arburst = axi_s_arburst;
assign s4_arlock  = axi_s_arlock;
assign s4_arcache = axi_s_arcache;
assign s4_arprot  = axi_s_arprot;

reg [`SLV_MUX_NUM-1:0] s_awvalid;
reg [`SLV_MUX_NUM-1:0] s_wvalid ;
reg [`SLV_MUX_NUM-1:0] s_bready ;
reg [`SLV_MUX_NUM-1:0] s_arvalid;
reg [`SLV_MUX_NUM-1:0] s_rready ;

assign s0_awvalid          =        s_awvalid[0]  ;
assign s0_wvalid           =        s_wvalid [0]  ;
assign s0_bready           =        s_bready [0]  ;
assign s0_arvalid          =        s_arvalid[0]  ;
assign s0_rready           =        s_rready [0]  ;

assign s1_awvalid          =        s_awvalid[1]  ;
assign s1_wvalid           =        s_wvalid [1]  ;
assign s1_bready           =        s_bready [1]  ;
assign s1_arvalid          =        s_arvalid[1]  ;
assign s1_rready           =        s_rready [1]  ;

assign s2_awvalid          =        s_awvalid[2]  ;
assign s2_wvalid           =        s_wvalid [2]  ;
assign s2_bready           =        s_bready [2]  ;
assign s2_arvalid          =        s_arvalid[2]  ;
assign s2_rready           =        s_rready [2]  ;
assign s3_awvalid          =        s_awvalid[3]  ;
assign s3_wvalid           =        s_wvalid [3]  ;
assign s3_bready           =        s_bready [3]  ;
assign s3_arvalid          =        s_arvalid[3]  ;
assign s3_rready           =        s_rready [3]  ;
assign s4_awvalid          =        s_awvalid[4]  ;
assign s4_wvalid           =        s_wvalid [4]  ;
assign s4_bready           =        s_bready [4]  ;
assign s4_arvalid          =        s_arvalid[4]  ;
assign s4_rready           =        s_rready [4]  ;

assign s_awready[0]  = s0_awready  ;
assign s_wready[0]   = s0_wready   ;
assign s_bid[0]      = s0_bid      ;
assign s_bresp[0]    = s0_bresp    ;
assign s_bvalid[0]   = s0_bvalid   ;
assign s_arready[0]  = s0_arready  ;
assign s_rid[0]      = s0_rid      ;
assign s_rdata[0]    = s0_rdata    ;
assign s_rresp[0]    = s0_rresp    ;
assign s_rlast[0]    = s0_rlast    ;
assign s_rvalid[0]   = s0_rvalid   ;
assign s_awready[1]  = s1_awready  ;
assign s_wready[1]   = s1_wready   ;
assign s_bid[1]      = s1_bid      ;
assign s_bresp[1]    = s1_bresp    ;
assign s_bvalid[1]   = s1_bvalid   ;
assign s_arready[1]  = s1_arready  ;
assign s_rid[1]      = s1_rid      ;
assign s_rdata[1]    = s1_rdata    ;
assign s_rresp[1]    = s1_rresp    ;
assign s_rlast[1]    = s1_rlast    ;
assign s_rvalid[1]   = s1_rvalid   ;

assign s_awready[2]  = s2_awready  ;
assign s_wready[2]   = s2_wready   ;
assign s_bid[2]      = s2_bid      ;
assign s_bresp[2]    = s2_bresp    ;
assign s_bvalid[2]   = s2_bvalid   ;
assign s_arready[2]  = s2_arready  ;
assign s_rid[2]      = s2_rid      ;
assign s_rdata[2]    = s2_rdata    ;
assign s_rresp[2]    = s2_rresp    ;
assign s_rlast[2]    = s2_rlast    ;
assign s_rvalid[2]   = s2_rvalid   ;
assign s_awready[3]  = s3_awready  ;
assign s_wready[3]   = s3_wready   ;
assign s_bid[3]      = s3_bid      ;
assign s_bresp[3]    = s3_bresp    ;
assign s_bvalid[3]   = s3_bvalid   ;
assign s_arready[3]  = s3_arready  ;
assign s_rid[3]      = s3_rid      ;
assign s_rdata[3]    = s3_rdata    ;
assign s_rresp[3]    = s3_rresp    ;
assign s_rlast[3]    = s3_rlast    ;
assign s_rvalid[3]   = s3_rvalid   ;
assign s_awready[4]  = s4_awready  ;
assign s_wready[4]   = s4_wready   ;
assign s_bid[4]      = s4_bid      ;
assign s_bresp[4]    = s4_bresp    ;
assign s_bvalid[4]   = s4_bvalid   ;
assign s_arready[4]  = s4_arready  ;
assign s_rid[4]      = s4_rid      ;
assign s_rdata[4]    = s4_rdata    ;
assign s_rresp[4]    = s4_rresp    ;
assign s_rlast[4]    = s4_rlast    ;
assign s_rvalid[4]   = s4_rvalid   ;

wire [4:0]BASE_ADDR [`SLV_MUX_NUM-1:0];
wire [2:0]wr_sel_group_0;
wire [2:0]wr_sel_group_1;
wire [2:0]bvalid_group_0;
wire [2:0]bvalid_group_1;

wire [2:0]rd_sel_group_0;
wire [2:0]rd_sel_group_1;
wire [2:0]rd_valid_group_0;
wire [2:0]rd_valid_group_1;

assign bvalid_group_0 = s_bvalid[2:0];
assign bvalid_group_1 = {1'b0,s_bvalid[4:3]};
assign rd_valid_group_0 = s_rvalid[2:0];
assign rd_valid_group_1 = {1'b0,s_rvalid[4:3]};

wire                wr_fifo_empty;
wire                wr_fifo_full;
wire                rd_fifo_empty;
wire                rd_fifo_full;

assign clk        = axi_s_aclk;
assign rst_n      = axi_s_aresetn;

reg axi_s_awready ;
reg axi_s_wready ;
reg axi_s_bvalid; 
reg [`LID -1:0] axi_s_bid;
reg [1:0]       axi_s_bresp; 
wire        wr_dir_ins;
wire        wr_dir_del;
wire [2:0]  wr_data_dir;
reg  [2:0]  wr_addr_dir;
reg  [2:0]  wr_resp_pre_sel;
reg         wr_resp_prog;
reg  [2:0]  wr_resp_sel_reg;
wire [2:0]  wr_resp_sel;

integer axi_s_awready_int; 
always @(s_awready or wr_fifo_full or wr_addr_hit)
begin
        axi_s_awready = 1'b0;
    for(axi_s_awready_int= 0 ; axi_s_awready_int< `SLV_MUX_NUM ;axi_s_awready_int=axi_s_awready_int+ 1)
        begin
        if(!wr_fifo_full  & wr_addr_hit[axi_s_awready_int])
            axi_s_awready = s_awready[axi_s_awready_int]; 
        end
end

integer awvlid_int;
always @(axi_s_awvalid or wr_fifo_full or wr_addr_hit)
begin
    for(awvlid_int= 0 ; awvlid_int< `SLV_MUX_NUM ;awvlid_int=awvlid_int+ 1)
          s_awvalid [awvlid_int] = !wr_fifo_full && wr_addr_hit[awvlid_int] && axi_s_awvalid;
end

integer resp_int;
always @(wr_resp_prog or wr_resp_sel  or wr_resp_sel_reg )
begin
    for(resp_int= 0 ; resp_int< `SLV_MUX_NUM ;resp_int= resp_int+ 1)
        wr_resp_s_hit [resp_int]  =  !wr_resp_prog && wr_resp_sel == resp_int|| wr_resp_prog && wr_resp_sel_reg == resp_int;
end

assign wr_sel_group_0=get_num(bvalid_group_0,wr_resp_pre_sel,2'h0); 
assign wr_sel_group_1=get_num(bvalid_group_1,wr_resp_pre_sel,2'h3); 
assign wr_resp_sel= ((wr_sel_group_0== 3'h7)  && (wr_sel_group_1== 3'h7) ) ? 3'h7:  
                    ((wr_sel_group_0!= 3'h7)  && (wr_sel_group_1== 3'h7) ) ?wr_sel_group_0:  
                    ((wr_sel_group_0== 3'h7)  && (wr_sel_group_1!= 3'h7) ) ?wr_sel_group_1:  
                    (wr_resp_pre_sel > 2'h2) ? wr_sel_group_0 : wr_sel_group_1;

integer axi_s_resp_int; 
always @(*)
begin
            axi_s_bid       =8'h0;
            axi_s_bresp     =2'h0;
            axi_s_bvalid    =1'h0;
    for(axi_s_resp_int= 0 ; axi_s_resp_int< `SLV_MUX_NUM ;axi_s_resp_int=axi_s_resp_int+ 1)
        begin
            s_bready [axi_s_resp_int]  = 1'b0;
        if(wr_resp_s_hit[axi_s_resp_int])
        begin
            axi_s_bid       = s_bid[axi_s_resp_int];
            axi_s_bresp     = s_bresp[axi_s_resp_int];
            axi_s_bvalid    = s_bvalid[axi_s_resp_int];
            s_bready [axi_s_resp_int]  = axi_s_bready;
        end
        end
end

assign wr_dir_ins = !wr_fifo_full && axi_s_awvalid && axi_s_awready;
assign wr_dir_del = !wr_fifo_empty && axi_s_wvalid && axi_s_wready && axi_s_wlast;

integer w_addr_dir_int;
always @(wr_addr_hit)
begin
        wr_addr_dir =  3'b0;
    for(w_addr_dir_int= 0 ; w_addr_dir_int< `SLV_MUX_NUM ;w_addr_dir_int= w_addr_dir_int+ 1)
        if(wr_addr_hit[w_addr_dir_int])
        wr_addr_dir =w_addr_dir_int;
end

integer w_ad_int;
always @(wr_fifo_empty or  wr_data_dir )
begin
    for(w_ad_int = 0 ; w_ad_int < `SLV_MUX_NUM ;w_ad_int = w_ad_int + 1)
        wr_data_s_hit[w_ad_int]  =  (!wr_fifo_empty && wr_data_dir == w_ad_int);
end

assign wr_addr_hit[1] = axi_s_awaddr[31:20]==12'h1fc ||
                        axi_s_awaddr[31:16]==16'h1fe8;  //SPI
assign wr_addr_hit[2] = axi_s_awaddr[31:16]==16'h1fe4 ||
                        axi_s_awaddr[31:16]==16'h1fe7 ; //APB: uart and nand
assign wr_addr_hit[3] = axi_s_awaddr[31:16]==16'h1fd0;  //CONF
assign wr_addr_hit[4] = axi_s_awaddr[31:16]==16'h1ff0;  //MAC
assign wr_addr_hit[0] = ~|wr_addr_hit[4:1];             //DDR3

nb_sync_fifo_mux wr_fifo
(
.clk(clk),
.rst_n(rst_n),

.empty(wr_fifo_empty),
.full(wr_fifo_full),

.shift_in(wr_dir_ins),
.data_in(wr_addr_dir),

.shift_out(wr_dir_del),
.data_out(wr_data_dir)
);

always@(posedge clk) begin
  if(!rst_n)
    wr_resp_pre_sel <= 3'b0;
  else if(axi_s_bvalid && axi_s_bready)
    wr_resp_pre_sel <= wr_resp_sel; 
end


always@(posedge clk) begin
  if(!rst_n || axi_s_bvalid && axi_s_bready)
    wr_resp_prog <= 1'b0;
  else if(!wr_resp_prog && (|s_bvalid) )
    wr_resp_prog <= 1'b1;
end

always@(posedge clk) begin
  if(!rst_n)
    wr_resp_sel_reg <= 3'b0;
  else if(!wr_resp_prog && (|s_bvalid) )
    wr_resp_sel_reg <= wr_resp_sel;
end

integer axi_s_wready_int; 
always @(s_wready or wr_data_s_hit)
begin
        axi_s_wready = 1'b0;
    for(axi_s_wready_int= 0 ; axi_s_wready_int< `SLV_MUX_NUM ;axi_s_wready_int=axi_s_wready_int+ 1)
        begin
        if(wr_data_s_hit[axi_s_wready_int])
            begin
                axi_s_wready = s_wready [axi_s_wready_int];
            end
        end
end

integer wvalid_int;
always @(wr_data_s_hit or  axi_s_wvalid )
begin
    for(wvalid_int= 0 ; wvalid_int< `SLV_MUX_NUM ;wvalid_int= wvalid_int+ 1)
        s_wvalid[wvalid_int]  = axi_s_wvalid && wr_data_s_hit[wvalid_int];
end


wire [2:0] rd_data_sel; 
wire       rd_dir_ins;
wire       rd_dir_del;
wire [2:0] rd_data_dir;
reg  [2:0] rd_addr_dir;
reg [2:0] rd_data_pre_sel;
integer   rd_arready_int; 
integer   rd_arvalid_int;
integer   rd_addr_hit_int;

always @(s_arready or rd_fifo_full or rd_addr_hit)
begin
            axi_s_arready   ='h0; 
    for(rd_arready_int= 0 ; rd_arready_int< `SLV_MUX_NUM ;rd_arready_int=rd_arready_int+ 1)
            if(!rd_fifo_full && rd_addr_hit[rd_arready_int])
            begin
                axi_s_arready   =s_arready[rd_arready_int]; 
            end
end

always @(axi_s_arvalid or rd_fifo_full or rd_addr_hit)
begin
    for(rd_arvalid_int= 0 ; rd_arvalid_int< `SLV_MUX_NUM ;rd_arvalid_int=rd_arvalid_int+ 1)
        s_arvalid [rd_arvalid_int] = !rd_fifo_full && rd_addr_hit[rd_arvalid_int]  && axi_s_arvalid;
end

assign rd_addr_hit[1] = ((axi_s_araddr[31:16]) ==16'h1fe8) || ((axi_s_araddr[31:20])==12'h1fc);  //SPI
assign rd_addr_hit[2] = (axi_s_araddr[31:16]) ==16'h1fe4 ||
                        (axi_s_araddr[31:16]) ==16'h1fe7  ;//APB:uart and nand
assign rd_addr_hit[3] = (axi_s_araddr[31:16]) ==16'h1fd0;  //CONF
assign rd_addr_hit[4] = (axi_s_araddr[31:16]) == 16'h1ff0; //MAC
assign rd_addr_hit[0] = ~|rd_addr_hit[4:1];                //DDR3

integer rd_addr_dir_int;
always @(rd_addr_hit)
begin
        rd_addr_dir =  3'b0;
    for(rd_addr_dir_int= 0 ; rd_addr_dir_int< `SLV_MUX_NUM ;rd_addr_dir_int= rd_addr_dir_int+ 1)
        if(rd_addr_hit[rd_addr_dir_int])
        rd_addr_dir =rd_addr_dir_int;
end

integer   axi_rd_data_int; 
always @(*)
begin
            axi_s_rid       =8'h0;
            axi_s_rdata     =128'h0;
            axi_s_rresp     =2'h0;
            axi_s_rlast     =1'h0;
            axi_s_rvalid    =1'h0;
    for(axi_rd_data_int= 0 ; axi_rd_data_int< `SLV_MUX_NUM ;axi_rd_data_int=axi_rd_data_int+ 1)
            begin
            s_rready [axi_rd_data_int] = 1'b0;
            if(rd_data_sel==axi_rd_data_int) begin
                s_rready [axi_rd_data_int] = axi_s_rready;
                axi_s_rid       =s_rid    [axi_rd_data_int];
                axi_s_rdata     =s_rdata  [axi_rd_data_int];
                axi_s_rresp     =s_rresp  [axi_rd_data_int];
                axi_s_rlast     =s_rlast  [axi_rd_data_int];
                axi_s_rvalid    =s_rvalid [axi_rd_data_int];
            end
      end
end

always@(posedge clk) begin
  if(!rst_n) 
      begin
    rd_data_pre_sel<= 3'b0;
    end
  else if(axi_s_rvalid && axi_s_rready)
      begin
        rd_data_pre_sel <= rd_data_sel;
    end
end

assign rd_data_sel =rd_data_dir;

nb_sync_fifo_mux rd_fifo
(
.clk(clk),
.rst_n(rst_n),

.empty(rd_fifo_empty),
.full(rd_fifo_full),

.shift_in(rd_dir_ins),
.data_in(rd_addr_dir),

.shift_out(rd_dir_del),
.data_out(rd_data_dir)
);

assign rd_dir_ins = !rd_fifo_full && axi_s_arvalid && axi_s_arready;
assign rd_dir_del = !rd_fifo_empty && axi_s_rvalid && axi_s_rready && axi_s_rlast;

function [2:0] get_num;
input [2:0]    valid;    
input [2:0]    pre_num;  
input [1:0]    group;    
begin
get_num=(valid == 3'b001)? (3'h0+group) :
        (valid == 3'b010)? (3'h1+group) :
        (valid == 3'b100)? (3'h2+group) :
        (valid == 3'b011)? (pre_num!=(3'h0+group))?(3'h0+group):(3'h1+group) :
        (valid == 3'b110)? (pre_num!=(3'h1+group))?(3'h1+group):(3'h2+group) :
        (valid == 3'b101)? (pre_num!=(3'h2+group))?(3'h2+group):(3'h0+group) :
        (valid == 3'b111)?((pre_num==(3'h0+group))?(3'h1+group):(pre_num==(3'h1+group))?(3'h2+group):(3'h0+group)):3'h7;
end
endfunction 
endmodule

`undef SLV_MUX_5
`undef SLV_MUX_NUM

module nb_sync_fifo_mux
(
clk,
rst_n,

empty,
full,

shift_in,
data_in,

shift_out,
data_out
);
parameter FIFO_WIDTH = 3;

input                      clk;
input                      rst_n;

output                     empty;
output                     full;

input                      shift_in;
input [FIFO_WIDTH-1:0]     data_in;

input                      shift_out;
output[FIFO_WIDTH-1:0]     data_out;


reg   [FIFO_WIDTH-1:0] fifo_ram [1:0];
reg   [1:0]             wr_ptr;
reg   [1:0]             rd_ptr;

wire  [0:0]             mem_wr_pos;
wire  [0:0]             mem_rd_pos;

always@(posedge clk) begin
  if(!rst_n)
    wr_ptr <= 2'h0;
  else if(~full && shift_in)
    wr_ptr <= wr_ptr + 2'h1;
end

always@(posedge clk) begin
  if(!rst_n)
    rd_ptr <= 2'h0;
  else if(~empty && shift_out)
    rd_ptr <= rd_ptr + 2'h1;
end

assign full  = wr_ptr == {~rd_ptr[1],rd_ptr[0]};  
assign empty = wr_ptr == rd_ptr;  

assign mem_wr_pos = wr_ptr[0:0]; 
assign mem_rd_pos = rd_ptr[0:0];

assign data_out = fifo_ram[mem_rd_pos];

integer i;

always@(posedge clk) begin
  if(!rst_n)
    for(i=0;i<2;i=i+1)
      fifo_ram[i] <= 2'b0;
  else if(shift_in && ~full)
    fifo_ram[mem_wr_pos] <= data_in;
end

endmodule
