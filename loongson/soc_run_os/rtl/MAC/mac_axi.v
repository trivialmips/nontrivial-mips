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

module MAC_AXI (
  clkt,
  clkr,
  rsttco,
  rstrco,
  interrupt,
  tps,
  rps,
  mhclk,
  mhresetn,
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
  shclk,
  shresetn,
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
  trdata,
  twe,
  twaddr,
  traddr,
  twdata,
  rrdata,
  rwe,
  rwaddr,
  rraddr,
  rwdata,
  frdata,
  fwe,
  fwaddr,
  fraddr,
  fwdata,
  match,
  matchval,
  matchen,
  matchdata,
  sdi,
  sclk,
  scs,
  sdo,
  rxer,
  rxdv,
  col,
  crs,
  rxd,
  txen,
  txer,
  txd,
  mdc,
  mdi,
  mdo,
  mden
  );

  parameter MAXIADDRESSWIDTH  = 32;
  parameter SAXIADDRESSWIDTH  = 32;
  parameter TFIFODEPTH        = 9;
  parameter RFIFODEPTH        = 9;
  parameter TCDEPTH           = 1;
  parameter RCDEPTH           = 2;
  parameter MAXIDATAWIDTH     = 32;
  parameter SAXIDATAWIDTH     = 32;
  `include "utility.v"


  input     clkt; 
  input     clkr; 
  output    rsttco; 
  wire      rsttco;
  output    rstrco; 
  wire      rstrco;

    
  output    interrupt; 
  wire      interrupt;

  output    tps; 
  wire      tps;
  output    rps; 
  wire      rps;
    
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
  input     [MAXIDATAWIDTH - 1:0] trdata; 
  output    twe; 
  wire      twe;
  output    [TFIFODEPTH - 1:0] twaddr; 
  wire      [TFIFODEPTH - 1:0] twaddr;
  output    [TFIFODEPTH - 1:0] traddr; 
  wire      [TFIFODEPTH - 1:0] traddr;
  output    [MAXIDATAWIDTH - 1:0] twdata; 
  wire      [MAXIDATAWIDTH - 1:0] twdata;


  input     [MAXIDATAWIDTH - 1:0] rrdata; 
  output    rwe; 
  wire      rwe;
  output    [RFIFODEPTH - 1:0] rwaddr; 
  wire      [RFIFODEPTH - 1:0] rwaddr;
  output    [RFIFODEPTH - 1:0] rraddr; 
  wire      [RFIFODEPTH - 1:0] rraddr;
  output    [MAXIDATAWIDTH - 1:0] rwdata; 
  wire      [MAXIDATAWIDTH - 1:0] rwdata;
    
  input     [15:0] frdata; 
  output    fwe; 
  wire      fwe;
  output    [ADDRDEPTH - 1:0] fwaddr; 
  wire      [ADDRDEPTH - 1:0] fwaddr;
  output    [ADDRDEPTH - 1:0] fraddr; 
  wire      [ADDRDEPTH - 1:0] fraddr;
  output    [15:0] fwdata; 
  wire      [15:0] fwdata;
    
  input     match; 
  input     matchval; 
  output    matchen; 
  wire      matchen;
  output    [47:0] matchdata; 
  wire      [47:0] matchdata;
    
  input     sdi; 
  output    sclk; 
  wire      sclk;
  output    scs; 
  wire      scs;
  output    sdo; 
  wire      sdo;
    
  input     rxer; 
  input     rxdv; 
  input     col; 
  input     crs; 
  input     [MIIWIDTH - 1:0] rxd; 
  output    txen; 
  wire      txen;
  output    txer; 
  wire      txer;
  output    [MIIWIDTH - 1:0] txd; 
  wire      [MIIWIDTH - 1:0] txd;
  output    mdc; 
  wire      mdc;
  input     mdi; 
  output    mdo; 
  wire      mdo;
  output    mden; 
  wire      mden;


  wire      datareq; 
  wire      datareqc; 
  wire      datarw; 
  wire      dataeob; 
  wire      dataeobc; 
  wire      [(MAXIADDRESSWIDTH - 1):0] dataaddr; 
  wire      [(MAXIDATAWIDTH - 1):0] datao; 
  wire      dataack; 
  wire      [(MAXIDATAWIDTH - 1):0] datai; 

  wire      rstcsr; 
  wire      csrack; 
  wire      [SAXIDATAWIDTH - 1:0] csrdatao; 
  wire      csrreq; 
  wire      csrrw; 
  wire      [SAXIDATAWIDTH / 8 - 1:0] csrbe; 
  wire      [SAXIDATAWIDTH - 1:0] csrdatai; 
  wire      [7:0] csraddr; 

  MAC
  #(SAXIDATAWIDTH,
    MAXIDATAWIDTH,
    MAXIADDRESSWIDTH,
    TFIFODEPTH,
    RFIFODEPTH,
    TCDEPTH,
    RCDEPTH)
  U_MAC (
  .clkdma           (mhclk),
  .clkcsr           (shclk),
  .clkt             (clkt),
  .clkr             (clkr),
  .rstcsr           (rstcsr),
  .rsttco           (rsttco),
  .rstrco           (rstrco),
  .interrupt              (interrupt),
  .rps              (rps),
  .tps              (tps),
  .csrreq           (csrreq),
  .csrrw            (csrrw),
  .csrbe            (csrbe),
  .csrdatai         (csrdatai),
  .csrack           (csrack),
  .csraddr          (csraddr),
  .csrdatao         (csrdatao),
  .dataack          (dataack),
  .datareq          (datareq),
  .datareqc         (datareqc),
  .datarw           (datarw),
  .dataeob          (dataeob),
  .dataeobc         (dataeobc),
  .datai            (datai),
  .dataaddr         (dataaddr),
  .datao            (datao),
  .trdata           (trdata),
  .twe              (twe),
  .twaddr           (twaddr),
  .traddr           (traddr),
  .twdata           (twdata),
  .rrdata           (rrdata),
  .rwe              (rwe),
  .rwaddr           (rwaddr),
  .rraddr           (rraddr),
  .rwdata           (rwdata),
  .frdata           (frdata),
  .fwe              (fwe),
  .fraddr           (fraddr),
  .fwaddr           (fwaddr),
  .fwdata           (fwdata),
  .match            (match),
  .matchval         (matchval),
  .matchen          (matchen),
  .matchdata        (matchdata),
  .sdi              (sdi),
  .sclk             (sclk),
  .scs              (scs),
  .sdo              (sdo),
  .rxer             (rxer),
  .rxdv             (rxdv),
  .col              (col),
  .crs              (crs),
  .rxd              (rxd),
  .txen             (txen),
  .txer             (txer),
  .txd              (txd),
  .mdi              (mdi),
  .mdo              (mdo),
  .mden             (mden),
  .mdc              (mdc)
  ); 

  MAC2AXI
  #(MAXIDATAWIDTH,
    MAXIADDRESSWIDTH,
    SAXIDATAWIDTH,
    SAXIADDRESSWIDTH,
    MAXIDATAWIDTH,
    MAXIADDRESSWIDTH,
    SAXIDATAWIDTH,
    8)
  U_MAC2AXI (

  .mhclk             (mhclk      ),
  .mhresetn          (mhresetn   ),
  .shclk             (shclk      ),
  .shresetn          (shresetn   ),
  .mawid_o           (mawid_o    ),
  .mawaddr_o         (mawaddr_o  ),
  .mawlen_o          (mawlen_o   ),
  .mawsize_o         (mawsize_o  ),
  .mawburst_o        (mawburst_o ),
  .mawlock_o         (mawlock_o  ),
  .mawcache_o        (mawcache_o ),
  .mawprot_o         (mawprot_o  ),
  .mawvalid_o        (mawvalid_o ),
  .mawready_i        (mawready_i ),
  .mwid_o            (mwid_o     ),
  .mwdata_o          (mwdata_o   ),
  .mwstrb_o          (mwstrb_o   ),
  .mwlast_o          (mwlast_o   ),
  .mwvalid_o         (mwvalid_o  ),
  .mwready_i         (mwready_i  ),
  .mbid_i            (mbid_i     ),
  .mbresp_i          (mbresp_i   ),
  .mbvalid_i         (mbvalid_i  ),
  .mbready_o         (mbready_o  ),
  .marid_o           (marid_o    ),
  .maraddr_o         (maraddr_o  ),
  .marlen_o          (marlen_o   ),
  .marsize_o         (marsize_o  ),
  .marburst_o        (marburst_o ),
  .marlock_o         (marlock_o  ),
  .marcache_o        (marcache_o ),
  .marprot_o         (marprot_o  ),
  .marvalid_o        (marvalid_o ),
  .marready_i        (marready_i ),
  .mrid_i            (mrid_i     ),
  .mrdata_i          (mrdata_i   ),
  .mrresp_i          (mrresp_i   ),
  .mrlast_i          (mrlast_i   ),
  .mrvalid_i         (mrvalid_i  ),
  .mrready_o         (mrready_o  ),
  .sawid_i           (sawid_i    ),
  .sawaddr_i         (sawaddr_i  ),
  .sawlen_i          (sawlen_i   ),
  .sawsize_i         (sawsize_i  ),
  .sawburst_i        (sawburst_i ),
  .sawlock_i         (sawlock_i  ),
  .sawcache_i        (sawcache_i ),
  .sawprot_i         (sawprot_i  ),
  .sawvalid_i        (sawvalid_i ),
  .sawready_o        (sawready_o ),   
  .swid_i            (swid_i     ),
  .swdata_i          (swdata_i   ),
  .swstrb_i          (swstrb_i   ),
  .swlast_i          (swlast_i   ),
  .swvalid_i         (swvalid_i  ),
  .swready_o         (swready_o  ),
  .sbid_o            (sbid_o     ),
  .sbresp_o          (sbresp_o   ),
  .sbvalid_o         (sbvalid_o  ),
  .sbready_i         (sbready_i  ),
  .sarid_i           (sarid_i    ),
  .saraddr_i         (saraddr_i  ),
  .sarlen_i          (sarlen_i   ),
  .sarsize_i         (sarsize_i  ),
  .sarburst_i        (sarburst_i ),
  .sarlock_i         (sarlock_i  ),
  .sarcache_i        (sarcache_i ),
  .sarprot_i         (sarprot_i  ),
  .sarvalid_i        (sarvalid_i ),
  .sarready_o        (sarready_o ),
  .srid_o            (srid_o     ),
  .srdata_o          (srdata_o   ),
  .srresp_o          (srresp_o   ),
  .srlast_o          (srlast_o   ),
  .srvalid_o         (srvalid_o  ),
  .srready_i         (srready_i  ),                 
  .datareq           (datareq    ),
  .datareqc          (datareqc   ),
  .datarw            (datarw     ),
  .dataeob           (dataeob    ),
  .dataeobc          (dataeobc   ),
  .dataaddr          (dataaddr   ),
  .datao             (datao      ),
  .dataack           (dataack    ),
  .datai             (datai      ),
  .rstcsr            (rstcsr     ),
  .csrack            (csrack     ),
  .csrdatao          (csrdatao   ),
  .csrreq            (csrreq     ),
  .csrrw             (csrrw      ),
  .csrbe             (csrbe      ),
  .csrdatai          (csrdatai   ),
  .csraddr           (csraddr    )
  );

endmodule 
