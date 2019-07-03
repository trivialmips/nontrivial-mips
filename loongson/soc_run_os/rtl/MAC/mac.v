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

module MAC (
  clkdma,
  clkcsr,
  rstcsr,
  clkt,
  clkr,
  rsttco,
  rstrco,
  interrupt,
  tps,
  rps,
  csrreq,
  csrrw,
  csrbe,
  csrdatai,
  csraddr,
  csrack,
  csrdatao,
  dataack, 
  datareq,
  datareqc,
  datarw,
  dataeob,
  dataeobc,
  datai,
  dataaddr,
  datao,
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

  parameter CSRWIDTH   = 32;
  parameter DATAWIDTH  = 32;
  parameter DATADEPTH  = 32;
  parameter TFIFODEPTH = 9;
  parameter RFIFODEPTH = 9;
  parameter TCDEPTH = 1;
  parameter RCDEPTH = 2;

  `include "utility.v"

  input     clkdma; 
  input     clkcsr; 
  input     rstcsr;
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

  input     csrreq;
  input     csrrw;
  input     [CSRWIDTH / 8 - 1:0] csrbe;
  input     [CSRWIDTH - 1:0] csrdatai;
  input     [7:0]            csraddr;
  output    csrack; 
  wire      csrack;
  output    [CSRWIDTH - 1:0] csrdatao; 
  wire      [CSRWIDTH - 1:0] csrdatao;

  input     dataack;
  output    datareq; 
  wire      datareq;
  output    datareqc; 
  wire      datareqc;
  output    datarw; 
  wire      datarw;
  output    dataeob; 
  wire      dataeob;
  output    dataeobc; 
  wire      dataeobc;
  input     [DATAWIDTH - 1:0] datai;
  output    [DATADEPTH - 1:0] dataaddr; 
  wire      [DATADEPTH - 1:0] dataaddr;
  output    [DATAWIDTH - 1:0] datao; 
  wire      [DATAWIDTH - 1:0] datao;
  
  input     [DATAWIDTH - 1:0] trdata;
  output    twe; 
  wire      twe;
  output    [TFIFODEPTH - 1:0] twaddr; 
  wire      [TFIFODEPTH - 1:0] twaddr;
  output    [TFIFODEPTH - 1:0] traddr; 
  wire      [TFIFODEPTH - 1:0] traddr;
  output    [DATAWIDTH - 1:0] twdata; 
  wire      [DATAWIDTH - 1:0] twdata;

  input     [DATAWIDTH - 1:0] rrdata; 
  output    rwe; 
  wire      rwe;
  output    [RFIFODEPTH - 1:0] rwaddr; 
  wire      [RFIFODEPTH - 1:0] rwaddr;
  output    [RFIFODEPTH - 1:0] rraddr; 
  wire      [RFIFODEPTH - 1:0] rraddr;
  output    [DATAWIDTH - 1:0] rwdata; 
  wire      [DATAWIDTH - 1:0] rwdata;

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


  wire      rstsoft; 
  wire      rsttc; 
  wire      rstrc; 
  wire      rstdmao; 
  wire      rstcsro; 

  wire      [5:0] pbl; 
  wire      ac; 
  wire      dpd; 
  wire      [4:0] dsl; 
  wire      tpoll; 
  wire      [DATADEPTH - 1:0] tdbad; 
  wire      sf; 
  wire      [2:0] tm; 
  wire      fd; 
  wire      ble; 
  wire      dbo; 
  wire      ra; 
  wire      pm; 
  wire      pr; 
  wire      pb; 
  wire      rif; 
  wire      ho; 
  wire      hp; 
  wire      rpoll; 
  wire      rpollack; 
  wire      [DATADEPTH - 1:0] rdbad; 

  wire      insert_en;

  wire      tdes; 
  wire      tbuf; 
  wire      tset; 
  wire      tstat; 
  wire      tu; 
  wire      [1:0] ft; 
  wire      rdes; 
  wire      rstat; 
  wire      ru; 
  wire      rcomp; 
  wire      rcompack; 
  wire      tcomp; 
  wire      tcompack; 
 
  wire      [1:0] dma_priority; 
  wire      treq; 
  wire      twrite; 
  wire      [FIFODEPTH_MAX - 1:0] tcnt; 
  wire      [DATADEPTH - 1:0] taddr; 
  wire      [DATAWIDTH - 1:0] tdatai; 
  wire      tack; 
  wire      teob; 
  wire      [DATAWIDTH - 1:0] tdatao; 
  wire      rreq; 
  wire      rwrite; 
  wire      [FIFODEPTH_MAX - 1:0] rcnt; 
  wire      [DATADEPTH - 1:0] raddr; 
  wire      [DATAWIDTH - 1:0] rdatai; 
  wire      rack; 
  wire      reob; 
  wire      [DATAWIDTH - 1:0] rdatao; 
  wire      [DATADEPTH - 1:0] idataaddr; 

  wire      tfifonf; 
  wire      tfifocnf; 
  wire      tfifoval; 
  wire      tfifowe; 
  wire      tfifoeof; 
  wire      [DATAWIDTH / 8 - 1:0] tfifobe; 
  wire      [DATAWIDTH - 1:0] tfifodata; 
  wire      [TFIFODEPTH - 1:0] tfifolev; 
  wire      [TFIFODEPTH - 1:0] tradg; 

  wire      etiack; 
  wire      etireq; 
  wire      tcsne; 
  wire      tcachere; 
  wire      ic; 
  wire      ici; 
  wire      aci; 
  wire      dpdi; 
  wire      lo_o; 
  wire      nc_o; 
  wire      lc_o; 
  wire      ec_o; 
  wire      de_o; 
  wire      ur_o; 
  wire      [3:0] cc_o; 
  wire      lo_i; 
  wire      nc_i; 
  wire      lc_i; 
  wire      ec_i; 
  wire      de_i; 
  wire      ur_i; 
  wire      [3:0] cc_i; 

  wire      tpollack; 
  wire      tdbadc; 
  wire      [DATADEPTH - 1:0] statado; 
  wire      [DATADEPTH - 1:0] statadi; 

  wire      sofreq; 
  wire      eofreq; 
  wire      [DATAWIDTH / 8 - 1:0] be; 
  wire      [TFIFODEPTH - 1:0] eofad; 
  wire      [TFIFODEPTH - 1:0] twadg; 
  wire      tireq; 
  wire      tiack; 
  wire      winp; 

  wire      coll; 
  wire      carrier; 
  wire      bkoff; 
  wire      tpend; 
  wire      tprog; 
  wire      preamble; 

  wire      tcsreq; 
  wire      tcsack; 

  wire      stopt; 
  wire      stoptc; 
  wire      stoptfifo; 
  wire      stoptlsm; 

  wire      [RFIFODEPTH - 1:0] rradg; 
  wire      [RFIFODEPTH - 1:0] rwadg; 
  wire      rfifore; 
  wire      [DATAWIDTH - 1:0] rfifodata; 
  wire      rcachere; 
  wire      rcachene; 
  wire      rcachenf; 
  wire      [DATAWIDTH - 1:0] irwdata;
  wire      irwe;

  wire      riack; 
  wire      ren; 
  wire      rireq; 
  wire      ff; 
  wire      rf; 
  wire      mf; 
  wire      db; 
  wire      re; 
  wire      ce; 
  wire      tl; 
  wire      ftp; 
  wire      ov; 
  wire      cs;
  wire      [13:0] length; 
  wire      rprog;
  wire      rcpoll;


  wire      ff_o; 
  wire      rf_o; 
  wire      mf_o; 
  wire      tl_o; 
  wire      re_o; 
  wire      db_o; 
  wire      ce_o; 
  wire      ov_o; 
  wire      cs_o;
  wire      [13:0] fl_o; 

  wire      rdbadc; 
  wire      erireq; 
  wire      eriack; 
  wire      rbuf; 

  wire      foclack; 
  wire      mfclack; 
  wire      oco; 
  wire      mfo; 
  wire      [10:0] focg; 
  wire      [15:0] mfcg; 
  wire      focl; 
  wire      mfcl; 

  wire      stopr; 
  wire      stoprc; 
  wire      stoprfifo; 
  wire      stoprlsm; 
 
  wire      rcsack; 
  wire      rcsreq; 

  DMA #(DATAWIDTH, DATADEPTH) U_DMA(
   .clk           (clkdma),
   .rst           (rstdmao),
   .dma_priority      (dma_priority),
   .ble           (ble),
   .dbo           (dbo),
   .rdes          (rdes),
   .rbuf          (rbuf),
   .rstat         (rstat),
   .tdes          (tdes),
   .tbuf          (tbuf),
   .tstat         (tstat),
   .dataack       (dataack),
   .datai         (datai),
   .datareq       (datareq),
   .datareqc      (datareqc),
   .datarw        (datarw),
   .dataeob       (dataeob),
   .dataeobc      (dataeobc),
   .datao         (datao),
   .dataaddr      (dataaddr),
   .idataaddr     (idataaddr),
   .req1          (treq),
   .write1        (twrite),
   .tcnt1         (tcnt),
   .addr1         (taddr),
   .datai1        (tdatao),
   .ack1          (tack),
   .eob1          (teob),
   .datao1        (tdatai),
   .req2          (rreq),
   .write2        (rwrite),
   .tcnt2         (rcnt),
   .addr2         (raddr),
   .datai2        (rdatao),
   .ack2          (rack),
   .eob2          (reob),
   .datao2        (rdatai)
   ); 

  TLSM #(DATAWIDTH, DATADEPTH, TFIFODEPTH) U_TLSM(
   .clk           (clkdma),
   .rst           (rstdmao),
   .fifonf        (tfifonf),
   .fifocnf       (tfifocnf),
   .fifoval       (tfifoval),
   .fifowe        (tfifowe),
   .fifoeof       (tfifoeof),
   .fifobe        (tfifobe),
   .fifodata      (tfifodata),
   .fifolev       (tfifolev),
   .ic            (ici),
   .ac            (aci),
   .dpd           (dpdi),
   .statado       (statadi),
   .csne          (tcsne),
   .lo            (lo_i),
   .nc            (nc_i),
   .lc            (lc_i),
   .ec            (ec_i),
   .de            (de_i),
   .ur            (ur_i),
   .cc            (cc_i),
   .cachere       (tcachere),
   .statadi       (statado),
   .dmaack        (tack),
   .dmaeob        (teob),
   .dmadatai      (tdatai),
   .dmaaddr       (idataaddr),
   .dmareq        (treq),
   .dmawr         (twrite),
   .dmacnt        (tcnt),
   .dmaaddro      (taddr),
   .dmadatao      (tdatao),
   .fwe           (fwe),
   .fdata         (fwdata),
   .faddr         (fwaddr),
   .dsl           (dsl),
   .pbl           (pbl),
   .poll          (tpoll),
   .dbadc         (tdbadc),
   .dbad          (tdbad),
   .pollack       (tpollack),
   .tcompack      (tcompack),
   .tcomp         (tcomp),
   .des           (tdes),
   .fbuf          (tbuf),
   .stat          (tstat),
   .setp          (tset),
   .tu            (tu),
   .ft            (ft),
   .stopi         (stopt),
   .stopo         (stoptlsm)
   );
 
  TFIFO #(DATAWIDTH, DATADEPTH, TFIFODEPTH, TCDEPTH) U_TFIFO(
   .clk           (clkdma),
   .rst           (rstdmao),
   .ramwe         (twe),
   .ramaddr       (twaddr),
   .ramdata       (twdata),
   .fifowe        (tfifowe),
   .fifoeof       (tfifoeof),
   .fifobe        (tfifobe),
   .fifodata      (tfifodata),
   .fifonf        (tfifonf),
   .fifocnf       (tfifocnf),
   .fifoval       (tfifoval),
   .flev          (tfifolev),
   .ici           (ici),
   .dpdi          (dpdi),
   .aci           (aci),
   .statadi       (statadi),
   .cachere       (tcachere),
   .deo           (de_i),
   .lco           (lc_i),
   .loo           (lo_i),
   .nco           (nc_i),
   .eco           (ec_i),
   .ico           (ic),
   .uro           (ur_i), 
   .csne          (tcsne),
   .cco           (cc_i),
   .statado       (statado),
   .sofreq        (sofreq),
   .eofreq        (eofreq),
   .dpdo          (dpd),
   .aco           (ac),
   .beo           (be),
   .eofad         (eofad),
   .wadg          (twadg), 
   .tireq         (tireq),
   .winp          (winp),
   .dei           (de_o),
   .lci           (lc_o),
   .loi           (lo_o),
   .nci           (nc_o),
   .eci           (ec_o),
   .uri           (ur_o),
   .cci           (cc_o),
   .radg          (tradg),
   .tiack         (tiack),
   .sf            (sf),
   .fdp           (fd),
   .tm            (tm),
   .pbl           (pbl),
   .etiack        (etiack),
   .etireq        (etireq),
   .stopi         (stopt),
   .stopo         (stoptfifo)
   );

  TC #(TFIFODEPTH, DATAWIDTH) U_TC(
   .clk           (clkt),
   .rst           (rsttc),
   .txen          (txen),
   .txer          (txer),
   .txd           (txd),
   .ramdata       (trdata),
   .ramaddr       (traddr),
   .wadg          (twadg),
   .radg          (tradg),
   .dpd           (dpd),
   .ac            (ac),
   .sofreq        (sofreq),
   .eofreq        (eofreq),
   .tiack         (tiack),
   .lastbe        (be),
   .eofadg        (eofad),
   .tireq         (tireq),
   .ur            (ur_o),
   .de            (de_o),
   .coll          (coll),
   .carrier       (carrier),
   .bkoff         (bkoff),
   .tpend         (tpend),
   .tprog         (tprog),
   .preamble      (preamble),
   .stopi         (stopt),
   .stopo         (stoptc),
   .tcsack        (tcsack),
   .tcsreq        (tcsreq)
   ); 

  BD U_BD(
   .clk           (clkt),
   .rst           (rsttc),
   .col           (col),
   .crs           (crs),
   .fdp           (fd),
   .tprog         (tprog),
   .preamble      (preamble),
   .tpend         (tpend),
   .winp          (winp),
   .tiack         (tiack),
   .coll          (coll),
   .carrier       (carrier),
   .bkoff         (bkoff),
   .lc            (lc_o),
   .lo            (lo_o),
   .nc            (nc_o),
   .ec            (ec_o),
   .cc            (cc_o)
   ); 


  RC #(RFIFODEPTH, DATAWIDTH) U_RC(
   .clk           (clkr),
   .rst           (rstrc),
   .col           (col),
   .rxdv          (rxdv),
   .rxer          (rxer),
   .rxd           (rxd),
   .ramwe         (irwe),
   .ramaddr       (rwaddr),
   .ramdata       (irwdata),
   .fdata         (frdata),
   .faddr         (fraddr),
   .cachenf       (rcachenf),
   .radg          (rradg),
   .wadg          (rwadg),
   .rprog         (rprog),
   .rcpoll        (rcpoll),
   .riack         (riack),
   .ren           (ren),
   .ra            (ra),
   .pm            (pm),
   .pr            (pr),
   .pb            (pb),
   .rif           (rif),
   .ho            (ho),
   .hp            (hp),
   .rireq         (rireq),
   .ff            (ff),
   .rf            (rf),
   .mf            (mf),
   .db            (db),
   .re            (re),
   .ce            (ce),
   .tl            (tl),
   .ftp           (ftp),
   .ov            (ov),
   .cs            (cs),
   .length        (length),
   .match         (match),
   .matchval      (matchval),
   .matchen       (matchen),
   .matchdata     (matchdata),
   .focl          (focl),
   .foclack       (foclack),
   .oco           (oco),
   .focg          (focg),
   .mfcl          (mfcl),
   .mfclack       (mfclack),
   .mfo           (mfo),
   .mfcg          (mfcg),
   .stopi         (stopr),
   .stopo         (stoprc),
   .rcsack        (rcsack),
   .rcsreq        (rcsreq),
   .insert_en_i   (insert_en)
   ); 

  RFIFO #(DATAWIDTH, DATADEPTH, RFIFODEPTH, RCDEPTH) U_RFIFO(
   .clk           (clkdma),
   .rst           (rstdmao),
   .ramdata       (rrdata),
   .ramaddr       (rraddr),
   .fifore        (rfifore),
   .ffo           (ff_o),
   .rfo           (rf_o),
   .mfo           (mf_o),
   .tlo           (tl_o),
   .reo           (re_o),
   .dbo           (db_o),
   .ceo           (ce_o),
   .ovo           (ov_o),
   .cso           (cs_o),
   .flo           (fl_o),
   .fifodata      (rfifodata),
   .cachere       (rcachere),
   .cachene       (rcachene),
   .cachenf       (rcachenf),
   .radg          (rradg),
   .rireq         (rireq),
   .ffi           (ff),
   .rfi           (rf),
   .mfi           (mf),
   .tli           (tl),
   .rei           (re),
   .dbi           (db),
   .cei           (ce),
   .ovi           (ov),
   .csi           (cs),
   .fli           (length),
   .wadg          (rwadg),
   .riack         (riack)
   ); 

  RLSM #(DATAWIDTH, DATADEPTH, RFIFODEPTH) U_RLSM(
   .clk           (clkdma),
   .rst           (rstdmao),
   .fifodata      (rfifodata),
   .fifore        (rfifore),
   .cachere       (rcachere),
   .dmaack        (rack),
   .dmaeob        (reob),
   .dmadatai      (rdatai),
   .dmaaddr       (idataaddr),
   .dmareq        (rreq),
   .dmawr         (rwrite),
   .dmacnt        (rcnt),
   .dmaaddro      (raddr),
   .dmadatao      (rdatao),
   .rprog         (rprog),
   .rcpoll        (rcpoll),
   .fifocne       (rcachene),
   .ff            (ff_o),
   .rf            (rf_o),
   .mf            (mf_o),
   .db            (db_o),
   .re            (re_o),
   .ce            (ce_o),
   .tl            (tl_o),
   .ftp           (ftp),
   .ov            (ov_o),
   .cs            (cs_o),
   .length        (fl_o),
   .pbl           (pbl),
   .dsl           (dsl),
   .rpoll         (rpoll),
   .rdbadc        (rdbadc),
   .rdbad         (rdbad),
   .rpollack      (rpollack),
   .bufack        (eriack),
   .rcompack      (rcompack),
   .des           (rdes),
   .fbuf          (rbuf),
   .stat          (rstat),
   .ru            (ru),
   .rcomp         (rcomp),
   .bufcomp       (erireq),
   .stopi         (stopr),
   .stopo         (stoprlsm),
   .insert_en_i   (insert_en)
   ); 

  CSR #(CSRWIDTH, DATAWIDTH, DATADEPTH, RFIFODEPTH, RCDEPTH) U_CSR(
   .clk           (clkcsr),
   .rst           (rstcsro),
   .interrupt           (interrupt),
   .rstsofto      (rstsoft),
   .csrreq        (csrreq),
   .csrrw         (csrrw),
   .csrbe         (csrbe),
   .csraddr       (csraddr),
   .csrdatai      (csrdatai),
   .csrack        (csrack),
   .csrdatao      (csrdatao),
   .tprog         (tprog),
   .tireq         (tcomp),
   .unf           (ur_i), 
   .tiack         (tcompack),
   .tcsreq        (tcsreq),
   .tcsack        (tcsack),
   .fd            (fd),
   .ic            (ic),
   .etireq        (etireq),
   .etiack        (etiack),
   .tm            (tm),
   .sf            (sf),
   .tset          (tset),
   .tdes          (tdes),
   .tbuf          (tbuf),
   .tstat         (tstat),
   .tu            (tu),
   .tpollack      (tpollack),
   .ft            (ft),
   .tpoll         (tpoll),
   .tdbadc        (tdbadc),
   .tdbad         (tdbad),
   .rireq         (rcomp),
   .rcsreq        (rcsreq),
   .rprog         (rprog),
   .riack         (rcompack),
   .rcsack        (rcsack),
   .ren           (ren),
   .ra            (ra),
   .pm            (pm),
   .pr            (pr),
   .pb            (pb),
   .rif           (rif),
   .ho            (ho),
   .hp            (hp),
   .foclack       (foclack),
   .mfclack       (mfclack),
   .oco           (oco),
   .mfo           (mfo),
   .focg          (focg),
   .mfcg          (mfcg),
   .focl          (focl),
   .mfcl          (mfcl),
   .erireq        (erireq),
   .ru            (ru),
   .rpollack      (rpollack),
   .rdes          (rdes),
   .rbuf          (rbuf),
   .rstat         (rstat),
   .eriack        (eriack),
   .rpoll         (rpoll),
   .rdbadc        (rdbadc),
   .rdbad         (rdbad),
   .ble           (ble),
   .dbo           (dbo),
   .dma_priority      (dma_priority),
   .pbl           (pbl),
   .dsl           (dsl),
   .stoptc        (stoptc),
   .stoptlsm      (stoptlsm),
   .stoptfifo     (stoptfifo),
   .stopt         (stopt),
   .tps           (tps),
   .stoprc        (stoprc),
   .stoprlsm      (stoprlsm),
   .stopr         (stopr),
   .rps           (rps),
   .sdi           (sdi),
   .sclk          (sclk),
   .scs           (scs),
   .sdo           (sdo),
   .mdi           (mdi),
   .mdc           (mdc),
   .mdo           (mdo),
   .mden          (mden),
   .insert_en_o   (insert_en)
   ); 
 
  RSTC U_RSTC (
   .clkdma(clkdma),
   .clkcsr(clkcsr),
   .clkt(clkt),
   .clkr(clkr),
   .rstcsr(rstcsr),
   .rstsoft(rstsoft),
   .rsttc(rsttc),
   .rstrc(rstrc),
   .rstdmao(rstdmao),
   .rstcsro(rstcsro)
   ); 

  assign rwe = irwe ; 

  assign rwdata = irwdata ; 

  assign rsttco = rsttc ; 

  assign rstrco = rstrc ; 

endmodule 
