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

`timescale 1ns/1ps
`define IO_DELAY 2.5

module virtual_mac(
        hclk,        hrst_n,
        mtxclk,      mtxen,       mtxd,        mtxerr,
        mrxclk,      mrxdv,       mrxd,        mrxerr,
        mcoll,       mcrs,
        mdc,         md_io,
        gpio);

input           hclk, hrst_n;
input           mtxclk;  
output   [3:0]  mtxd;    
output          mtxen;   
output          mtxerr;  

input           mrxclk;  
input    [3:0]  mrxd;    
input           mrxdv;   
input           mrxerr;  

input           mcoll;   
input           mcrs;    

inout           md_io;
output          mdc;     

input           gpio;

wire md_oe, md_o;
wire mdio = md_oe ? md_o : 1'bz;
wire md_i = mdio;

wire [1:0]  v_htrans;
wire [2:0]  v_hburst;
wire [31:0] v_haddr;
wire        v_hwrite;
wire [2:0]  v_hsize;
wire [31:0] v_hrdata;
wire [31:0] v_hwdata;
wire        v_hrdy;
wire [1:0]  v_hresp = 2'b0;

wire        m_hreq, m_hlock, m_hgnt;
wire [1:0]  m_htrans;
wire [2:0]  m_hburst;
wire [31:0] m_haddr;
wire        m_hwrite;
wire [2:0]  m_hsize;
wire [3:0]  m_hprot;
wire [31:0] m_hwdata;

wire        s_hsel, s_hrdy;
wire [1:0]  s_hresp;
wire [15:0] s_hsplit;
wire [31:0] s_hrdata;

wire        read_complete;
assign m_hgnt = ~s_hsel;
reg    grant_dly;
always @(posedge hclk)
    grant_dly <= m_hgnt & m_hreq;
    
wire   [3:0]  mtxd_mid;    
wire          mtxen_mid;   
wire          mtxerr_mid;  
wire          mdc_mid;
assign #`IO_DELAY mtxd = mtxd_mid;
assign #`IO_DELAY mtxen = mtxen_mid;
assign #`IO_DELAY mtxerr = mtxerr_mid;
assign #`IO_DELAY mdc = mdc_mid;     
vMAC_TOP virtual_core
(
        .hclk(hclk),        .hrst_(hrst_n),      .SYS_RST_(hrst_n),

        .hmst(4'b1),            .hmstlock(1'b0),
        .htrans(v_htrans),      .hburst(v_hburst),      .haddr(v_haddr),
        .hwrite(v_hwrite),      .hsize(v_hsize),        
        .hrdata(v_hrdata),      .hwdata(v_hwdata),      .hrdy(v_hrdy),        .hresp(v_hresp),
        .eth_hreq(m_hreq),      .eth_hlock(m_hlock),    .eth_hgnt(m_hgnt),
        .eth_htrans(m_htrans),  .eth_hburst(m_hburst),  .eth_haddr(m_haddr),
        .eth_hwrite(m_hwrite),  .eth_hsize(m_hsize),    .eth_hprot(m_hprot),
        .eth_hwdata(m_hwdata),
        .eth_hsel(s_hsel),       .eth_hrdy(s_hrdy),     .eth_hresp(s_hresp),   .eth_hsplit(s_hsplit),
        .eth_hrdata(s_hrdata),

        .interrupt(),
        .mtxclk(mtxclk),      .mtxen(mtxen_mid),       .mtxd(mtxd_mid),        .mtxerr(mtxerr_mid),
        .mrxclk(mrxclk),      .mrxdv(mrxdv),       .mrxd(mrxd),        .mrxerr(mrxerr),
        .mcoll(mcoll),        .mcrs(mcrs),
        .mdc(mdc_mid),            .md_i(md_i),         .md_o(md_o),        .md_oe(md_oe),

	.bist_mode(1'b0)
    );

virtual_mac_slave virtual_mac_slave_0(
                   .hclk(hclk),        .hrst_n(hrst_n),
                   .hreq(m_hreq),      .hlock(m_hlock),     .hgnt(m_hgnt),    .hrdy(v_hrdy),
                   .htrans(m_htrans),  .hburst(m_hburst),   .haddr(m_haddr),  .hrdata(v_hrdata),
                   .hwrite(m_hwrite),  .hsize(m_hsize),     .hprot(m_hprot),  .hwdata(m_hwdata), .read_complete(read_complete));

virtual_mac_master virtual_mac_master_0(
          .hclk(hclk),       .hrst_n(hrst_n),     .grant_dly(grant_dly),
          .hsel(s_hsel),     .htrans(v_htrans),   .hburst(v_hburst),   .hsize(v_hsize),  .hrdy(s_hrdy),
          .hwrite(v_hwrite), .hrdata(s_hrdata),   .hwdata(v_hwdata),   .haddr(v_haddr),  .hprot(),     .read_complete(read_complete),
          .gpio(gpio));
endmodule

module virtual_mac_slave(
                   hclk,    hrst_n,
                   hreq,    hlock,    hgnt,   hrdy,
                   htrans,  hburst,   haddr,  hrdata,
                   hwrite,  hsize,    hprot,  hwdata,  read_complete);
input        hclk, hrst_n;
input        hreq, hlock, hgnt;
input [1:0]  htrans;
input [2:0]  hburst;
input [31:0] haddr;
output[31:0] hrdata;
input        hwrite;
input [2:0]  hsize;
input [3:0]  hprot;
input [31:0] hwdata;
output       hrdy;
input        read_complete;

wire         hrdy      = 1'b1;
wire         s_command = (htrans[1] == 1'b1) & hrdy;


reg [31:0]   MEM_in[1048575:0];
reg [31:0]   MEM_out[1048575:0];
reg reg_enable;
wire  s_end = hrdy & reg_enable;
always @(posedge hclk)
    if (~hrst_n)
        reg_enable <= 1'b0;
    else if (s_command)
        reg_enable <= 1'b1;
    else if (s_end)
        reg_enable <= 1'b0;

reg reg_we;
always @(posedge hclk)
    if (~hrst_n)
        reg_we <= 1'b0;
    else if (s_command)
        reg_we <= hwrite;
    else if (s_end)
        reg_we <= 1'b0;

reg [31:0] reg_addr;
always @(posedge hclk)
    if (~hrst_n)
        reg_addr <= 31'b0;
    else if (s_command)
        reg_addr <= {2'b00,haddr[31:2]};

integer i;
`ifdef VIRTUAL_MAC
initial
begin
    for (i = 0 ;i <1048576; i = i+1) MEM_out[i] = 32'b0;
    #100;
    $readmemh("../../testbench/vmac/ram.vlog", MEM_out);
    $display("[%t]:)[virtual_mac]:reading ../../testbench/vmac/ram.vlog",$time);
    $display("DEBUG: MEM_out[32'h1040]=%h, MEM_out[32'h840]=%h", MEM_out[32'h1040], MEM_out[32'h840]);
end
`endif

initial
begin
    @(posedge read_complete);
    for (i= 0; i < 32'h40; i= i+1)
        if (MEM_out[i+32'h800] != MEM_out[i+32'h1000])
            $display("[%t]:[virtual_mac]:error data, MEM_out[%h] = %h, correct is %h",$time, i, MEM_out[i+32'h1000], MEM_out[i+32'h800]);
        else 
            $display("data, MEM_out[%h] = %h", i, MEM_out[i+32'h1000]);
`ifdef MAC_DEBUG
    $display("[%t]:[virtual_mac]:valuation complete",$time);
`endif
end

reg flag;
initial
  begin
    flag = 1'b0;
  end

always @(posedge hclk)
    if (hrst_n & reg_we & s_end)
      begin
        MEM_out[reg_addr] <= hwdata;
        if (reg_addr==32'h1040) flag = 1'b1;
      end

assign hrdata = (reg_addr == 32'h400 |reg_addr == 32'h420)? 32'h80000000: MEM_out[reg_addr];

endmodule

module virtual_mac_master(
          hclk,   hrst_n,   grant_dly,
          hsel,   htrans,   hburst,   hsize,  hrdy,
          hwrite, hrdata,   hwdata,   haddr,  hprot, read_complete,
          gpio);
input         hclk, hrst_n;
input         grant_dly;
output        hsel;
output [1:0]  htrans;
output [2:0]  hburst;
output [2:0]  hsize;
input         hrdy;
output        hwrite;
input [31:0]  hrdata;
output [31:0] hwdata;
output [31:0] haddr;
output [3:0]  hprot;
output        read_complete;
input         gpio;

reg ready;
reg hsel;
reg [1:0] htrans;
reg [2:0] hburst;
reg [2:0] hsize;
reg       hwrite;
reg [31:0] hwdata;
reg [31:0] haddr;
reg [3:0]  hprot;

reg read_complete;

`ifdef MAC_DEBUG
wire  debug = 1;
`else
wire  debug = 0;
`endif

initial begin

htrans = 2'b00;
haddr = 2'b00;
hburst = 3'b00;
hwrite = 1'b0;
hsize = 3'b000;
hwdata = 32'b0;
hsel  = 1'b0;
hprot = 4'b0;

read_complete = 1'b0;

ready = 1'b0;

`ifdef VIRTUAL_MAC
@(posedge hrst_n);

wait(gpio); 

@(posedge hclk)

if (debug) $display("[%t]:[virtual_mac]:start transmit process ",$time);
while (grant_dly) @(posedge hclk);
one_write(32'h00,32'h0000, 2);

while (grant_dly) @(posedge hclk);
one_write(32'h20,32'h1000, 2);

while (grant_dly) @(posedge hclk);
one_write(32'h18,32'h1100, 2);

while (grant_dly) @(posedge hclk);
one_write(32'h30,32'h40002002, 2);

@(posedge hclk)

while (grant_dly) @(posedge hclk);
one_read(32'h28,2);
while (hrdata[6]==0)
begin
    while (grant_dly) @(posedge hclk);
    one_read(32'h28,2);
    repeat(10)@(posedge hclk);
    #3;
end
read_complete = 1'b1;

if (debug) $display("[%t]:[virtual_mac]:receive process complete",$time);

`endif
end


task one_write;
input [11:0] addr;
input [31:0] wdata;
input [2:0] size;
begin
if (debug) $display("[%t]:[virtual_mac]: write address phase begin: haddr = %x",$time, addr); 
htrans = 2'b10;
haddr  = addr;
hburst = 3'b00;
hwrite = 1'b1;
hsize  = size;
hsel   = 1'b1;
ready  = 1'b0;

@(posedge hclk);
    if( hrdy == 1'b1) ready = 1'b1;
while (ready != 1'b1)
begin
    @(posedge hclk);
    if( hrdy == 1'b1) ready = 1'b1;
    #3;
end
ready = 1'b0;

if (debug) $display("[%t]:[virtual_mac]: write data phase begin: haddr = %x", $time, addr); 

hwdata = wdata;
hsel   = 1'b0;
htrans = 2'b00;
@(posedge hclk);
    if( hrdy == 1'b1) ready = 1'b1;
while (ready != 1'b1)
begin
    @(posedge hclk);
    if( hrdy == 1'b1) ready = 1'b1;
    #3;
end
ready = 1'b0;

if (debug) $display("[%t]:[virtual_mac]: write complete!!!", $time);
end
endtask

task one_read;
input [11:0] addr;
input [2:0]  size;
begin
htrans = 2'b10;
haddr  = addr;
hburst = 3'b00;
hwrite = 1'b0;
hsize  = size;
hsel   = 1'b1;


@(posedge hclk);
    if( hrdy == 1'b1) ready = 1'b1;
while (ready != 1'b1)
begin
    @(posedge hclk);
    if( hrdy == 1'b1) ready = 1'b1;
    #3;
end
ready = 1'b0;

htrans = 2'b00;

hsel   = 1'b0;
@(posedge hclk);
    if( hrdy == 1'b1) ready = 1'b1;
while (ready != 1'b1)
begin
    @(posedge hclk);
    if( hrdy == 1'b1) ready = 1'b1;
end
ready = 1'b0;
end
endtask

endmodule
