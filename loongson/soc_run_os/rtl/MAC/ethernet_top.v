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

module ethernet_top
(
    hclk,
    hrst_,      
    mawid_o    ,
    mawaddr_o  ,
    mawlen_o   ,
    mawsize_o  ,
    mawburst_o ,
    mawlock_o  ,
    mawcache_o ,
    mawprot_o  ,
    mawvalid_o ,
    mawready_i ,
    mwid_o     ,
    mwdata_o   ,
    mwstrb_o   ,
    mwlast_o   ,
    mwvalid_o  ,
    mwready_i  ,
    mbid_i     ,
    mbresp_i   ,
    mbvalid_i  ,
    mbready_o  ,
    marid_o    ,
    maraddr_o  ,
    marlen_o   ,
    marsize_o  ,
    marburst_o ,
    marlock_o  ,
    marcache_o ,
    marprot_o  ,
    marvalid_o ,
    marready_i ,
    mrid_i     ,
    mrdata_i   ,
    mrresp_i   ,
    mrlast_i   ,
    mrvalid_i  ,
    mrready_o  ,
    sawid_i    ,
    sawaddr_i  ,
    sawlen_i   ,
    sawsize_i  ,
    sawburst_i ,
    sawlock_i  ,
    sawcache_i ,
    sawprot_i  ,
    sawvalid_i ,
    sawready_o ,   
    swid_i     ,
    swdata_i   ,
    swstrb_i   ,
    swlast_i   ,
    swvalid_i  ,
    swready_o  ,
    sbid_o     ,
    sbresp_o   ,
    sbvalid_o  ,
    sbready_i  ,
    sarid_i    ,
    saraddr_i  ,
    sarlen_i   ,
    sarsize_i  ,
    sarburst_i ,
    sarlock_i  ,
    sarcache_i ,
    sarprot_i  ,
    sarvalid_i ,
    sarready_o ,
    srid_o     ,
    srdata_o   ,
    srresp_o   ,
    srlast_o   ,
    srvalid_o  ,
    srready_i  ,                 

    interrupt_0,
 
    mtxclk_0,     
    mtxen_0,      
    mtxd_0,       
    mtxerr_0,
    mrxclk_0,      
    mrxdv_0,     
    mrxd_0,        
    mrxerr_0,
    mcoll_0,
    mcrs_0,
    mdc_0,
    md_i_0,
    md_o_0,       
    md_oe_0
);

input   hclk;
input   hrst_;      

  output  [  3:0] mawid_o              ;
  output  [ 31:0] mawaddr_o            ;
  output  [  3:0] mawlen_o             ;
  output  [  2:0] mawsize_o            ;
  output  [  1:0] mawburst_o           ;
  output  [  1:0] mawlock_o            ;
  output  [  3:0] mawcache_o           ;
  output  [  2:0] mawprot_o            ;
  output          mawvalid_o           ;
  input           mawready_i           ;
  output  [  3:0] mwid_o               ;
  output  [ 31:0] mwdata_o             ;
  output  [  3:0] mwstrb_o             ;
  output          mwlast_o             ;
  output          mwvalid_o            ;
  input           mwready_i            ;
  input   [  3:0] mbid_i               ;
  input   [  1:0] mbresp_i             ;
  input           mbvalid_i            ;
  output          mbready_o            ;
  output  [  3:0] marid_o              ;
  output  [ 31:0] maraddr_o            ;
  output  [  3:0] marlen_o             ;
  output  [  2:0] marsize_o            ;
  output  [  1:0] marburst_o           ;
  output  [  1:0] marlock_o            ;
  output  [  3:0] marcache_o           ;
  output  [  2:0] marprot_o            ;
  output          marvalid_o           ;
  input           marready_i           ;
  input   [  3:0] mrid_i               ;
  input   [ 31:0] mrdata_i             ;
  input   [  1:0] mrresp_i             ;
  input           mrlast_i             ;
  input           mrvalid_i            ;
  output          mrready_o            ;                 

  input   [  3:0]   sawid_i              ;
  input   [ 31:0]   sawaddr_i            ;
  input   [  3:0]   sawlen_i             ;
  input   [  2:0]   sawsize_i            ;
  input   [  1:0]   sawburst_i           ;
  input   [  1:0]   sawlock_i            ;
  input   [  3:0]   sawcache_i           ;
  input   [  2:0]   sawprot_i            ;
  input             sawvalid_i           ;
  output            sawready_o           ;
  input   [  3:0]   swid_i               ;
  input   [ 31:0]   swdata_i             ;
  input   [  3:0]   swstrb_i             ;
  input             swlast_i             ;
  input             swvalid_i            ;
  output            swready_o            ;
  output  [  3:0]   sbid_o               ;
  output  [  1:0]   sbresp_o             ;
  output            sbvalid_o            ;
  input             sbready_i            ;
  input   [  3:0]   sarid_i              ;
  input   [ 31:0]   saraddr_i            ;
  input   [  3:0]   sarlen_i             ;
  input   [  2:0]   sarsize_i            ;
  input   [  1:0]   sarburst_i           ;
  input   [  1:0]   sarlock_i            ;
  input   [  3:0]   sarcache_i           ;
  input   [  2:0]   sarprot_i            ;
  input             sarvalid_i           ;
  output            sarready_o           ;
  output  [  3:0]   srid_o               ;
  output  [ 31:0]   srdata_o             ;
  output  [  1:0]   srresp_o             ;
  output            srlast_o             ;
  output            srvalid_o            ;
  input             srready_i            ;                 

input           mtxclk_0;  
output  [3:0]   mtxd_0;    
output          mtxen_0;   
output          mtxerr_0;  

input           mrxclk_0;  
input   [3:0]   mrxd_0;    
input           mrxdv_0;   
input           mrxerr_0;  

input           mcoll_0;   
input           mcrs_0;    

input           md_i_0;      
output          mdc_0;     
output          md_o_0;      
output          md_oe_0;    

output          interrupt_0;


`define  MAHBDATAWIDTH 32
`define  TFIFODEPTH 9
`define  RFIFODEPTH 9
`define  ADDRDEPTH  6

wire    [`MAHBDATAWIDTH - 1:0] trdata_0;  
wire    twe_0;
wire    [`TFIFODEPTH - 1:0] twaddr_0;
wire    [`TFIFODEPTH - 1:0] traddr_0;
wire    [`MAHBDATAWIDTH - 1:0] twdata_0;

wire    [`MAHBDATAWIDTH - 1:0] rrdata_0; 
wire    rwe_0;
wire    [`RFIFODEPTH - 1:0] rwaddr_0;
wire    [`RFIFODEPTH - 1:0] rraddr_0;
wire    [`MAHBDATAWIDTH - 1:0] rwdata_0;    


mac_top u_mac_top_0
(
    .hclk(hclk),       
    .hrst_(hrst_),      

    .mawid_o      (mawid_o    ),
    .mawaddr_o    (mawaddr_o  ),
    .mawlen_o     (mawlen_o   ),
    .mawsize_o    (mawsize_o  ),
    .mawburst_o   (mawburst_o ),
    .mawlock_o    (mawlock_o  ),
    .mawcache_o   (mawcache_o ),
    .mawprot_o    (mawprot_o  ),
    .mawvalid_o   (mawvalid_o ),
    .mawready_i   (mawready_i ),
    .mwid_o       (mwid_o     ),
    .mwdata_o     (mwdata_o   ),
    .mwstrb_o     (mwstrb_o   ),
    .mwlast_o     (mwlast_o   ),
    .mwvalid_o    (mwvalid_o  ),
    .mwready_i    (mwready_i  ),
    .mbid_i       (mbid_i     ),
    .mbresp_i     (mbresp_i   ),
    .mbvalid_i    (mbvalid_i  ),
    .mbready_o    (mbready_o  ),
    .marid_o      (marid_o    ),
    .maraddr_o    (maraddr_o  ),
    .marlen_o     (marlen_o   ),
    .marsize_o    (marsize_o  ),
    .marburst_o   (marburst_o ),
    .marlock_o    (marlock_o  ),
    .marcache_o   (marcache_o ),
    .marprot_o    (marprot_o  ),
    .marvalid_o   (marvalid_o ),
    .marready_i   (marready_i ),
    .mrid_i       (mrid_i     ),
    .mrdata_i     (mrdata_i   ),
    .mrresp_i     (mrresp_i   ),
    .mrlast_i     (mrlast_i   ),
    .mrvalid_i    (mrvalid_i  ),
    .mrready_o    (mrready_o  ),
    .sawid_i       (sawid_i    ),
    .sawaddr_i     (sawaddr_i  ),
    .sawlen_i      (sawlen_i   ),
    .sawsize_i     (sawsize_i  ),
    .sawburst_i    (sawburst_i ),
    .sawlock_i     (sawlock_i  ),
    .sawcache_i    (sawcache_i ),
    .sawprot_i     (sawprot_i  ),
    .sawvalid_i    (sawvalid_i ),
    .sawready_o    (sawready_o ),   
    .swid_i        (swid_i     ),
    .swdata_i      (swdata_i   ),
    .swstrb_i      (swstrb_i   ),
    .swlast_i      (swlast_i   ),
    .swvalid_i     (swvalid_i  ),
    .swready_o     (swready_o  ),
    .sbid_o        (sbid_o     ),
    .sbresp_o      (sbresp_o   ),
    .sbvalid_o     (sbvalid_o  ),
    .sbready_i     (sbready_i  ),
    .sarid_i       (sarid_i    ),
    .saraddr_i     (saraddr_i  ),
    .sarlen_i      (sarlen_i   ),
    .sarsize_i     (sarsize_i  ),
    .sarburst_i    (sarburst_i ),
    .sarlock_i     (sarlock_i  ),
    .sarcache_i    (sarcache_i ),
    .sarprot_i     (sarprot_i  ),
    .sarvalid_i    (sarvalid_i ),
    .sarready_o    (sarready_o ),
    .srid_o        (srid_o     ),
    .srdata_o      (srdata_o   ),
    .srresp_o      (srresp_o   ),
    .srlast_o      (srlast_o   ),
    .srvalid_o     (srvalid_o  ),
    .srready_i     (srready_i  ),                 

    .interrupt(interrupt_0),
 
    .mtxclk(mtxclk_0),      .mtxen(mtxen_0),       .mtxd(mtxd_0),        .mtxerr(mtxerr_0),
    .mrxclk(mrxclk_0),      .mrxdv(mrxdv_0),       .mrxd(mrxd_0),        .mrxerr(mrxerr_0),
    .mcoll(mcoll_0),       .mcrs(mcrs_0),
    .mdc(mdc_0),         .md_i(md_i_0),        .md_o(md_o_0),        .md_oe(md_oe_0),

    .trdata(trdata_0),
    .twe(twe_0),
    .twaddr(twaddr_0),
    .traddr(traddr_0),
    .twdata(twdata_0),

    .rrdata(rrdata_0),
    .rwe(rwe_0),
    .rwaddr(rwaddr_0),
    .rraddr(rraddr_0),
    .rwdata(rwdata_0)
); 

wire [31:0] douta_nc;
dpram_512x32 dpram_512x32_tx(
  .clka     (hclk    ),
  .ena      (twe_0   ),
  .wea      (twe_0   ),
  .addra    (twaddr_0),
  .dina     (twdata_0),
  .clkb     (mtxclk_0),
  .addrb    (traddr_0),
  .doutb    (trdata_0)
);

wire [31:0] doutb_nc;
dpram_512x32 dpram_512x32_rx(
  .clka     (mrxclk_0),
  .ena      (rwe_0   ),
  .wea      (rwe_0   ),
  .addra    (rwaddr_0),
  .dina     (rwdata_0),
  .clkb     (hclk    ),
  .addrb    (rraddr_0),
  .doutb    (rrdata_0)
);

endmodule

