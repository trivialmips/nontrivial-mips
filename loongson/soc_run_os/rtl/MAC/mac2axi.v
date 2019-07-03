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

module MAC2AXI (
  mhclk,
  mhresetn,
  shclk,
  shresetn,

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

  datareq,
  datareqc,
  datarw,
  dataeob,
  dataeobc,
  dataaddr,
  datao,
  dataack,
  datai,
  rstcsr,
  csrack,
  csrdatao,
  csrreq,
  csrrw,
  csrbe,
  csrdatai,
  csraddr
  );

  parameter MAXIDATAWIDTH     = 32;
  parameter MAXIADDRESSWIDTH  = 32;
    
  parameter SAXIDATAWIDTH     = 32;
  parameter SAXIADDRESSWIDTH  = 32;
    
  parameter MACDATAWIDTH      = 32;
  parameter MACADDRESSWIDTH   = 32;
    
  parameter CSRDATAWIDTH      = 32;
  parameter CSRADDRESSWIDTH   = 8;


  input     mhclk; 
  input     mhresetn; 
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

  input     shclk; 
  input     shresetn; 

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


  MACDATA2AXI
  #(MAXIDATAWIDTH, MAXIADDRESSWIDTH, MACDATAWIDTH, MACADDRESSWIDTH)
  U_MACDATA2AXI (
  .maclk          (mhclk      ),   
  .maresetn       (mhresetn   ),
  .awid_o         (mawid_o    ),
  .awaddr_o       (mawaddr_o  ),
  .awlen_o        (mawlen_o   ),
  .awsize_o       (mawsize_o  ),
  .awburst_o      (mawburst_o ),
  .awlock_o       (mawlock_o  ),
  .awcache_o      (mawcache_o ),
  .awprot_o       (mawprot_o  ),
  .awvalid_o      (mawvalid_o ),
  .awready_i      (mawready_i ),
  .wid_o          (mwid_o     ),
  .wdata_o        (mwdata_o   ),
  .wstrb_o        (mwstrb_o   ),
  .wlast_o        (mwlast_o   ),
  .wvalid_o       (mwvalid_o  ),
  .wready_i       (mwready_i  ),
  .bid_i          (mbid_i     ),
  .bresp_i        (mbresp_i   ),
  .bvalid_i       (mbvalid_i  ),
  .bready_o       (mbready_o  ),
  .arid_o         (marid_o    ),
  .araddr_o       (maraddr_o  ),
  .arlen_o        (marlen_o   ),
  .arsize_o       (marsize_o  ),
  .arburst_o      (marburst_o ),
  .arlock_o       (marlock_o  ),
  .arcache_o      (marcache_o ),
  .arprot_o       (marprot_o  ),
  .arvalid_o      (marvalid_o ),
  .arready_i      (marready_i ),
  .rid_i          (mrid_i     ),
  .rdata_i        (mrdata_i   ),
  .rresp_i        (mrresp_i   ),
  .rlast_i        (mrlast_i   ),
  .rvalid_i       (mrvalid_i  ),
  .rready_o       (mrready_o  ),
  .datareq        (datareq    ), 
  .datareqc       (datareqc   ), 
  .datarw         (datarw     ), 
  .dataeob        (dataeob    ), 
  .dataeobc       (dataeobc   ), 
  .dataaddr       (dataaddr   ), 
  .datao          (datao      ), 
  .dataack        (dataack    ), 
  .datai          (datai      )
  );
  MACCSR2AXI
  #(SAXIDATAWIDTH, SAXIADDRESSWIDTH, CSRDATAWIDTH, CSRADDRESSWIDTH)
  U_MACCSR2AXI(
  .saclk         (shclk    ),
  .saresetn      (shresetn ),
  .awid_i        (sawid_i   ),
  .awaddr_i      (sawaddr_i ),
  .awlen_i       (sawlen_i  ),
  .awsize_i      (sawsize_i ),
  .awburst_i     (sawburst_i),
  .awlock_i      (sawlock_i ),
  .awcache_i     (sawcache_i),
  .awprot_i      (sawprot_i ),
  .awvalid_i     (sawvalid_i),
  .awready_o     (sawready_o),   
  .wid_i         (swid_i    ),
  .wdata_i       (swdata_i  ),
  .wstrb_i       (swstrb_i  ),
  .wlast_i       (swlast_i  ),
  .wvalid_i      (swvalid_i ),
  .wready_o      (swready_o ),
  .bid_o         (sbid_o    ),
  .bresp_o       (sbresp_o  ),
  .bvalid_o      (sbvalid_o ),
  .bready_i      (sbready_i ),
  .arid_i        (sarid_i   ),
  .araddr_i      (saraddr_i ),
  .arlen_i       (sarlen_i  ),
  .arsize_i      (sarsize_i ),
  .arburst_i     (sarburst_i),
  .arlock_i      (sarlock_i ),
  .arcache_i     (sarcache_i),
  .arprot_i      (sarprot_i ),
  .arvalid_i     (sarvalid_i),
  .arready_o     (sarready_o),
  .rid_o         (srid_o    ),
  .rdata_o       (srdata_o  ),
  .rresp_o       (srresp_o  ),
  .rlast_o       (srlast_o  ),
  .rvalid_o      (srvalid_o ),
  .rready_i      (srready_i ),                 
  .rstcsr        (rstcsr   ) ,
  .csrack        (csrack   ) ,
  .csrdatao      (csrdatao ) ,
  .csrreq        (csrreq   ) ,
  .csrrw         (csrrw    ) ,
  .csrbe         (csrbe    ) ,
  .csrdatai      (csrdatai ) ,
  .csraddr       (csraddr  )
  );

endmodule 
