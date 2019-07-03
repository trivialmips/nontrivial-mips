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

module vMAC_TOP
(
        hclk,        hrst_,      SYS_RST_,

        hmst,        hmstlock,
        htrans,      hburst,      haddr,
        hwrite,      hsize,        
        hrdata,      hwdata,      hrdy,        hresp,
        eth_hreq,    eth_hlock,   eth_hgnt,
        eth_htrans,  eth_hburst,  eth_haddr,
        eth_hwrite,  eth_hsize,   eth_hprot,
        eth_hwdata,
        eth_hsel,    eth_hrdy,    eth_hresp,   eth_hsplit,
        eth_hrdata,

        interrupt,
     
        mtxclk,      mtxen,       mtxd,        mtxerr,
        mrxclk,      mrxdv,       mrxd,        mrxerr,
        mcoll,       mcrs,
        mdc,         md_i,        md_o,        md_oe,

	bist_mode
 
    );

input		hclk;
input		hrst_;
input	 [3:0]  hmst;
input		hmstlock;
input	 [1:0]  htrans;
input	 [2:0]  hburst;
input 	[31:0]  haddr;
input   		hwrite;
input 	 [2:0]  hsize;
input 	[31:0]  hrdata;
input   [31:0]  hwdata;
input 		hrdy;
input	 [1:0]  hresp;

output		eth_hreq;
output		eth_hlock;
input		eth_hgnt;
output	 [1:0]  eth_htrans;
output	 [2:0]  eth_hburst;
output	[31:0]  eth_haddr;
output		eth_hwrite;
output	 [2:0]  eth_hsize;
output   [3:0]  eth_hprot;
output	[31:0]  eth_hwdata;

input           eth_hsel;
output          eth_hrdy;
output   [1:0]  eth_hresp;
output  [15:0]  eth_hsplit;
output  [31:0]  eth_hrdata;

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

input           md_i;
output          mdc;
output          md_o;
output          md_oe;

output          interrupt;

input           bist_mode;
input           SYS_RST_;

wire tps,rps,rsttco,rstrco,sclk,scs,sdo;
  `define  MAHBDATAWIDTH 32
  `define  TFIFODEPTH 9
  `define  RFIFODEPTH 9
  `define  ADDRDEPTH  6
  wire      [`MAHBDATAWIDTH - 1:0] trdata;  
  wire      twe;
  wire      [`TFIFODEPTH - 1:0] twaddr;
  wire      [`TFIFODEPTH - 1:0] traddr;
  wire      [`MAHBDATAWIDTH - 1:0] twdata;
  wire      [`MAHBDATAWIDTH - 1:0] rrdata; 
  wire      rwe;
  wire      [`RFIFODEPTH - 1:0] rwaddr;
  wire      [`RFIFODEPTH - 1:0] rraddr;
  wire      [`MAHBDATAWIDTH - 1:0] rwdata;    
  wire      [15:0] frdata; 
  wire      fwe;
  wire      [`ADDRDEPTH - 1:0] fwaddr;
  wire      [`ADDRDEPTH - 1:0] fraddr;
  wire      [15:0] fwdata;   
  wire     match; 
  wire     matchval; 
  wire     matchen;
  wire     [47:0] matchdata;


RF2_512x32 TX_RAM(.CLKA(mtxclk),.CENA(1'b0),.AA(traddr),.QA(trdata),
	              .CLKB(hclk  ),.CENB(!twe),.AB(twaddr),.DB(twdata));


RF2_512x32 RX_RAM(.CLKA(hclk  ),.CENA(1'b0),.AA(rraddr),.QA(rrdata),
	              .CLKB(mrxclk),.CENB(!rwe),.AB(rwaddr),.DB(rwdata));

RF2_64x16 ADDR_RAM(.CLKA(mrxclk),.CENA(1'b0),.AA(fraddr),.QA(frdata),
                   .CLKB(hclk  ),.CENB(!fwe),.AB(fwaddr),.DB(fwdata));

	          
CAM_V FIL_CAM(.clk(mrxclk), .matchen(matchen), .matchdata(matchdata), .match(match), .matchval(matchval));  
MAC_AHB_V MAC_TEST(
  .clkt(mtxclk),
  .clkr(mrxclk),
  .rsttco(rsttco),
  .rstrco(rstrco),
  .interrupt(interrupt),
  .tps(tps),
  .rps(rps),
  .mhclk(hclk),
  .mhresetn(hrst_),
  .mhrdata(hrdata),
  .mhready(hrdy),
  .mhresp(hresp),
  .mhaddr(eth_haddr),
  .mhtrans(eth_htrans),
  .mhwrite(eth_hwrite),
  .mhsize(eth_hsize),
  .mhburst(eth_hburst),
  .mhprot(eth_hprot),
  .mhwdata(eth_hwdata),
  .mhgrantmac(eth_hgnt),
  .mhbusreqmac(eth_hreq),
  .mhlockmac(eth_hlock),
  .shclk(hclk),
  .shresetn(hrst_),
  .shselmac(eth_hsel),
  .shaddr(haddr[7:0]),
  .shwrite(hwrite),
  .shreadyi(hrdy),
  .shtrans(htrans),
  .shsize(hsize),
  .shburst(hburst),
  .shwdata(hwdata),
  .shreadyo(eth_hrdy),
  .shresp(eth_hresp),
  .shrdata(eth_hrdata),
  .trdata(trdata),
  .twe(twe),
  .twaddr(twaddr),
  .traddr(traddr),
  .twdata(twdata),
  .rrdata(rrdata),
  .rwe(rwe),
  .rwaddr(rwaddr),
  .rraddr(rraddr),
  .rwdata(rwdata),
  .frdata(frdata),
  .fwe(fwe),
  .fwaddr(fwaddr),
  .fraddr(fraddr),
  .fwdata(fwdata),
  .match(match),
  .matchval(matchval),
  .matchen(matchen),
  .matchdata(matchdata),
  .sdi(1'b0),
  .sclk(sclk),
  .scs(scs),
  .sdo(sdo),
  .rxer(mrxerr),
  .rxdv(mrxdv),
  .col(mcoll),
  .crs(mcrs),
  .rxd(mrxd),
  .txen(mtxen),
  .txer(mtxerr),
  .txd(mtxd),
  .mdc(mdc),
  .mdi(md_i),
  .mdo(md_o),
  .mden(md_oe)
  );

endmodule

module BD_V (
  clk,
  rst,
  col,
  crs,
  fdp,
  tprog,
  preamble,
  tpend,
  winp,
  tiack,
  coll,
  carrier,
  bkoff,
  lc,
  lo,
  nc,
  ec,
  cc
  );

  `include "utility.v"

  input     clk;
  input     rst;

  input     col;
  input     crs;

  input     fdp;

  input     tprog;
  input     preamble; 
  input     tpend; 
  output    winp; 
  wire      winp;
  input     tiack; 
  output    coll; 
  wire      coll;
  output    carrier; 
  wire      carrier;
  output    bkoff; 
  wire      bkoff;
  output    lc; 
  wire      lc;
  output    lo; 
  reg       lo;
  output    nc; 
  wire      nc;
  output    ec; 
  reg       ec;
  output    [3:0] cc; 
  wire      [3:0] cc;


  reg       crs_r; 
  reg       inc; 

  reg       ibkoff; 
  reg       ibkoff_r; 
  reg       icoll; 
  reg       ilc;
  reg       [3:0] ccnt; 
  reg       [9:0] bkcnt; 
  reg       [8:0] slcnt; 
  reg       [9:0] bkrel_c; 
  wire      [9:0] p_rand; 
  reg       [31:0] lfsr;
  reg       [31:0] lfsr_c;
  reg       iwinp; 

  always @(posedge clk)
  begin : crs_reg_proc
    if (rst)
    begin
      crs_r <= 1'b0 ;
      lo    <= 1'b0 ;
      inc   <= 1'b0 ;
    end
    else
    begin
      if (fdp)
      begin
        crs_r <= 1'b0 ; 
      end
      else
      begin
        crs_r <= crs ; 
      end 

      if (tprog & !inc & !crs_r)
      begin
        lo <= 1'b1 ; 
      end
      else if(!tpend & !tprog)
      begin
        lo <= 1'b0 ; 
      end

      if (tprog & crs_r)
      begin
        inc <= 1'b0 ;
      end
      else if (!tpend & !tprog)
      begin
        inc <= 1'b1 ;
      end
    end  
  end

  assign nc = inc ; 

  always @(ccnt or p_rand)
  begin : bkrel_proc
    case (ccnt)
      4'b0000 :
        begin
        bkrel_c <= {9'b000000000, p_rand[0]} ; 
        end
      4'b0001 :
        begin
        bkrel_c <= {8'b00000000, p_rand[1:0]} ; 
        end
      4'b0010 :
        begin
        bkrel_c <= {7'b0000000, p_rand[2:0]} ; 
        end
      4'b0011 :
        begin
        bkrel_c <= {6'b000000, p_rand[3:0]} ; 
        end
      4'b0100 :
        begin
        bkrel_c <= {5'b00000, p_rand[4:0]} ; 
        end
      4'b0101 :
        begin
        bkrel_c <= {4'b0000, p_rand[5:0]} ; 
        end
      4'b0110 :
        begin
        bkrel_c <= {3'b000, p_rand[6:0]} ; 
        end
      4'b0111 :
        begin
        bkrel_c <= {2'b00, p_rand[7:0]} ; 
        end
      4'b1000 :
        begin
        bkrel_c <= {1'b0, p_rand[8:0]} ; 
        end
      default :
        begin
        bkrel_c <= p_rand[9:0] ; 
        end
    endcase 
  end 

  always @(posedge clk)
  begin : slcnt_reg_proc
    if (rst)
    begin
      slcnt <= {9{1'b1}} ; 
    end
    else
    begin
      if (tprog & !preamble & !icoll)
      begin
        if (slcnt != 9'b000000000)
        begin
          slcnt <= slcnt - 1 ; 
        end 
      end
      else if (ibkoff)
      begin
        if (slcnt == 9'b000000000 | icoll)
        begin
          slcnt <= SLOT_TIME ; 
        end
        else
        begin
          slcnt <= slcnt - 1 ; 
        end 
      end
      else
      begin
        slcnt <= SLOT_TIME ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : bkcnt_reg_proc
    if (rst)
    begin
      bkcnt <= {10{1'b1}} ; 
    end
    else
    begin
      if (icoll & !ibkoff)
      begin
        bkcnt <= bkrel_c ; 
      end
      else if (slcnt == 9'b000000000)
      begin
        bkcnt <= bkcnt - 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : rand_reg_proc
    if (rst)
    begin
      lfsr <= {31{1'b1}};      
    end
    else
    begin
      lfsr <= lfsr_c;
    end
  end

  always @(lfsr)
  begin : lfsr_drv

    reg     [31:0] lfsr_n;
    
    integer i;
    for(i=0; i<=30; i=i+1)
    begin
      lfsr_n[i] = lfsr[i+1];
    end
    
    lfsr_n[31] = 1'b0;  
    if(lfsr[0]==1'b1)
    begin
      lfsr_n = lfsr_n ^ 32'b10000000000000000000111010100110; 
    end

    lfsr_c <= lfsr_n;
    
  end
  
  assign p_rand = lfsr[9:0] ;
  
  
  always @(posedge clk)
  begin : ibkoff_reg_proc
    if (rst)
    begin
      ibkoff <= 1'b0 ; 
      ibkoff_r <= 1'b0 ; 
    end
    else
    begin
      ibkoff_r <= ibkoff ; 
      if(icoll & ccnt!=4'b1111 & !iwinp & !ilc)
      begin
        ibkoff <= 1'b1 ; 
      end
      else if (bkcnt == 10'b0000000000)
      begin
        ibkoff <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : coll_reg_proc
    if (rst)
    begin
      icoll <= 1'b0 ;
      ilc   <= 1'b0 ;
      ec    <= 1'b0 ;
      iwinp <= 1'b1 ;
      ccnt  <= 4'b0000 ; 
    end
    else
    begin
      if ((preamble | tprog) & col & !fdp)
      begin
        icoll <= 1'b1 ; 
      end
      else if (!tprog & !preamble)
      begin
        icoll <= 1'b0 ; 
      end 

      if (tiack)
      begin
        ilc <= 1'b0 ; 
      end
      else if (tprog & icoll & iwinp)
      begin
        ilc <= 1'b1 ; 
      end 

      if (tiack)
      begin
        ec <= 1'b0 ; 
      end
      else if (icoll & ccnt == 4'b1111 & tprog)
      begin
        ec <= 1'b1 ; 
      end 

      if (slcnt == 9'b000000000 | !tprog)
      begin
        iwinp <= 1'b1 ;
      end
      else
      begin
        iwinp <= 1'b0 ;
      end
        
      if (!tpend & !tprog)
      begin
        ccnt <= 4'b0000 ;
      end
      else if (ibkoff & !ibkoff_r)
      begin
        ccnt <= ccnt + 4'b0001 ;
      end
    end  
  end

  assign winp = iwinp ;

  assign lc = ilc;

  assign carrier = crs_r ; 

  assign coll = icoll ; 

  assign bkoff = ibkoff ; 

  assign cc = ccnt ; 

endmodule



module CAM_V (clk, matchen, matchdata, match, matchval);

  input     clk;
  input     matchen;
  input     [47:0] matchdata;
  output    match; 
  wire      match;
  output    matchval; 
  wire      matchval;

  parameter [47:0] adr0 = {8'b10111010, 8'b10011000, 8'b01110110,
                           8'b01010100, 8'b00110010, 8'b00010001};
  parameter [47:0] adr1 = {8'b00000000, 8'b00000000, 8'b00000000,
                           8'b00000000, 8'b00000000, 8'b00000000}; 
  parameter [47:0] adr2 = {8'b00000000, 8'b00000000, 8'b00000000,
                           8'b00000000, 8'b00000000, 8'b00000000}; 
  parameter [47:0] adr3 = {8'b00000000, 8'b00000000, 8'b00000000,
                           8'b00000000, 8'b00000000, 8'b00000000}; 
  reg       imatchval; 

  always @(posedge clk)
  begin : imatchval_proc
    imatchval <= matchen ; 
  end

  assign match = (imatchval & (adr0 == matchdata |
                               adr1 == matchdata |
                               adr2 == matchdata |
                               adr3 == matchdata)) ? 1'b1 : 1'b0 ; 

  assign matchval = imatchval ; 

endmodule



module CSR_V (
  clk,
  rst,
  interrupt,
  csrreq,
  csrrw,
  csrbe,
  csraddr,
  csrdatai,
  csrack,
  csrdatao,
  rstsofto,
  tprog,
  tireq,
  unf,
  tcsreq,
  tiack,
  tcsack,
  fd,
  ic,
  etireq,
  etiack,
  tm,
  sf,
  tset,
  tdes,
  tbuf,
  tstat,
  tu,
  tpollack,
  ft,
  tpoll,
  tdbadc,
  tdbad,
  rcsreq,
  rprog,
  rcsack,
  ren,
  ra,
  pm,
  pr,
  pb,
  rif,
  ho,
  hp,
  foclack,
  mfclack,
  oco,
  mfo,
  focg,
  mfcg,
  focl,
  mfcl,
  rireq,
  erireq,
  ru,
  rpollack,
  rdes,
  rbuf,
  rstat,
  riack,
  eriack,
  rpoll,
  rdbadc,
  rdbad,
  ble,
  dbo,
  dma_priority,
  pbl,
  dsl,
  stoptc,
  stoptlsm,
  stoptfifo,
  stopt,
  tps,
  stoprc,
  stoprlsm,
  stopr,
  rps,
  sdi,
  sclk,
  scs,
  sdo,
  mdi,
  mdc,
  mdo,
  mden
  );

  parameter CSRWIDTH = 32;
  parameter DATAWIDTH = 32;
  parameter DATADEPTH = 32;
  parameter RFIFODEPTH  = 9;
  parameter RCDEPTH  = 2;

  `include "utility.v"

  input     clk; 
  input     rst; 
  output    interrupt; 
  wire      interrupt;

  input     csrreq; 
  input     csrrw;
  input     [CSRWIDTH / 8 - 1:0] csrbe;
  input     [CSRDEPTH - 1:0] csraddr; 
  input     [CSRWIDTH - 1:0] csrdatai; 
  output    csrack; 
  wire      csrack;
  output    [CSRWIDTH - 1:0] csrdatao; 
  reg       [CSRWIDTH - 1:0] csrdatao;

  output    rstsofto; 
  reg       rstsofto;
  
  input     tprog; 
  input     tireq;
  input     unf; 
  input     tcsreq;
  output    tiack; 
  wire      tiack;
  output    tcsack; 
  wire      tcsack;
  output    fd; 
  wire      fd;
  
  input     ic;
  input     etireq;
  output    etiack; 
  wire      etiack;
  output    [2:0] tm; 
  wire      [2:0] tm;
  output    sf; 
  wire      sf;

  input     tset;
  input     tdes; 
  input     tbuf;
  input     tstat; 
  input     tu; 
  input     tpollack; 
  input     [1:0] ft; 
  output    tpoll; 
  wire      tpoll;
  output    tdbadc; 
  reg       tdbadc;
  output    [DATADEPTH - 1:0] tdbad; 
  wire      [DATADEPTH - 1:0] tdbad;

  input     rcsreq;
  input     rprog;
  output    rcsack; 
  wire      rcsack;
  output    ren; 
  wire      ren;
  output    ra; 
  wire      ra;
  output    pm; 
  wire      pm;
  output    pr; 
  wire      pr;
  output    pb; 
  wire      pb;
  output    rif; 
  wire      rif;
  output    ho; 
  wire      ho;
  output    hp; 
  wire      hp;

  input     foclack; 
  input     mfclack;
  input     oco; 
  input     mfo;
  input     [10:0] focg; 
  input     [15:0] mfcg;
  output    focl; 
  reg       focl;
  output    mfcl;
  reg       mfcl;

  input     rireq; 
  input     erireq; 
  input     ru; 
  input     rpollack; 
  input     rdes; 
  input     rbuf;
  input     rstat;
  output    riack;
  wire      riack;
  output    eriack; 
  wire      eriack;
  output    rpoll; 
  reg       rpoll;
  output    rdbadc; 
  reg       rdbadc;
  output    [DATADEPTH - 1:0] rdbad; 
  wire      [DATADEPTH - 1:0] rdbad;

  output    ble; 
  wire      ble;
  output    dbo; 
  wire      dbo;
  output    [1:0] dma_priority; 
  wire      [1:0] dma_priority;
  output    [5:0] pbl; 
  wire      [5:0] pbl;
  output    [4:0] dsl; 
  wire      [4:0] dsl;

  input     stoptc;
  input     stoptlsm; 
  input     stoptfifo; 
  output    stopt; 
  wire      stopt;
  output    tps; 
  reg       tps;

  input     stoprc; 
  input     stoprlsm;
  output    stopr; 
  wire      stopr;
  output    rps; 
  reg       rps;

  input     sdi; 
  output    sclk; 
  wire      sclk;
  output    scs; 
  wire      scs;
  output    sdo; 
  wire      sdo;

  input     mdi; 
  output    mdc; 
  wire      mdc;
  output    mdo; 
  wire      mdo;
  output    mden; 
  wire      mden;


  reg       [31:0] csrdata_c; 
  reg       [3:0] csrdbe_c; 
  wire      [1:0] csraddr10; 
  wire      [5:0] csraddr72; 
  wire      [1:0] csrbe10; 
  wire      [31:0] csr0; 
  wire      [31:0] csr5; 
  wire      [31:0] csr6; 
  wire      [31:0] csr7; 
  wire      [31:0] csr8; 
  wire      [31:0] csr9; 
  wire      [31:0] csr11; 

  reg       csr0_dbo; 
  reg       [2:0] csr0_tap; 
  reg       [5:0] csr0_pbl; 
  reg       csr0_ble; 
  reg       [4:0] csr0_dsl; 
  reg       csr0_bar; 
  reg       csr0_swr; 

  reg       [31:0] csr3; 

  reg       [31:0] csr4; 

  reg       [2:0] csr5_ts; 
  reg       [2:0] csr5_rs; 
  reg       csr5_nis; 
  reg       csr5_ais; 
  reg       csr5_eri; 
  reg       csr5_gte; 
  reg       csr5_eti; 
  reg       csr5_rps; 
  reg       csr5_ru; 
  reg       csr5_ri; 
  reg       csr5_unf; 
  reg       csr5_tu; 
  reg       csr5_tps; 
  reg       csr5_ti; 

  reg       csr6_ra; 
  reg       csr6_ttm; 
  reg       csr6_sf; 
  reg       [1:0] csr6_tr; 
  reg       csr6_st; 
  reg       csr6_fd; 
  reg       csr6_pm; 
  reg       csr6_pr; 
  reg       csr6_if; 
  reg       csr6_pb; 
  reg       csr6_ho; 
  reg       csr6_sr; 
  reg       csr6_hp; 

  reg       csr7_nie; 
  reg       csr7_aie; 
  reg       csr7_ere; 
  reg       csr7_gte; 
  reg       csr7_ete; 
  reg       csr7_rse; 
  reg       csr7_rue; 
  reg       csr7_rie; 
  reg       csr7_une; 
  reg       csr7_tue; 
  reg       csr7_tse; 
  reg       csr7_tie; 

  reg       [10:0] csr8_foc; 
  reg       csr8_oco; 
  reg       [15:0] csr8_mfc; 
  reg       csr8_mfo; 
  reg       csr8read; 

  reg       csr9_mdi; 
  reg       csr9_mii; 
  reg       csr9_mdo; 
  reg       csr9_mdc; 
  reg       csr9_sdi; 
  reg       csr9_sclk; 
  reg       csr9_scs; 
  reg       csr9_sdo; 

  reg       csr11_cs; 
  reg       [3:0] csr11_tt; 
  reg       [2:0] csr11_ntp; 
  reg       [3:0] csr11_rt; 
  reg       [2:0] csr11_nrp; 
  reg       csr11_con; 
  reg       [15:0] csr11_tim; 
  reg       csr11wr; 

  reg       tapwr; 
  reg       tpollcmd; 
  reg       itpoll; 
  reg       [2:0] tapcnt; 

  reg       [1:0] tpsm_c; 
  reg       [1:0] tpsm; 
  reg       tstopcmd; 
  reg       tstartcmd; 
  reg       stoptc_r; 
  reg       stoptlsm_r; 
  reg       stoptfifo_r; 
  wire      [2:0] ts_c; 

  reg       [1:0] rpsm_c; 
  reg       [1:0] rpsm; 
  reg       rstopcmd; 
  reg       rstartcmd; 
  reg       stoprc_r; 
  reg       stoprlsm_r; 
  wire      [2:0] rs_c; 

  reg       rpollcmd; 

  wire      csr5wr_c; 
  reg       csr5wr;
  reg       gte; 
  reg       iint; 
  reg       rireq_r; 
  reg       rireq_r2; 
  reg       eri; 
  reg       erireq_r; 
  reg       erireq_r2; 
  reg       tireq_r; 
  reg       tireq_r2; 
  reg       eti; 
  reg       etireq_r; 
  reg       etireq_r2; 
  reg       unfi; 
  reg       unf_r; 
  reg       unf_r2; 
  reg       tui; 
  reg       tu_r; 
  reg       tu_r2; 
  reg       rui; 
  reg       ru_r; 
  reg       ru_r2; 
  reg       iic; 

  reg       rcsreq_r; 
  reg       rcsreq_r1; 
  reg       rimprog; 
  reg       [3:0] rcscnt; 
  reg       rcs2048; 
  reg       rcs128; 
  reg       [3:0] rtcnt; 
  reg       [2:0] rcnt; 
  reg       rimex; 

  reg       timprog; 
  reg       [7:0] ttcnt; 
  reg       [2:0] tcnt; 
  reg       timex; 
  reg       tcsreq_r1; 
  reg       tcsreq_r2; 
  reg       [3:0] tcscnt; 
  reg       tcs2048; 
  reg       tcs128; 

  reg       [10:0] foc_c; 
  reg       [15:0] mfc_c; 
  reg       [10:0] focg_r;
  reg       [15:0] mfcg_r;

  reg       gstart; 
  reg       gstart_r; 
  reg       [15:0] gcnt; 
  wire      [CSRWIDTH_MAX + 1:0] csrdatai_max;
  wire      [CSRWIDTH_MAX + 1:0] czero_max;
  wire      [CSRWIDTH_MAX/8 + 1:0] csrbe_max;

  assign csraddr10 = csraddr[1:0] ; 

  assign csraddr72 = csraddr[7:2] ; 

  assign csrbe10 = (CSRWIDTH == 16) ? csrbe_max[1:0] : {2{1'b1}} ; 

  always @(csrdatai_max or csrbe_max or csraddr or csraddr10 or csrbe10)
  begin : csrdata_proc
    csrdata_c <= {32{1'b1}} ; 
    csrdbe_c <= {4{1'b1}} ; 
    case (CSRWIDTH)
      8 :
        begin
          if (csrbe_max[0])
          begin
            case (csraddr10)
              2'b00 :
                begin
                  csrdata_c[7:0] <= csrdatai_max[CSRWIDTH-1:0] ; 
                  csrdbe_c <= 4'b0001 ; 
                end
              2'b01 :
                begin
                  csrdata_c[15:8] <= csrdatai_max[CSRWIDTH-1:0] ; 
                  csrdbe_c <= 4'b0010 ; 
                end
              2'b10 :
                begin
                  csrdata_c[23:16] <= csrdatai_max[CSRWIDTH-1:0] ; 
                  csrdbe_c <= 4'b0100 ; 
                end
              default :
                begin
                  csrdata_c[31:24] <= csrdatai_max[CSRWIDTH-1:0] ; 
                  csrdbe_c <= 4'b1000 ; 
                end
            endcase 
          end
          else
          begin
            csrdbe_c <= 4'b0000 ; 
          end 
        end
      16 :
        begin
          case (csrbe10)
            2'b11 :
              begin
                if (csraddr[1])
                begin
                  csrdata_c[31:16] <= csrdatai_max[CSRWIDTH-1:0] ; 
                  csrdbe_c <= 4'b1100 ; 
                end
                else
                begin
                  csrdata_c[15:0] <= csrdatai_max[CSRWIDTH-1:0] ; 
                  csrdbe_c <= 4'b0011 ; 
                end 
              end
            2'b10 :
              begin
                if (csraddr[1])
                begin
                  csrdata_c[31:24] <= 
                    csrdatai_max[CSRWIDTH - 1:CSRWIDTH / 2] ; 
                  csrdbe_c <= 4'b1000 ; 
                end
                else
                begin
                  csrdata_c[15: 8] <= 
                    csrdatai_max[CSRWIDTH - 1:CSRWIDTH / 2] ; 
                  csrdbe_c <= 4'b0010 ; 
                end 
              end
            2'b01 :
              begin
                if (csraddr[1])
                begin
                  csrdata_c[23:16] <= csrdatai_max[7:0] ; 
                  csrdbe_c <= 4'b0100 ; 
                end
                else
                begin
                  csrdata_c[7:0] <= csrdatai_max[7:0] ; 
                  csrdbe_c <= 4'b0001 ; 
                end 
              end
            default :
              begin
                csrdbe_c <= 4'b0000 ; 
              end
          endcase 
        end
      default :
        begin
          csrdata_c <= csrdatai_max[31:0] ; 
          csrdbe_c <= csrbe_max[3:0] ; 
        end
    endcase 
  end

  always @(posedge clk)
  begin : csr0_reg_proc
    if (rst)
    begin
      csr0_dbo <= CSR0_RV[20] ; 
      csr0_tap <= CSR0_RV[19:17] ; 
      csr0_pbl <= CSR0_RV[13:8] ; 
      csr0_ble <= CSR0_RV[7] ; 
      csr0_dsl <= CSR0_RV[6:2] ; 
      csr0_bar <= CSR0_RV[1] ; 
      csr0_swr <= CSR0_RV[0] ; 
      tapwr <= 1'b0 ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR0_ID)
      begin
        if (csrdbe_c[2])
        begin
          csr0_dbo <= csrdata_c[20] ; 
          csr0_tap <= csrdata_c[19:17] ; 
          tapwr <= 1'b1 ; 
        end
        else
        begin
          tapwr <= 1'b0 ; 
        end 
        if (csrdbe_c[1])
        begin
          csr0_pbl <= csrdata_c[13:8] ; 
        end 
        if (csrdbe_c[0])
        begin
          csr0_ble <= csrdata_c[7] ; 
          csr0_dsl <= csrdata_c[6:2] ; 
          csr0_bar <= csrdata_c[1] ; 
          csr0_swr <= csrdata_c[0] ; 
        end 
      end
      else
      begin
        tapwr <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : tpoolcmd_reg_proc
    if (rst)
    begin
      tpollcmd <= 1'b0 ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR1_ID)
      begin
        tpollcmd <= 1'b1 ; 
      end
      else
      begin
        tpollcmd <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : rpoolcmd_reg_proc
    if (rst)
    begin
      rpollcmd <= 1'b0 ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR2_ID)
      begin
        rpollcmd <= 1'b1 ; 
      end
      else
      begin
        rpollcmd <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : csr3_reg_proc
    if (rst)
    begin
      csr3 <= CSR3_RV ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR3_ID)
      begin
        if (csrdbe_c[0])
        begin
          csr3[7:0] <= csrdata_c[7:0] ; 
        end 
        if (csrdbe_c[1])
        begin
          csr3[15:8] <= csrdata_c[15:8] ; 
        end 
        if (csrdbe_c[2])
        begin
          csr3[23:16] <= csrdata_c[23:16] ; 
        end 
        if (csrdbe_c[3])
        begin
          csr3[31:24] <= csrdata_c[31:24] ; 
        end 
      end 
    end  
  end

  assign rdbad = csr3[DATADEPTH - 1:0] ; 

  always @(posedge clk)
  begin : rdbadc_reg_proc
    if (rst)
    begin
      rdbadc <= 1'b1 ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR3_ID & rpsm == PSM_STOP)
      begin
        rdbadc <= 1'b1 ; 
      end
      else if (rpsm == PSM_RUN)
      begin
        rdbadc <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : csr4_reg_proc
    if (rst)
    begin
      csr4 <= CSR4_RV ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR4_ID)
      begin
        if (csrdbe_c[0])
        begin
          csr4[7:0] <= csrdata_c[7:0] ; 
        end 
        if (csrdbe_c[1])
        begin
          csr4[15:8] <= csrdata_c[15:8] ; 
        end 
        if (csrdbe_c[2])
        begin
          csr4[23:16] <= csrdata_c[23:16] ; 
        end 
        if (csrdbe_c[3])
        begin
          csr4[31:24] <= csrdata_c[31:24] ; 
        end 
      end 
    end  
  end

  always @(posedge clk)
  begin : tdbadc_reg_proc
    if (rst)
    begin
      tdbadc <= 1'b1 ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR4_ID)
      begin
        tdbadc <= 1'b1 ; 
      end
      else if (tpsm == PSM_RUN)
      begin
        tdbadc <= 1'b0 ; 
      end 
    end  
  end

  assign csr5wr_c = (!csrrw & csrreq & csraddr72 == CSR5_ID) ? 1'b1 :
                                                               1'b0 ; 

  always @(posedge clk)
  begin : csr5wr_reg_proc
    if (rst)
    begin
      csr5wr <= 1'b0 ;
    end
    else
    begin
      csr5wr <= csr5wr_c ;
    end
  end

  always @(posedge clk)
  begin : csr5_reg_proc
    if (rst)
    begin
      csr5_ts <= CSR5_RV[22:20] ; 
      csr5_rs <= CSR5_RV[19:17] ; 
      csr5_nis <= CSR5_RV[16] ; 
      csr5_ais <= CSR5_RV[15] ; 
      csr5_eri <= CSR5_RV[14] ; 
      csr5_gte <= CSR5_RV[11] ; 
      csr5_eti <= CSR5_RV[10] ; 
      csr5_rps <= CSR5_RV[8] ; 
      csr5_ru <= CSR5_RV[7] ; 
      csr5_ri <= CSR5_RV[6] ; 
      csr5_unf <= CSR5_RV[5] ; 
      csr5_tu <= CSR5_RV[2] ; 
      csr5_tps <= CSR5_RV[1] ; 
      csr5_ti <= CSR5_RV[0] ; 
    end
    else
    begin
      if (csr5wr_c)
      begin
        if (csrdbe_c[2])
        begin
          csr5_nis <= ~csrdata_c[16] & csr5_nis ; 
        end 
        if (csrdbe_c[1])
        begin
          csr5_ais <= ~csrdata_c[15] & csr5_ais ; 
          csr5_eri <= ~csrdata_c[14] & csr5_eri ; 
          csr5_gte <= ~csrdata_c[11] & csr5_gte ; 
          csr5_eti <= ~csrdata_c[10] & csr5_eti ; 
          csr5_rps <= ~csrdata_c[8] & csr5_rps ; 
        end 
        if (csrdbe_c[0])
        begin
          csr5_ru <= ~csrdata_c[7] & csr5_ru ; 
          csr5_ri <= ~csrdata_c[6] & csr5_ri ; 
          csr5_unf <= ~csrdata_c[5] & csr5_unf ; 
          csr5_tu <= ~csrdata_c[2] & csr5_tu ; 
          csr5_tps <= ~csrdata_c[1] & csr5_tps ; 
          csr5_ti <= ~csrdata_c[0] & csr5_ti ; 
        end 
      end
      else
      begin
        if (timex)
        begin
          csr5_ti <= 1'b1 ; 
        end 
        if (rimex)
        begin
          csr5_ri <= 1'b1 ; 
        end 
        if (eti)
        begin
          csr5_eti <= 1'b1 ; 
        end 
        if (eri)
        begin
          csr5_eri <= 1'b1 ; 
        end 
        if (gte)
        begin
          csr5_gte <= 1'b1 ; 
        end 
        if (tpsm_c == PSM_STOP & 
            (tpsm == PSM_RUN | tpsm == PSM_SUSPEND))
        begin
          csr5_tps <= 1'b1 ; 
        end 
        if (rpsm_c == PSM_STOP &
            (rpsm == PSM_RUN | rpsm == PSM_SUSPEND))
        begin
          csr5_rps <= 1'b1 ; 
        end 
        if (rui)
        begin
          csr5_ru <= 1'b1 ; 
        end 
        if (tui)
        begin
          csr5_tu <= 1'b1 ; 
        end 
        if (unfi)
        begin
          csr5_unf <= 1'b1 ; 
        end 
        if ((csr5_ri  & csr7_rie) |
            (csr5_ti  & csr7_tie) |
            (csr5_eri & csr7_ere) |
            (csr5_tu  & csr7_tue) |
            (csr5_gte & csr7_gte))
        begin
          csr5_nis <= 1'b1 ; 
        end
        else
        begin
          csr5_nis <= 1'b0 ; 
        end 
        if ((csr5_eti & csr7_ete) |
            (csr5_rps & csr7_rse) |
            (csr5_ru  & csr7_rue) |
            (csr5_unf & csr7_une) |
            (csr5_tps & csr7_tse))
        begin
          csr5_ais <= 1'b1 ; 
        end
        else
        begin
          csr5_ais <= 1'b0 ; 
        end 
        csr5_ts <= ts_c ; 
        csr5_rs <= rs_c ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : csr6_reg_proc
    if (rst)
    begin
      csr6_ra <= CSR6_RV[30] ; 
      csr6_ttm <= CSR6_RV[22] ; 
      csr6_sf <= CSR6_RV[21] ; 
      csr6_tr <= CSR6_RV[15:14] ; 
      csr6_st <= CSR6_RV[13] ; 
      csr6_fd <= CSR6_RV[9] ; 
      csr6_pm <= CSR6_RV[7] ; 
      csr6_pr <= CSR6_RV[6] ; 
      csr6_if <= CSR6_RV[4] ; 
      csr6_pb <= CSR6_RV[3] ; 
      csr6_ho <= CSR6_RV[2] ;
      csr6_sr <= CSR6_RV[1] ;
      csr6_hp <= CSR6_RV[0] ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR6_ID)
      begin
        if (csrdbe_c[3])
        begin
          csr6_ra <= csrdata_c[30] ; 
        end 
        if (csrdbe_c[2])
        begin
          csr6_ttm <= csrdata_c[22] ; 
          if (tpsm == PSM_STOP)
          begin
            csr6_sf <= csrdata_c[21] ; 
          end 
        end 
        if (csrdbe_c[1])
        begin
          csr6_tr <= csrdata_c[15:14] ; 
          csr6_st <= csrdata_c[13] ; 
          csr6_fd <= csrdata_c[9] ; 
        end 
        if (csrdbe_c[0])
        begin
          csr6_pm <= csrdata_c[7] ; 
          csr6_pr <= csrdata_c[6] ; 
          csr6_pb <= csrdata_c[3] ;
          csr6_sr <= csrdata_c[1] ;
        end 
      end 
      case (ft)
        FT_PERFECT :
          begin
            csr6_ho <= 1'b0 ; 
            csr6_if <= 1'b0 ; 
            csr6_hp <= 1'b0 ; 
          end
        FT_HASH :
          begin
            csr6_ho <= 1'b0 ; 
            csr6_if <= 1'b0 ; 
            csr6_hp <= 1'b1 ; 
          end
        FT_INVERSE :
          begin
            csr6_ho <= 1'b0 ; 
            csr6_if <= 1'b1 ; 
            csr6_hp <= 1'b0 ; 
          end
        default :
          begin
            csr6_ho <= 1'b1 ; 
            csr6_if <= 1'b0 ; 
            csr6_hp <= 1'b1 ; 
          end
      endcase 
    end  
  end

  always @(posedge clk)
  begin : csr7_reg_proc
    if (rst)
    begin
      csr7_nie <= CSR7_RV[16] ; 
      csr7_aie <= CSR7_RV[15] ; 
      csr7_ere <= CSR7_RV[14] ; 
      csr7_gte <= CSR7_RV[11] ; 
      csr7_ete <= CSR7_RV[10] ; 
      csr7_rse <= CSR7_RV[8] ; 
      csr7_rue <= CSR7_RV[7] ; 
      csr7_rie <= CSR7_RV[6] ; 
      csr7_une <= CSR7_RV[5] ; 
      csr7_tue <= CSR7_RV[2] ; 
      csr7_tse <= CSR7_RV[1] ; 
      csr7_tie <= CSR7_RV[0] ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR7_ID)
      begin
        if (csrdbe_c[2])
        begin
          csr7_nie <= csrdata_c[16] ; 
        end 
        if (csrdbe_c[1])
        begin
          csr7_aie <= csrdata_c[15] ; 
          csr7_ere <= csrdata_c[14] ; 
          csr7_gte <= csrdata_c[11] ; 
          csr7_ete <= csrdata_c[10] ; 
          csr7_rse <= csrdata_c[8] ; 
        end 
        if (csrdbe_c[0])
        begin
          csr7_rue <= csrdata_c[7] ; 
          csr7_rie <= csrdata_c[6] ; 
          csr7_une <= csrdata_c[5] ; 
          csr7_tue <= csrdata_c[2] ; 
          csr7_tse <= csrdata_c[1] ; 
          csr7_tie <= csrdata_c[0] ; 
        end 
      end 
    end  
  end

  always @(posedge clk)
  begin : csr8_reg_proc
    if (rst)
    begin
      csr8_oco <= 1'b0 ;
      csr8_mfo <= 1'b0 ;
      csr8_foc <= {11{1'b0}} ; 
      csr8_mfc <= {16{1'b0}} ; 
    end
    else
    begin
      if (!(csrrw & csrreq & csraddr72 == CSR8_ID))
      begin
        if (!csr8read)
        begin
          csr8_foc <= foc_c ; 
          csr8_mfc <= mfc_c ; 
          csr8_oco <= oco ; 
          csr8_mfo <= mfo ; 
        end 
      end 
    end  
  end

  always @(posedge clk)
  begin : csr8read_reg_proc
    if (rst)
    begin
      csr8read <= 1'b0 ; 
    end
    else
    begin
      if (csrrw & csrreq & csraddr72 == CSR8_ID)
      begin
        csr8read <= csrdbe_c[3] ;
      end
      else
      begin
        csr8read <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : csr9_reg_proc
    if (rst)
    begin
      csr9_mdi <= CSR9_RV[19] ; 
      csr9_mii <= CSR9_RV[18] ; 
      csr9_mdo <= CSR9_RV[17] ; 
      csr9_mdc <= CSR9_RV[16] ; 
      csr9_sdi <= CSR9_RV[2] ; 
      csr9_sclk <= CSR9_RV[1] ; 
      csr9_scs <= CSR9_RV[0] ; 
      csr9_sdo <= CSR9_RV[3] ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR9_ID)
      begin
        if (csrdbe_c[0])
        begin
          csr9_sclk <= csrdata_c[1] ; 
          csr9_scs <= csrdata_c[0] ; 
          csr9_sdo <= csrdata_c[3] ; 
        end 
        if (csrdbe_c[2])
        begin
          csr9_mii <= csrdata_c[18] ; 
          csr9_mdo <= csrdata_c[17] ; 
          csr9_mdc <= csrdata_c[16] ; 
        end 
      end 
      csr9_mdi <= mdi ; 
      csr9_sdi <= sdi ; 
    end  
  end

  always @(posedge clk)
  begin : csr11_reg_proc
    if (rst)
    begin
      csr11_cs <= CSR11_RV[31] ; 
      csr11_tt <= CSR11_RV[30:27] ; 
      csr11_ntp <= CSR11_RV[26:24] ; 
      csr11_rt <= CSR11_RV[23:20] ; 
      csr11_nrp <= CSR11_RV[19:17] ; 
      csr11_con <= CSR11_RV[16] ; 
      csr11_tim <= CSR11_RV[15:0] ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR11_ID)
      begin
        if (csrdbe_c[3])
        begin
          csr11_cs <= csrdata_c[31] ; 
          csr11_tt <= csrdata_c[30:27] ; 
          csr11_ntp <= csrdata_c[26:24] ; 
        end 
        if (csrdbe_c[2])
        begin
          csr11_rt <= csrdata_c[23:20] ; 
          csr11_nrp <= csrdata_c[19:17] ; 
          csr11_con <= csrdata_c[16] ; 
        end 
        if (csrdbe_c[1])
        begin
          csr11_tim[15:8] <= csrdata_c[15:8] ; 
        end 
        if (csrdbe_c[0])
        begin
          csr11_tim[7:0] <= csrdata_c[7:0] ; 
        end 
      end 
    end  
  end

  always @(posedge clk)
  begin : csr11wr_reg_proc
    if (rst)
    begin
      csr11wr <= 1'b0 ; 
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR11_ID)
      begin
        csr11wr <= 1'b1 ; 
      end
      else
      begin
        csr11wr <= 1'b0 ; 
      end 
    end  
  end

  assign csr0 = {CSR0_RV[31:26], CSR0_RV[25:21], csr0_dbo, csr0_tap,
                 CSR0_RV[16:14], csr0_pbl, csr0_ble,
                 csr0_dsl, csr0_bar, (rst | csr0_swr)} ; 

  assign csr5 = {CSR5_RV[31:23], csr5_ts, csr5_rs, csr5_nis,
                 csr5_ais, csr5_eri, CSR5_RV[13:12], csr5_gte, csr5_eti,
                 CSR5_RV[9], csr5_rps, csr5_ru, csr5_ri, csr5_unf,
                 CSR5_RV[4:3], csr5_tu, csr5_tps, csr5_ti} ; 

  assign csr6 = {CSR6_RV[31], csr6_ra, CSR6_RV[29:26],
                 CSR6_RV[25:23], csr6_ttm, csr6_sf, CSR6_RV[20],
                 CSR6_RV[19], CSR6_RV[18], CSR6_RV[17], CSR6_RV[16],
                 csr6_tr, csr6_st, CSR6_RV[13], CSR6_RV[12:11],
                 csr6_fd, CSR6_RV[8], csr6_pm, csr6_pr, CSR6_RV[5],
                 csr6_if, csr6_pb, csr6_ho, csr6_sr, csr6_hp} ; 

  assign csr7 = {CSR7_RV[31:17], csr7_nie, csr7_aie, csr7_ere,
                 CSR7_RV[13:12], csr7_gte, csr7_ete, CSR6_RV[9],
                 csr7_rse, csr7_rue, csr7_rie, csr7_une,
                 CSR7_RV[4:3], csr7_tue, csr7_tse, csr7_tie} ; 

  assign csr8 = {CSR8_RV[31:29], csr8_oco, csr8_foc,
                 csr8_mfo, csr8_mfc} ; 

  assign csr9 = {CSR9_RV[31:20], csr9_mdi, csr9_mii, csr9_mdo,
                 csr9_mdc, CSR9_RV[15:4], csr9_sdo, csr9_sdi,
                 csr9_sclk, csr9_scs} ; 

  assign csr11 = {csr11_cs, ttcnt[7:4], tcnt[2:0], rtcnt[3:0],
                  rcnt[2:0], csr11_con, gcnt} ; 

  always @(csr0 or
           csr3 or
           csr4 or
           csr5 or
           csr6 or
           csr7 or
           csr8 or
           csr9 or 
           csr11 or
           csraddr or 
           csraddr72 or
           csraddr10)
  begin : csrmux_proc
    case (CSRWIDTH)
      8 :
        begin
          case (csraddr10)
            2'b00 :
              begin
                case (csraddr72)
                  CSR0_ID :
                    begin
                      csrdatao <= csr0[7:0] ; 
                    end
                  CSR3_ID :
                    begin
                      csrdatao <= csr3[7:0] ; 
                    end
                  CSR4_ID :
                    begin
                      csrdatao <= csr4[7:0] ; 
                    end
                  CSR5_ID :
                    begin
                      csrdatao <= csr5[7:0] ; 
                    end
                  CSR6_ID :
                    begin
                      csrdatao <= csr6[7:0] ; 
                    end
                  CSR7_ID :
                    begin
                      csrdatao <= csr7[7:0] ; 
                    end
                  CSR8_ID :
                    begin
                      csrdatao <= csr8[7:0] ; 
                    end
                  CSR9_ID :
                    begin
                      csrdatao <= csr9[7:0] ; 
                    end
                  CSR11_ID :
                    begin
                      csrdatao <= csr11[7:0] ; 
                    end
                  default :
                    begin
                      csrdatao <= {CSRWIDTH{1'b0}} ; 
                    end
                endcase 
              end
            2'b01 :
              begin
                case (csraddr72)
                  CSR0_ID :
                    begin
                      csrdatao <= csr0[15:8] ; 
                    end
                  CSR3_ID :
                    begin
                      csrdatao <= csr3[15:8] ; 
                    end
                  CSR4_ID :
                    begin
                      csrdatao <= csr4[15:8] ; 
                    end
                  CSR5_ID :
                    begin
                      csrdatao <= csr5[15:8] ; 
                    end
                  CSR6_ID :
                    begin
                      csrdatao <= csr6[15:8] ; 
                    end
                  CSR7_ID :
                    begin
                      csrdatao <= csr7[15:8] ; 
                    end
                  CSR8_ID :
                    begin
                      csrdatao <= csr8[15:8] ; 
                    end
                  CSR9_ID :
                    begin
                      csrdatao <= csr9[15:8] ; 
                    end
                  CSR11_ID :
                    begin
                      csrdatao <= csr11[15:8] ; 
                    end
                  default :
                    begin
                      csrdatao <= {CSRWIDTH{1'b0}} ; 
                    end
                endcase 
              end
            2'b10 :
              begin
                case (csraddr72)
                  CSR0_ID :
                    begin
                      csrdatao <= csr0[23:16] ; 
                    end
                  CSR3_ID :
                    begin
                      csrdatao <= csr3[23:16] ; 
                    end
                  CSR4_ID :
                    begin
                      csrdatao <= csr4[23:16] ; 
                    end
                  CSR5_ID :
                    begin
                      csrdatao <= csr5[23:16] ; 
                    end
                  CSR6_ID :
                    begin
                      csrdatao <= csr6[23:16] ; 
                    end
                  CSR7_ID :
                    begin
                      csrdatao <= csr7[23:16] ; 
                    end
                  CSR8_ID :
                    begin
                      csrdatao <= csr8[23:16] ; 
                    end
                  CSR9_ID :
                    begin
                      csrdatao <= csr9[23:16] ; 
                    end
                  CSR11_ID :
                    begin
                      csrdatao <= csr11[23:16] ; 
                    end
                  default :
                    begin
                      csrdatao <= {CSRWIDTH{1'b0}} ; 
                    end
                endcase 
              end
            2'b11 :
              begin
                case (csraddr72)
                  CSR0_ID :
                    begin
                      csrdatao <= csr0[31:24] ; 
                    end
                  CSR3_ID :
                    begin
                      csrdatao <= csr3[31:24] ; 
                    end
                  CSR4_ID :
                    begin
                      csrdatao <= csr4[31:24] ; 
                    end
                  CSR5_ID :
                    begin
                      csrdatao <= csr5[31:24] ; 
                    end
                  CSR6_ID :
                    begin
                      csrdatao <= csr6[31:24] ; 
                    end
                  CSR7_ID :
                    begin
                      csrdatao <= csr7[31:24] ; 
                    end
                  CSR8_ID :
                    begin
                      csrdatao <= csr8[31:24] ; 
                    end
                  CSR9_ID :
                    begin
                      csrdatao <= csr9[31:24] ; 
                    end
                  CSR11_ID :
                    begin
                      csrdatao <= csr11[31:24] ; 
                    end
                  default :
                    begin
                      csrdatao <= {CSRWIDTH{1'b0}} ; 
                    end
                endcase 
              end
            default :
              begin
                csrdatao <= {CSRWIDTH{1'b0}} ; 
              end
          endcase 
        end
      16 :
        begin
          case (csraddr[1])
            1'b0 :
              begin
                case (csraddr72)
                  CSR0_ID :
                    begin
                      csrdatao <= csr0[15:0] ; 
                    end
                  CSR3_ID :
                    begin
                      csrdatao <= csr3[15:0] ; 
                    end
                  CSR4_ID :
                    begin
                      csrdatao <= csr4[15:0] ; 
                    end
                  CSR5_ID :
                    begin
                      csrdatao <= csr5[15:0] ; 
                    end
                  CSR6_ID :
                    begin
                      csrdatao <= csr6[15:0] ; 
                    end
                  CSR7_ID :
                    begin
                      csrdatao <= csr7[15:0] ; 
                    end
                  CSR8_ID :
                    begin
                      csrdatao <= csr8[15:0] ; 
                    end
                  CSR9_ID :
                    begin
                      csrdatao <= csr9[15:0] ; 
                    end
                  CSR11_ID :
                    begin
                      csrdatao <= csr11[15:0] ; 
                    end
                  default :
                    begin
                      csrdatao <= {CSRWIDTH{1'b0}} ; 
                    end
                endcase 
              end
            1'b1 :
              begin
                case (csraddr72)
                  CSR0_ID :
                    begin
                      csrdatao <= csr0[31:16] ; 
                    end
                  CSR3_ID :
                    begin
                      csrdatao <= csr3[31:16] ; 
                    end
                  CSR4_ID :
                    begin
                      csrdatao <= csr4[31:16] ; 
                    end
                  CSR5_ID :
                    begin
                      csrdatao <= csr5[31:16] ; 
                    end
                  CSR6_ID :
                    begin
                      csrdatao <= csr6[31:16] ; 
                    end
                  CSR7_ID :
                    begin
                      csrdatao <= csr7[31:16] ; 
                    end
                  CSR8_ID :
                    begin
                      csrdatao <= csr8[31:16] ; 
                    end
                  CSR9_ID :
                    begin
                      csrdatao <= csr9[31:16] ; 
                    end
                  CSR11_ID :
                    begin
                      csrdatao <= csr11[31:16] ; 
                    end
                  default :
                    begin
                      csrdatao <= {CSRWIDTH{1'b0}} ; 
                    end
                endcase 
              end
            default :
              begin
                csrdatao <= {CSRWIDTH{1'b0}} ; 
              end
          endcase
        end
      default :
        begin
          case (csraddr72)
            CSR0_ID :
              begin
                csrdatao <= csr0 ; 
              end
            CSR3_ID :
              begin
                csrdatao <= csr3 ; 
              end
            CSR4_ID :
              begin
                csrdatao <= csr4 ; 
              end
            CSR5_ID :
              begin
                csrdatao <= csr5 ; 
              end
            CSR6_ID :
              begin
                csrdatao <= csr6 ; 
              end
            CSR7_ID :
              begin
                csrdatao <= csr7 ; 
              end
            CSR8_ID :
              begin
                csrdatao <= csr8 ; 
              end
            CSR9_ID :
              begin
                csrdatao <= csr9 ; 
              end
            CSR11_ID :
              begin
                csrdatao <= csr11 ; 
              end
            default :
              begin
                csrdatao <= {CSRWIDTH{1'b0}} ; 
              end
          endcase 
        end
    endcase 
  end

  assign csrack = 1'b1 ; 

  assign dma_priority = (csr0_bar & !tprog) ? 2'b01 :
                    (csr0_bar & tprog)  ? 2'b10 :
                                          2'b00 ;
 
  assign dbo = csr0_dbo ; 

  assign pbl = csr0_pbl ; 

  assign dsl = csr0_dsl ; 

  assign ble = csr0_ble ; 

  assign tdbad = csr4[DATADEPTH - 1:0] ; 

  always @(posedge clk)
  begin : itpoll_reg_proc
    if (rst)
    begin
      itpoll <= 1'b0 ; 
    end
    else
    begin
      if (((((csr0_tap == 3'b001 |
              csr0_tap == 3'b010 |
              csr0_tap == 3'b011) & tcs2048) |
            ((csr0_tap == 3'b100 |
              csr0_tap == 3'b101 |
              csr0_tap == 3'b110 |
              csr0_tap == 3'b111) & tcs128)) &
           tapcnt == 3'b000 & tpsm == PSM_SUSPEND) |
          tpollcmd | tstartcmd)
      begin
        itpoll <= 1'b1 ; 
      end
      else if (tpollack)
      begin
        itpoll <= 1'b0 ; 
      end 
    end  
  end

  assign tpoll = itpoll ; 

  always @(posedge clk)
  begin : tap_reg_proc
    if (rst)
    begin
      tapcnt <= {3{1'b1}} ; 
    end
    else
    begin
      if (((csr0_tap == 3'b001 |
            csr0_tap == 3'b010 |
            csr0_tap == 3'b011) & (tcs2048 | tapwr)) |
          ((csr0_tap == 3'b100 |
            csr0_tap == 3'b101 |
            csr0_tap == 3'b110 |
            csr0_tap == 3'b111) & (tcs128 | tapwr)))
      begin
        if (tapcnt == 3'b000 | tapwr)
        begin
          case (csr0_tap)
            3'b001 :
              begin
                tapcnt <= 3'b000 ; 
              end
            3'b010 :
              begin
                tapcnt <= 3'b010 ; 
              end
            3'b011 :
              begin
                tapcnt <= 3'b110 ; 
              end
            3'b100 :
              begin
                tapcnt <= 3'b000 ; 
              end
            3'b101 :
              begin
                tapcnt <= 3'b001 ; 
              end
            3'b110 :
              begin
                tapcnt <= 3'b010 ; 
              end
            default :
              begin
                tapcnt <= 3'b111 ; 
              end
          endcase 
        end
        else
        begin
          tapcnt <= tapcnt - 1 ; 
        end 
      end 
    end  
  end

  assign tm = {csr6_ttm, csr6_tr} ; 

  assign sf = csr6_sf ; 

  always @(posedge clk)
  begin : tim_reg_proc
    if (rst)
    begin
      timprog <= 1'b0 ;
      timex   <= 1'b0 ;
      ttcnt   <= {8{1'b1}} ;
      tcnt    <= {3{1'b1}} ;
    end
    else
    begin
      if (csr5_ti)
      begin
        timprog <= 1'b0 ; 
      end
      else if (tireq_r & !tireq_r2)
      begin
        timprog <= 1'b1 ; 
      end
 
      if (csr5_ti)
      begin
        timex <= 1'b0 ; 
      end
      else if (timprog & 
               ((ttcnt == 8'b00000000 & csr11_tt  != 4'b0000) |
                (tcnt  == 3'b000      & csr11_ntp != 3'b000)  |
                (iic) |
                (csr11_tt == 4'b0000  & csr11_ntp == 3'b000)))
      begin
        timex <= 1'b1 ; 
      end 

      if ((tireq_r & !tireq_r2) | csr5_ti | csr11wr)
      begin
        ttcnt <= {csr11_tt, 4'b0000} ; 
      end
      else if (((tcs128 & csr11_cs) |
                (tcs2048 & !csr11_cs)) &
               ttcnt != 8'b00000000 & timprog)
      begin
        ttcnt <= ttcnt - 1 ; 
      end 

      if (csr5_ti | csr11wr)
      begin
        tcnt <= csr11_ntp ; 
      end
      else if (tireq_r & !tireq_r2 &
               tcnt != 3'b000 & csr11_ntp != 3'b000)
      begin
        tcnt <= tcnt - 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : tcscnt_reg_proc
    if (rst)
    begin
      tcsreq_r1 <= 1'b0 ; 
      tcsreq_r2 <= 1'b0 ;
      tcs2048   <= 1'b0 ;
      tcs128    <= 1'b0 ;
      tcscnt    <= {4{1'b1}} ;
    end
    else
    begin
      tcsreq_r1 <= tcsreq ; 
      tcsreq_r2 <= tcsreq_r1 ; 

      if (tcs128)
      begin
        if (tcscnt == 4'b0000)
        begin
          tcscnt <= 4'b1111 ; 
        end
        else
        begin
          tcscnt <= tcscnt - 1 ; 
        end 
      end 

      if (tcsreq_r1 & !tcsreq_r2)
        begin
        tcs128 <= 1'b1 ;
        end
      else
        begin
        tcs128 <= 1'b0 ;
        end

      if (tcscnt == 4'b0000 & tcs128)
      begin
        tcs2048 <= 1'b1 ; 
      end
      else
      begin
        tcs2048 <= 1'b0 ; 
      end 

    end  
  end

  assign tcsack = tcsreq_r2 ; 

  always @(posedge clk)
  begin : st_reg_proc
    if (rst)
    begin
      tstopcmd <= 1'b1 ; 
      tstartcmd <= 1'b0 ; 
    end
    else
    begin
      if (tstartcmd)
      begin
        tstopcmd <= 1'b0 ; 
      end
      else if (!csrrw & csrreq & !(csrdata_c[13]) &
               csraddr72 == CSR6_ID & (csrdbe_c[1]))
      begin
        tstopcmd <= 1'b1 ; 
      end

      if (tpsm == PSM_RUN | tpsm == PSM_SUSPEND)
      begin
        tstartcmd <= 1'b0 ; 
      end
      else if (!csrrw & csrreq & (csrdata_c[13]) &
               csraddr72 == CSR6_ID & (csrdbe_c[1]))
      begin
        tstartcmd <= 1'b1 ; 
      end 
 
    end  
  end

  assign ts_c = (tpsm == PSM_STOP)    ? 3'b000 :
                (tpsm == PSM_SUSPEND) ? 3'b110 :
                (tstat)               ? 3'b111 :
                (tdes)                ? 3'b001 :
                (tset)                ? 3'b101 :
                (tbuf)                ? 3'b011 :
                (tprog)               ? 3'b010 :
                                       csr5_ts ; 

  always @(posedge clk)
  begin : tpsack_reg_proc
    if (rst)
    begin
      stoptc_r <= 1'b0 ; 
      stoptlsm_r <= 1'b0 ; 
      stoptfifo_r <= 1'b0 ; 
    end
    else
    begin
      stoptc_r <= stoptc ; 
      stoptlsm_r <= stoptlsm ; 
      stoptfifo_r <= stoptfifo ; 
    end  
  end

  always @(tpsm or
           tstartcmd or
           tstopcmd or
           tu_r or
           stoptc_r or 
           stoptlsm_r or
           stoptfifo_r)
  begin : tpsm_proc
    case (tpsm)
      PSM_STOP :
        begin
          if (tstartcmd & !stoptc_r & !stoptlsm_r & !stoptfifo_r)
          begin
            tpsm_c <= PSM_RUN ; 
          end
          else
          begin
            tpsm_c <= PSM_STOP ; 
          end 
        end
      PSM_SUSPEND :
        begin
          if (tstopcmd & stoptc_r & stoptlsm_r & stoptfifo_r)
          begin
            tpsm_c <= PSM_STOP ; 
          end
          else if (!tu_r)
          begin
            tpsm_c <= PSM_RUN ; 
          end
          else
          begin
            tpsm_c <= PSM_SUSPEND ; 
          end 
        end
      default :
        begin
          if (tstopcmd & stoptc_r & stoptlsm_r & stoptfifo_r)
          begin
            tpsm_c <= PSM_STOP ; 
          end
          else if (tu_r)
          begin
            tpsm_c <= PSM_SUSPEND ; 
          end
          else
          begin
            tpsm_c <= PSM_RUN ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : tpsm_reg_proc
    if (rst)
    begin
      tpsm <= PSM_STOP ; 
    end
    else
    begin
      tpsm <= tpsm_c ; 
    end  
  end

  always @(posedge clk)
  begin : tps_reg_proc
    if (rst)
    begin
      tps <= 1'b0 ; 
    end
    else
    begin
      if (tstartcmd)
      begin
        tps <= 1'b0 ; 
      end
      else if (tpsm == PSM_STOP)
      begin
        tps <= 1'b1 ; 
      end 
    end  
  end

  assign stopt = tstopcmd ; 

  assign ren = csr6_sr ; 

  assign fd = csr6_fd ; 

  assign ra = csr6_ra ; 

  assign pm = csr6_pm ; 

  assign pr = csr6_pr ; 

  assign rif = csr6_if ; 

  assign pb = csr6_pb ; 

  assign ho = csr6_ho ; 

  assign hp = csr6_hp ; 

  always @(posedge clk)
  begin : rpoll_reg_proc
    if (rst)
    begin
      rpoll <= 1'b0 ; 
    end
    else
    begin
      if (rpollcmd | rstartcmd)
      begin
        rpoll <= 1'b1 ; 
      end
      else if (rpollack)
      begin
        rpoll <= 1'b0 ; 
      end 
    end  
  end

  assign rs_c = (rpsm == PSM_STOP)    ? 3'b000 :
                (rpsm == PSM_SUSPEND) ? 3'b100 :
                (rstat)               ? 3'b101 :
                (rdes)                ? 3'b001 :
                (rbuf)                ? 3'b111 :
                (rprog)               ? 3'b010 :
                                        3'b011 ; 

  always @(posedge clk)
  begin : rpsack_reg_proc
    if (rst)
    begin
      stoprc_r <= 1'b0 ; 
      stoprlsm_r <= 1'b0 ; 
    end
    else
    begin
      stoprc_r <= stoprc ; 
      stoprlsm_r <= stoprlsm ; 
    end  
  end

  always @(rpsm or
           rstartcmd or
           rstopcmd or
           rui or
           ru_r or
           stoprc_r or
           stoprlsm_r)
  begin : rpsm_proc
    case (rpsm)
      PSM_STOP :
        begin
          if (rstartcmd & !stoprc_r & !stoprlsm_r)
          begin
            rpsm_c <= PSM_RUN ; 
          end
          else
          begin
            rpsm_c <= PSM_STOP ; 
          end 
        end
      PSM_SUSPEND :
        begin
          if (rstopcmd & stoprc_r & stoprlsm_r)
          begin
            rpsm_c <= PSM_STOP ; 
          end
          else if (!ru_r)
          begin
            rpsm_c <= PSM_RUN ; 
          end
          else
          begin
            rpsm_c <= PSM_SUSPEND ; 
          end 
        end
      default :
        begin
          if (rstopcmd & stoprc_r & stoprlsm_r)
          begin
            rpsm_c <= PSM_STOP ; 
          end
          else if (rui)
          begin
            rpsm_c <= PSM_SUSPEND ; 
          end
          else
          begin
            rpsm_c <= PSM_RUN ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : rpsm_reg_proc
    if (rst)
    begin
      rpsm <= PSM_STOP ; 
    end
    else
    begin
      rpsm <= rpsm_c ; 
    end  
  end

  always @(posedge clk)
  begin : rps_reg_proc
    if (rst)
    begin
      rps <= 1'b0 ; 
    end
    else
    begin
      if (rstartcmd)
      begin
        rps <= 1'b0 ; 
      end 
      else if (rpsm == PSM_STOP)
      begin
        rps <= 1'b1 ; 
      end
    end  
  end

  always @(posedge clk)
  begin : rstartcmd_reg_proc
    if (rst)
    begin
      rstartcmd <= 1'b0 ; 
      rstopcmd <= 1'b0 ; 
    end
    else
    begin
      if (rpsm == PSM_RUN)
      begin
        rstartcmd <= 1'b0 ; 
      end
      else if (!csrrw & csrreq & (csrdata_c[1]) &
               csraddr72 == CSR6_ID & (csrdbe_c[0]))
      begin
        rstartcmd <= 1'b1 ; 
      end 

      if (rpsm == PSM_STOP)
      begin
        rstopcmd <= 1'b0 ; 
      end
      else if (!csrrw & csrreq & !(csrdata_c[1]) &
               csraddr72 == CSR6_ID & (csrdbe_c[0]))
      begin
        rstopcmd <= 1'b1 ; 
      end 
    end  
  end

  assign stopr = rstopcmd ; 

  always @(posedge clk)
  begin : rim_reg_proc
    if (rst)
    begin
      rimex   <= 1'b0 ; 
      rimprog <= 1'b0 ; 
      rtcnt   <= {4{1'b1}} ; 
      rcnt    <= {3{1'b1}} ; 
    end
    else
    begin
      if (csr5_ri)
      begin
        rimex <= 1'b0 ; 
      end
      else if (rimprog &
               ((rtcnt    == 4'b0000 & csr11_rt  != 4'b0000) |
                (rcnt     == 3'b000  & csr11_nrp != 3'b000) |
                (csr11_rt == 4'b0000 & csr11_nrp == 3'b000)))
      begin
        rimex <= 1'b1 ; 
      end 

      if (csr5_ri)
      begin
        rimprog <= 1'b0 ; 
      end
      else if (rireq_r & !rireq_r2)
      begin
        rimprog <= 1'b1 ; 
      end 

      if ((rireq_r & !rireq_r2) | csr5_ri)
      begin
        rtcnt <= csr11_rt ; 
      end
      else if (((rcs128 & csr11_cs) |
                (rcs2048 & !csr11_cs)) &
               rtcnt != 4'b0000 & rimprog)
      begin
        rtcnt <= rtcnt - 1 ; 
      end 

      if (csr5_ri | csr11wr)
      begin
        rcnt <= csr11_nrp ; 
      end
      else if (rireq_r & !rireq_r2 &
               rcnt != 3'b000 & csr11_nrp != 3'b000)
      begin
        rcnt <= rcnt - 1 ; 
      end 

    end  
  end

  always @(posedge clk)
  begin : rcscnt_reg_proc
    if (rst)
    begin
      rcsreq_r  <= 1'b0 ; 
      rcsreq_r1 <= 1'b0 ; 
      rcscnt    <= {4{1'b1}} ; 
      rcs128    <= 1'b0 ; 
      rcs2048   <= 1'b0 ; 
    end
    else
    begin

      rcsreq_r  <= rcsreq ; 
      rcsreq_r1 <= rcsreq_r ; 

      if (rcs128)
      begin
        if (rcscnt == 4'b0000)
        begin
          rcscnt <= 4'b1111 ; 
        end
        else
        begin
          rcscnt <= rcscnt - 1 ; 
        end 
      end 

      if (rcsreq_r & !rcsreq_r1)
      begin
        rcs128 <= 1'b1 ; 
      end
      else
      begin
        rcs128 <= 1'b0 ; 
      end 

      if (rcscnt == 4'b0000 & rcs128)
      begin
        rcs2048 <= 1'b1 ; 
      end
      else
      begin
        rcs2048 <= 1'b0 ; 
      end 
    end  
  end

  assign rcsack = rcsreq_r ; 

  always @(posedge clk)
  begin : ireq_reg_proc
    if (rst)
    begin
      rireq_r <= 1'b0 ; 
      rireq_r2 <= 1'b0 ; 
      erireq_r <= 1'b0 ; 
      erireq_r2 <= 1'b0 ; 
      tireq_r <= 1'b0 ; 
      tireq_r2 <= 1'b0 ; 
      etireq_r <= 1'b0 ; 
      etireq_r2 <= 1'b0 ; 
      unf_r <= 1'b0 ; 
      unf_r2 <= 1'b0 ; 
      tu_r <= 1'b0 ; 
      tu_r2 <= 1'b0 ; 
      ru_r <= 1'b0 ; 
      ru_r2 <= 1'b0 ; 
    end
    else
    begin
      rireq_r <= rireq ; 
      rireq_r2 <= rireq_r ; 
      erireq_r <= erireq ; 
      erireq_r2 <= erireq_r ; 
      tireq_r <= tireq ; 
      tireq_r2 <= tireq_r ; 
      etireq_r <= etireq ; 
      etireq_r2 <= etireq_r ; 
      unf_r <= unf ; 
      unf_r2 <= unf_r ; 
      tu_r <= tu ; 
      tu_r2 <= tu_r ; 
      ru_r <= ru ; 
      ru_r2 <= ru_r ; 
    end  
  end

  always @(posedge clk)
  begin : iic_reg_proc
    if (rst)
    begin
      iic <= 1'b0 ; 
    end
    else
    begin
      if (tireq_r & !tireq_r2)
      begin
        if (!ic & !iint)
        begin
          iic <= 1'b0 ; 
        end
        else
        begin
          iic <= 1'b1 ; 
        end 
      end 
    end  
  end

  always @(posedge clk)
  begin : eti_reg_proc
    if (rst)
    begin
      eti <= 1'b0 ; 
    end
    else
    begin
      if (etireq_r & !etireq_r2)
      begin
        eti <= 1'b1 ; 
      end
      else if (!csr5wr_c)
      begin
        eti <= 1'b0 ; 
      end 
    end  
  end

  assign etiack = etireq_r2 ; 

  always @(posedge clk)
  begin : eri_reg_proc
    if (rst)
    begin
      eri <= 1'b0 ; 
    end
    else
    begin
      if (erireq_r & !erireq_r2)
      begin
        eri <= 1'b1 ; 
      end
      else if (!csr5wr_c)
      begin
        eri <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : unfi_reg_proc
    if (rst)
    begin
      unfi <= 1'b0 ; 
    end
    else
    begin
      if (unf_r & !unf_r2)
      begin
        unfi <= 1'b1 ; 
      end
      else if (!csr5wr_c)
      begin
        unfi <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : tui_reg_proc
    if (rst)
    begin
      tui <= 1'b0 ; 
    end
    else
    begin
      if (tu_r & !tu_r2)
      begin
        tui <= 1'b1 ; 
      end
      else if (!csr5wr_c)
      begin
        tui <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : rui_reg_proc
    if (rst)
    begin
      rui <= 1'b0 ; 
    end
    else
    begin
      if (ru_r & !ru_r2)
      begin
        rui <= 1'b1 ; 
      end
      else if (!csr5wr_c)
      begin
        rui <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : iint_reg_proc
    if (rst)
    begin
      iint <= 1'b0 ; 
    end
    else
    begin
      iint <= ((csr5_nis && csr7_nie) ||
               (csr5_ais && csr7_aie)) && ~csr5wr;
    end  
  end

  assign interrupt = iint ; 

  assign riack = rireq_r2 ; 

  assign eriack = erireq_r2 ; 

  assign tiack = tireq_r2 ; 

  always @(focg_r)
  begin : foc_proc
    reg [10:0] foc_v;

    foc_v[10] = focg_r[10] ; 
    begin : foc_loop
      integer i;
      for(i = 9; i >= 0; i = i - 1)
      begin
        foc_v[i] = foc_v[i + 1] ^ focg_r[i] ; 
      end
    end 
    foc_c = foc_v;
  end

  always @(mfcg_r)
  begin : mfc_proc
    reg [15:0] mfc_v;

    mfc_v[15] = mfcg_r[10] ; 
    begin : mfc_loop
      integer i;
      for(i = 14; i >= 0; i = i - 1)
      begin
        mfc_v[i] = mfc_v[i + 1] ^ mfcg_r[i] ; 
      end      
    end 
    mfc_c = mfc_v;
  end

  always @(posedge clk)
  begin : sc_reg_proc
    if (rst)
    begin
      focl <= 1'b0 ; 
      mfcl <= 1'b0 ;
      focg_r <= {11{1'b0}} ;
      mfcg_r <= {16{1'b0}} ;
    end
    else
    begin
      if (csr8read)
      begin
        focl <= 1'b1 ; 
      end
      else if (foclack)
      begin
        focl <= 1'b0 ; 
      end 

      if (csr8read)
      begin
        mfcl <= 1'b1 ; 
      end
      else if (mfclack)
      begin
        mfcl <= 1'b0 ; 
      end

      mfcg_r <= mfcg ;
        
      focg_r <= focg ;
 
    end  
  end

  assign mdo = csr9_mdo ; 

  assign mden = csr9_mii ; 

  assign mdc = csr9_mdc ; 

  assign sclk = csr9_sclk ; 

  assign scs = csr9_scs ; 

  assign sdo = csr9_sdo ; 

  always @(posedge clk)
  begin : gpt_reg_proc
    if (rst)
    begin
      gstart   <= 1'b0 ; 
      gstart_r <= 1'b0 ; 
      gcnt     <= {16{1'b0}} ; 
      gte      <= 1'b0 ; 
    end
    else
    begin
      if (!csrrw & csrreq & (csrdbe_c[3]) & csraddr72 == CSR11_ID)
      begin
        gstart <= 1'b1 ; 
      end
      else if ((!csr11_con & gte) |
               csr11_tim == 16'b0000000000000000)
      begin
        gstart <= 1'b0 ; 
      end

      if(csr11_tim != 16'b0000000000000000)
      begin
        gstart_r <= gstart ; 
      end 
      else
      begin 
        gstart_r <= 1'b0 ; 
      end

      if (gstart & !gstart_r)
      begin
        gcnt <= csr11_tim ; 
      end
      else if (gcnt == 16'b0000000000000000)
      begin
        if (csr11_con)
        begin
          gcnt <= csr11_tim ; 
        end 
      end
      else if (tcs2048)
      begin
        gcnt <= gcnt - 1 ; 
      end 

      if (csr5wr_c)
      begin
        gte <= 1'b0 ; 
      end
      else if (gstart_r & gcnt == 16'b0000000000000000 &
               csr11_tim != 16'b0000000000000000)
            begin
        gte <= 1'b1 ; 
      end 

    end  
  end

  always @(posedge clk)
  begin : rstsofto_reg_proc
      rstsofto <= csr0_swr;
  end

  assign czero_max = {CSRWIDTH_MAX{1'b0}} ; 

  assign csrdatai_max = {czero_max[CSRWIDTH_MAX+1:CSRWIDTH],
                         csrdatai}; 

  assign csrbe_max = {czero_max[CSRWIDTH_MAX/8+1:CSRWIDTH/8],
                      csrbe}; 

endmodule



module DMA_V (
  clk,
  rst,
  dma_priority,
  ble,
  dbo,
  rdes,
  rbuf,
  rstat,
  tdes,
  tbuf,
  tstat,
  dataack,
  datai,
  datareq,
  datareqc,
  datarw,
  dataeob,
  dataeobc,
  datao,
  dataaddr,
  idataaddr,
  req1,
  write1,
  tcnt1,
  addr1,
  datai1,
  ack1,
  eob1,
  datao1,
  req2,
  write2,
  tcnt2,
  addr2,
  datai2,
  ack2,
  eob2,
  datao2);

  parameter DATAWIDTH = 32;
  parameter DATADEPTH  = 32;

  `include "utility.v"

  input     clk;
  input     rst; 

  input     [1:0] dma_priority;
  input     ble;
  input     dbo;
  input     rdes;
  input     rbuf;
  input     rstat;
  input     tdes;
  input     tbuf;
  input     tstat;
 

  input     dataack;
  input     [DATAWIDTH - 1:0] datai; 
  output    datareq; 
  wire      datareq;
  output    datareqc; 
  wire      datareqc;
  output    datarw; 
  reg       datarw;
  output    dataeob; 
  wire      dataeob;
  output    dataeobc; 
  wire      dataeobc;
  output    [DATAWIDTH - 1:0] datao; 
  wire      [DATAWIDTH - 1:0] datao;
  output    [DATADEPTH - 1:0] dataaddr; 
  wire      [DATADEPTH - 1:0] dataaddr;
  output    [DATADEPTH - 1:0] idataaddr; 
  wire      [DATADEPTH - 1:0] idataaddr;

  input     req1; 
  input     write1; 
  input     [FIFODEPTH_MAX - 1:0] tcnt1; 
  input     [DATADEPTH - 1:0] addr1; 
  input     [DATAWIDTH - 1:0] datai1; 
  output    ack1; 
  wire      ack1;
  output    eob1; 
  wire      eob1;
  output    [DATAWIDTH - 1:0] datao1; 
  wire      [DATAWIDTH - 1:0] datao1;

  input     req2;
  input     write2; 
  input     [FIFODEPTH_MAX - 1:0] tcnt2; 
  input     [DATADEPTH - 1:0] addr2; 
  input     [DATAWIDTH - 1:0] datai2; 
  output    ack2; 
  wire      ack2;
  output    eob2; 
  wire      eob2;
  output    [DATAWIDTH - 1:0] datao2; 
  wire      [DATAWIDTH - 1:0] datao2;


  reg       [1:0] dsm_c; 
  reg       [1:0] dsm; 
  reg       hist1; 
  reg       hist2; 
  wire      [1:0] dmareq; 
  reg       [FIFODEPTH_MAX - 1:0] msmbcnt; 
  reg       idatareq; 
  reg       idatareqc; 
  reg       eob; 
  reg       eobc; 
  reg       [DATADEPTH - 1:0] addr_c; 
  reg       [DATADEPTH - 1:0] addr; 
  reg       blesel_c;
  reg       [DATAWIDTH - 1:0] dataible_c;
  reg       [DATAWIDTH - 1:0] dataoble_c;
  wire      [DATAWIDTH_MAX + 1:0] datai_max; 
  reg       req_c; 
  reg       write_c; 
  reg       [FIFODEPTH_MAX - 1:0] tcnt_c; 
  reg       [DATADEPTH - 1:0] saddr_c; 
  reg       [DATAWIDTH_MAX - 1:0] datai_c; 
  wire      [DATAWIDTH_MAX + 1:0] datai_max_c;
  wire      [FIFODEPTH_MAX - 1:0] fzero; 
  wire      [DATAWIDTH_MAX + 1:0] dzero; 

  assign dmareq = {req2, req1} ; 

  always @(dsm or
           dmareq or
           hist1 or
           hist2 or
           dma_priority or
           eob or
           dataack)
  begin : dsm_proc
    case (dsm)
      DSM_IDLE :
        begin
          case (dmareq)
            2'b11 :
              begin
                case (dma_priority)
                  2'b01 :
                    begin
                      if (!hist1 & !hist2)
                      begin
                        dsm_c <= DSM_CH2 ; 
                      end
                      else
                      begin
                        dsm_c <= DSM_CH1 ; 
                      end 
                    end
                  2'b10 :
                    begin
                      if (hist1 & hist2)
                      begin
                        dsm_c <= DSM_CH1 ; 
                      end
                      else
                      begin
                        dsm_c <= DSM_CH2 ; 
                      end 
                    end
                  default :
                    begin
                      if (hist1)
                      begin
                        dsm_c <= DSM_CH1 ; 
                      end
                      else
                      begin
                        dsm_c <= DSM_CH2 ; 
                      end 
                    end
                endcase 
              end
            2'b01 :
              begin
                dsm_c <= DSM_CH1 ; 
              end
            2'b10 :
              begin
                dsm_c <= DSM_CH2 ; 
              end
            default :
              begin
                dsm_c <= DSM_IDLE ; 
              end
          endcase 
        end
      DSM_CH1 :
        begin
          if (eob & dataack)
          begin
            dsm_c <= DSM_IDLE ; 
          end
          else
          begin
            dsm_c <= DSM_CH1 ; 
          end 
        end
      default :
        begin
          if (eob & dataack)
          begin
            dsm_c <= DSM_IDLE ; 
          end
          else
          begin
            dsm_c <= DSM_CH2 ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : dsm_reg_proc
    if (rst)
    begin
      dsm <= DSM_IDLE ; 
    end
    else
    begin
      dsm <= dsm_c ; 
    end  
  end

  always @(posedge clk)
  begin : hist_reg_proc
    if (rst)
    begin
      hist1 <= 1'b1 ; 
      hist2 <= 1'b1 ; 
    end
    else
    begin
      if (eob)
      begin
        case (dsm)
          DSM_CH1 :
            begin
              hist1 <= 1'b1 ;
            end
          DSM_CH2 :
            begin 
              hist1 <= 1'b0 ;
            end
          default :
            begin 
              hist1 <= hist1 ;
            end
        endcase
      end 
      hist2 <= hist1 ; 
    end  
  end

  always @(dbo or
           ble or
           dsm_c or
           dsm or
           tdes or
           tbuf or
           tstat or
           rdes or
           rbuf or
           rstat)
  begin : blesel_proc
    if (dsm_c == DSM_CH1 | dsm == DSM_CH1)
    begin
      if ((tbuf & ble) |
          ((tdes | tstat) & dbo))
      begin
        blesel_c <= 1'b1 ;
      end
      else
      begin
        blesel_c <= 1'b0 ;
      end
    end
    else
    begin
      if ((rbuf & ble) |
          ((rdes | rstat) & dbo))
      begin
        blesel_c <= 1'b1 ;
      end
      else
      begin
        blesel_c <= 1'b0 ;
      end
    end
  end

  always @(dsm_c or
           dsm or
           req1 or
           write1 or
           tcnt1 or
           addr1 or
           datai1 or 
           req2 or
           write2 or
           tcnt2 or
           addr2 or
           datai2)
  begin : chmux_proc
    if (dsm_c == DSM_CH1 | dsm == DSM_CH1)
    begin
      req_c <= req1 ; 
      write_c <= write1 ; 
      tcnt_c <= tcnt1 ; 
      saddr_c <= addr1 ; 
      datai_c <= {{((DATAWIDTH_MAX+1)-DATAWIDTH){1'b0}},datai1} ; 
    end
    else
    begin
      req_c <= req2 ; 
      write_c <= write2 ; 
      tcnt_c <= tcnt2 ; 
      saddr_c <= addr2 ; 
      datai_c <= {{((DATAWIDTH_MAX+1)-DATAWIDTH){1'b0}},datai2} ; 
    end 
  end

  assign datai_max_c = {dzero[DATAWIDTH_MAX+1:DATAWIDTH],datai_c}; 

  always @(datai_max_c or blesel_c)
  begin : dataoble_proc
    case (DATAWIDTH)
      32 :
        begin
          if (blesel_c)
          begin
            dataoble_c <= {datai_max_c[ 7: 0],
                           datai_max_c[15: 8],
                           datai_max_c[23:16],
                           datai_max_c[31:24]};
          end
          else
          begin
            dataoble_c <= datai_max_c[31:0];
          end
        end
      16 :
        begin
          if (blesel_c)
          begin
            dataoble_c <= {datai_max_c[7 :0],
                           datai_max_c[15:8]};
          end
          else
          begin
            dataoble_c <= datai_max_c[15:0];
          end
        end
      default :
        begin
        dataoble_c <= datai_max_c[7:0];
        end
    endcase
  end

  assign datai_max = {dzero[DATAWIDTH_MAX+1:DATAWIDTH],datai}; 

  always @(datai_max or blesel_c)
  begin : dataible_proc
    case (DATAWIDTH)
      32 :
        begin
          if (blesel_c)
          begin
            dataible_c <= {datai_max[ 7: 0],
                           datai_max[15: 8],
                           datai_max[23:16],
                           datai_max[31:24]};
          end
          else
          begin
            dataible_c <= datai_max[31:0];
          end
        end
      16 :
        begin
          if (blesel_c)
          begin
            dataible_c <= {datai_max[7 :0],
                           datai_max[15:8]};
          end
          else
          begin
            dataible_c <= datai_max[15:0];
          end
        end
      default :
        begin
        dataible_c <= datai_max[7:0];
        end
    endcase
  end

  always @(posedge clk)
  begin : msmbcnt_reg_proc
    if (rst)
    begin
      msmbcnt <= {FIFODEPTH_MAX{1'b0}} ; 
    end
    else
    begin
      if (!idatareq)
      begin
        msmbcnt <= tcnt_c ; 
      end
      else if (dataack & idatareq)
      begin
        msmbcnt <= msmbcnt - 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : datarw_reg_proc
    if (rst)
    begin
      datarw <= 1'b1 ;
    end
    else
    begin
      if (req_c)
      begin
        datarw <= ~write_c ; 
      end
    end
  end

  always @(posedge clk)
  begin : idatareq_reg_proc
    if (rst)
    begin
      idatareq <= 1'b0 ; 
    end
    else
    begin
      if (eob & dataack & idatareq)
      begin
        idatareq <= 1'b0 ; 
      end
      else if (req1 | req2)
      begin
        idatareq <= 1'b1 ; 
      end 
    end  
  end

  assign datareq = idatareq ; 

  always @(idatareq or
           dataack or
           req1 or
           req2 or
           eob
          )
  begin : idatareqc_comb_proc
    if (eob & dataack & idatareq)
    begin
      idatareqc <= 1'b0 ; 
    end
    else if (req1 | req2)
    begin
      idatareqc <= 1'b1 ; 
    end 
    else
    begin
      idatareqc <= idatareq ; 
    end 
  end

  assign datareqc = idatareqc ; 

  assign dataeob = eob ; 

  assign dataeobc = eobc ; 

  assign datao1 = dataible_c ; 

  assign datao2 = dataible_c ; 

  assign datao = dataoble_c ; 

  always @(dataack or
           idatareq or
           addr or
           saddr_c or
           req_c or
           dsm)
  begin : addr_proc
    if (dataack & idatareq)
    begin
      case (DATAWIDTH)
        8 :
          begin
            addr_c <= addr + 1 ; 
          end
        16 :
          begin
            addr_c <= {addr[DATADEPTH - 1:1] + 1, 1'b0} ; 
          end
        default :
          begin
            addr_c <= {addr[DATADEPTH - 1:2] + 1, 2'b00} ; 
          end
      endcase 
    end
    else if (req_c & dsm == DSM_IDLE)
    begin
      addr_c <= saddr_c ; 
    end
    else
    begin
      addr_c <= addr ; 
    end 
  end

  always @(posedge clk)
  begin : addr_reg_proc
    if (rst)
    begin
      addr <= {DATADEPTH{1'b1}} ; 
    end
    else
    begin
      addr <= addr_c ; 
    end  
  end

  assign dataaddr = addr ; 

  assign idataaddr = addr ; 

  assign ack1 = (dataack & dsm == DSM_CH1) ? 1'b1 : 1'b0 ; 

  assign ack2 = (dataack & dsm == DSM_CH2) ? 1'b1 : 1'b0 ; 

  always @(posedge clk)
  begin : eob_reg_proc
    if (rst)
    begin
      eob <= 1'b0 ;
    end
    else if (req_c | idatareq)
    begin
      if ((idatareq &
           (msmbcnt  ==  fzero |
            msmbcnt  == {fzero[FIFODEPTH_MAX-1:1], 1'b1} |
            (msmbcnt == {fzero[FIFODEPTH_MAX-1:2], 2'b10} & dataack)))
          |
          (!idatareq &
           (tcnt_c ==  fzero |
            tcnt_c == {fzero[FIFODEPTH_MAX-1:1], 1'b1})))
      begin
        eob <= 1'b1 ;
      end
      else
      begin
        eob <= 1'b0 ;
      end
    end
  end
  
  always @(req_c or
           idatareq or
           msmbcnt or
           dataack or
           tcnt_c or
           fzero or
           eob)
  begin : eob_comb_proc
    if (req_c | idatareq)
    begin
      if ((idatareq &
           (msmbcnt  ==  fzero |
            msmbcnt  == {fzero[FIFODEPTH_MAX-1:1], 1'b1} |
            (msmbcnt == {fzero[FIFODEPTH_MAX-1:2], 2'b10} & dataack)))
          |
          (!idatareq &
           (tcnt_c ==  fzero |
            tcnt_c == {fzero[FIFODEPTH_MAX-1:1], 1'b1})))
      begin
        eobc <= 1'b1 ;
      end
      else
      begin
        eobc <= 1'b0 ;
      end
    end
    else
    begin
      eobc <= eob;
    end
  end
  
  assign eob1 = eob ; 

  assign eob2 = eob ; 

  assign fzero = {FIFODEPTH_MAX{1'b0}} ; 

  assign dzero = {(DATAWIDTH_MAX+1){1'b0}} ; 

endmodule


module MAC_V (
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
  input     [CSRDEPTH - 1:0] csraddr;
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

  DMA_V #(DATAWIDTH, DATADEPTH) U_DMA(
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

  TLSM_V #(DATAWIDTH, DATADEPTH, TFIFODEPTH) U_TLSM(
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
 
  TFIFO_V #(DATAWIDTH, DATADEPTH, TFIFODEPTH, TCDEPTH) U_TFIFO(
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

  TC_V #(TFIFODEPTH, DATAWIDTH) U_TC(
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

  BD_V U_BD(
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



  RC_V #(RFIFODEPTH, DATAWIDTH) U_RC(
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
   .rcsreq        (rcsreq)
   ); 

  RFIFO_V #(DATAWIDTH, DATADEPTH, RFIFODEPTH, RCDEPTH) U_RFIFO(
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

  RLSM_V #(DATAWIDTH, DATADEPTH, RFIFODEPTH) U_RLSM(
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
   .stopo         (stoprlsm)
   ); 

  CSR_V #(CSRWIDTH, DATAWIDTH, DATADEPTH, RFIFODEPTH, RCDEPTH) U_CSR(
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
   .mden          (mden)
   ); 
 
  RSTC_V U_RSTC (
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





module MAC2AHB_V (
  mhclk,
  mhresetn,
  mhrdata,
  mhready,
  mhresp,
  mhaddr,
  mhtrans,
  mhwrite,
  mhsize,
  mhburst,
  mhprot,
  mhwdata,
  mhgrantmac,
  mhbusreqmac,
  mhlockmac,
  shclk,
  shresetn,
  shselmac,
  shaddr,
  shwrite,
  shreadyi,
  shtrans,
  shsize,
  shburst,
  shwdata,
  shreadyo,
  shresp,
  shrdata,
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

  parameter MAHBDATAWIDTH     = 32;
  parameter MAHBADDRESSWIDTH  = 32;
    
  parameter SAHBDATAWIDTH     = 32;
  parameter SAHBADDRESSWIDTH  = 32;
    
  parameter MACDATAWIDTH      = 32;
  parameter MACADDRESSWIDTH   = 32;
    
  parameter CSRDATAWIDTH      = 32;
  parameter CSRADDRESSWIDTH   = 32;

  `include "mac2ahb_package.v"

  input     mhclk; 
  input     mhresetn; 
  input     [MAHBDATAWIDTH - 1:0] mhrdata; 
  input     mhready; 
  input     [1:0] mhresp; 
  output    [MAHBADDRESSWIDTH - 1:0] mhaddr; 
  wire      [MAHBADDRESSWIDTH - 1:0] mhaddr;
  output    [1:0] mhtrans; 
  wire      [1:0] mhtrans;
  output    mhwrite; 
  wire      mhwrite;
  output    [2:0] mhsize; 
  wire      [2:0] mhsize;
  output    [2:0] mhburst; 
  wire      [2:0] mhburst;
  output    [3:0] mhprot; 
  wire      [3:0] mhprot;
  output    [MAHBDATAWIDTH - 1:0] mhwdata; 
  wire      [MAHBDATAWIDTH - 1:0] mhwdata;

  input     mhgrantmac; 
  output    mhbusreqmac; 
  wire      mhbusreqmac;
  output    mhlockmac; 
  wire      mhlockmac;

  input     shclk; 
  input     shresetn; 
  input     shselmac; 
  input     [SAHBADDRESSWIDTH - 1:0] shaddr; 
  input     shwrite; 
  input     shreadyi; 
  input     [1:0] shtrans; 
  input     [2:0] shsize; 
  input     [2:0] shburst; 
  input     [SAHBDATAWIDTH - 1:0] shwdata; 
  output    shreadyo; 
  wire      shreadyo;
  output    [1:0] shresp; 
  wire      [1:0] shresp;
  output    [SAHBDATAWIDTH - 1:0] shrdata; 
  wire      [SAHBDATAWIDTH - 1:0] shrdata;
    
    
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


  MACDATA2AHB_V
  #(MAHBDATAWIDTH, MAHBADDRESSWIDTH, MACDATAWIDTH, MACADDRESSWIDTH)
  U_MACDATA2AHB (
  .mhclk          (mhclk),
  .mhresetn       (mhresetn),
  .mhrdata        (mhrdata),
  .mhready        (mhready),
  .mhresp         (mhresp),
  .mhaddr         (mhaddr),
  .mhtrans        (mhtrans),
  .mhwrite        (mhwrite),
  .mhsize         (mhsize),
  .mhburst        (mhburst),
  .mhprot         (mhprot),
  .mhwdata        (mhwdata),
  .mhgrantmac     (mhgrantmac),
  .mhbusreqmac    (mhbusreqmac),
  .mhlockmac      (mhlockmac),
  .datareq        (datareq),
  .datareqc       (datareqc),
  .datarw         (datarw),
  .dataeob        (dataeob),
  .dataeobc       (dataeobc),
  .dataaddr       (dataaddr),
  .datao          (datao),
  .dataack        (dataack),
  .datai          (datai)
  ); 

  MACCSR2AHB_V
  #(SAHBDATAWIDTH, SAHBADDRESSWIDTH, CSRDATAWIDTH, CSRADDRESSWIDTH)
  U_MACCSR2AHB(
  .shclk          (shclk),
  .shresetn       (shresetn),
  .shselmac       (shselmac),
  .shaddr         (shaddr),
  .shwrite        (shwrite),
  .shreadyi       (shreadyi),
  .shtrans        (shtrans),
  .shsize         (shsize),
  .shburst        (shburst),
  .shwdata        (shwdata),
  .shreadyo       (shreadyo),
  .shresp         (shresp),
  .shrdata        (shrdata),
  .rstcsr         (rstcsr),
  .csrack         (csrack),
  .csrdatao       (csrdatao),
  .csrreq         (csrreq),
  .csrrw          (csrrw),
  .csrbe          (csrbe),
  .csrdatai       (csrdatai),
  .csraddr        (csraddr)
  ); 

endmodule




module MAC_AHB_V (
  clkt,
  clkr,
  rsttco,
  rstrco,
  interrupt,
  tps,
  rps,
  mhclk,
  mhresetn,
  mhrdata,
  mhready,
  mhresp,
  mhaddr,
  mhtrans,
  mhwrite,
  mhsize,
  mhburst,
  mhprot,
  mhwdata,
  mhgrantmac,
  mhbusreqmac,
  mhlockmac,
  shclk,
  shresetn,
  shselmac,
  shaddr,
  shwrite,
  shreadyi,
  shtrans,
  shsize,
  shburst,
  shwdata,
  shreadyo,
  shresp,
  shrdata,
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

  parameter MAHBDATAWIDTH     = 32;
  parameter MAHBADDRESSWIDTH  = 32;
  parameter TFIFODEPTH        = 9;
  parameter RFIFODEPTH        = 9;
  parameter TCDEPTH           = 1;
  parameter RCDEPTH           = 2;

  `include "utility.v"

  parameter SAHBDATAWIDTH    = 32; 
  parameter SAHBADDRESSWIDTH = CSRDEPTH; 

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
  input     [MAHBDATAWIDTH - 1:0] mhrdata; 
  input     mhready; 
  input     [1:0] mhresp; 
  output    [MAHBADDRESSWIDTH - 1:0] mhaddr; 
  wire      [MAHBADDRESSWIDTH - 1:0] mhaddr;
  output    [1:0] mhtrans; 
  wire      [1:0] mhtrans;
  output    mhwrite; 
  wire      mhwrite;
  output    [2:0] mhsize; 
  wire      [2:0] mhsize;
  output    [2:0] mhburst; 
  wire      [2:0] mhburst;
  output    [3:0] mhprot; 
  wire      [3:0] mhprot;
  output    [MAHBDATAWIDTH - 1:0] mhwdata; 
  wire      [MAHBDATAWIDTH - 1:0] mhwdata;
  input     mhgrantmac; 
  output    mhbusreqmac; 
  wire      mhbusreqmac;
  output    mhlockmac; 
  wire      mhlockmac;

  input     shclk; 
  input     shresetn; 
  input     shselmac; 
  input     [SAHBADDRESSWIDTH - 1:0] shaddr; 
  input     shwrite; 
  input     [1:0] shtrans; 
  input     [2:0] shsize; 
  input     shreadyi; 
  input     [2:0] shburst; 
  input     [SAHBDATAWIDTH - 1:0] shwdata; 
  output    shreadyo; 
  wire      shreadyo;
  output    [1:0] shresp; 
  wire      [1:0] shresp;
  output    [SAHBDATAWIDTH - 1:0] shrdata; 
  wire      [SAHBDATAWIDTH - 1:0] shrdata;
    
  input     [MAHBDATAWIDTH - 1:0] trdata; 
  output    twe; 
  wire      twe;
  output    [TFIFODEPTH - 1:0] twaddr; 
  wire      [TFIFODEPTH - 1:0] twaddr;
  output    [TFIFODEPTH - 1:0] traddr; 
  wire      [TFIFODEPTH - 1:0] traddr;
  output    [MAHBDATAWIDTH - 1:0] twdata; 
  wire      [MAHBDATAWIDTH - 1:0] twdata;


  input     [MAHBDATAWIDTH - 1:0] rrdata; 
  output    rwe; 
  wire      rwe;
  output    [RFIFODEPTH - 1:0] rwaddr; 
  wire      [RFIFODEPTH - 1:0] rwaddr;
  output    [RFIFODEPTH - 1:0] rraddr; 
  wire      [RFIFODEPTH - 1:0] rraddr;
  output    [MAHBDATAWIDTH - 1:0] rwdata; 
  wire      [MAHBDATAWIDTH - 1:0] rwdata;
    
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
  wire      [(MAHBADDRESSWIDTH - 1):0] dataaddr; 
  wire      [(MAHBDATAWIDTH - 1):0] datao; 
  wire      dataack; 
  wire      [(MAHBDATAWIDTH - 1):0] datai; 

  wire      rstcsr; 
  wire      csrack; 
  wire      [SAHBDATAWIDTH - 1:0] csrdatao; 
  wire      csrreq; 
  wire      csrrw; 
  wire      [SAHBDATAWIDTH / 8 - 1:0] csrbe; 
  wire      [SAHBDATAWIDTH - 1:0] csrdatai; 
  wire      [SAHBADDRESSWIDTH - 1:0] csraddr; 

  MAC_V
  #(SAHBDATAWIDTH,
    MAHBDATAWIDTH,
    MAHBADDRESSWIDTH,
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

  MAC2AHB_V
  #(MAHBDATAWIDTH,
    MAHBADDRESSWIDTH,
    SAHBDATAWIDTH,
    SAHBADDRESSWIDTH,
    MAHBDATAWIDTH,
    MAHBADDRESSWIDTH,
    SAHBDATAWIDTH,
    SAHBADDRESSWIDTH)
  U_MAC2AHB (
  .mhclk             (mhclk),
  .mhresetn          (mhresetn),
  .mhrdata           (mhrdata),
  .mhready           (mhready),
  .mhresp            (mhresp),
  .mhaddr            (mhaddr), 
  .mhtrans           (mhtrans),
  .mhwrite           (mhwrite),
  .mhsize            (mhsize),
  .mhburst           (mhburst),
  .mhprot            (mhprot),
  .mhwdata           (mhwdata),
  .mhgrantmac        (mhgrantmac),
  .mhbusreqmac       (mhbusreqmac),
  .mhlockmac         (mhlockmac),
  .shclk             (shclk),
  .shresetn          (shresetn),
  .shselmac          (shselmac),
  .shaddr            (shaddr),
  .shwrite           (shwrite),
  .shreadyi          (shreadyi),
  .shtrans           (shtrans),
  .shsize            (shsize),
  .shburst           (shburst),
  .shwdata           (shwdata),
  .shreadyo          (shreadyo),
  .shresp            (shresp),
  .shrdata           (shrdata),
  .datareq           (datareq),
  .datareqc          (datareqc),
  .datarw            (datarw),
  .dataeob           (dataeob),
  .dataeobc          (dataeobc),
  .dataaddr          (dataaddr),
  .datao             (datao),
  .dataack           (dataack),
  .datai             (datai),
  .rstcsr            (rstcsr),
  .csrack            (csrack),
  .csrdatao          (csrdatao),
  .csrreq            (csrreq),
  .csrrw             (csrrw),
  .csrbe             (csrbe),
  .csrdatai          (csrdatai),
  .csraddr           (csraddr)
  ); 


endmodule




module MACCSR2AHB_V (
  shclk,
  shresetn,
  shselmac,
  shaddr,
  shwrite,
  shreadyi,
  shtrans,
  shsize,
  shburst,
  shwdata,
  shreadyo,
  shresp,
  shrdata,
  rstcsr,
  csrack,
  csrdatao,
  csrreq,
  csrrw,
  csrbe,
  csrdatai,
  csraddr
  );

  parameter SAHBDATAWIDTH     = 32;
  parameter SAHBADDRESSWIDTH  = 8;
  parameter CSRDATAWIDTH      = 32;
  parameter CSRADDRESSWIDTH   = 8;

  `include "mac2ahb_package.v"

    
  input     shclk; 
  input     shresetn; 
  input     shselmac; 
  input     [SAHBADDRESSWIDTH - 1:0] shaddr; 
  input     shwrite; 
  input     shreadyi; 
  input     [1:0] shtrans; 
  input     [2:0] shsize; 
  input     [2:0] shburst; 
  input     [SAHBDATAWIDTH - 1:0] shwdata; 
  output    shreadyo; 
  wire      shreadyo;
  output    [1:0] shresp; 
  wire      [1:0] shresp;
  output    [SAHBDATAWIDTH - 1:0] shrdata; 
  wire      [SAHBDATAWIDTH - 1:0] shrdata;
    
    
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


  reg       [CSRADDRESSWIDTH - 1:0] i_addrreg_r; 

  reg       i_transfind_r; 

  reg       i_transfdir_r; 

  reg       [CSRDATAWIDTH / 8 - 1:0] i_calcbe; 

  reg       [CSRDATAWIDTH / 8 - 1:0] i_calcbe_r; 

  always @(posedge shclk)
  begin : i_transfind_proc
    if (!shresetn)
    begin
      i_transfind_r <= 1'b0 ; 
    end
    else
    begin
      i_transfind_r <= 1'b0 ; 
      if (shtrans == HTRANS_NONSEQ & shreadyi &
          shburst == HBURST_SINGLE & shselmac)
      begin
        i_transfind_r <= 1'b1 ; 
      end 
    end  
  end 

  always @(posedge shclk)
  begin : i_transfdir_proc
    if (!shresetn)
    begin
      i_transfdir_r <= 1'b1 ; 
    end
    else
    begin
      if (shtrans == HTRANS_NONSEQ & shselmac & shreadyi)
      begin
        if (shwrite)
        begin
          i_transfdir_r <= 1'b0 ; 
        end
        else
        begin
          i_transfdir_r <= 1'b1 ; 
        end 
      end 
    end  
  end 

  always @(posedge shclk)
  begin : i_addrreg_proc
    if (!shresetn)
    begin
      i_addrreg_r <= {CSRADDRESSWIDTH{1'b0}} ; 
    end
    else
    begin
      i_addrreg_r <= i_addrreg_r ; 
      if (shtrans == HTRANS_NONSEQ & shselmac & shreadyi)
      begin
        i_addrreg_r <= shaddr[CSRADDRESSWIDTH - 1:0] ; 
      end 
    end  
  end 

  always @(posedge shclk)
  begin : i_calcbe_reg_proc
    if (!shresetn)
    begin
      i_calcbe_r <= {CSRDATAWIDTH / 8{1'b0}} ; 
    end
    else
    begin
      i_calcbe_r <= i_calcbe ; 
    end  
  end 

  always @(shaddr or shsize)
  begin : i_calcbe_proc
    case (SAHBDATAWIDTH)
      8 :
        begin
          i_calcbe = 1'b1 ; 
        end
      16 :
        begin
          i_calcbe = {CSRDATAWIDTH / 8{1'b1}} ; 
          case (shsize)
            HSIZE_8BIT :
              begin
                if (shaddr[0])
                begin
                  i_calcbe = 2'b10 ;
                end
                else
                begin
                  i_calcbe = 2'b01 ;
                end 
              end
            HSIZE_16BIT :
              begin
                if (!(shaddr[0]))
                begin
                  i_calcbe = 2'b11 ; 
                end
                else
                begin
                  i_calcbe = 2'b00 ; 
                end 
              end
            default :
              begin
              end
          endcase 
        end
      32 :
        begin
          i_calcbe = {CSRDATAWIDTH / 8{1'b1}} ; 
          case (shsize)
            HSIZE_8BIT :
              begin
                if (shaddr[1:0] == 2'b00)
                begin
                  i_calcbe = 4'b0001 ;
                end
                else if (shaddr[1:0] == 2'b01)
                begin
                  i_calcbe = 4'b0010 ;
                end
                else if (shaddr[1:0] == 2'b10)
                begin
                  i_calcbe = 4'b0100 ;
                end
                else
                begin
                  i_calcbe = 4'b1000 ;
                end 
              end
            HSIZE_16BIT :
              begin
                if (shaddr[1:0] == 2'b00)
                begin
                  i_calcbe = 4'b0011 ;
                end
                else if (shaddr[1:0] == 2'b10)
                begin
                  i_calcbe = 4'b1100 ;
                end
                else
                begin
                  i_calcbe = 4'b0000 ;
                end 
              end
            HSIZE_32BIT :
              begin
                if (shaddr[1:0] == 2'b00)
                begin
                  i_calcbe = 4'b1111 ; 
                end
                else
                begin
                  i_calcbe = 4'b0000 ; 
                end 
              end
            default :
              begin
              end
          endcase 
        end
      default :
        begin
        end
    endcase 
  end 

  assign shresp = HRESP_OKAY ;

  assign csrdatai = shwdata ;

  assign csrbe = i_calcbe_r ;

  assign csraddr = i_addrreg_r ;

  assign csrreq = i_transfind_r ;

  assign csrrw = i_transfdir_r ;

  assign rstcsr = ~shresetn ;

  assign shreadyo = csrack ;

  assign shrdata = csrdatao ;

endmodule


module MACDATA2AHB_V (
  mhclk,   
  mhresetn, 
  mhrdata, 
  mhready, 
  mhresp, 
  mhaddr, 
  mhtrans, 
  mhwrite, 
  mhsize, 
  mhburst, 
  mhprot, 
  mhwdata, 
  mhgrantmac, 
  mhbusreqmac, 
  mhlockmac, 
  datareq, 
  datareqc, 
  datarw, 
  dataeob, 
  dataeobc, 
  dataaddr, 
  datao, 
  dataack, 
  datai
  );

  parameter MAHBDATAWIDTH     = 32;
  parameter MAHBADDRESSWIDTH  = 32;
  parameter MACDATAWIDTH      = 32;
  parameter MACADDRESSWIDTH   = 32;

  `include "mac2ahb_package.v"

    
  input     mhclk; 
  input     mhresetn; 
  input     [MAHBDATAWIDTH - 1:0] mhrdata; 
  input     mhready; 
  input     [1:0] mhresp; 
  output    [MAHBADDRESSWIDTH - 1:0] mhaddr; 
  wire      [MAHBADDRESSWIDTH - 1:0] mhaddr;
  output    [1:0] mhtrans; 
  reg       [1:0] mhtrans;
  output    mhwrite; 
  wire      mhwrite;
  output    [2:0] mhsize; 
  reg       [2:0] mhsize;
  output    [2:0] mhburst; 
  reg       [2:0] mhburst;
  output    [3:0] mhprot; 
  wire      [3:0] mhprot;
  output    [MAHBDATAWIDTH - 1:0] mhwdata; 
  wire      [MAHBDATAWIDTH - 1:0] mhwdata;

  input     mhgrantmac; 
  output    mhbusreqmac; 
  wire      mhbusreqmac;
  output    mhlockmac; 
  wire      mhlockmac;

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



  wire      [MAHBDATAWIDTH - 1:0] ahb_hrdata; 
  wire      ahb_hready; 
  reg[1:0]  ahb_hresp; 
  wire      [MAHBADDRESSWIDTH - 1:0] ahb_haddr; 
  wire      [1:0] ahb_htrans; 
  wire      ahb_hwrite; 
  wire      [2:0] ahb_hsize; 
  wire      [0:0] ahb_hburst; 
  wire      [3:0] ahb_hprot; 
  wire      [MAHBDATAWIDTH - 1:0] ahb_hwdata; 
  wire      ahb_hgrantmac; 
  reg       ahb_hbusreqmac; 
  wire      ahb_hlockmac; 
  wire      mac_datareqc; 
  wire      mac_datareq; 
  wire      mac_datarw; 
  wire      mac_dataeobc; 
  wire      mac_dataeobcc; 
  wire      [MACADDRESSWIDTH - 1:0] mac_dataaddr; 
  wire      [MACDATAWIDTH - 1:0] mac_datao; 
  wire      mac_dataack; 
  wire      [MACDATAWIDTH - 1:0] mac_datai; 
  reg       [1:0] fsm_macdata2ahb_nxt; 
  reg       [1:0] fsm_macdata2ahb_r; 
  reg       [MACADDRESSWIDTH - 1:0] i_ahb_haddr; 
  reg       [MACADDRESSWIDTH - 1:0] i_ahb_haddr_c; 
  reg       i_ahb_hgrant_r; 
  wire      i_hbusreq_c; 
  reg       i_mac_dataeobc_r; 
  reg       i_datareqc_r; 
  wire      i_hwritem_c; 
  reg       i_hwritem; 
  wire      [1:0] i_htransm_c; 
  reg       [1:0] i_htransm; 
  wire      i_dataack_c; 
  wire      i_1kc; 

  assign ahb_hwdata = mac_datao ;
  
  assign mac_datai = ahb_hrdata ;

  always @(i_ahb_haddr or 
           fsm_macdata2ahb_r or 
           ahb_hready or 
           mac_dataaddr or 
           i_ahb_hgrant_r or 
           i_mac_dataeobc_r or 
           i_datareqc_r or
           dataaddr)
  begin : i_ahb_haddr_proc
    case (fsm_macdata2ahb_r)
      AHBM_ADDR :
        begin
          if (ahb_hready == 1'b1 & i_mac_dataeobc_r == 1'b0)
          begin
            i_ahb_haddr_c = i_ahb_haddr + 3'b100 ; 
          end
          else
          begin
            i_ahb_haddr_c = i_ahb_haddr ; 
          end 
        end
      AHBM_ADDRDATA :
        begin
          if (ahb_hready == 1'b1 & i_mac_dataeobc_r == 1'b0)
          begin
            i_ahb_haddr_c = i_ahb_haddr + 3'b100 ; 
          end
          else
          begin
            i_ahb_haddr_c = i_ahb_haddr ; 
          end 
        end
      AHBM_IDLE :
        begin
          if (i_datareqc_r == 1'b1)
          begin
            i_ahb_haddr_c = dataaddr ; 
          end
          else
          begin
            i_ahb_haddr_c = i_ahb_haddr ; 
          end 
        end
      default :
        begin              
          i_ahb_haddr_c = i_ahb_haddr ; 
        end
    endcase 
  end

  always @(posedge mhclk)
  begin : iahbaddrm_reg_proc
    if (mhresetn == 1'b0)
    begin
      i_ahb_haddr <= {MACADDRESSWIDTH - 1+1{1'b1}} ; 
    end
    else
    begin
      i_ahb_haddr <= i_ahb_haddr_c ; 
    end  
  end
  
  assign ahb_haddr = i_ahb_haddr ;
  
  assign i_1kc = (ahb_htrans == SEQ | ahb_htrans == NONSEQ) ? 
                   (i_ahb_haddr[10] ^ i_ahb_haddr_c[10]) : 1'b0 ;
  
  assign i_hbusreq_c = (mac_datareqc == 1'b1 & 
                         (
                           mac_dataeobc == 1'b0 | 
                           fsm_macdata2ahb_nxt == AHBM_IDLE
                         )
                       ) ? 1'b1 : 1'b0 ;
  
  assign ahb_hwrite = i_hwritem ;
  
  assign ahb_htrans = (!ahb_hgrantmac & fsm_macdata2ahb_r == AHBM_ADDR) ?
                       IDLE : i_htransm ;
  
  assign ahb_hlockmac = 1'b0 ;
  
  
  assign i_hwritem_c = (fsm_macdata2ahb_nxt == AHBM_ADDR) ? 
                       ~mac_datarw : i_hwritem ;
  
  
  assign ahb_hburst = INCR ;
  
  assign i_htransm_c = (fsm_macdata2ahb_nxt == AHBM_ADDR)     ? NONSEQ : 
                       (fsm_macdata2ahb_nxt == AHBM_ADDRDATA) ? SEQ    : 
                                                                IDLE ;
  
  assign i_dataack_c = (ahb_hready == 1'b1 & 
                          (
                            ahb_hresp == OKAY | ahb_hresp == ERROR
                          ) & 
                          (
                            fsm_macdata2ahb_r == AHBM_DATA | 
                            fsm_macdata2ahb_r == AHBM_ADDRDATA
                          )
                       ) ? 1'b1 : 1'b0 ;
  
  assign mac_dataack = i_dataack_c ;

  always @(fsm_macdata2ahb_r or 
           ahb_hgrantmac or 
           ahb_hresp or 
           ahb_hready or 
           i_datareqc_r or 
           i_mac_dataeobc_r or 
           mac_dataeobc or 
           mac_datareqc or 
           mac_datareq or 
           i_1kc)
  begin : fsm_macdata2ahb_r_proc
    case (fsm_macdata2ahb_r)
      AHBM_IDLE :
        begin
          if (ahb_hgrantmac == 1'b1 & 
              ahb_hready    == 1'b1 & 
              mac_datareq   == 1'b1)
          begin
            fsm_macdata2ahb_nxt = AHBM_ADDR ; 
          end
          else
          begin
            fsm_macdata2ahb_nxt = AHBM_IDLE ; 
          end 
        end
      AHBM_ADDR :
        begin
          if(!ahb_hgrantmac)
          begin
            fsm_macdata2ahb_nxt = AHBM_IDLE;
          end
          else if (ahb_hready == 1'b1)
          begin
            if (i_mac_dataeobc_r == 1'b1 | 
                ahb_hgrantmac    == 1'b0 | 
                i_1kc            == 1'b1)
            begin
              fsm_macdata2ahb_nxt = AHBM_DATA ; 
            end
            else
            begin
              fsm_macdata2ahb_nxt = AHBM_ADDRDATA ; 
            end 
          end
          else
          begin
            fsm_macdata2ahb_nxt = AHBM_ADDR ; 
          end 
        end
      AHBM_DATA :
        begin
          if (ahb_hready == 1'b1)
          begin
            if (ahb_hgrantmac == 1'b1 & 
                mac_datareqc  == 1'b1 & 
                i_1kc         == 1'b0)
            begin
              fsm_macdata2ahb_nxt = AHBM_ADDR ; 
            end
            else
            begin
              fsm_macdata2ahb_nxt = AHBM_IDLE ; 
            end 
          end
        else
        begin
          if (ahb_hresp == OKAY | ahb_hresp == ERROR)
          begin
            fsm_macdata2ahb_nxt = AHBM_DATA ; 
          end
          else
          begin
            fsm_macdata2ahb_nxt = AHBM_IDLE ; 
          end 
        end 
      end
      default:
        begin
        if (ahb_hready == 1'b1)
          begin
          if (ahb_hgrantmac == 1'b0 | 
              mac_dataeobc  == 1'b1 | 
              i_1kc         == 1'b1)
          begin
            fsm_macdata2ahb_nxt = AHBM_DATA ; 
          end
          else
          begin
            fsm_macdata2ahb_nxt = AHBM_ADDRDATA ; 
          end 
        end
        else
        begin
          if (ahb_hresp == OKAY | ahb_hresp == ERROR)
          begin
            fsm_macdata2ahb_nxt = AHBM_ADDRDATA ; 
          end
          else
          begin
            fsm_macdata2ahb_nxt = AHBM_IDLE ; 
          end 
        end 
      end
    endcase 
  end

  always @(posedge mhclk)
  begin : fsm_macdata2ahb_r_reg_proc
    if (mhresetn == 1'b0)
    begin
      fsm_macdata2ahb_r <= AHBM_IDLE ; 
    end
    else
    begin
      fsm_macdata2ahb_r <= fsm_macdata2ahb_nxt ; 
    end  
  end

  always @(posedge mhclk)
  begin : datactrl_reg_proc
    if (mhresetn == 1'b0)
    begin
      i_datareqc_r     <= 1'b0 ; 
      i_mac_dataeobc_r <= 1'b0 ; 
      i_ahb_hgrant_r   <= 1'b0 ; 
    end
    else
    begin
      i_datareqc_r     <= mac_datareqc ; 
      i_mac_dataeobc_r <= mac_dataeobc ; 
      i_ahb_hgrant_r   <= ahb_hgrantmac ; 
    end  
  end 

  always @(posedge mhclk)
  begin : ahbm_ctrl_reg_proc
    if (mhresetn == 1'b0)
    begin
      ahb_hbusreqmac <= 1'b0 ; 
      i_hwritem      <= 1'b0 ; 
      i_htransm      <= IDLE ; 
    end
    else
    begin
      ahb_hbusreqmac <= i_hbusreq_c ; 
      i_hwritem      <= i_hwritem_c ; 
      i_htransm      <= i_htransm_c ; 
    end  
  end 
  assign ahb_hsize = (MAHBDATAWIDTH == 8)  ? HSIZE8BIT  : 
                     (MAHBDATAWIDTH == 16) ? HSIZE16BIT : 
                     (MAHBDATAWIDTH == 32) ? HSIZE32BIT : 
                     (MAHBDATAWIDTH == 64) ? HSIZE64BIT : 
                     UNSUPPORTED ; 
                     
  assign ahb_hprot = HPROT_MACPROTECTIONCONTROL ;
  
  assign ahb_hrdata = mhrdata ;
  
  assign ahb_hready = mhready ;

  always @(mhresp)
  begin : ahb_hresp_map_proc
    case (mhresp)
      HRESP_ERROR :
        begin
          ahb_hresp = ERROR ; 
        end
      HRESP_RETRY :
        begin
          ahb_hresp = RETRY ; 
        end
      HRESP_SPLIT :
        begin
          ahb_hresp = SPLIT ; 
        end
      default :
        begin
          ahb_hresp = OKAY ; 
        end
    endcase 
  end 
  
  assign mhaddr = ahb_haddr ;

  always @(ahb_htrans)
  begin : ahb_htrans_map_proc
    case (ahb_htrans)
      NONSEQ :
        begin
          mhtrans = HTRANS_NONSEQ ; 
        end
      SEQ :
        begin
          mhtrans = HTRANS_SEQ ; 
        end
      default :
        begin
          mhtrans = HTRANS_IDLE ; 
        end
    endcase 
  end 

  assign mhwrite = ahb_hwrite ;

  always @(ahb_hsize)
  begin : ahb_hsize_map_proc
    case (ahb_hsize)
      HSIZE8BIT :
        begin
          mhsize = HSIZE_8BIT ; 
        end
      HSIZE16BIT :
        begin
          mhsize = HSIZE_16BIT ; 
        end
      default :
        begin
          mhsize = HSIZE_32BIT ; 
        end
    endcase 
  end 

  always @(ahb_hburst)
  begin : ahb_hburst_map_proc
    case (ahb_hburst)
      INCR :
        begin
          mhburst = HBURST_INCR ; 
        end
      default :
        begin
          mhburst = HBURST_SINGLE ; 
        end
    endcase 
  end 
  
  assign mhprot = ahb_hprot ;
  
  assign mhwdata = ahb_hwdata ;
  
  assign ahb_hgrantmac = mhgrantmac ;
  
  assign mhbusreqmac = ahb_hbusreqmac ;
  
  assign mhlockmac = ahb_hlockmac ;
  
  
  assign mac_datareqc = datareqc ;
  
  assign mac_datareq = datareq ;
  
  assign mac_datarw = datarw ;
  
  assign mac_dataeobc = dataeobc ;
  
  assign mac_dataaddr = dataaddr ;
  
  assign mac_datao = datao ;
  
  assign dataack = mac_dataack ;
  
  assign datai = mac_datai ;
  
endmodule


module RC_V (
  clk,
  rst,
  rxdv,
  rxer,
  rxd,
  col,
  ramwe,
  ramaddr,
  ramdata,
  fdata,
  faddr,
  cachenf,
  radg,
  wadg,
  rprog,
  rcpoll,
  riack,
  ren,
  ra,
  pm,
  pr,
  pb,
  rif,
  ho,
  hp,
  rireq,
  ff,
  rf,
  mf,
  db,
  re,
  ce,
  tl,
  ftp,
  ov,
  cs,
  length,
  match,
  matchval,
  matchen,
  matchdata,
  focl,
  foclack,
  oco,
  focg,
  mfcl,
  mfclack,
  mfo,
  mfcg,
  stopi,
  stopo,
  rcsack,
  rcsreq);

  parameter FIFODEPTH  = 9;
  parameter DATAWIDTH = 32;

  `include "utility.v"

  input     clk;
  input     rst;

  input     col; 
  input     rxdv; 
  input     rxer;
  input     [MIIWIDTH - 1:0] rxd;

  output    ramwe;
  wire      ramwe;
  output    [FIFODEPTH - 1:0] ramaddr; 
  wire      [FIFODEPTH - 1:0] ramaddr;
  output    [DATAWIDTH - 1:0] ramdata; 
  wire      [DATAWIDTH - 1:0] ramdata;
 
  input     [ADDRWIDTH - 1:0] fdata; 
  output    [ADDRDEPTH - 1:0] faddr; 
  wire      [ADDRDEPTH - 1:0] faddr;

  input     cachenf;
  input     [FIFODEPTH - 1:0] radg; 
  output    [FIFODEPTH - 1:0] wadg; 
  wire      [FIFODEPTH - 1:0] wadg;
  output    rprog; 
  reg       rprog;
  output    rcpoll;
  wire      rcpoll;

  input     riack;
  input     ren;
  input     ra;
  input     pm; 
  input     pr; 
  input     pb; 
  input     rif; 
  input     ho; 
  input     hp;
  output    rireq; 
  reg       rireq;
  output    ff; 
  reg       ff;
  output    rf; 
  reg       rf;
  output    mf; 
  reg       mf;
  output    db; 
  reg       db;
  output    re; 
  reg       re;
  output    ce; 
  reg       ce;
  output    tl; 
  reg       tl;
  output    ftp; 
  reg       ftp;
  output    cs; 
  reg       cs;
  output    ov; 
  reg       ov;
  output    [13:0] length; 
  reg       [13:0] length;

  input     match;
  input     matchval; 
  output    matchen; 
  reg       matchen;
  output    [47:0] matchdata; 
  wire      [47:0] matchdata;
  
  input     focl;
  output    foclack; 
  wire      foclack;
  output    oco; 
  reg       oco;
  output    [10:0] focg; 
  reg       [10:0] focg;
  input     mfcl;
  output    mfclack;
  output    mfo;
  reg       mfo;
  output    [15:0] mfcg;
  reg       [15:0] mfcg;

  input     stopi;
  output    stopo; 
  reg       stopo;

  input     rcsack;
  output    rcsreq; 
  reg       rcsreq;
  


  reg       we; 
  reg       full; 
  reg       [FIFODEPTH - 1:0] wad; 
  reg       [FIFODEPTH - 1:0] wadi; 
  reg       [FIFODEPTH - 1:0] iwadg; 
  reg       [FIFODEPTH - 1:0] wadig; 
  reg       [FIFODEPTH - 1:0] radg_0_r; 
  reg       [FIFODEPTH - 1:0] radg_r; 
  reg       [FIFODEPTH - 1:0] isofad;
  reg       cachenf_r;
  reg       cachenf_2r;
  reg       fcfbci;
  reg       fcfbci_r;
  reg       eorfff;
 

  reg       col_r;
  reg       rxdv_r; 
  reg       rxer_r; 
  reg       [MIIWIDTH - 1:0] rxd_r; 
  wire      [3:0] rxd_r4; 

  reg       [3:0] rsm_c; 
  reg       [3:0] rsm; 
  reg       [3:0] ncnt; 
  wire      [1:0] ncnt10; 
  wire      [2:0] ncnt20; 
  reg       [DATAWIDTH - 1:0] data_c; 
  reg       [DATAWIDTH - 1:0] data; 
  reg       [31:0] crc_c; 
  reg       [31:0] crc; 
  reg       [6:0] bcnt; 
  wire      [2:0] bcnt20; 
  reg       bz; 
  reg       winp; 
  wire      iri_c; 
  reg       iri; 
  reg       riack_r; 
  reg       [13:0] lcnt; 
  reg       [15:0] lfield; 
  reg       ren_r; 
  reg       irprog; 

  reg       [2:0] fsm_c; 
  reg       [2:0] fsm; 
  reg       perfm_c; 
  reg       perfm; 
  reg       invm; 
  reg       [8:0] crchash; 
  reg       hash; 
  reg       [47:0] dest; 
  reg       [2:0] flcnt; 
  reg       [ADDRDEPTH - 1:0] fa; 
  reg       [15:0] fdata_r; 

  reg       rcs; 
  reg       rcsack_r; 
  reg       [7:0] rcscnt; 

  reg       [10:0] focnt; 
  reg       focl_r; 
  reg       [15:0] mfcnt;
  reg       mfcl_r;

  reg       stop_r; 

  wire      [FIFODEPTH - 1:0] fzero; 
  wire      [MIIWIDTH_MAX + 1:0] mzero_max; 
  wire      [MIIWIDTH_MAX + 1:0] rxd_r_max; 

  always @(posedge clk)
  begin : mii_reg_proc
    if (rst)
    begin
      col_r <= 1'b0;
      rxdv_r <= 1'b0 ; 
      rxer_r <= 1'b0 ; 
      rxd_r <= {MIIWIDTH{1'b0}} ; 
      data <= {DATAWIDTH{1'b1}} ; 
    end
    else
    begin
      col_r <= col ;
      rxdv_r <= rxdv ; 
      rxer_r <= rxer ; 
      rxd_r <= rxd ; 
      data <= data_c ; 
    end  
  end

  assign rxd_r4 = rxd_r_max[MIIWIDTH-1:0]; 

  assign ncnt10 = ncnt[1:0] ; 

  assign ncnt20 = ncnt[2:0] ; 

  always @(ncnt or ncnt10 or ncnt20 or rxd_r_max or data)
  begin : data_proc
    reg[15:0] data16; 
    reg[31:0] data32; 
    case (DATAWIDTH)
      8 :
        begin
          data_c <= data ; 
          if (!(ncnt[0]))
          begin
            data_c[3:0] <= rxd_r_max[MIIWIDTH-1:0] ; 
          end
          else
          begin
            data_c[7:4] <= rxd_r_max[MIIWIDTH-1:0] ; 
          end 
        end
      16 :
        begin
          data16 = data; 
          case (ncnt10)
            2'b00 :
              begin
                data16[3:0] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            2'b01 :
              begin
                data16[7:4] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            2'b10 :
              begin
                data16[11:8] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            default :
              begin
                data16[15:12] = rxd_r_max[MIIWIDTH-1:0]; 
              end
          endcase 
          data_c <= data16 ; 
        end
      default :
        begin
          data32 = data; 
          case (ncnt20)
            3'b000 :
              begin
                data32[3:0] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            3'b001 :
              begin
                data32[7:4] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            3'b010 :
              begin
                data32[11:8] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            3'b011 :
              begin
                data32[15:12] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            3'b100 :
              begin
                data32[19:16] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            3'b101 :
              begin
                data32[23:20] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            3'b110 :
              begin
                data32[27:24] = rxd_r_max[MIIWIDTH-1:0]; 
              end
            default :
              begin
                data32[31:28] = rxd_r_max[MIIWIDTH-1:0]; 
              end
          endcase 
          data_c <= data32 ; 
        end
    endcase 
  end

  always @(posedge clk)
  begin : fifofull_reg_proc
    if (rst)
    begin
      cachenf_r  <= 1'b1 ;
      cachenf_2r <= 1'b1 ;
      full <= 1'b0 ; 
    end
    else
    begin
      cachenf_r <= cachenf ;

      if(cachenf_2r |
          (
            (!rxdv_r & cachenf_r) |
            ( rxdv_r & cachenf_r &
              (rsm==RSM_IDLE_RCSMT | rsm==RSM_SFD)
            )
          )
        )
      begin
        cachenf_2r <= cachenf ;
      end
      
      if ((wadig == radg_r) | (iwadg == radg_r & full))
      begin
        full <= 1'b1 ; 
      end
      else
      begin
        full <= 1'b0 ; 
      end 
    end
  end

  always @(posedge clk)
  begin : addr_reg_proc
    if (rst)
    begin
      wad    <= {FIFODEPTH{1'b0}} ; 
      wadi   <= {fzero[FIFODEPTH - 1:1], 1'b1} ; 
      iwadg  <= {FIFODEPTH{1'b0}} ; 
      isofad <= {FIFODEPTH{1'b0}} ; 
      wadig  <= {fzero[FIFODEPTH - 1:1],1'b1} ; 
      radg_0_r <= {FIFODEPTH{1'b0}} ; 
      radg_r <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      if (rsm == RSM_BAD)
      begin
        wad <= isofad ; 
      end
      else if (we)
      begin
        wad <= wad + 1 ; 
      end 

      if (rsm == RSM_BAD)
      begin
        wadi <= isofad + 1 ; 
      end
      else if (we)
      begin
        wadi <= wadi + 1 ; 
      end 

      iwadg[FIFODEPTH - 1] <= wad[FIFODEPTH - 1] ; 
      begin : iwaddrg_loop
        integer i;
        for(i = FIFODEPTH - 2; i >= 0; i = i - 1)
        begin
          iwadg[i] <= wad[i + 1] ^ wad[i] ; 
        end
      end 

      wadig[FIFODEPTH - 1] <= wadi[FIFODEPTH - 1] ; 
      begin : waddrig_loop
        integer i;
        for(i = FIFODEPTH - 2; i >= 0; i = i - 1)
        begin
          wadig[i] <= wadi[i + 1] ^ wadi[i] ; 
        end
      end 

      if (rsm == RSM_IDLE_RCSMT)
      begin
        isofad <= wad ; 
      end 

      radg_0_r <= radg ; 
      radg_r <= radg_0_r ; 

    end  
  end

  always @(posedge clk)
  begin : we_reg_proc
    if (rst)
    begin
      we <= 1'b0 ; 
    end
    else
    begin
      if ((rsm == RSM_INFO |
           rsm == RSM_DEST |
           rsm == RSM_LENGTH |
           rsm == RSM_SOURCE) &
          ((rxdv_r & ((DATAWIDTH == 8 & (ncnt[0])) |
                      (DATAWIDTH == 16 & ncnt[1:0] == 2'b11) |
                      (DATAWIDTH == 32 & ncnt[2:0] == 3'b111))) |
           (!rxdv_r & !we & 
             (
               (DATAWIDTH==32 & ncnt[2:1]!=2'b00) |
               (DATAWIDTH==16 & ncnt[1]  !=1'b0)
             )
           ) | 
	   (full & !we)))
      begin
        we <= 1'b1 ; 
      end
      else
      begin
        we <= 1'b0 ; 
      end
    end  
  end

  assign ramdata = data ; 

  assign ramwe = we ; 

  assign ramaddr = wad ; 

  assign wadg = iwadg ; 

  always @(rsm or
           rxdv_r or
           rxd_r_max or
           rxd_r4 or
           stop_r or
           bz or
           fsm or
           ra or
           pm or
           pb or
           dest or
           riack_r or
           full or
           ren_r or
           winp or
           irprog or
           cachenf_r)
  begin : rsm_proc
    case (rsm)
      RSM_IDLE_RCSMT :
        begin
          if (rxdv_r & !stop_r & ren_r)
          begin
            if (rxd_r_max[MIIWIDTH-1:0] == 4'b0101)
            begin
              rsm_c <= RSM_SFD ; 
            end
            else
            begin
              rsm_c <= RSM_IDLE_RCSMT ; 
            end 
          end
          else
          begin
            rsm_c <= RSM_IDLE_RCSMT ; 
          end 
        end
      RSM_SFD :
        begin
          if (rxdv_r & !full & cachenf_r)
          begin
            case (rxd_r4)
              4'b1101 :
                begin
                  rsm_c <= RSM_DEST ; 
                end
              4'b0101 :
                begin
                  rsm_c <= RSM_SFD ; 
                end
              default :
                begin
                  rsm_c <= RSM_IDLE_RCSMT ; 
                end
            endcase 
          end
          else if (full | !cachenf_r)
          begin
            rsm_c <= RSM_BAD ; 
          end 
          else
          begin
            rsm_c <= RSM_IDLE_RCSMT ; 
          end 
        end
      RSM_DEST :
        begin
          if (!rxdv_r | full | !cachenf_r)
          begin
            rsm_c <= RSM_BAD ; 
          end
          else if (bz)
          begin
            rsm_c <= RSM_SOURCE ; 
          end
          else
          begin
            rsm_c <= RSM_DEST ; 
          end 
        end
      RSM_SOURCE :
        begin
          if (!rxdv_r)
          begin
            if ((pb) & (fsm == FSM_MATCH | ra | (pm & (dest[0]))))
            begin
              rsm_c <= RSM_SUCC ; 
            end
            else
            begin
              rsm_c <= RSM_BAD ; 
            end 
          end
          else if (full | !cachenf_r)
          begin
            rsm_c <= RSM_BAD ; 
          end
          else if (bz)
          begin
            rsm_c <= RSM_LENGTH ; 
          end
          else
          begin
            rsm_c <= RSM_SOURCE ; 
          end 
        end
      RSM_LENGTH :
        begin
          if (!rxdv_r)
          begin
            if ((pb) & (fsm == FSM_MATCH | ra | (pm & (dest[0]))))
            begin
              rsm_c <= RSM_SUCC ; 
            end
            else
            begin
              rsm_c <= RSM_BAD ; 
            end 
          end
          else if (full | !cachenf_r)
          begin
            rsm_c <= RSM_BAD ; 
          end
          else if (bz)
          begin
            rsm_c <= RSM_INFO ; 
          end
          else
          begin
            rsm_c <= RSM_LENGTH ; 
          end 
        end
      RSM_INFO :
        begin
          if (!rxdv_r)
          begin
            if ((winp | pb) &
                (fsm == FSM_MATCH | ra | (pm & (dest[0]))))
            begin
              rsm_c <= RSM_SUCC ; 
            end
            else
            begin
              rsm_c <= RSM_BAD ; 
            end 
          end
          else if (full | !cachenf_r)
          begin
            if (winp)
            begin
              rsm_c <= RSM_SUCC ; 
            end
            else
            begin
              rsm_c <= RSM_BAD ; 
            end 
          end
          else if (fsm == FSM_FAIL & !ra & ~(pm & (dest[0])))
          begin
            rsm_c <= RSM_BAD ; 
          end
          else
          begin
            rsm_c <= RSM_INFO ; 
          end 
        end
      RSM_SUCC :
        begin
          rsm_c <= RSM_INT ; 
        end
      RSM_INT :
        begin
          if (riack_r)
          begin
            rsm_c <= RSM_INT1 ; 
          end
          else
          begin
            rsm_c <= RSM_INT ; 
          end 
        end
      RSM_INT1 :
        begin
          if (!rxdv_r & !riack_r)
          begin
            rsm_c <= RSM_IDLE_RCSMT ; 
          end
          else
          begin
            rsm_c <= RSM_INT1 ; 
          end 
        end
      default :
        begin
          if (!rxdv_r & !riack_r & !irprog)
          begin
            rsm_c <= RSM_IDLE_RCSMT ; 
          end
          else
          begin
            rsm_c <= RSM_BAD ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : rsm_reg_proc
    if (rst)
    begin
      rsm <= RSM_IDLE_RCSMT ; 
    end
    else
    begin
      rsm <= rsm_c ; 
    end  
  end

  always @(posedge clk)
  begin : rprog_reg_proc
    if (rst)
    begin
      irprog <= 1'b0 ; 
      rprog  <= 1'b0 ;
    end
    else
    begin
      if (rsm == RSM_IDLE_RCSMT |
          rsm == RSM_BAD |
          rsm == RSM_INT |
          rsm == RSM_INT1)
      begin
        irprog <= 1'b0 ; 
      end
      else
      begin
        irprog <= 1'b1 ; 
      end 

      if (winp & irprog)
      begin
        rprog <= 1'b1 ;
      end
      else
      begin
        rprog <= 1'b0 ;
      end
    end  
  end

  assign rcpoll = irprog ;

  always @(posedge clk)
  begin : bncnt_reg_proc
    if (rst)
    begin
      bcnt <= {7{1'b0}} ; 
      bz   <= 1'b0 ; 
      ncnt <= 4'b0000 ; 
    end
    else
    begin
      if(cachenf_r)
      begin
        if (bz | rsm == RSM_IDLE_RCSMT)
        begin
          case (rsm)
            RSM_IDLE_RCSMT :
              begin
                bcnt <= 7'b0000101 ;
              end
            RSM_DEST :
              begin
                bcnt <= 7'b0000101 ;
              end
            RSM_SOURCE :
              begin
                bcnt <= 7'b0000001 ;
              end
            default :
              begin
                bcnt <= 7'b0110001 ;
              end
          endcase 
        end
        else
        begin
          if (ncnt[0])
          begin
            bcnt <= bcnt - 1 ; 
          end 
        end 
      end
      else
      begin
        if(!fcfbci_r)
        begin
          bcnt <= 7'b0111110 ;
        end
        else
        begin
          if (!ncnt[0])
          begin
            bcnt <= bcnt - 1 ; 
          end 
        end 
      end 

      if (bcnt == 7'b0000000 & !ncnt[0])
      begin
        bz <= 1'b1 ; 
      end
      else
      begin
        bz <= 1'b0 ; 
      end 

      if (rsm == RSM_SFD | rsm == RSM_IDLE_RCSMT)
      begin
        ncnt <= 4'b0000 ; 
      end
      else
      begin
        ncnt <= ncnt + 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : winp_reg_proc
    if (rst)
    begin
      winp <= 1'b0 ; 
    end
    else
    begin
      if (rsm == RSM_IDLE_RCSMT)
      begin
        winp <= 1'b0 ; 
      end
      else if ((rsm == RSM_INFO & bz &  cachenf_2r) |
               (rsm == RSM_BAD  & bz & !cachenf_2r))
      begin
        winp <= 1'b1 ; 
      end 
    end  
  end

  always @(crc or rsm or rxd_r_max)
  begin : crc_proc
    case (rsm)
      RSM_IDLE_RCSMT :
        begin
          crc_c <= {32{1'b1}} ; 
        end
      RSM_DEST, RSM_SOURCE, RSM_LENGTH, RSM_INFO :
        begin
          crc_c[0]  <= crc[28] ^ 
                       rxd_r_max[3] ; 
          crc_c[1]  <= crc[28] ^ crc[29] ^
                       rxd_r_max[2] ^ rxd_r_max[3] ; 
          crc_c[2]  <= crc[28] ^ crc[29] ^ crc[30] ^
                       rxd_r_max[1] ^ rxd_r_max[2] ^ rxd_r_max[3] ; 
          crc_c[3]  <= crc[29] ^ crc[30] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[1] ^ rxd_r_max[2] ; 
          crc_c[4]  <= crc[0] ^ crc[28] ^ crc[30] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[1] ^ rxd_r_max[3] ; 
          crc_c[5]  <= crc[1] ^ crc[28] ^ crc[29] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[2] ^ rxd_r_max[3] ; 
          crc_c[6]  <= crc[2] ^ crc[29] ^ crc[30] ^
                       rxd_r_max[1] ^ rxd_r_max[2] ; 
          crc_c[7]  <= crc[3] ^ crc[28] ^ crc[30] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[1] ^ rxd_r_max[3] ; 
          crc_c[8]  <= crc[4] ^ crc[28] ^ crc[29] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[2] ^ rxd_r_max[3] ; 
          crc_c[9]  <= crc[5] ^ crc[29] ^ crc[30] ^
                       rxd_r_max[1] ^ rxd_r_max[2] ; 
          crc_c[10] <= crc[6] ^ crc[28] ^ crc[30] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[1] ^ rxd_r_max[3] ; 
          crc_c[11] <= crc[7] ^ crc[28] ^ crc[29] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[2] ^ rxd_r_max[3] ; 
          crc_c[12] <= crc[8] ^ crc[28] ^ crc[29] ^ crc[30] ^
                       rxd_r_max[1] ^ rxd_r_max[2] ^ rxd_r_max[3] ; 
          crc_c[13] <= crc[9] ^ crc[29] ^ crc[30] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[1] ^ rxd_r_max[2] ; 
          crc_c[14] <= crc[10] ^ crc[30] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[1] ;
          crc_c[15] <= crc[11] ^ crc[31] ^
                       rxd_r_max[0] ; 
          crc_c[16] <= crc[12] ^ crc[28] ^
                       rxd_r_max[3] ; 
          crc_c[17] <= crc[13] ^ crc[29] ^
                       rxd_r_max[2] ; 
          crc_c[18] <= crc[14] ^ crc[30] ^
                       rxd_r_max[1] ; 
          crc_c[19] <= crc[15] ^ crc[31] ^
                       rxd_r_max[0] ; 
          crc_c[20] <= crc[16] ; 
          crc_c[21] <= crc[17] ; 
          crc_c[22] <= crc[18] ^ crc[28] ^
                       rxd_r_max[3] ; 
          crc_c[23] <= crc[19] ^ crc[28] ^ crc[29] ^
                       rxd_r_max[2] ^ rxd_r_max[3] ;
          crc_c[24] <= crc[20] ^ crc[29] ^ crc[30] ^
                       rxd_r_max[1] ^ rxd_r_max[2] ;
          crc_c[25] <= crc[21] ^ crc[30] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[1] ;
          crc_c[26] <= crc[22] ^ crc[28] ^ crc[31] ^
                       rxd_r_max[0] ^ rxd_r_max[3] ;
          crc_c[27] <= crc[23] ^ crc[29] ^
                       rxd_r_max[2] ; 
          crc_c[28] <= crc[24] ^ crc[30] ^
                       rxd_r_max[1] ; 
          crc_c[29] <= crc[25] ^ crc[31] ^
                       rxd_r_max[0] ; 
          crc_c[30] <= crc[26] ; 
          crc_c[31] <= crc[27] ; 
        end
      default :
        begin
          crc_c <= crc ; 
        end
    endcase 
  end

  always @(posedge clk)
  begin : crc_reg_proc
    if (rst)
    begin
      crc <= {32{1'b1}} ; 
    end
    else
    begin
      crc <= crc_c ; 
    end  
  end

  assign iri_c = (rsm == RSM_INT) ? 1'b1 : 1'b0 ; 

  always @(posedge clk)
  begin : rint_reg_proc
    if (rst)
    begin
      iri <= 1'b0 ; 
      riack_r <= 1'b0 ; 
      rireq <= 1'b0 ; 
    end
    else
    begin
      iri <= iri_c ; 
      riack_r <= riack ; 
      rireq <= iri ; 
    end  
  end

  always @(posedge clk)
  begin : length_reg_proc
    if (rst)
    begin
      lcnt <= {14{1'b0}} ; 
      length <= {14{1'b0}} ; 
    end
    else
    begin
      if ((rsm == RSM_IDLE_RCSMT && cachenf_2r) |
          (!fcfbci && !cachenf_2r) |
           rsm == RSM_INT1)
      begin
        lcnt <= {14{1'b0}} ; 
      end
      else if (((rsm == RSM_INFO |
                 rsm == RSM_LENGTH |
                 rsm == RSM_DEST |
                 rsm == RSM_SOURCE) & rxdv_r) |
		(fcfbci && !cachenf_2r)) 
      begin
        if (ncnt[0])
        begin
          lcnt <= lcnt + 1 ; 
        end 
      end 

      length[13] <= lcnt[13] ; 
      begin : length_loop
        integer i;
        for(i = 12; i >= 0; i = i - 1)
        begin
          length[i] <= lcnt[i + 1] ^ lcnt[i] ; 
        end
      end 
    end  
  end

  always @(posedge clk)
  begin : fcfbci_reg_proc
    if (rst)
    begin
      fcfbci   <= 1'b0 ;	    
      fcfbci_r <= 1'b0 ;	    
    end
    else
    begin

      fcfbci_r <= fcfbci ;	    

      if(!cachenf_2r)	    
      begin
        if(rxdv_r && rxd_r4==4'b1101)
        begin
          fcfbci <= 1'b1 ;
	end
	else if(!rxdv_r)
        begin
          fcfbci <= 1'b0 ;
	end
      end
      else
      begin
        fcfbci <= 1'b0 ;
      end
    end
  end
	    
  always @(posedge clk)
  begin : eorfff_reg_proc
    if (rst)
    begin
      eorfff <= 1'b0 ;
    end
    else
    begin
      if(rsm_c==RSM_IDLE_RCSMT && rsm==RSM_BAD && !cachenf_2r)
      begin
        eorfff <= 1'b1 ;
      end
      else
      begin
        eorfff <= 1'b0 ;
      end
    end
  end

  
  always @(posedge clk)
  begin : stat_reg_proc
    if (rst)
    begin
      lfield <= {16{1'b0}} ; 
      ftp <= 1'b0 ; 
      tl <= 1'b0 ; 
      ff <= 1'b0 ; 
      mf <= 1'b0 ; 
      re <= 1'b0 ; 
      ce <= 1'b0 ; 
      db <= 1'b0 ; 
      rf <= 1'b0 ; 
      ov <= 1'b0 ; 
      cs <= 1'b0 ;       
    end
    else
    begin
      if (rsm == RSM_LENGTH)
      begin
        if (bcnt[1:0] == 2'b00)
        begin
          if (!(ncnt[0]))
          begin
            lfield[3:0] <= rxd_r_max[MIIWIDTH-1:0] ; 
          end
          else
          begin
            lfield[7:4] <= rxd_r_max[MIIWIDTH-1:0] ; 
          end 
        end
        else
        begin
          if (!(ncnt[0]))
          begin
            lfield[11:8] <= rxd_r_max[MIIWIDTH-1:0] ; 
          end
          else
          begin
            lfield[15:12] <= rxd_r_max[MIIWIDTH-1:0] ; 
          end 
        end 
      end 

      if (lfield > MAX_SIZE)
      begin
        ftp <= 1'b1 ; 
      end
      else
      begin
        ftp <= 1'b0 ; 
      end 

      if (lcnt == MAX_FRAME & !iri_c)
      begin
        tl <= 1'b1 ; 
      end
      else if (rsm == RSM_IDLE_RCSMT)
      begin
        tl <= 1'b0 ; 
      end 

      if (!iri_c)
      begin
        if (fsm == FSM_MATCH)
        begin
          ff <= 1'b0 ; 
        end
        else
        begin
          ff <= 1'b1 ; 
        end 
      end 

      if (!iri_c)
      begin
        mf <= dest[0] ; 
      end 

      if (rxer_r & !iri_c)
      begin
        re <= 1'b1 ; 
      end
      else if (rsm == RSM_IDLE_RCSMT)
      begin
        re <= 1'b0 ; 
      end 

      if (rsm == RSM_INFO & !(ncnt[0]))
      begin
        if (crc == CRCVAL)
        begin
          ce <= 1'b0 ; 
        end
        else
        begin
          ce <= 1'b1 ; 
        end 
      end 

      if (rsm == RSM_INFO)
      begin
        if (!rxdv_r & (ncnt[0]))
        begin
          db <= 1'b1 ; 
        end
        else
        begin
          db <= 1'b0 ; 
        end 
      end 

      if (!winp & iri_c)
      begin
        rf <= 1'b1 ; 
      end
      else if (rsm == RSM_IDLE_RCSMT)
      begin
        rf <= 1'b0 ; 
      end 

      if (rsm == RSM_IDLE_RCSMT)
      begin
        ov <= 1'b0 ; 
      end
      else if (full | !cachenf_r)
      begin
        ov <= 1'b1 ; 
      end 
      
      if (col_r & !iri_c)
      begin
        cs <= 1'b1 ;
      end
      else if (rsm == RSM_IDLE_RCSMT)
      begin
        cs <= 1'b0 ;
      end
        
      
    end  
  end

  always @(posedge clk)
  begin : ren_reg_proc
    if (rst)
    begin
      ren_r <= 1'b0 ; 
    end
    else
    begin
      if (rsm == RSM_IDLE_RCSMT)
      begin
        ren_r <= ren ; 
      end 
    end  
  end

  always @(fsm or
           rsm or
           ho or
           hp or
           dest or
           lcnt or
           ncnt or
           flcnt or
           perfm or 
           hash or
           pr or
           fa or
           invm or
           rif or 
           matchval or
           match)
  begin : fsm_proc
    case (fsm)
      FSM_IDLE :
        begin
          if (lcnt[2:0] == 3'b101 & (ncnt[0]))
          begin
            if (pr)
            begin
              fsm_c <= FSM_MATCH ; 
            end
            else if (ho | (hp & (dest[0])))
            begin
              fsm_c <= FSM_HASH ; 
            end
            else if (!hp)
            begin
              fsm_c <= FSM_PERF16 ; 
            end
            else
            begin
              fsm_c <= FSM_PERF1 ; 
            end 
          end
          else
          begin
            fsm_c <= FSM_IDLE ; 
          end 
        end
      FSM_PERF1 :
        begin
          if (fa == 6'b101100)
          begin
            if(perfm |
              (matchval & match))
            begin
              fsm_c <= FSM_MATCH ; 
            end
            else
            begin
              fsm_c <= FSM_FAIL ; 
            end
          end
          else
          begin
            fsm_c <= FSM_PERF1 ; 
          end 
        end
      FSM_PERF16 :
        begin
          if ((flcnt == 3'b010 & perfm & !rif) |
              (fa == 6'b110010 & rif & invm) |
              (matchval & match))
          begin
            fsm_c <= FSM_MATCH ; 
          end
          else if (fa == 6'b110010)
          begin
            fsm_c <= FSM_FAIL ; 
          end
          else
          begin
            fsm_c <= FSM_PERF16 ; 
          end 
        end
      FSM_HASH :
        begin
          if (matchval & match)
          begin
            fsm_c <= FSM_MATCH ;
          end
          else if (flcnt == 3'b101)
          begin
            if (hash)
            begin
              fsm_c <= FSM_MATCH ; 
            end
            else
            begin
              fsm_c <= FSM_FAIL ; 
            end 
          end
          else
          begin
            fsm_c <= FSM_HASH ; 
          end 
        end
      FSM_MATCH :
        begin
          if (rsm == RSM_IDLE_RCSMT)
          begin
            fsm_c <= FSM_IDLE ; 
          end
          else
          begin
            fsm_c <= FSM_MATCH ; 
          end 
        end
      default :
        begin
          if (rsm == RSM_IDLE_RCSMT)
          begin
            fsm_c <= FSM_IDLE ; 
          end
          else
          begin
            fsm_c <= FSM_FAIL ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : fsm_reg_proc
    if (rst)
    begin
      fsm <= FSM_IDLE ; 
    end
    else
    begin
      fsm <= fsm_c ; 
    end  
  end

  assign bcnt20 = bcnt[2:0] ; 

  always @(posedge clk)
  begin : dest_reg_proc
    if (rst)
    begin
      dest <= {48{1'b0}} ; 
    end
    else
    begin
      if (rsm == RSM_DEST)
      begin
        if (!(ncnt[0]))
        begin
          case (bcnt20)
            3'b101 :
              begin
                dest[3:0] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            3'b100 :
              begin
                dest[11:8] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            3'b011 :
              begin
                dest[19:16] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            3'b010 :
              begin
                dest[27:24] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            3'b001 :
              begin
                dest[35:32] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            default :
              begin
                dest[43:40] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
          endcase 
        end
        else
        begin
          case (bcnt20)
            3'b101 :
              begin
                dest[7:4] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            3'b100 :
              begin
                dest[15:12] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            3'b011 :
              begin
                dest[23:20] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            3'b010 :
              begin
                dest[31:28] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            3'b001 :
              begin
                dest[39:36] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
            default :
              begin
                dest[47:44] <= rxd_r_max[MIIWIDTH-1:0] ; 
              end
          endcase 
        end 
      end 
    end  
  end

  always @(posedge clk)
  begin : hash_reg_proc
    if (rst)
    begin
      crchash <= {9{1'b0}} ; 
      hash    <= 1'b0 ; 
      fdata_r <= {16{1'b0}} ; 
    end
    else
    begin
      if (fsm == FSM_HASH & flcnt == 3'b000)
      begin
        crchash <= {crc[23], crc[24], crc[25], crc[26],
                    crc[27], crc[28], crc[29], crc[30], crc[31]} ; 
      end

      hash <= fdata_r[crchash[3:0]] ;

      fdata_r <= fdata ; 
    end  
  end

  always @(perfm or flcnt or fsm or fdata_r or dest)
  begin : perfm_proc
    if ((flcnt == 3'b001 & fdata_r != dest[47:32]) |
        (flcnt == 3'b000 & fdata_r != dest[31:16]) |
        (flcnt == 3'b010 & fdata_r != dest[15:0]) | fsm == FSM_IDLE)
    begin
      perfm_c <= 1'b0 ; 
    end
    else if (flcnt == 3'b010 & fdata_r == dest[15:0])
    begin
      perfm_c <= 1'b1 ; 
    end
    else
    begin
      perfm_c <= perfm ; 
    end 
  end

  always @(posedge clk)
  begin : perfm_reg_proc
    if (rst)
    begin
      invm <= 1'b0 ; 
      perfm <= 1'b0 ; 
    end
    else
    begin
      perfm <= perfm_c ; 

      if (fsm == FSM_IDLE)
      begin
        invm <= 1'b1 ; 
      end
      else if (flcnt == 3'b001 & perfm_c)
      begin
        invm <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : fa_reg_proc
    if (rst)
    begin
      flcnt <= {3{1'b0}} ; 
      fa    <= {ADDRDEPTH{1'b0}} ; 
    end
    else
    begin
      case (fsm)
        FSM_PERF1, FSM_PERF16 :
          begin
            fa <= fa + 1 ; 
          end
        FSM_HASH :
          begin
            fa[5:0] <= {1'b0, crchash[8:4]} ; 
          end
        default :
          begin
            if (hp & !(dest[0]))
            begin
              fa <= PERF1_ADDR ; 
            end
            else
            begin
              fa <= {ADDRDEPTH{1'b0}} ; 
            end 
          end
      endcase 

      if (fsm_c == FSM_IDLE |
          (flcnt == 3'b010 & fsm_c == FSM_PERF16) |
          (flcnt == 3'b010 & fsm_c == FSM_PERF1))
      begin
        flcnt <= {3{1'b0}} ; 
      end
      else if (fsm == FSM_PERF1 |
               fsm == FSM_PERF16 |
               fsm == FSM_HASH)
      begin
        flcnt <= flcnt + 1 ; 
      end 
    end  
  end

  assign faddr = fa ; 

  assign matchdata = dest ; 

  always @(posedge clk)
  begin : matchen_reg_proc
    if (rst)
    begin
      matchen <= 1'b0 ; 
    end
    else
    begin
      if (fsm == FSM_PERF1 | fsm == FSM_HASH | fsm == FSM_PERF16)
      begin
        matchen <= 1'b1 ;
      end
      else
      begin
        matchen <= 1'b0 ;
      end
    end  
  end

  always @(posedge clk)
  begin : stop_reg_proc
    if (rst)
    begin
      stop_r <= 1'b0 ; 
      stopo <= 1'b0 ; 
    end
    else
    begin
      stop_r <= stopi ; 

      if (stop_r & rsm == RSM_IDLE_RCSMT)
      begin
        stopo <= 1'b1 ; 
      end
      else
      begin
        stopo <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : rcscnt_reg_proc
    if (rst)
    begin
      rcscnt   <= {8{1'b0}} ; 
      rcs      <= 1'b0 ; 
      rcsreq   <= 1'b0 ; 
      rcsack_r <= 1'b0 ; 
    end
    else
    begin
      if (rcscnt == 8'b00000000)
      begin
        rcscnt <= 8'b10000000 ; 
      end
      else
      begin
        rcscnt <= rcscnt - 1 ; 
      end 

      if (rcscnt == 8'b00000000)
      begin
        rcs <= 1'b1 ; 
      end
      else if (rcsack_r)
      begin
        rcs <= 1'b0 ; 
      end 

      if (rcs & !rcsack_r)
      begin
        rcsreq <= 1'b1 ; 
      end
      else if (rcsack_r)
      begin
        rcsreq <= 1'b0 ; 
      end 

      rcsack_r <= rcsack ; 
    end  
  end

  always @(posedge clk)
  begin : focnt_reg_proc
    if (rst)
    begin
      focnt  <= {11{1'b0}} ; 
      oco    <= 1'b0 ; 
      focl_r <= 1'b0 ; 
      focg   <= {11{1'b0}} ; 
    end
    else
    begin
      if (focl_r)
      begin
        focnt <= {11{1'b0}} ; 
      end
      else if ((rsm == RSM_DEST |
                rsm == RSM_SOURCE |
                rsm == RSM_LENGTH |
                rsm == RSM_INFO |
                rsm == RSM_SFD) & 
               full)
      begin
        focnt <= focnt + 1 ; 
      end 

      if (focl_r)
      begin
        oco <= 1'b0 ; 
      end
      else if ((rsm == RSM_DEST |
                rsm == RSM_SOURCE |
                rsm == RSM_LENGTH |
                rsm == RSM_INFO) &
               focnt == 11'b11111111111 &
               (full | !cachenf_r))
      begin
        oco <= 1'b1 ; 
      end 

      focl_r <= focl ; 

      focg[10] <= focnt[10] ; 
      begin : focg_loop
        integer i;
        for(i = 9; i >= 0; i = i - 1)
        begin
          focg[i] <= focnt[i] ^ focnt[i + 1] ; 
        end
      end 
    end  
  end

  assign foclack = focl_r ; 

  always @(posedge clk)
  begin : mfcnt_reg_proc
    if (rst)
    begin
      mfcnt  <= {16{1'b0}} ;
      mfo    <= 1'b0 ;
      mfcl_r <= 1'b0 ;
      mfcg   <= {16{1'b0}} ;
    end
    else
    begin
      if (mfcl_r)
      begin
        mfcnt <= {16{1'b0}} ;
      end
      else if (
	        eorfff && 
                (pb | winp) && 
	        (
		  fsm==FSM_MATCH | ra |
	          ( 
		    pm && dest[0]
	          )
	        )
              )
      begin
        mfcnt <= mfcnt + 1'b1 ;
      end

      if (mfcl_r)
      begin
        mfo <= 1'b0 ;
      end
      else if (
	        mfcnt=={16{1'b1}} && pb && 
	        (
		  fsm==FSM_MATCH | ra |
	          ( 
		    pm && dest[0]
	          )
	        )
              )
      begin
        mfo <= 1'b1 ;
      end

      mfcl_r <= mfcl;

      begin : mfcg_reg_write
        integer i;
        mfcg[15] <= mfcnt[15];
        for(i = 14; i >= 0; i = i - 1)
        begin
          mfcg[i] <= mfcnt[i] ^ mfcnt[i + 1];
        end
      end
    end
  end

  assign mfclack = mfcl_r ;
    
  assign fzero = {FIFODEPTH{1'b0}} ; 

  assign mzero_max = {(MIIWIDTH_MAX + 1){1'b0}} ; 

  assign rxd_r_max = {mzero_max[MIIWIDTH_MAX + 1:MIIWIDTH],
                      rxd_r}; 

endmodule



module RFIFO_V (
  clk,
  rst,
  ramdata,
  ramaddr,
  fifore,
  ffo,
  rfo,
  mfo,
  tlo,
  reo,
  dbo,
  ceo,
  ovo,
  cso,
  flo,
  fifodata,
  cachere,
  cachene,
  cachenf,
  radg,
  rireq,
  ffi,
  rfi,
  mfi,
  tli,
  rei,
  dbi,
  cei,
  ovi,
  csi,
  fli,
  wadg,
  riack
  );

  parameter DATAWIDTH   = 32;
  parameter DATADEPTH   = 32;
  parameter FIFODEPTH   = 9;
  parameter CACHEDEPTH  = 2;

  input     clk;
  input     rst; 

  input     [DATAWIDTH - 1:0] ramdata; 
  output    [FIFODEPTH - 1:0] ramaddr; 
  wire      [FIFODEPTH - 1:0] ramaddr;

  input     fifore;
  output    ffo; 
  wire      ffo;
  output    rfo; 
  wire      rfo;
  output    mfo; 
  wire      mfo;
  output    tlo; 
  wire      tlo;
  output    reo; 
  wire      reo;
  output    dbo; 
  wire      dbo;
  output    ceo; 
  wire      ceo;
  output    ovo; 
  wire      ovo;
  output    cso; 
  wire      cso;
  output    [13:0] flo; 
  wire      [13:0] flo;
  output    [DATAWIDTH - 1:0] fifodata; 
  wire      [DATAWIDTH - 1:0] fifodata;

  input     cachere; 
  output    cachene; 
  wire      cachene;
 
  output    cachenf; 
  wire      cachenf;
  output    [FIFODEPTH - 1:0] radg; 
  reg       [FIFODEPTH - 1:0] radg;

  input     rireq; 
  input     ffi;
  input     rfi; 
  input     mfi; 
  input     tli; 
  input     rei; 
  input     dbi; 
  input     cei; 
  input     ovi; 
  input     csi;
  input     [13:0] fli; 
  input     [FIFODEPTH - 1:0] wadg;
  output    riack; 
  wire      riack;


  parameter CSWIDTH = 23; 
  reg       [CSWIDTH - 1:0] csmem[(1'b1 << CACHEDEPTH) - 1:0]; 
  wire      cswe; 
  wire      csre; 
  reg       csnf; 
  reg       csne; 
  reg       [CACHEDEPTH - 1:0] cswad; 
  reg       [CACHEDEPTH - 1:0] cswadi; 
  reg       [CACHEDEPTH - 1:0] csrad; 
  reg       [CACHEDEPTH - 1:0] csrad_r; 
  wire      [CSWIDTH - 1:0] csdi; 
  wire      [CSWIDTH - 1:0] csdo; 

  reg       [FIFODEPTH - 1:0] stat; 
  reg       [FIFODEPTH - 1:0] rad_c; 
  reg       [FIFODEPTH - 1:0] rad; 
  reg       [FIFODEPTH - 1:0] wad_c; 
  reg       [FIFODEPTH - 1:0] wad; 
  reg       [FIFODEPTH - 1:0] wadg_0_r;
  reg       [FIFODEPTH - 1:0] wadg_r;
  reg       [13:0] flibin_c; 
  reg       [13:0] flibin; 
  reg       [13:0] fli_r;

  reg       rireq_r; 
  reg       iriack; 

  wire      [FIFODEPTH - 1:0] fzero;

  always @(posedge clk)
  begin : csmem_reg_proc
    if (rst)
    begin : csmem_reset
      integer i;
      for(i = ((1'b1 << CACHEDEPTH) - 1); i >= 0; i = i - 1)
      begin
        csmem[i] <= {CSWIDTH{1'b0}};
      end
      csrad_r <= csrad ;
    end
    else
    begin  
      csmem[cswad] <= csdi ; 
      csrad_r <= csrad ;
    end
  end

  always @(posedge clk)
  begin : cswad_reg_proc
    if (rst)
    begin
      cswad <= {CACHEDEPTH{1'b1}} ; 
    end
    else
    begin
      if (cswe)
      begin
        cswad <= cswad + 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : csrad_reg_proc
    if (rst)
    begin
      csrad <= {CACHEDEPTH{1'b1}} ; 
    end
    else
    begin
      if (csre)
      begin
        csrad <= csrad + 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : csne_reg_proc
    if (rst)
    begin
      csne <= 1'b0 ; 
    end
    else
    begin
      if (cswad == csrad)
      begin
        csne <= 1'b0 ; 
      end
      else
      begin
        csne <= 1'b1 ; 
      end 
    end  
  end

  always @(cswad)
  begin : cswadi_drv
    cswadi <= cswad + 1;
  end
  
  always @(posedge clk)
  begin : csnf_reg_proc
    if (rst)
    begin
      csnf <= 1'b0 ; 
    end
    else
    begin
      if (cswadi == csrad)    
      begin
        csnf <= 1'b0 ; 
      end
      else
      begin
        csnf <= 1'b1 ; 
      end 
    end  
  end

  always @(fli_r)
  begin : flibin_proc
    reg[13:0] flibin_v; 
    flibin_v[13] = fli_r[13]; 
    begin : flibin_loop
      integer i;
      for(i = 12; i >= 0; i = i - 1)
      begin
        flibin_v[i] = flibin_v[i + 1] ^ fli_r[i]; 
      end
    end 
    flibin_c = flibin_v ; 
  end

  always @(posedge clk)
  begin : flibin_reg_proc
    if (rst)
    begin
      flibin <= {14{1'b0}} ; 
      fli_r  <= {14{1'b0}} ;
    end
    else
    begin
      flibin <= flibin_c ; 
      fli_r  <= fli ;
    end  
  end

  assign cachene = csne ; 

  assign cachenf = csnf ; 

  assign cswe = rireq_r & ~iriack ; 

  assign csdo = csmem[csrad_r] ; 

  assign csdi = {ffi, rfi, mfi, tli, rei, dbi, cei, ovi, csi, flibin} ; 

  assign ffo = csdo[CSWIDTH - 1] ; 

  assign rfo = csdo[CSWIDTH - 2] ; 

  assign mfo = csdo[CSWIDTH - 3] ; 

  assign tlo = csdo[CSWIDTH - 4] ; 

  assign reo = csdo[CSWIDTH - 5] ; 

  assign dbo = csdo[CSWIDTH - 6] ; 

  assign ceo = csdo[CSWIDTH - 7] ; 

  assign ovo = csdo[CSWIDTH - 8] ; 

  assign cso = csdo[CSWIDTH - 9];
  
  assign flo = csdo[13:0] ; 

  assign csre = cachere ; 

  always @(posedge clk)
  begin : rireq_reg_proc
    if (rst)
    begin
      rireq_r <= 1'b0 ; 
    end
    else
    begin
      rireq_r <= rireq ; 
    end  
  end

  always @(posedge clk)
  begin : irecack_reg_proc
    if (rst)
    begin
      iriack <= 1'b0 ; 
    end
    else
    begin
      iriack <= rireq_r ; 
    end  
  end

  assign riack = iriack ; 

  always @(rad or fifore)
  begin : rad_proc
    if (fifore)
    begin
      rad_c <= rad + 1 ; 
    end
    else
    begin
      rad_c <= rad ; 
    end 
  end

  always @(posedge clk)
  begin : rad_reg_proc
    if (rst)
    begin
      rad <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      rad <= rad_c ; 
    end  
  end 

  always @(posedge clk)
  begin : radg_reg_proc
    if (rst)
    begin
      radg <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      radg[FIFODEPTH - 1] <= rad[FIFODEPTH - 1] ; 
      begin : radg_loop
        integer i;
        for(i = FIFODEPTH - 2; i >= 0; i = i - 1)
        begin
          radg[i] <= rad[i] ^ rad[i + 1] ; 
        end
      end 
    end  
  end

  always @(posedge clk)
  begin : wadg_reg_proc
    if (rst)
    begin
      wadg_0_r <= {FIFODEPTH{1'b0}} ;
      wadg_r <= {FIFODEPTH{1'b0}} ;
    end
    else
    begin
      wadg_0_r <= wadg;
      wadg_r <= wadg_0_r;
    end
  end

  always @(wadg_r)
  begin : wad_proc
    reg[FIFODEPTH - 1:0] wad_v; 
    wad_v[FIFODEPTH - 1] = wadg_r[FIFODEPTH - 1]; 
    begin : wad_loop
      integer i;
      for(i = FIFODEPTH - 2; i >= 0; i = i - 1)
      begin
        wad_v[i] = wad_v[i + 1] ^ wadg_r[i]; 
      end
    end 
    wad_c = wad_v ; 
  end

  always @(posedge clk)
  begin : ad_reg_proc
    if (rst)
    begin
      wad <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      wad <= wad_c ; 
    end  
  end

  always @(posedge clk)
  begin : stat_reg_proc
    if (rst)
    begin
      stat <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      stat <= wad - rad ; 
    end  
  end

  assign ramaddr = rad_c ; 

  assign fifodata = ramdata ; 


  assign fzero = {FIFODEPTH{1'b0}};

endmodule



module RLSM_V (
  clk,
  rst,
  fifodata,
  fifore,
  cachere,
  dmaack,
  dmaeob,
  dmadatai,
  dmaaddr,
  dmareq,
  dmawr,
  dmacnt,
  dmaaddro,
  dmadatao,
  rprog,
  rcpoll,
  fifocne,
  ff,
  rf,
  mf,
  db,
  re,
  ce,
  tl,
  ftp,
  ov,
  cs,
  length,
  pbl,
  dsl,
  rpoll,
  rdbadc,
  rdbad,
  rpollack,
  rcompack,
  bufack,
  des,
  fbuf,
  stat,
  ru,
  rcomp,
  bufcomp,
  stopi,
  stopo
  );

  parameter DATAWIDTH = 32;
  parameter DATADEPTH  = 32;
  parameter FIFODEPTH  = 9;

  `include "utility.v"

  input     clk; 
  input     rst; 

  input     [DATAWIDTH - 1:0] fifodata; 
  output    fifore; 
  wire      fifore;
  output    cachere; 
  wire      cachere;

  input     dmaack;
  input     dmaeob;
  input     [DATAWIDTH - 1:0] dmadatai; 
  input     [DATADEPTH - 1:0] dmaaddr; 
  output    dmareq; 
  wire      dmareq;
  output    dmawr; 
  wire      dmawr;
  output    [FIFODEPTH_MAX - 1:0] dmacnt; 
  reg       [FIFODEPTH_MAX - 1:0] dmacnt;
  output    [DATADEPTH - 1:0] dmaaddro; 
  reg       [DATADEPTH - 1:0] dmaaddro;
  output    [DATAWIDTH - 1:0] dmadatao; 
  reg       [DATAWIDTH - 1:0] dmadatao;

  input     rprog;
  input     rcpoll;
  input     fifocne; 
  input     ff; 
  input     rf; 
  input     mf; 
  input     db; 
  input     re;
  input     ce;
  input     tl; 
  input     ftp;
  input     ov; 
  input     cs;
  input     [13:0] length;

  input     [5:0] pbl; 
  input     [4:0] dsl; 
  input     rpoll; 
  input     rdbadc; 
  input     [DATADEPTH - 1:0] rdbad;
  output    rpollack; 
  reg       rpollack;

  input     rcompack; 
  input     bufack; 
  output    des; 
  reg       des;
  output    fbuf; 
  reg       fbuf;
  output    stat; 
  reg       stat;
  output    ru; 
  reg       ru;
  output    rcomp; 
  reg       rcomp;
  output    bufcomp; 
  reg       bufcomp;

  input     stopi; 
  output    stopo; 
  reg       stopo;
  


  reg       [3:0] lsm_c; 
  reg       [3:0] lsm; 
  reg       [3:0] lsm_r; 
  reg       own_c; 
  reg       own; 
  reg       rch; 
  reg       rer; 
  reg       rls; 
  reg       rfs; 
  reg       rde; 
  wire      res_c; 
  reg       [10:0] bs1; 
  reg       [10:0] bs2; 

  reg       adwrite; 
  reg       [DATADEPTH - 1:0] bad; 
  reg       [DATADEPTH - 1:0] dad; 
  reg       [10:0] bcnt; 
  reg       [DATADEPTH - 1:0] statad; 
  reg       [DATADEPTH - 1:0] tstatad; 
  reg       dbadc_r; 

  reg       req_c; 
  reg       req; 
  wire      [2:0] dmaaddr20; 
  wire      [1:0] addr10;
  reg       [DATADEPTH_MAX - 1:0] dataimax_r; 
  wire      [31:0] fstat; 

  reg       rprog_r; 
  reg       rcpoll_r;
  reg       rcpoll_r2;
  reg       whole; 

  reg       [13:0] fifolev_r; 
  reg       [13:0] fbcnt; 
  reg       [13:0] fbcnt_c;
  reg       [13:0] length_r;
  wire      ififore;
  reg       ififore_r;
  reg       icachere; 
  wire      [FIFODEPTH_MAX - 1:0] bsmax; 
  wire      [FIFODEPTH_MAX - 1:0] flmax; 
  wire      [FIFODEPTH_MAX - 1:0] blmax; 
  reg       fl_g_16; 
  reg       fl_g_bs; 
  reg       fl_g_bl; 
  reg       bl_g_bs; 
  reg       pblz; 

  reg       stop_r; 

  wire      [FIFODEPTH_MAX - 1:0] fzero_max; 
  wire      [DATAWIDTH_MAX + 1:0] dmadatai_max;
  wire      [DATAWIDTH_MAX + 1:0] dzero_max;

  always @(posedge clk)
  begin : dataimax_reg_proc
    if (rst)
    begin
      dataimax_r <= {DATADEPTH_MAX{1'b1}} ; 
    end
    else
    begin
      case (DATAWIDTH)
        8 :
          begin
            case (dmaaddr20)
              3'b000, 3'b100 :
                begin
                  dataimax_r[7:0] <= dmadatai_max[DATAWIDTH-1:0] ; 
                end
              3'b001, 3'b101 :
                begin
                  dataimax_r[15:8] <= dmadatai_max[DATAWIDTH-1:0] ; 
                end
              3'b010, 3'b110 :
                begin
                  dataimax_r[23:16] <= dmadatai_max[DATAWIDTH-1:0] ; 
                end
              default :
                begin
                  dataimax_r[31:24] <= dmadatai_max[DATAWIDTH-1:0] ; 
                end
            endcase 
          end
        16 :
          begin
            if (!(dmaaddr[1]))
            begin
              dataimax_r[15:0] <= dmadatai_max[DATAWIDTH-1:0] ; 
            end
            else
            begin
              dataimax_r[31:16] <= dmadatai_max[DATAWIDTH-1:0] ; 
            end 
          end
        default :
          begin
            dataimax_r <= dmadatai_max[31:0] ; 
          end
      endcase 
    end  
  end

  always @(posedge clk)
  begin : fifolev_reg_proc
    if (rst)
    begin
      length_r  <= {14{1'b0}} ; 
      fifolev_r <= {14{1'b0}} ; 
      fl_g_bs   <= 1'b0 ; 
      fl_g_16   <= 1'b0 ; 
      fl_g_bl   <= 1'b0 ; 
      bl_g_bs   <= 1'b0 ; 
      pblz      <= 1'b0 ; 
    end
    else
    begin
      length_r <= length;

      fifolev_r <= length_r - fbcnt_c ; 

      if (flmax >= bsmax)
      begin
        fl_g_bs <= 1'b1 ; 
      end
      else
      begin
        fl_g_bs <= 1'b0 ; 
      end 

      case (DATAWIDTH)
        8 :
          begin
            if (flmax > ({fzero_max[FIFODEPTH_MAX - 1:6],
                          6'b111111}))
            begin
              fl_g_16 <= 1'b1 ; 
            end
            else
            begin
              fl_g_16 <= 1'b0 ; 
            end 
          end
        16 :
          begin
            if (flmax > ({fzero_max[FIFODEPTH_MAX - 1:5],
                          5'b11111}))
            begin
              fl_g_16 <= 1'b1 ; 
            end
            else
            begin
              fl_g_16 <= 1'b0 ; 
            end 
          end
        default :
          begin
            if (flmax > ({fzero_max[FIFODEPTH_MAX - 1:4],
                          4'b1111}))
            begin
              fl_g_16 <= 1'b1 ; 
            end
            else
            begin
              fl_g_16 <= 1'b0 ; 
            end 
          end
      endcase 

      if (flmax >= (blmax + 1'b1))
      begin
        fl_g_bl <= 1'b1 ; 
      end
      else
      begin
        fl_g_bl <= 1'b0 ; 
      end 

      if (blmax >= bsmax)
      begin
        bl_g_bs <= 1'b1 ; 
      end
      else
      begin
        bl_g_bs <= 1'b0 ; 
      end 

      if (pbl == 6'b000000)
      begin
        pblz <= 1'b1 ; 
      end
      else
      begin
        pblz <= 1'b0 ; 
      end 
    end  
  end

  assign flmax = (DATAWIDTH == 8)  ? {fzero_max[FIFODEPTH_MAX - 1:14],
                                      fifolev_r} :
                 (DATAWIDTH == 16) ? {fzero_max[FIFODEPTH_MAX - 1:13],
                                      fifolev_r[13:1]} :
                                     {fzero_max[FIFODEPTH_MAX - 1:12],
                                      fifolev_r[13:2]} ;
 
  assign blmax = {fzero_max[FIFODEPTH_MAX - 1:6], pbl} ; 
 
  assign bsmax = (DATAWIDTH == 8)  ? {fzero_max[FIFODEPTH_MAX - 1:11],
                                      bcnt} :
                 (DATAWIDTH == 16) ? {fzero_max[FIFODEPTH_MAX - 1:10],
                                      bcnt[10:1]} :
                                     {fzero_max[FIFODEPTH_MAX - 1:9],
                                      bcnt[10:2]} ;

  always @(lsm or
           fl_g_bs or
           fl_g_bl or
           bl_g_bs or
           pblz or
           blmax or 
           bsmax or
           flmax or
           fzero_max)
  begin : dmacnt_proc
    if (lsm == LSM_DES0 |
        lsm == LSM_DES1 |
        lsm == LSM_DES2 |
        lsm == LSM_DES3 |
        lsm == LSM_STAT |
        lsm == LSM_FSTAT |
        lsm == LSM_DES0P)
    begin
      case (DATAWIDTH)
        8 :
          begin
            dmacnt <= {fzero_max[FIFODEPTH_MAX - 1:3], 3'b100} ; 
          end
        16 :
          begin
            dmacnt <= {fzero_max[FIFODEPTH_MAX - 1:3], 3'b010} ; 
          end
        default :
          begin
            dmacnt <= {fzero_max[FIFODEPTH_MAX - 1:3], 3'b001} ; 
          end
      endcase 
    end
    else
    begin
      if (pblz)
      begin
        if (fl_g_bs)
        begin
          dmacnt <= bsmax ; 
        end
        else
        begin
          dmacnt <= flmax ; 
        end 
      end
      else
      begin
        if (fl_g_bl)
        begin
          if (bl_g_bs)
          begin
            dmacnt <= bsmax ; 
          end
          else
          begin
            dmacnt <= blmax ; 
          end 
        end
        else
        begin
          if (fl_g_bs)
          begin
            dmacnt <= bsmax ; 
          end
          else
          begin
            dmacnt <= flmax ; 
          end 
        end 
      end 
    end 
  end

  always @(req or
           lsm or
           lsm_c or
           fifocne or
           fl_g_bl or
           fl_g_16 or
           pblz or
           whole or 
           rprog_r or
           dmaack or
           dmaeob or
           flmax or
           fzero_max)
  begin : req_proc
    case (lsm)
      LSM_BUF1, LSM_BUF2 :
        begin
          if ((dmaack & dmaeob) | lsm_c==LSM_NXT)
          begin
            req_c <= 1'b0 ; 
          end
          else if (fifocne | (rprog_r & ((fl_g_bl & !pblz) |
                                         (fl_g_16 & pblz))))
          begin
            req_c <= 1'b1 ; 
          end
          else
          begin
            req_c <= req ; 
          end 
        end
      LSM_DES0, LSM_DES1, LSM_DES2,
      LSM_DES3, LSM_STAT, LSM_DES0P :
        begin
          if (dmaack)
          begin
            req_c <= 1'b0 ; 
          end
          else
          begin
            req_c <= 1'b1 ; 
          end 
        end
      LSM_FSTAT :
        begin
          if (dmaack | !whole |
              (DATAWIDTH ==  8 & flmax[1:0] != fzero_max[1:0])
              |
              (DATAWIDTH == 16 & flmax[  1] != fzero_max[1]))
          begin
            req_c <= 1'b0 ;
          end
          else
          begin
            req_c <= 1'b1 ;
          end
        end
      default :
        begin
          req_c <= 1'b0 ; 
        end
    endcase 
  end

  always @(posedge clk)
  begin : req_reg_proc
    if (rst)
    begin
      req <= 1'b0 ; 
    end
    else
    begin
      req <= req_c ; 
    end  
  end

  always @(lsm or bad or dad or statad)
  begin : dmaaddro_proc
    case (lsm)
      LSM_BUF1, LSM_BUF2 :
        begin
          dmaaddro <= bad ; 
        end
      LSM_STAT, LSM_FSTAT :
        begin
          dmaaddro <= statad ; 
        end
      default :
        begin
          dmaaddro <= dad ; 
        end
    endcase 
  end

  assign fstat = {1'b0, ff, length, res_c, rde,
                  RDES0_RV[13:12], rf, mf, rfs, rls, tl,
                  cs, ftp, RDES0_RV[4], re, db, ce, ov} ; 

  assign dmawr = (lsm == LSM_STAT |
                  lsm == LSM_FSTAT |
                  lsm == LSM_BUF1 | 
                  lsm == LSM_BUF2) ? 1'b1 : 1'b0 ; 

  always @(fifodata or lsm or addr10 or fstat)
  begin : dmadatao_proc
    if (lsm == LSM_BUF1 | lsm == LSM_BUF2)
    begin
      dmadatao <= fifodata ; 
    end
    else
    begin
      case (DATAWIDTH)
        8 :
          begin
            case (addr10)
              2'b00 :
                begin
                  dmadatao <= fstat[7:0] ; 
                end
              2'b01 :
                begin
                  dmadatao <= fstat[15:8] ; 
                end
              2'b10 :
                begin
                  dmadatao <= fstat[23:16] ; 
                end
              default :
                begin
                  dmadatao <= fstat[31:24] ; 
                end
            endcase 
          end
        16 :
          begin
            if (addr10 == 2'b00)
            begin
              dmadatao <= fstat[15:0] ; 
            end
            else
            begin
              dmadatao <= fstat[31:16] ; 
            end 
          end
        default :
          begin
            dmadatao <= fstat ; 
          end
      endcase 
    end 
  end

  assign dmareq = req ; 

  always @(lsm or
           rcpoll_r or
           rcpoll_r2 or
           rpoll or
           dmaack or
           dmaeob or 
           own_c or
           bs1 or
           bs2 or
           whole or
           rch or
           stop_r or
           own or
           bcnt or 
           dbadc_r)
  begin : lsm_proc
    case (lsm)
      LSM_IDLE :
        begin
          if (!dbadc_r & !stop_r & ((rcpoll_r & !rcpoll_r2) | rpoll))
          begin
            lsm_c <= LSM_DES0 ; 
          end
          else
          begin
            lsm_c <= LSM_IDLE ; 
          end 
        end
      LSM_DES0 :
        begin
          if (dmaack & dmaeob)
          begin
            if (own_c)
            begin
              lsm_c <= LSM_DES1 ; 
            end
            else
            begin
              lsm_c <= LSM_IDLE ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_DES0 ; 
          end 
        end
      LSM_DES0P :
        begin
          if (dmaack & dmaeob)
          begin
            if (!own_c | whole)
            begin
              lsm_c <= LSM_FSTAT ; 
            end
            else
            begin
              lsm_c <= LSM_STAT ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_DES0P ; 
          end 
        end
      LSM_DES1 :
        begin
          if (dmaack & dmaeob)
          begin
            lsm_c <= LSM_DES2 ; 
          end
          else
          begin
            lsm_c <= LSM_DES1 ; 
          end 
        end
      LSM_DES2 :
        begin
          if (dmaack & dmaeob)
          begin
            if (bs1 == 11'b00000000000)
            begin
              lsm_c <= LSM_DES3 ; 
            end
            else
            begin
              lsm_c <= LSM_BUF1 ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_DES2 ; 
          end 
        end
      LSM_DES3 :
        begin
          if (dmaack & dmaeob)
          begin
            if (bs2 != 11'b00000000000 & !rch)
            begin
              lsm_c <= LSM_BUF2 ; 
            end
            else
            begin
              lsm_c <= LSM_NXT ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_DES3 ; 
          end 
        end
      LSM_BUF1 :
        begin
          if (whole | bcnt == 11'b00000000000)
          begin
            lsm_c <= LSM_DES3 ; 
          end
          else if(dbadc_r)
          begin
            lsm_c <= LSM_IDLE ; 
          end
          else
          begin
            lsm_c <= LSM_BUF1 ; 
          end 
        end
      LSM_BUF2 :
        begin
          if (whole | bcnt == 11'b00000000000)
          begin
            lsm_c <= LSM_NXT ; 
          end
          else if(dbadc_r)
          begin
            lsm_c <= LSM_IDLE ; 
          end
          else
          begin
            lsm_c <= LSM_BUF2 ; 
          end 
        end
      LSM_NXT :
        begin
          if (whole)
          begin
            if (stop_r)
            begin
              lsm_c <= LSM_FSTAT ; 
            end
            else
            begin
              lsm_c <= LSM_DES0P ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_DES0P ; 
          end
        end
      LSM_STAT :
        begin
          if (dmaack & dmaeob)
          begin
            lsm_c <= LSM_DES1 ; 
          end
          else
          begin
            lsm_c <= LSM_STAT ; 
          end 
        end
      default :
        begin
          if (dmaack & dmaeob)
          begin
            if (own & !stop_r)
            begin
              lsm_c <= LSM_DES1 ; 
            end
            else
            begin
              lsm_c <= LSM_IDLE ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_FSTAT ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : rlsm_reg_proc
    if (rst)
    begin
      lsm <= LSM_IDLE ; 
      lsm_r <= LSM_IDLE ; 
    end
    else
    begin
      lsm <= lsm_c ; 
      lsm_r <= lsm ; 
    end  
  end

  always @(posedge clk)
  begin : rpollack_reg_proc
    if (rst)
    begin
      rpollack <= 1'b0 ; 
    end
    else
    begin
      if (rpoll & !dbadc_r)
      begin
        rpollack <= 1'b1 ; 
      end
      else if (!rpoll)
      begin
        rpollack <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : bcnt_reg_proc
    if (rst)
    begin
      bcnt <= {11{1'b1}} ; 
    end
    else
    begin
      if (lsm == LSM_DES2)
      begin
        bcnt <= bs1 ; 
      end
      else if (lsm == LSM_DES3)
      begin
        bcnt <= bs2 ; 
      end
      else
      begin
        if (dmaack)
        begin
          case (DATAWIDTH)
            8 :
              begin
                bcnt <= bcnt - 1 ; 
              end
            16 :
              begin
                bcnt <= {(bcnt[10:1] - 1), 1'b0} ; 
              end
            default :
              begin
                bcnt <= {(bcnt[10:2] - 1), 2'b00} ; 
              end
          endcase 
        end 
      end 
    end  
  end

  always @(own or
           dmaack or
           dmaeob or
           lsm or
           dmadatai_max)
  begin : own_proc
    if (dmaack & dmaeob & (lsm == LSM_DES0 | lsm == LSM_DES0P))
    begin
      own_c <= dmadatai_max[DATAWIDTH - 1] ; 
    end
    else
    begin
      own_c <= own ; 
    end 
  end

  always @(posedge clk)
  begin : des1_reg_proc
    reg ft22; 
    if (rst)
    begin
      rer <= 1'b0 ; 
      rch <= 1'b0 ; 
      bs2 <= {11{1'b0}} ; 
      bs1 <= {11{1'b0}} ; 
    end
    else
    begin
      if (lsm == LSM_DES1 & dmaack)
      begin
        case (DATAWIDTH)
          8 :
            begin
              case (dmaaddr20)
                3'b000, 3'b100 :
                  begin
                    bs1[7:0] <= dmadatai_max[7:0] ; 
                  end
                3'b001, 3'b101 :
                  begin
                    bs1[10:8] <= dmadatai_max[2:0] ; 
                    bs2[4:0] <= dmadatai_max[7:3] ; 
                  end
                3'b010, 3'b110 :
                  begin
                    bs2[10:5] <= dmadatai_max[5:0] ; 
                  end
                default :
                  begin
                    rer <= dmadatai_max[1] ; 
                    rch <= dmadatai_max[0] ; 
                  end
              endcase 
            end
          16 :
            begin
              case (dmaaddr20)
                3'b000, 3'b100 :
                  begin
                    bs1[10:0] <= dmadatai_max[10:0] ; 
                    bs2[4:0] <= dmadatai_max[15:11] ; 
                  end
                default :
                  begin
                    bs2[10:5] <= dmadatai_max[5:0] ; 
                    rer <= dmadatai_max[9] ; 
                    rch <= dmadatai_max[8] ; 
                  end
              endcase 
            end
          default :
            begin
              rer <= dmadatai_max[25] ; 
              rch <= dmadatai_max[24] ; 
              bs2 <= dmadatai_max[21:11] ; 
              bs1 <= dmadatai_max[10:0] ; 
            end
        endcase 
      end 
    end  
  end

  always @(posedge clk)
  begin : rdes_reg_proc
    if (rst)
    begin
      own <= 1'b0 ; 
      rfs <= 1'b1 ; 
      rls <= 1'b0 ; 
      rde <= 1'b0 ; 
    end
    else
    begin
      if (lsm == LSM_FSTAT & dmaack & dmaeob)
      begin
        rfs <= 1'b1 ; 
      end
      else if (lsm == LSM_STAT & dmaack & dmaeob)
      begin
        rfs <= 1'b0 ; 
      end 

      if (lsm == LSM_FSTAT)
      begin
        rls <= 1'b1 ; 
      end
      else
      begin
        rls <= 1'b0 ; 
      end 

      if (lsm == LSM_FSTAT & !whole)
      begin
        rde <= 1'b1 ; 
      end
      else if (lsm == LSM_IDLE)
      begin
        rde <= 1'b0 ; 
      end 

      own <= own_c ; 
    end  
  end

  assign res_c = rf | ce | rde | cs | tl ; 

  always @(posedge clk)
  begin : adwrite_reg_proc
    if (rst)
    begin
      adwrite <= 1'b0 ; 
      dbadc_r <= 1'b0 ; 
    end
    else
    begin
      if (dmaack & dmaeob)
      begin
        adwrite <= 1'b1 ; 
      end
      else
      begin
        adwrite <= 1'b0 ; 
      end 

      dbadc_r <= rdbadc ; 
    end  
  end

  always @(posedge clk)
  begin : dad_reg_proc
    if (rst)
    begin
      dad <= {DATADEPTH{1'b1}} ; 
    end
    else
    begin
      if (dbadc_r)
      begin
        dad <= rdbad ; 
      end
      else if (adwrite & lsm == LSM_NXT & rch)
      begin
        dad <= dataimax_r[DATADEPTH - 1:0] ; 
      end
      else if (adwrite)
      begin
        case (lsm_r)
          LSM_DES3 :
            begin
              if (rer)
              begin
                dad <= rdbad ; 
              end
              else
              begin
                dad <= dmaaddr + ({dsl, 2'b00}) ; 
              end 
            end
          LSM_DES0, LSM_DES0P :
            begin
              if (own)
              begin
                dad <= dmaaddr ; 
              end 
            end
          LSM_DES2 :
            begin
              dad <= dmaaddr ; 
            end
          LSM_DES1 :
            begin
              dad <= dmaaddr ; 
            end
          LSM_FSTAT :
		    begin
			  dad <= (lsm == LSM_IDLE) ? rdbad : dad;
			end
          default :
            begin
              dad <= dad ; 
            end
        endcase 
      end 
    end  
  end

  always @(posedge clk)
  begin : bad_reg_proc
    if (rst)
    begin
      bad <= {DATADEPTH{1'b1}} ; 
    end
    else
    begin
      if (adwrite)
      begin
        if (lsm_r == LSM_BUF1 | lsm_r == LSM_BUF2)
        begin
          bad <= dmaaddr ; 
        end
        else
        begin
          bad <= dataimax_r[DATADEPTH - 1:0] ; 
        end 
      end 
    end  
  end

  always @(posedge clk)
  begin : stataddr_reg_proc
    if (rst)
    begin
      tstatad <= {DATADEPTH{1'b1}} ; 
      statad  <= {DATADEPTH{1'b1}} ; 
    end
    else
    begin
      if (lsm == LSM_DES1 & adwrite)
      begin
        statad <= tstatad ; 
      end 

      if ((lsm == LSM_DES0 | lsm == LSM_DES0P) & dmaack & dmaeob)
      begin
        tstatad <= dad ; 
      end 
    end  
  end

  always @(fbcnt or icachere or ififore)
  begin : fbcnt_proc
    if (icachere)
    begin
      fbcnt_c <= {14{1'b0}} ; 
    end
    else
    begin
      if (ififore)
      begin
        case (DATAWIDTH)
          8 :
            begin
              fbcnt_c <= fbcnt + 1 ; 
            end
          16 :
            begin
              fbcnt_c <= fbcnt + 2'b10 ; 
            end
          default :
            begin
              fbcnt_c <= fbcnt + 3'b100 ; 
            end
        endcase 
      end
      else
      begin
        fbcnt_c <= fbcnt;
      end
    end 
  end

  always @(posedge clk)
  begin : fbcnt_reg_proc
    if(rst)
    begin	    
      fbcnt <= {14{1'b0}};
    end
    else
    begin
      fbcnt <= fbcnt_c;
    end
  end
  
  always @(fbcnt or length or fifocne)
  begin : whole_proc
    if (fbcnt >= length & fifocne)
    begin
      whole <= 1'b1 ; 
    end
    else
    begin
      whole <= 1'b0 ; 
    end 
  end

  assign ififore = (((lsm == LSM_BUF1 | lsm == LSM_BUF2) & dmaack) |
                    (lsm == LSM_FSTAT & !whole &
                     flmax != fzero_max[14:0] & !ififore_r) |
                    (lsm == LSM_FSTAT & !whole &
                     fifocne & !ififore_r)) ? 1'b1 : 1'b0 ; 

  always @(posedge clk)
  begin : ififore_reg_proc
    if (rst)
    begin
      ififore_r <= 1'b0 ;
      icachere <= 1'b0 ; 
    end
    else
    begin
      ififore_r <= ififore ;

      if (lsm == LSM_FSTAT & dmaack & dmaeob)
      begin
        icachere <= 1'b1 ; 
      end
      else
      begin
        icachere <= 1'b0 ; 
      end 
    end
  end

  assign fifore = ififore ; 

  assign cachere = icachere ; 

  always @(posedge clk)
  begin : rprog_reg_proc
    if (rst)
    begin
      rprog_r   <= 1'b0 ; 
      rcpoll_r  <= 1'b0 ;
      rcpoll_r2 <= 1'b0 ;
    end
    else
    begin
      rprog_r  <= rprog ; 
      rcpoll_r <= rcpoll ;
      if (lsm == LSM_IDLE)
      begin
        rcpoll_r2 <= rcpoll_r ;
      end
    end  
  end

  always @(posedge clk)
  begin : stat_reg_drv
    if (rst)
    begin
      des     <= 1'b0 ; 
      fbuf    <= 1'b0 ; 
      stat    <= 1'b0 ; 
      rcomp   <= 1'b0 ; 
      bufcomp <= 1'b0 ; 
      ru      <= 1'b0 ; 
    end
    else
    begin
      if (lsm == LSM_DES0 |
          lsm == LSM_DES1 |
          lsm == LSM_DES2 |
          lsm == LSM_DES3 |
          lsm == LSM_DES0P)
      begin
        des <= 1'b1 ; 
      end
      else
      begin
        des <= 1'b0 ; 
      end 

      if ((lsm == LSM_BUF1 | lsm == LSM_BUF2) & req)
      begin
        fbuf <= 1'b1 ; 
      end
      else
      begin
        fbuf <= 1'b0 ; 
      end 

      if (lsm == LSM_STAT | lsm == LSM_FSTAT)
      begin
        stat <= 1'b1 ; 
      end
      else
      begin
        stat <= 1'b0 ; 
      end 

      if (lsm == LSM_FSTAT & dmaack & dmaeob)
      begin
        rcomp <= 1'b1 ; 
      end
      else if (rcompack)
      begin
        rcomp <= 1'b0 ; 
      end 

      if (lsm == LSM_STAT & dmaack & dmaeob)
      begin
        bufcomp <= 1'b1 ; 
      end
      else if (bufack)
      begin
        bufcomp <= 1'b0 ; 
      end 

      if (own & !own_c)
      begin
        ru <= 1'b1 ; 
      end
      else if (own)
      begin
        ru <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : stop_reg_proc
    if (rst)
    begin
      stop_r <= 1'b1 ; 
      stopo  <= 1'b1 ; 
    end
    else
    begin
      stop_r <= stopi ; 

      if (stop_r & (lsm == LSM_IDLE |
                    ((lsm == LSM_BUF1 | lsm == LSM_BUF2) & 
                     !fifocne & !rprog_r)))
      begin
        stopo <= 1'b1 ; 
      end
      else
      begin
        stopo <= 1'b0 ; 
      end 
    end  
  end

  assign dzero_max = {DATAWIDTH_MAX{1'b0}} ; 

  assign fzero_max = {FIFODEPTH_MAX{1'b0}} ; 

  assign dmadatai_max = {dzero_max[DATAWIDTH_MAX+1:DATAWIDTH],
                         dmadatai}; 

  assign dmaaddr20 = dmaaddr[2:0] ; 

  assign addr10 = dmaaddr[1:0] ; 

endmodule



module RSTC_V (
  clkdma,
  clkcsr,
  clkt,
  clkr,
  rstcsr,
  rstsoft,
  rsttc,
  rstrc,
  rstdmao,
  rstcsro
  );

  input     clkdma; 
  input     clkcsr; 
  input     clkt; 
  input     clkr; 
  
  input     rstcsr; 
  input     rstsoft; 
  output    rsttc; 
  reg       rsttc;
  output    rstrc; 
  reg       rstrc;
  output    rstdmao; 
  reg       rstdmao;
  output    rstcsro; 
  reg       rstcsro;


  reg       rstsoft_rc1; 
  reg       rstsoft_rc2; 
  reg       rstsoft_rc3; 
  reg       rstsoft_tc1; 
  reg       rstsoft_tc2; 
  reg       rstsoft_tc3; 
  reg       rstsoft_dma1; 
  reg       rstsoft_dma2; 
  reg       rstsoft_dma3; 
  reg       rstsoft_csr; 
  reg       rstsoft_dma_csr1;
  reg       rstsoft_dma_csr2;
  reg       rstsoft_rc_csr1;
  reg       rstsoft_rc_csr2;
  reg       rstsoft_tc_csr1;
  reg       rstsoft_tc_csr2;
  reg       rstcsr_r1;
  reg       rstcsr_r2;
  reg       rstcsr_tc1;
  reg       rstcsr_tc2;
  reg       rstcsr_rc1;
  reg       rstcsr_rc2;
  reg       rstcsr_dma1;
  reg       rstcsr_dma2;

  
  always @(posedge clkcsr)
  begin : rstsoft_csr_reg_proc
    if (rstcsr_r2)
    begin
      rstsoft_csr      <= 1'b0 ; 
      rstsoft_dma_csr1 <= 1'b0 ;
      rstsoft_dma_csr2 <= 1'b0 ;
      rstsoft_tc_csr1  <= 1'b0 ;
      rstsoft_tc_csr2  <= 1'b0 ;
      rstsoft_rc_csr1  <= 1'b0 ;
      rstsoft_rc_csr2  <= 1'b0 ;
    end
    else
    begin
      if (rstsoft)
      begin
        rstsoft_csr <= 1'b1 ; 
      end
      else if (rstsoft_rc_csr2 & rstsoft_tc_csr2 & rstsoft_dma_csr2)
      begin
        rstsoft_csr    <= 1'b0 ;
      end 
      rstsoft_dma_csr1 <= rstsoft_dma3;
      rstsoft_dma_csr2 <= rstsoft_dma_csr1;
      rstsoft_tc_csr1  <= rstsoft_tc3;
      rstsoft_tc_csr2  <= rstsoft_tc_csr1;
      rstsoft_rc_csr1  <= rstsoft_rc3;
      rstsoft_rc_csr2  <= rstsoft_rc_csr1;	
    end  
  end

  always @(posedge clkcsr)
  begin : rstcsro_reg_proc
    rstcsr_r1 <= rstcsr;
    rstcsr_r2 <= rstcsr_r1;
    rstcsro   <= rstcsr_r2 | rstsoft_csr;
  end

  always @(posedge clkr)
  begin : rstrc_reg_proc
      rstcsr_rc1  <= rstcsr;
      rstcsr_rc2  <= rstcsr_rc1;
      rstsoft_rc1 <= rstsoft_csr;
      rstsoft_rc2 <= rstsoft_rc1;
      rstsoft_rc3 <= rstsoft_rc2;
      rstrc       <= rstcsr_rc2 | rstsoft_rc2;
  end

  always @(posedge clkt)
  begin : rsttc_proc
    rstcsr_tc1  <= rstcsr;
    rstcsr_tc2  <= rstcsr_tc1;
    rstsoft_tc1 <= rstsoft_csr;
    rstsoft_tc2 <= rstsoft_tc1;
    rstsoft_tc3 <= rstsoft_tc2;
    rsttc       <= rstcsr_tc2 | rstsoft_tc2;
  end

  always @(posedge clkdma)
  begin : rstdma_reg_proc
    rstcsr_dma1  <= rstcsr;
    rstcsr_dma2  <= rstcsr_dma1;
    rstsoft_dma1 <= rstsoft_csr;
    rstsoft_dma2 <= rstsoft_dma1;
    rstsoft_dma3 <= rstsoft_dma2;
    rstdmao <= rstcsr_dma2 | rstsoft_dma2;
  end

endmodule

module TC_V (
  clk,
  rst,
  txen,
  txer,
  txd,
  ramdata,
  ramaddr,
  wadg,
  radg,
  dpd, 
  ac,
  sofreq,
  eofreq,
  tiack,
  lastbe,
  eofadg,
  tireq,
  ur,
  de,
  coll,
  carrier,
  bkoff,
  tpend,
  tprog,
  preamble,
  stopi,
  stopo,
  tcsack,
  tcsreq
  );

  parameter FIFODEPTH  = 9;
  parameter DATAWIDTH = 32;

  `include "utility.v"

  input     clk; 
  input     rst; 

  output    txen; 
  reg       txen;
  output    txer; 
  wire      txer;
  output    [MIIWIDTH - 1:0] txd; 
  reg       [MIIWIDTH - 1:0] txd;

  input     [DATAWIDTH - 1:0] ramdata; 
  output    [FIFODEPTH - 1:0] ramaddr; 
  wire      [FIFODEPTH - 1:0] ramaddr;

  input     [FIFODEPTH - 1:0] wadg; 
  output    [FIFODEPTH - 1:0] radg; 
  wire      [FIFODEPTH - 1:0] radg;

  input     dpd;
  input     ac; 
  input     sofreq; 
  input     eofreq; 
  input     tiack; 
  input     [DATAWIDTH / 8 - 1:0] lastbe; 
  input     [FIFODEPTH - 1:0] eofadg;
  output    tireq; 
  reg       tireq;
  output    ur; 
  wire      ur;
  output    de;
  reg       de;
  
  input     coll; 
  input     carrier; 
  input     bkoff; 
  output    tpend; 
  wire      tpend;
  output    tprog; 
  reg       tprog;
  output    preamble; 
  reg       preamble;

  input     stopi; 
  output    stopo; 
  reg       stopo;

  input     tcsack; 
  output    tcsreq; 
  reg       tcsreq;


  reg       re_c; 
  reg       re; 
  reg       empty_c; 
  reg       empty; 
  reg       [FIFODEPTH - 1:0] rad_r; 
  reg       [FIFODEPTH - 1:0] rad; 
  reg       [FIFODEPTH - 1:0] iradg; 
  reg       [FIFODEPTH - 1:0] wadg_0_r; 
  reg       [FIFODEPTH - 1:0] iwadg; 
  reg       [FIFODEPTH - 1:0] iwad_c; 
  reg       [FIFODEPTH - 1:0] iwad; 
  reg       [FIFODEPTH - 1:0] sofad; 
  reg       [FIFODEPTH - 1:0] eofadg_r; 
  reg       sofreq_r; 
  reg       eofreq_r; 
  reg       whole; 
  reg       eof; 
  reg       [DATAWIDTH - 1:0] ramdata_r; 

  reg       [MIIWIDTH - 1:0] itxd0; 
  reg       [DATAWIDTH - 1:0] pmux; 
  reg       [DATAWIDTH - 1:0] datamux_c; 
  wire      [DATAWIDTH_MAX + 1:0] datamux_c_max; 
  reg       txen1; 
  reg       txen_rise; 
  reg       [MIIWIDTH - 1:0] txd_rise; 

  reg       [3:0] tsm_c; 
  reg       [3:0] tsm; 
  reg       nset; 
  reg       [3:0] ncnt; 
  wire      [1:0] ncnt10; 
  wire      [2:0] ncnt20; 
  reg       [6:0] brel; 
  reg       bset; 
  reg       [6:0] bcnt; 
  reg       bz; 
  reg       nopad; 
  reg       crcgen; 
  reg       crcsend; 
  reg       [31:0] crc_c; 
  reg       [31:0] crc; 
  reg       [31:0] crcneg_c; 
  reg       itprog; 
  reg       itpend; 
  reg       iur; 
  reg       iti; 
  reg       tiack_r; 
  reg       [3:0] ifscnt; 

  reg       tcsack_r; 
  reg       [7:0] tcscnt; 
  reg       tcs; 

  reg       ifs1p; 
  reg       ifs2p; 
  wire      defer; 

  reg       bkoff_r; 

  reg       stop_r;
  wire      [3:0] hnibble; 
  wire      [MIIWIDTH_MAX + 1:0] itxd0_max; 
  wire      [MIIWIDTH_MAX + 1:0] itxd0zero_max; 
  wire      [DATAWIDTH_MAX + 1:0] dzero_max; 

  always @(posedge clk)
  begin : faddr_reg_proc
    if (rst)
    begin
      rad      <= {FIFODEPTH{1'b0}} ; 
      rad_r    <= {FIFODEPTH{1'b0}} ; 
      iradg    <= {FIFODEPTH{1'b0}} ; 
      sofad    <= {FIFODEPTH{1'b0}} ; 
      eofadg_r <= {FIFODEPTH{1'b0}} ; 
      iwad     <= {FIFODEPTH{1'b0}} ; 
      wadg_0_r <= {FIFODEPTH{1'b0}} ; 
      iwadg    <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      if (bkoff_r)
      begin
        rad <= sofad ; 
      end
      else if (re_c)
      begin
        rad <= rad + 1 ; 
      end
      else if (eof & tsm == TSM_FLUSH)
      begin
        rad <= iwad ; 
      end 

      rad_r <= rad ; 

      iradg <= rad ^ {1'b0, rad[FIFODEPTH - 1:1]} ; 

      if (tsm == TSM_IDLE_TCSMT)
      begin
        sofad <= rad_r ; 
      end 

      eofadg_r <= eofadg ;

      iwad <= iwad_c ; 

      wadg_0_r <= wadg;
      if (eofreq_r)
      begin
        iwadg <= eofadg_r ; 
      end
      else
      begin
        iwadg <= wadg_0_r ; 
      end 
    end  
  end

  always @(iwadg)
  begin : iwad_proc
    reg[FIFODEPTH - 1:0] wad_v; 
    wad_v[FIFODEPTH - 1] = iwadg[FIFODEPTH - 1]; 
    begin : iwad_loop
      integer i;
      for(i = FIFODEPTH - 2; i >= 0; i = i - 1)
      begin
        wad_v[i] = wad_v[i + 1] ^ iwadg[i]; 
      end
    end 
    iwad_c = wad_v ; 
  end

  always @(rad or iwad)
  begin : empty_proc
    if (rad == iwad)
    begin
      empty_c <= 1'b1 ; 
    end
    else
    begin
      empty_c <= 1'b0 ; 
    end
  end

  always @(posedge clk)
  begin : empty_reg_proc
    if (rst)
    begin
      empty <= 1'b1 ; 
    end
    else
    begin
      empty <= empty_c ; 
    end  
  end

  always @(tsm or empty_c or ncnt)
  begin : re_proc
    if ((tsm == TSM_INFO |
         tsm == TSM_SFD |
         tsm == TSM_FLUSH) & !empty_c &
        ((DATAWIDTH == 8 & !(ncnt[0])) |
         (DATAWIDTH == 16 & ncnt[1:0] == 2'b10) |
         (DATAWIDTH == 32 & ncnt[2:0] == 3'b110)))
    begin
      re_c <= 1'b1 ; 
    end
    else
    begin 
      re_c <= 1'b0 ;
    end 
  end

  always @(posedge clk)
  begin : re_reg_proc
    if (rst)
    begin
      re <= 1'b0 ; 
    end
    else
    begin
      re <= re_c ; 
    end  
  end

  assign ramaddr = rad ;

  assign radg = iradg ; 

  always @(posedge clk)
  begin : whole_reg_proc
    if (rst)
    begin
      whole <= 1'b0 ; 
    end
    else
    begin
      if (iti)
      begin
        whole <= 1'b0 ; 
      end
      else if (eofreq_r)
      begin
        whole <= 1'b1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : se_reg_proc
    if (rst)
    begin
      sofreq_r  <= 1'b0 ; 
      eofreq_r  <= 1'b0 ; 
    end
    else
    begin
      sofreq_r  <= sofreq ; 
      eofreq_r  <= eofreq ; 
    end  
  end

  always @(tsm or
           itpend or
           bkoff_r or
           defer or bz or
           ncnt or dpd or
           iur or 
           hnibble or
           ac or
           empty or
           whole or
           tiack_r or
           nopad or
           coll or 
           eof)
  begin : tsm_proc
    case (tsm)
      TSM_IDLE_TCSMT :
        begin
          if (itpend & !bkoff_r & !defer)
          begin
            tsm_c <= TSM_PREA ; 
          end
          else
          begin
            tsm_c <= TSM_IDLE_TCSMT ; 
          end 
        end
      TSM_PREA :
        begin
          if (bz & (ncnt[0]))
          begin
            tsm_c <= TSM_SFD ; 
          end
          else
          begin
            tsm_c <= TSM_PREA ; 
          end 
        end
      TSM_SFD :
        begin
          if (bz & (ncnt[0]))
          begin
            tsm_c <= TSM_INFO ; 
          end
          else
          begin
            tsm_c <= TSM_SFD ; 
          end 
        end
      TSM_INFO :
        begin
          if (coll)
          begin
            tsm_c <= TSM_JAM ;
          end
          else if (empty)
          begin
            if (!whole & ncnt == hnibble)
            begin
              tsm_c <= TSM_JAM ;
            end
            else if (eof & (nopad | dpd))
            begin
              if (ac)
              begin
                tsm_c <= TSM_INT ;
              end
              else
              begin
                tsm_c <= TSM_CRC ;
              end
            end
            else if (eof)
            begin
              tsm_c <= TSM_PAD ;
            end
            else
            begin
              tsm_c <= TSM_INFO ;
            end
          end
          else
          begin
            tsm_c <= TSM_INFO ;
          end
        end
      TSM_PAD :
        begin
          if (coll)
          begin
            tsm_c <= TSM_JAM ; 
          end
          else if (nopad & (ncnt[0]))
          begin
            tsm_c <= TSM_CRC ; 
          end
          else
          begin
            tsm_c <= TSM_PAD ; 
          end 
        end
      TSM_CRC :
        begin
          if (coll)
          begin
            tsm_c <= TSM_JAM ; 
          end
          else if (bz & (ncnt[0]))
          begin
            tsm_c <= TSM_INT ; 
          end
          else
          begin
            tsm_c <= TSM_CRC ; 
          end 
        end
      TSM_JAM :
        begin
          if (bz & (ncnt[0]))
          begin
            if (!bkoff_r | iur)
            begin
              tsm_c <= TSM_FLUSH ; 
            end
            else
            begin
              tsm_c <= TSM_IDLE_TCSMT ; 
            end 
          end
          else
          begin
            tsm_c <= TSM_JAM ; 
          end 
        end
      TSM_FLUSH :
        begin
          if (whole & empty)
          begin
            tsm_c <= TSM_INT ; 
          end
          else
          begin
            tsm_c <= TSM_FLUSH ; 
          end 
        end
      default :
        begin
          if (tiack_r)
          begin
            tsm_c <= TSM_IDLE_TCSMT ; 
          end
          else
          begin
            tsm_c <= TSM_INT ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : tsm_reg_proc
    if (rst)
    begin
      tsm <= TSM_IDLE_TCSMT ; 
    end
    else
    begin
      tsm <= tsm_c ; 
    end  
  end

  assign defer = ifs1p | ifs2p ; 

  always @(posedge clk)
  begin : ifs_reg_proc
    if (rst)
    begin
      ifs1p  <= 1'b0 ; 
      ifs2p  <= 1'b0 ; 
      ifscnt <= IFS1_TIME ; 
    end
    else
    begin
      if (!itprog & !ifs1p & !ifs2p & ifscnt != 4'b0000)
      begin
        ifs1p <= 1'b1 ; 
      end
      else if (ifscnt == 4'b0000 | ifs2p)
      begin
        ifs1p <= 1'b0 ; 
      end

      if (ifs1p & ifscnt == 4'b0000)
      begin
        ifs2p <= 1'b1 ; 
      end
      else if (ifs2p & ifscnt == 4'b0000)
      begin
        ifs2p <= 1'b0 ; 
      end 

      if (itprog |
          (carrier & ifs1p) |
          (carrier & ifscnt == 4'b0000 & !itpend) |
          (carrier & ifscnt == 4'b0000 &  bkoff_r))
      begin
        ifscnt <= IFS1_TIME ; 
      end
      else if (ifs1p & ifscnt == 4'b0000)
      begin
        ifscnt <= IFS2_TIME ; 
      end
      else if (ifscnt != 4'b0000)
      begin
        ifscnt <= ifscnt - 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : de_reg_proc
    if (rst)
    begin
      de <= 1'b0 ;
    end
    else
    begin
      if (ifs1p & itpend & carrier & tsm == TSM_IDLE_TCSMT)
      begin
        de <= 1'b1 ;
      end
      else if (tiack_r)
      begin
        de <= 1'b0 ;
      end
    end
  end

  always @(posedge clk)
  begin : eof_reg_proc
    if (rst)
    begin
      eof <= 1'b0 ;
    end
    else
    begin 
      case (DATAWIDTH)
        8 :
          begin
            if (whole & !(ncnt[0]))
            begin
              eof <= 1'b1 ; 
            end
            else
            begin
              eof <= 1'b0 ; 
            end
          end
        16 :
          begin
            if (whole & ((lastbe == 2'b11 & ncnt[1:0] == 2'b10) |
                         (lastbe == 2'b01 & ncnt[1:0] == 2'b00)))
            begin
              eof <= 1'b1 ; 
            end
            else
            begin
              eof <= 1'b0 ; 
            end
          end
        default :
          begin
            if (whole & ((lastbe == 4'b1111 & ncnt[2:0] == 3'b110) |
                         (lastbe == 4'b0111 & ncnt[2:0] == 3'b100) |
                         (lastbe == 4'b0011 & ncnt[2:0] == 3'b010) |
                         (lastbe == 4'b0001 & ncnt[2:0] == 3'b000)))
            begin
              eof <= 1'b1 ; 
            end 
            else
            begin
              eof <= 1'b0 ; 
            end
          end
      endcase
    end 
  end

  always @(coll or tsm or ncnt or bz or empty or eof or nopad)
  begin : bset_reg_proc
    if ((coll & (tsm == TSM_INFO |
                 tsm == TSM_PAD |
                 tsm == TSM_CRC)) |
        (tsm == TSM_PAD & nopad & !(ncnt[0])) |
        (tsm == TSM_PREA & bz & !(ncnt[0])) |
        (tsm == TSM_SFD & (ncnt[0])) |
        (tsm == TSM_INFO & empty & eof & nopad) |
        (tsm == TSM_IDLE_TCSMT))
    begin
      bset <= 1'b1 ; 
    end
    else
    begin
      bset <= 1'b0 ; 
    end 
  end

  always @(posedge clk)
  begin : bcnt_reg_proc
    if (rst)
    begin
      bcnt <= {7{1'b1}} ; 
      brel <= 7'b0000110 ; 
      bz   <= 1'b0 ; 
    end
    else
    begin
      if (bset)
      begin
        if(coll & tsm==TSM_INFO)
        begin		
          bcnt <= 7'b0000011;
        end
        else
        begin	      
          bcnt <= brel ; 
        end
      end
      else if ((ncnt[0]) & !bz)
      begin
        bcnt <= bcnt - 1 ; 
      end 

      case (tsm)
        TSM_IDLE_TCSMT :
          begin
            brel <= 7'b0000110 ; 
          end
        TSM_PREA :
          begin
            brel <= 7'b0000000 ; 
          end
        TSM_SFD :
          begin
            if (coll)
            begin
              brel <= 7'b0000011 ; 
            end
            else
            begin
              brel <= MIN_FRAME - 1 ; 
            end 
          end
        default :
          begin
            brel <= 7'b0000011 ; 
          end
      endcase 

      if (bset & brel != 7'b0000000)
      begin
        bz <= 1'b0 ; 
      end
      else if (bcnt == 7'b0000001 & (ncnt[0]) & !bz)
      begin
        bz <= 1'b1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : nopad_reg_proc
    if (rst)
    begin
      nopad <= 1'b0 ; 
    end
    else
    begin
      if ((tsm == TSM_INFO & bcnt == 7'b0000100 & !ac) |
          (tsm == TSM_INFO & bcnt == 7'b0000001 & ac)  |
          (tsm == TSM_PAD  & bcnt == 7'b0000100)       | (dpd & !ac))
      begin
        nopad <= 1'b1 ; 
      end
      else if (tsm == TSM_IDLE_TCSMT)
      begin
        nopad <= 1'b0 ; 
      end 
    end  
  end

  always @(tsm or
           itpend or
           bkoff_r or
           defer or
           ncnt or
           eof or
           empty or
           nopad)
  begin : nset_proc
    if ((tsm == TSM_IDLE_TCSMT & ~(itpend & !bkoff_r & !defer)) |
        (tsm == TSM_INFO & empty & eof) |
        (tsm == TSM_PAD & nopad & (ncnt[0])))
    begin
      nset <= 1'b1 ; 
    end
    else
    begin
      nset <= 1'b0 ; 
    end 
  end

  always @(posedge clk)
  begin : ncnt_reg_proc
    if (rst)
    begin
      ncnt <= {4{1'b0}} ; 
    end
    else
    begin
      if (nset)
      begin
        ncnt <= {4{1'b0}} ; 
      end
      else if (tsm != TSM_IDLE_TCSMT)
      begin
        ncnt <= ncnt + 1 ; 
      end 
    end  
  end

  always @(tsm or crc or itxd0_max or crcgen)
  begin : crc_proc
    if (tsm == TSM_PREA)
    begin
      crc_c <= {32{1'b1}} ; 
    end
    else if (crcgen)
    begin
      crc_c[0]  <= crc[28] ^
                   itxd0_max[3] ; 
      crc_c[1]  <= crc[28] ^ crc[29] ^
                   itxd0_max[2] ^ itxd0_max[3] ; 
      crc_c[2]  <= crc[28] ^ crc[29] ^ crc[30] ^
                   itxd0_max[1] ^ itxd0_max[2] ^ itxd0_max[3] ;
      crc_c[3]  <= crc[29] ^ crc[30] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[1] ^ itxd0_max[2] ;
      crc_c[4]  <= crc[0] ^ crc[28] ^ crc[30] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[1] ^ itxd0_max[3] ; 
      crc_c[5]  <= crc[1] ^ crc[28] ^ crc[29] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[2] ^ itxd0_max[3] ; 
      crc_c[6]  <= crc[2] ^ crc[29] ^ crc[30] ^
                   itxd0_max[1] ^ itxd0_max[2] ; 
      crc_c[7]  <= crc[3] ^ crc[28] ^ crc[30] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[1] ^ itxd0_max[3] ; 
      crc_c[8]  <= crc[4] ^ crc[28] ^ crc[29] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[2] ^ itxd0_max[3] ; 
      crc_c[9]  <= crc[5] ^ crc[29] ^ crc[30] ^
                   itxd0_max[1] ^ itxd0_max[2] ; 
      crc_c[10] <= crc[6] ^ crc[28] ^ crc[30] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[1] ^ itxd0_max[3] ; 
      crc_c[11] <= crc[7] ^ crc[28] ^ crc[29] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[2] ^ itxd0_max[3] ; 
      crc_c[12] <= crc[8] ^ crc[28] ^ crc[29] ^ crc[30] ^
                   itxd0_max[1] ^ itxd0_max[2] ^ itxd0_max[3] ; 
      crc_c[13] <= crc[9] ^ crc[29] ^ crc[30] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[1] ^ itxd0_max[2] ; 
      crc_c[14] <= crc[10] ^ crc[30] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[1] ; 
      crc_c[15] <= crc[11] ^ crc[31] ^
                   itxd0_max[0] ; 
      crc_c[16] <= crc[12] ^ crc[28] ^
                   itxd0_max[3] ; 
      crc_c[17] <= crc[13] ^ crc[29] ^
                   itxd0_max[2] ; 
      crc_c[18] <= crc[14] ^ crc[30] ^
                   itxd0_max[1] ; 
      crc_c[19] <= crc[15] ^ crc[31] ^
                   itxd0_max[0] ; 
      crc_c[20] <= crc[16] ; 
      crc_c[21] <= crc[17] ; 
      crc_c[22] <= crc[18] ^ crc[28] ^
                   itxd0_max[3] ; 
      crc_c[23] <= crc[19] ^ crc[28] ^ crc[29] ^
                   itxd0_max[2] ^ itxd0_max[3] ; 
      crc_c[24] <= crc[20] ^ crc[29] ^ crc[30] ^
                   itxd0_max[1] ^ itxd0_max[2] ; 
      crc_c[25] <= crc[21] ^ crc[30] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[1] ; 
      crc_c[26] <= crc[22] ^ crc[28] ^ crc[31] ^
                   itxd0_max[0] ^ itxd0_max[3] ; 
      crc_c[27] <= crc[23] ^ crc[29] ^
                   itxd0_max[2] ; 
      crc_c[28] <= crc[24] ^ crc[30] ^
                   itxd0_max[1] ; 
      crc_c[29] <= crc[25] ^ crc[31] ^
                   itxd0_max[0] ; 
      crc_c[30] <= crc[26] ; 
      crc_c[31] <= crc[27] ; 
    end
    else
    begin
      crc_c <= crc ; 
    end 
  end

  always @(posedge clk)
  begin : crc_reg_proc
    if (rst)
    begin
      crcgen  <= 1'b0 ; 
      crcsend <= 1'b0 ; 
      crc     <= {32{1'b1}} ; 
    end
    else
    begin
      crc <= crc_c ; 

      if (tsm == TSM_INFO | tsm == TSM_PAD)
      begin
        crcgen <= 1'b1 ; 
      end
      else
      begin
        crcgen <= 1'b0 ; 
      end 

      if (tsm == TSM_CRC)
      begin
        crcsend <= 1'b1 ; 
      end
      else
      begin
        crcsend <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : tstate_reg_proc
    if (rst)
    begin
      itprog   <= 1'b0 ; 
      itpend   <= 1'b0 ; 
      tprog    <= 1'b0 ; 
      preamble <= 1'b0 ; 
    end
    else
    begin
      if (tsm == TSM_INFO | tsm == TSM_PAD | tsm == TSM_CRC | 
          tsm == TSM_JAM)
      begin
        itprog <= 1'b1 ; 
      end
      else
      begin
        itprog <= 1'b0 ; 
      end 

      if (sofreq_r)
      begin
        itpend <= 1'b1 ; 
      end
      else
      begin
        itpend <= 1'b0 ; 
      end 

      if (tsm == TSM_PREA |
          tsm == TSM_SFD |
          tsm == TSM_INFO |
          tsm == TSM_PAD |
          tsm == TSM_CRC |
          tsm == TSM_JAM)
      begin
        tprog <= 1'b1 ; 
      end
      else
      begin
        tprog <= 1'b0 ; 
      end 

      if (tsm == TSM_PREA | tsm == TSM_SFD)
      begin
        preamble <= 1'b1 ; 
      end
      else
      begin
        preamble <= 1'b0 ; 
      end 
    end  
  end

  assign tpend = itpend ; 

  always @(posedge clk)
  begin : iti_reg_proc
    if (rst)
    begin
      iti     <= 1'b0 ; 
      tireq   <= 1'b0 ; 
      tiack_r <= 1'b0 ; 
    end
    else
    begin
      if (tsm == TSM_INT)
      begin
        iti <= 1'b1 ; 
      end
      else if (tiack)
      begin
        iti <= 1'b0 ; 
      end
 
      tireq   <= iti ; 
      tiack_r <= tiack ; 
    end  
  end

  always @(posedge clk)
  begin : iur_reg_proc
    if (rst)
    begin
      iur <= 1'b0 ; 
    end
    else
    begin
      if (itprog & empty & !whole)
      begin
        iur <= 1'b1 ; 
      end
      else if (tiack_r)
      begin
        iur <= 1'b0 ; 
      end 
    end  
  end

  assign ur = iur ; 

  always @(tsm or ramdata_r or pmux)
  begin : datamux_proc
    if (tsm == TSM_INFO)
    begin
      datamux_c <= ramdata_r ; 
    end
    else
    begin
      datamux_c <= pmux ; 
    end 
  end

  assign ncnt10 = ncnt[1:0] ; 

  assign ncnt20 = ncnt[2:0] ; 

  assign datamux_c_max = {dzero_max[DATAWIDTH_MAX + 1:DATAWIDTH],
                          datamux_c}; 

  always @(crc)
  begin : crcneg_proc
    begin : crcneg_loop
      integer i;
      for(i = 31; i >= 0; i = i - 1)
      begin
        crcneg_c[i] <= ~crc[31 - i] ; 
      end
    end 
  end

  always @(posedge clk)
  begin : txd_proc
    if (rst)
    begin
      txd_rise  <= {MIIWIDTH{1'b1}} ; 
      pmux      <= {DATAWIDTH{1'b1}} ; 
      itxd0     <= {MIIWIDTH{1'b1}} ; 
      ramdata_r <= {DATAWIDTH{1'b0}} ; 
    end
    else
    begin
      case (tsm_c)
        TSM_PAD :
          begin
            pmux <= PAD_PATTERN[63:64 - DATAWIDTH] ; 
          end
        TSM_JAM :
          begin
            pmux <= JAM_PATTERN[63:64 - DATAWIDTH] ; 
          end
        TSM_PREA :
          begin
            pmux <= PRE_PATTERN[63:64 - DATAWIDTH] ; 
          end
        TSM_SFD :
          begin
            pmux <= SFD_PATTERN[63:64 - DATAWIDTH] ; 
          end
        default :
          begin
            pmux <= {DATAWIDTH{1'b1}} ; 
          end
      endcase 

      case (DATAWIDTH)
        32 :
          begin
            case (ncnt20)
              3'b000 :
                begin
                  itxd0 <= datamux_c_max[3:0] ; 
                end
              3'b001 :
                begin
                  itxd0 <= datamux_c_max[7:4] ; 
                end
              3'b010 :
                begin
                  itxd0 <= datamux_c_max[11:8] ; 
                end
              3'b011 :
                begin
                  itxd0 <= datamux_c_max[15:12] ; 
                end
              3'b100 :
                begin
                  itxd0 <= datamux_c_max[19:16] ; 
                end
              3'b101 :
                begin
                  itxd0 <= datamux_c_max[23:20] ; 
                end
              3'b110 :
                begin
                  itxd0 <= datamux_c_max[27:24] ; 
                end
              default :
                begin
                  itxd0 <= datamux_c_max[31:28] ; 
                end
            endcase 
          end
        16 :
          begin
            case (ncnt10)
              2'b00 :
                begin
                  itxd0 <= datamux_c_max[3:0] ; 
                end
              2'b01 :
                begin
                  itxd0 <= datamux_c_max[7:4] ; 
                end
              2'b10 :
                begin
                  itxd0 <= datamux_c_max[11:8] ; 
                end
              default :
                begin
                  itxd0 <= datamux_c_max[15:12] ; 
                end
            endcase 
          end
        default :
          begin
            if (!(ncnt[0]))
            begin
              itxd0 <= datamux_c_max[3:0] ; 
            end
            else
            begin
              itxd0 <= datamux_c_max[7:4] ; 
            end 
          end
      endcase 

      if (re)
      begin
        ramdata_r <= ramdata ; 
      end 

      if (crcsend)
      begin
        case (ncnt)
          4'b0001 :
            begin
              txd_rise <= crcneg_c[3:0] ; 
            end
          4'b0010 :
            begin
              txd_rise <= crcneg_c[7:4] ; 
            end
          4'b0011 :
            begin
              txd_rise <= crcneg_c[11:8] ; 
            end
          4'b0100 :
            begin
              txd_rise <= crcneg_c[15:12] ; 
            end
          4'b0101 :
            begin
              txd_rise <= crcneg_c[19:16] ; 
            end
          4'b0110 :
            begin
              txd_rise <= crcneg_c[23:20] ; 
            end
          4'b0111 :
            begin
              txd_rise <= crcneg_c[27:24] ; 
            end
          default :
            begin
              txd_rise <= crcneg_c[31:28] ; 
            end
        endcase 
      end
      else
      begin
        txd_rise <= itxd0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : txen_reg_proc
    if (rst)
    begin
      txen1     <= 1'b0 ; 
      txen_rise <= 1'b0 ; 
    end
    else
    begin
      txen_rise <= txen1 ; 
      if (tsm == TSM_IDLE_TCSMT |
          tsm == TSM_INT |
          tsm == TSM_FLUSH)
      begin
        txen1 <= 1'b0 ; 
      end
      else
      begin
        txen1 <= 1'b1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : mii_fall_reg_proc
    txen <= txen_rise ; 
    txd  <= txd_rise;
  end

  assign txer = 1'b0 ; 

  always @(posedge clk)
  begin : bkoff_reg_proc
    if (rst)
    begin
      bkoff_r <= 1'b0 ; 
    end
    else
    begin
      if (bkoff)
      begin
        bkoff_r <= 1'b1 ; 
      end
      else if (tsm != TSM_JAM)
      begin
        bkoff_r <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : stopo_reg_proc
    if (rst)
    begin
      stop_r <= 1'b0 ; 
      stopo  <= 1'b0 ; 
    end
    else
    begin
      stop_r <= stopi;

      if (stop_r & tsm == TSM_IDLE_TCSMT & !itpend)
      begin
        stopo <= 1'b1 ; 
      end
      else
      begin
        stopo <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : cscnt_reg_proc
    if (rst)
    begin
      tcscnt   <= {8{1'b0}} ; 
      tcs      <= 1'b0 ; 
      tcsreq   <= 1'b0 ; 
      tcsack_r <= 1'b0 ; 
    end
    else
    begin
      if (tcscnt == 8'b00000000)
      begin
        tcscnt <= 8'b10000000 ; 
      end
      else
      begin
        tcscnt <= tcscnt - 1 ; 
      end 

      if (tcscnt == 8'b00000000)
      begin
        tcs <= 1'b1 ; 
      end
      else if (tcsack_r)
      begin
        tcs <= 1'b0 ; 
      end 

      if (tcs & !tcsack_r)
      begin
        tcsreq <= 1'b1 ; 
      end
      else if (tcsack_r)
      begin
        tcsreq <= 1'b0 ; 
      end 

      tcsack_r <= tcsack ; 

    end  
  end

  assign hnibble = (DATAWIDTH == 32) ? 4'b0111 :
                   (DATAWIDTH == 16) ? 4'b0011 :
                                       4'b0001 ; 

  assign itxd0zero_max = {(MIIWIDTH_MAX + 1){1'b0}} ; 

  assign itxd0_max = {itxd0zero_max[MIIWIDTH_MAX + 1:MIIWIDTH],
                      itxd0}; 

  assign dzero_max = {(DATAWIDTH_MAX + 1){1'b0}} ; 

endmodule



module TFIFO_V (
  clk,
  rst,
  ramwe,
  ramaddr,
  ramdata,
  fifowe,
  fifoeof,
  fifobe,
  fifodata,
  fifonf,
  fifocnf,
  fifoval,
  flev,
  ici,
  dpdi,
  aci,
  statadi,
  cachere,
  deo,
  lco,
  loo,
  nco,
  eco,
  csne,
  ico,
  uro,
  cco,
  statado,
  sofreq,
  eofreq,
  dpdo,
  aco,
  beo,
  eofad,
  wadg,
  tireq,
  winp,
  dei,
  lci,
  loi,
  nci,
  eci,
  uri,
  cci,
  radg,
  tiack,
  sf,
  fdp,
  tm,
  pbl,
  etiack,
  etireq,
  stopi,
  stopo
  );

  parameter DATAWIDTH = 32;
  parameter DATADEPTH  = 32;
  parameter FIFODEPTH  = 9;
  parameter CACHEDEPTH  = 1;

  `include "utility.v"

  input     clk; 
  input     rst;
 
  output    ramwe; 
  wire      ramwe;
  output    [FIFODEPTH - 1:0] ramaddr; 
  wire      [FIFODEPTH - 1:0] ramaddr;
  output    [DATAWIDTH - 1:0] ramdata; 
  wire      [DATAWIDTH - 1:0] ramdata;

  input     fifowe; 
  input     fifoeof; 
  input     [DATAWIDTH / 8 - 1:0] fifobe;
  input     [DATAWIDTH - 1:0] fifodata;
  output    fifonf; 
  reg       fifonf;
  output    fifocnf; 
  wire      fifocnf;
  output    fifoval; 
  reg       fifoval;
  output    [FIFODEPTH - 1:0] flev; 
  wire      [FIFODEPTH - 1:0] flev;
  
  input     ici;
  input     dpdi; 
  input     aci; 
  input     [DATADEPTH - 1:0] statadi; 

  input     cachere;
  output    deo; 
  wire      deo;
  output    lco; 
  wire      lco;
  output    loo; 
  wire      loo;
  output    nco; 
  wire      nco;
  output    eco; 
  wire      eco;
  output    csne; 
  wire      csne;
  output    ico; 
  wire      ico;
  output    uro; 
  wire      uro;
  output    [3:0] cco; 
  wire      [3:0] cco;
  output    [DATADEPTH - 1:0] statado; 
  wire      [DATADEPTH - 1:0] statado;

  output    sofreq; 
  wire      sofreq;
  output    eofreq; 
  reg       eofreq;
  output    dpdo; 
  wire      dpdo;
  output    aco; 
  wire      aco;
  output    [DATAWIDTH / 8 - 1:0] beo; 
  wire      [DATAWIDTH / 8 - 1:0] beo;
  output    [FIFODEPTH - 1:0] eofad; 
  reg       [FIFODEPTH - 1:0] eofad;
  output    [FIFODEPTH - 1:0] wadg; 
  reg       [FIFODEPTH - 1:0] wadg;

  input     tireq;
  input     winp;
  input     dei;
  input     lci; 
  input     loi; 
  input     nci;
  input     eci; 
  input     uri;
  input     [3:0] cci;
  input     [FIFODEPTH - 1:0] radg;
  output    tiack; 
  wire      tiack;

  input     sf; 
  input     fdp; 
  input     [2:0] tm; 
  input     [5:0] pbl; 

  input     etiack; 
  output    etireq; 
  reg       etireq;

  input     stopi; 
  output    stopo; 
  reg       stopo;


  parameter CCWIDTH = (3 + DATADEPTH + DATAWIDTH / 8 + FIFODEPTH); 
  reg       [CCWIDTH - 1:0] ccmem[(1'b1 << CACHEDEPTH) - 1:0]; 
  wire      ccwe; 
  wire      ccre; 
  reg       ccne; 
  reg       iccnf; 
  wire      [CACHEDEPTH - 1:0] ccwad_c; 
  reg       [CACHEDEPTH - 1:0] ccwad; 
  reg       [CACHEDEPTH - 1:0] ccrad; 
  reg       [CACHEDEPTH - 1:0] ccrad_r; 
  wire      [CCWIDTH - 1:0] ccdi; 
  wire      [CCWIDTH - 1:0] ccdo; 

  parameter CSWIDTH = (DATADEPTH + 11); 
  reg       [CSWIDTH - 1:0] csmem[(1'b1 << CACHEDEPTH) - 1:0]; 
  wire      cswe; 
  reg       csre; 
  reg       [CACHEDEPTH - 1:0] cswad; 
  wire      [CACHEDEPTH - 1:0] csrad_c; 
  reg       [CACHEDEPTH - 1:0] csrad; 
  reg       [CACHEDEPTH - 1:0] csrad_r; 
  wire      [CSWIDTH - 1:0] csdi; 
  wire      [CSWIDTH - 1:0] csdo; 
  wire      [DATADEPTH - 1:0] statad; 
  wire      ic; 
  reg       icsne;

  reg       tprog; 
  reg       tprog_r; 

  reg       winp_r; 
  reg       [FIFODEPTH_MAX - 1:0] tlev_c; 
  reg       tresh; 
  reg       [FIFODEPTH - 1:0] stat; 
  reg       [FIFODEPTH - 1:0] wad; 
  reg       [FIFODEPTH - 1:0] rad_c; 
  reg       [FIFODEPTH - 1:0] rad;
  reg       [FIFODEPTH - 1:0] radg_0_r;
  reg       [FIFODEPTH - 1:0] radg_r;
  reg       [FIFODEPTH - 1:0] sad; 
  wire      [FIFODEPTH - 1:0] eofad_bin; 
  reg       pblz; 
  reg       [FIFODEPTH_MAX - 1:0] sflev_c; 

  reg       tireq_r; 
  reg       tireq_r2; 

  reg       stop_r; 

  wire      [FIFODEPTH - 1:0] fone; 
  wire      [FIFODEPTH - 1:0] fzero;

  always @(posedge clk)
  begin : ccmem_reg_proc
    if (rst)
    begin : ccmem_reset
      integer i;
      for(i = ((1'b1 << CACHEDEPTH) - 1); i >= 0; i = i - 1)
      begin
        ccmem[i] <= {CCWIDTH{1'b0}};
      end
      ccrad_r <= {CACHEDEPTH{1'b0}} ;
    end
    else
    begin
      if (fifowe | fifoeof)
      begin
        ccmem[ccwad] <= ccdi ; 
      end 
      ccrad_r <= ccrad ;
    end  
  end

  assign ccwad_c = (fifoeof) ? ccwad + 1 : ccwad ; 

  always @(posedge clk)
  begin : ccaddr_reg_proc
    if (rst)
    begin
      ccwad <= {CACHEDEPTH{1'b0}} ; 
      ccrad <= {CACHEDEPTH{1'b0}} ; 
    end
    else
    begin
      ccwad <= ccwad_c ; 

      if (ccre)
      begin
        ccrad <= ccrad + 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : ccfe_reg_proc
    if (rst)
    begin
      iccnf <= 1'b1 ; 
      ccne  <= 1'b0 ; 
    end
    else
    begin
      if ((ccwad_c == ccrad) & ccwe)
      begin
        iccnf <= 1'b0 ; 
      end
      else if (ccre)
      begin
        iccnf <= 1'b1 ; 
      end 

      if (ccwad == ccrad & iccnf)
      begin
        ccne <= 1'b0 ; 
      end
      else
      begin
        ccne <= 1'b1 ; 
      end 
    end  
  end

  assign fifocnf = iccnf ; 

  assign ccdo = ccmem[ccrad_r] ; 

  assign ccdi = {ici, aci, dpdi, wad, fifobe, statadi} ; 

  assign ccwe = fifoeof ; 

  assign ccre = tireq_r & ~tireq_r2 ; 

  assign ic = ccdo[CCWIDTH - 1] ; 

  assign aco = ccdo[CCWIDTH - 2] ; 

  assign dpdo = ccdo[CCWIDTH - 3] ; 

  assign eofad_bin = ccdo[CCWIDTH - 4:CCWIDTH - 3 - FIFODEPTH] ; 

  always @(posedge clk)
  begin : eofad_reg_proc
    if (rst)
    begin
      eofad <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      eofad[FIFODEPTH - 1] <= eofad_bin[FIFODEPTH - 1] ; 
      begin : eofad_loop
        integer i;
        for(i = FIFODEPTH - 2; i >= 0; i = i - 1)
        begin
          eofad[i] <= eofad_bin[i] ^ eofad_bin[i + 1] ; 
        end
      end 
    end  
  end

  assign beo = ccdo[DATADEPTH + DATAWIDTH / 8 - 1:DATADEPTH] ; 

  assign statad = ccdo[DATADEPTH - 1:0] ; 

  always @(posedge clk)
  begin : csmem_reg_proc
    if (rst)
    begin : csmem_reset
      integer i;
      for(i = ((1'b1 << CACHEDEPTH) - 1); i >= 0; i = i - 1)
      begin
        csmem[i] <= {CSWIDTH{1'b0}};
      end
      csrad_r <= {CACHEDEPTH{1'b0}};
    end
    else
    begin
      csmem[cswad] <= csdi ; 
      csrad_r <= csrad ;
    end  
  end

  always @(posedge clk)
  begin : csaddr_reg_proc
    if (rst)
    begin
      cswad <= {CACHEDEPTH{1'b0}} ; 
      csrad <= {CACHEDEPTH{1'b0}} ; 
    end
    else
    begin
      if (cswe)
      begin
        cswad <= cswad + 1 ; 
      end 

      csrad <= csrad_c ; 
    end  
  end

  assign csrad_c = (csre) ? csrad + 1 : csrad ; 

  always @(posedge clk)
  begin : icsne_reg_proc
    if (rst)
    begin
      icsne <= 1'b0 ; 
    end
    else
    begin
      if (cswad == csrad | (csre & cswad == csrad_c))
      begin
        icsne <= 1'b0 ; 
      end
      else
      begin
        icsne <= 1'b1 ; 
      end 
    end  
  end

  assign csne = icsne;

  assign csdo = csmem[csrad_r] ; 

  assign csdi = {dei, lci, loi, nci, eci, ic, cci, uri, statad} ; 

  assign deo = csdo[CSWIDTH - 1] ; 

  assign lco = csdo[CSWIDTH - 2] ; 

  assign loo = csdo[CSWIDTH - 3] ; 

  assign nco = csdo[CSWIDTH - 4] ; 

  assign eco = csdo[CSWIDTH - 5] ; 

  assign ico = csdo[CSWIDTH - 6] ; 

  assign cco = csdo[CSWIDTH - 7:CSWIDTH - 10] ; 

  assign uro = csdo[CSWIDTH - 11] ; 

  assign statado = csdo[DATADEPTH - 1:0] ; 

  assign cswe = tireq_r & tprog ; 

  always @(posedge clk)
  begin : csre_reg_proc
    if (rst)
    begin
      csre <= 1'b0 ;
    end
    else
    begin
      csre <= cachere ;
    end
  end

  always @(posedge clk)
  begin : tprog_reg_proc
    if (rst)
    begin
      tprog <= 1'b0 ; 
      tprog_r <= 1'b0 ; 
    end
    else
    begin
      tprog_r <= tprog ; 
      if (tireq_r)
      begin
        tprog <= 1'b0 ; 
      end
      else if ((!sf & !tprog & !tireq_r & tresh) | ccne)
      begin
        tprog <= 1'b1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : eofreq_reg_proc
    if (rst)
    begin
      eofreq <= 1'b0 ; 
    end
    else
    begin
      if (tprog & ccne)
      begin
        eofreq <= 1'b1 ; 
      end
      else if (tireq_r)
      begin
        eofreq <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : tireq_reg_proc
    if (rst)
    begin
      tireq_r <= 1'b0 ; 
      tireq_r2 <= 1'b0 ; 
    end
    else
    begin
      tireq_r <= tireq ; 
      tireq_r2 <= tireq_r ; 
    end  
  end

  always @(posedge clk)
  begin : etireq_reg_proc
    if (rst)
    begin
      etireq <= 1'b0 ; 
    end
    else
    begin
      if (fifoeof)
      begin
        etireq <= 1'b1 ; 
      end
      else if (etiack)
      begin
        etireq <= 1'b0 ; 
      end 
    end  
  end

  assign tiack = tireq_r2 ; 

  assign sofreq = tprog ; 

  always @(posedge clk)
  begin : addr_reg_proc
    if (rst)
    begin
      wad    <= {FIFODEPTH{1'b0}} ; 
      wadg   <= {FIFODEPTH{1'b0}} ; 
      radg_0_r <= {FIFODEPTH{1'b0}} ;
      radg_r <= {FIFODEPTH{1'b0}} ;
      rad    <= {FIFODEPTH{1'b0}} ; 
      sad    <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      if (fifowe)
      begin
        wad <= wad + 1 ; 
      end

      wadg[FIFODEPTH - 1] <= wad[FIFODEPTH - 1] ; 
      begin : wadg_loop
        integer i;
        for(i = FIFODEPTH - 2; i >= 0; i = i - 1)
        begin
          wadg[i] <= wad[i] ^ wad[i + 1] ; 
        end
      end 

      radg_0_r <= radg ;
      radg_r <= radg_0_r ;

      rad <= rad_c ; 

      if (!tprog & tprog_r)
      begin
        sad <= eofad_bin ; 
      end  
    end  
  end

  always @(radg_r)
  begin : rad_proc
    reg[FIFODEPTH - 1:0] rad_v; 
    rad_v[FIFODEPTH - 1] = radg_r[FIFODEPTH - 1]; 
    begin : rad_loop
      integer i;
      for(i = FIFODEPTH - 2; i >= 0; i = i - 1)
      begin
        rad_v[i] = rad_v[i + 1] ^ radg_r[i]; 
      end
    end 
    rad_c = rad_v ; 
  end

  always @(posedge clk)
  begin : stat_reg_proc
    if (rst)
    begin
      stat <= {FIFODEPTH{1'b0}} ; 
    end
    else
    begin
      if ((!winp_r & !fdp & tprog & !tireq_r) | !tprog_r)
      begin
        stat <= wad - sad ; 
      end
      else
      begin
        stat <= wad - rad ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : winp_reg_proc
    if (rst)
    begin
      winp_r <= 1'b0 ; 
    end
    else
    begin
      winp_r <= winp ; 
    end  
  end

  always @(tm)
  begin : tresh_proc
    tlev_c <= {FIFODEPTH_MAX{1'b0}} ; 
    case (DATAWIDTH)
      8 :
        begin
          case (tm)
            3'b000, 3'b101, 3'b110 :
              begin
                tlev_c[10:0] <= 11'b00010000000 ; 
              end
            3'b001, 3'b111 :
              begin
                tlev_c[10:0] <= 11'b00100000000 ; 
              end
            3'b010 :
              begin
                tlev_c[10:0] <= 11'b01000000000 ; 
              end
            3'b011 :
              begin
                tlev_c[10:0] <= 11'b10000000000 ; 
              end
            default :
              begin
                tlev_c[10:0] <= 11'b00001000000 ; 
              end
          endcase 
        end
      16 :
        begin
          case (tm)
            3'b000, 3'b101, 3'b110 :
              begin
                tlev_c[10:0] <= 11'b00001000000 ; 
              end
            3'b001, 3'b111 :
              begin
                tlev_c[10:0] <= 11'b00010000000 ; 
              end
            3'b010 :
              begin
                tlev_c[10:0] <= 11'b00100000000 ; 
              end
            3'b011 :
              begin
                tlev_c[10:0] <= 11'b01000000000 ; 
              end
            default :
              begin
                tlev_c[10:0] <= 11'b00000100000 ; 
              end
          endcase 
        end
      default :
        begin
          case (tm)
            3'b000, 3'b101, 3'b110 :
              begin
                tlev_c[10:0] <= 11'b00000100000 ; 
              end
            3'b001, 3'b111 :
              begin
                tlev_c[10:0] <= 11'b00001000000 ; 
              end
            3'b010 :
              begin
                tlev_c[10:0] <= 11'b00010000000 ; 
              end
            3'b011 :
              begin
                tlev_c[10:0] <= 11'b00100000000 ; 
              end
            default :
              begin
                tlev_c[10:0] <= 11'b00000010000 ; 
              end
          endcase 
        end
    endcase 
  end

  always @(posedge clk)
  begin : tresh_reg_proc
    if (rst)
    begin
      tresh <= 1'b0 ; 
    end
    else
    begin
      if (stat >= tlev_c[FIFODEPTH - 1:0])
      begin
        tresh <= 1'b1 ; 
      end
      else
      begin
        tresh <= 1'b0 ; 
      end 
    end  
  end

  always @(pbl or pblz)
  begin : sflev_proc
    sflev_c[FIFODEPTH_MAX - 1:6] <= {(FIFODEPTH_MAX-6){1'b1}} ; 
    if (pblz)
    begin
      sflev_c[5:0] <= 6'b000000 ; 
    end
    else
    begin
      sflev_c[5:0] <= ~pbl ; 
    end 
  end

  always @(posedge clk)
  begin : fifoval_reg_proc
    if (rst)
    begin
      fifoval <= 1'b0 ; 
    end
    else
    begin
      if (stat <= sflev_c[FIFODEPTH - 1:0])
      begin
        fifoval <= 1'b1 ; 
      end
      else
      begin
        fifoval <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : pblz_reg_proc
    if (rst)
    begin
      pblz <= 1'b0 ; 
    end
    else
    begin
      if (pbl == 6'b000000)
      begin
        pblz <= 1'b1 ; 
      end
      else
      begin
        pblz <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : fifonf_reg_proc
    if (rst)
    begin
      fifonf <= 1'b1 ; 
    end
    else
    begin
      if ((stat == {fone[FIFODEPTH - 1:1], 1'b0} & fifowe) |
          (stat == fone))
      begin
        fifonf <= 1'b0 ; 
      end
      else
      begin
        fifonf <= 1'b1 ; 
      end 
    end  
  end

  assign flev = stat ; 

  assign ramaddr = wad ; 

  assign ramdata = fifodata ; 

  assign ramwe = fifowe ; 

  always @(posedge clk)
  begin : tstop_reg_proc
    if (rst)
    begin
      stop_r <= 1'b1 ; 
      stopo <= 1'b0 ; 
    end
    else
    begin
      stop_r <= stopi ; 

      if (stop_r & !ccne & !icsne & stat == fzero & !tprog)
      begin
        stopo <= 1'b1 ; 
      end
      else
      begin
        stopo <= 1'b0 ; 
      end 
    end  
  end

  assign fone = {FIFODEPTH{1'b1}} ; 

  assign fzero = {FIFODEPTH{1'b0}} ;

endmodule



module TLSM_V (
  clk,
  rst,
  fifonf,
  fifocnf,
  fifoval,
  fifolev,
  fifowe,
  fifoeof,
  fifobe,
  fifodata,
  ic,
  ac,
  dpd,
  statado,
  csne,
  lo,
  nc,
  lc,
  ec,
  de,
  ur,
  cc,
  statadi,
  cachere,
  dmaack,
  dmaeob,
  dmadatai,
  dmaaddr,
  dmareq,
  dmawr,
  dmacnt,
  dmaaddro,
  dmadatao,
  fwe,
  fdata,
  faddr,
  dsl,
  pbl,
  poll,
  dbadc,
  dbad,
  pollack,
  tcompack,
  tcomp,
  des,
  fbuf,
  stat,
  setp,
  tu,
  ft,
  stopi,
  stopo
  );

  parameter DATAWIDTH = 32;
  parameter DATADEPTH = 32;
  parameter FIFODEPTH  = 9;

  `include "utility.v"

  input     clk; 
  input     rst; 

  input     fifonf; 
  input     fifocnf; 
  input     fifoval;
  input     [FIFODEPTH - 1:0] fifolev; 
  output    fifowe; 
  wire      fifowe;
  output    fifoeof; 
  wire      fifoeof;
  output    [DATAWIDTH / 8 - 1:0] fifobe; 
  reg       [DATAWIDTH / 8 - 1:0] fifobe;
  output    [DATAWIDTH - 1:0] fifodata; 
  wire      [DATAWIDTH - 1:0] fifodata;

  output    ic; 
  reg       ic;
  output    ac; 
  reg       ac;
  output    dpd; 
  reg       dpd;
  output    [DATADEPTH - 1:0] statado; 
  wire      [DATADEPTH - 1:0] statado;

  input     csne; 
  input     lo; 
  input     nc;
  input     lc; 
  input     ec; 
  input     de;
  input     ur; 
  input     [3:0] cc;
  input     [DATADEPTH - 1:0] statadi; 
  output    cachere; 
  wire      cachere;
  
  input     dmaack;
  input     dmaeob;
  input     [DATAWIDTH - 1:0] dmadatai;
  input     [DATADEPTH - 1:0] dmaaddr;
  output    dmareq; 
  wire      dmareq;
  output    dmawr; 
  wire      dmawr;
  output    [FIFODEPTH_MAX - 1:0] dmacnt; 
  wire      [FIFODEPTH_MAX - 1:0] dmacnt;
  output    [DATADEPTH - 1:0] dmaaddro; 
  reg       [DATADEPTH - 1:0] dmaaddro;
  output    [DATAWIDTH - 1:0] dmadatao; 
  reg       [DATAWIDTH - 1:0] dmadatao;

  output    fwe; 
  wire      fwe;
  output    [ADDRWIDTH - 1:0] fdata; 
  wire      [ADDRWIDTH - 1:0] fdata;
  output    [ADDRDEPTH - 1:0] faddr; 
  wire      [ADDRDEPTH - 1:0] faddr;

  input     [4:0] dsl; 
  input     [5:0] pbl; 
  input     poll;
  input     dbadc; 
  input     [DATADEPTH - 1:0] dbad; 
  output    pollack; 
  wire      pollack;

  input     tcompack;
  output    tcomp; 
  wire      tcomp;
  output    des; 
  reg       des;
  output    fbuf; 
  reg       fbuf;
  output    stat; 
  reg       stat;
  output    setp; 
  reg       setp;
  output    tu; 
  reg       tu;
  output    [1:0] ft; 
  reg       [1:0] ft;

  input     stopi;
  output    stopo; 
  reg       stopo;


  wire      [DATAWIDTH_MAX + 1:0] dmadatai_max;
  reg       [DATAWIDTH_MAX - 1:0] dataimax_r; 
  wire      [1:0] dataimax_r10; 
  wire      [2:0] dmaaddr20; 
  reg       req_c; 
  reg       req; 
  reg       [2:0] req_r; 

  reg       idmareq; 
  wire      [31:0] datao32; 
  wire      [FIFODEPTH_MAX - 1:0] bsmax; 
  wire      [FIFODEPTH_MAX - 1:0] flmax; 
  wire      [FIFODEPTH - 1:0] flmax_sub; 
  wire      [FIFODEPTH_MAX - 1:0] blmax; 
  reg       fl_g_bs; 
  reg       fl_g_bl; 
  reg       bl_g_bs; 
  reg       pblz; 
  reg       buffetch; 
  reg       dmaack_r; 

  reg       [3:0] lsm_c; 
  reg       [3:0] lsm; 
  reg       [3:0] lsm_r; 
  reg       [2:0] csm_c; 
  reg       [2:0] csm; 
  reg       [2:0] lsmcnt; 
  reg       tsprog; 
  reg       [DATADEPTH - 1:0] statad; 
  wire      es_c; 
  reg       own_c; 
  reg       own; 
  reg       tch; 
  reg       ter; 
  reg       set; 
  reg       tls; 
  reg       tfs; 
  wire      [10:0] bs_c; 
  wire      [1:0] bs_c10; 
  reg       [10:0] bs1; 
  reg       [10:0] bs2; 
  reg       adwrite; 
  reg       [DATADEPTH - 1:0] bad; 
  reg       [DATADEPTH - 1:0] dad; 
  reg       dbadc_r; 
  wire      [31:0] tstat; 
  reg       lastdma; 
  reg       icachere; 
  reg       poll_r; 
  reg       [FIFODEPTH_MAX - 1:0] dmacnt_c;
  reg       [FIFODEPTH_MAX - 1:0] dmacnt_r;

  wire      [1:0] addsel16; 
  wire      [3:0] addsel32; 
  reg       [3:0] addv_c; 
  reg       [1:0] badd_c; 
  reg       [11:0] bcnt; 
  reg       ififowe; 
  wire      bufwe; 
  wire      firstb_c; 
  reg       firstb; 
  reg       [DATAWIDTH - 1:0] buf0_c; 
  reg       [DATAWIDTH * 2 - 9:0] buf_c; 
  reg       [DATAWIDTH * 2 - 9:0] buf_r; 
  reg       [3:0] buflev_c; 
  reg       [3:0] buflev; 
  reg       [DATAWIDTH / 8 - 1:0] firstbe; 
  reg       [DATAWIDTH / 8 - 1:0] lastbe; 
  reg       [DATAWIDTH / 8 - 1:0] be; 
  wire      [1:0] be10; 
  wire      [3:0] be30; 

  reg       itcomp; 
  reg       tcompack_r; 

  reg       ifwe; 
  reg       [ADDRDEPTH - 1:0] ifaddr; 

  reg       stop_r; 

  wire      [FIFODEPTH_MAX - 1:0] fzero_max; 
  wire      [DATAWIDTH_MAX + 1:0] dzero_max;
  wire      [DATAWIDTH_MAX * 2 - 7:0] buf_r_max; 
  wire      [DATAWIDTH_MAX * 2 - 7:0] bufzero_max;


  always @(posedge clk)
  begin : idmareq_reg_proc
    if (rst)
    begin
      idmareq <= 1'b0 ; 
    end
    else
    begin
      if (req_c)
      begin
        idmareq <= 1'b1 ; 
      end
      else if (dmaack & dmaeob)
      begin
        idmareq <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : cachere_reg_proc
    if (rst)
    begin
      icachere <= 1'b0 ; 
    end
    else
    begin
      if (itcomp & tcompack_r)
      begin
        icachere <= 1'b1 ; 
      end
      else
      begin
        icachere <= 1'b0 ; 
      end 
    end  
  end

  assign cachere = icachere ; 

  always @(lsm or
           csm or
           poll_r or
           dmaack or
           dmaeob or
           own_c or
           tch or
           bs1 or 
           bs2 or
           stop_r or
           lsmcnt or
           fifocnf or
           tsprog or
           lastdma or
           dbadc_r)
  begin : lsm_proc
    case (lsm)
      LSM_IDLE :
        begin
          if (!dbadc_r & !stop_r & fifocnf & (poll_r | (tsprog & dmaack & dmaeob)))
          begin
            lsm_c <= LSM_DES0 ; 
          end
          else
          begin
            lsm_c <= LSM_IDLE ; 
          end 
        end
      LSM_DES0 :
        begin
          if (dmaack & dmaeob & !tsprog)
          begin
            if (own_c)
            begin
              lsm_c <= LSM_DES1 ; 
            end
            else
            begin
              lsm_c <= LSM_IDLE ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_DES0 ; 
          end 
        end
      LSM_DES1 :
        begin
          if (dmaack & dmaeob & !tsprog)
          begin
            lsm_c <= LSM_DES2 ; 
          end
          else
          begin
            lsm_c <= LSM_DES1 ; 
          end 
        end
      LSM_DES2 :
        begin
          if (dmaack & dmaeob & !tsprog)
          begin
            if (bs1 == 11'b00000000000 | csm == CSM_IDLE)
            begin
              lsm_c <= LSM_DES3 ; 
            end
            else
            begin
              lsm_c <= LSM_BUF1 ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_DES2 ; 
          end 
        end
      LSM_DES3 :
        begin
          if (dmaack & dmaeob & !tsprog)
          begin
            if (bs2 == 11'b00000000000 | tch | csm == CSM_IDLE)
            begin
              lsm_c <= LSM_NXT ; 
            end
            else
            begin
              lsm_c <= LSM_BUF2 ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_DES3 ; 
          end 
        end
      LSM_BUF1 :
        begin
          if (!tsprog & dmaack & dmaeob & lastdma)
          begin
            lsm_c <= LSM_DES3 ; 
          end
          else
          begin
            lsm_c <= LSM_BUF1 ; 
          end 
        end
      LSM_BUF2 :
        begin
          if (!tsprog & dmaack & dmaeob & lastdma)
          begin
            lsm_c <= LSM_NXT ; 
          end
          else
          begin
            lsm_c <= LSM_BUF2 ; 
          end 
        end
      LSM_NXT :
        begin
          if (lsmcnt == 3'b000)
          begin
            if (csm == CSM_L | csm == CSM_FL)
            begin
              if (stop_r | !fifocnf)
              begin
                lsm_c <= LSM_IDLE ; 
              end
              else
              begin
                lsm_c <= LSM_DES0 ; 
              end 
            end
            else
            begin
              lsm_c <= LSM_STAT ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_NXT ; 
          end 
        end
      default :
        begin
          if (dmaack & dmaeob & !tsprog)
          begin
            if (stop_r)
            begin
              lsm_c <= LSM_IDLE ; 
            end
            else
            begin
              lsm_c <= LSM_DES0 ; 
            end 
          end
          else
          begin
            lsm_c <= LSM_STAT ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : lsm_reg_proc
    if (rst)
    begin
      lsm <= LSM_IDLE ; 
      lsm_r <= LSM_IDLE ; 
    end
    else
    begin
      lsm <= lsm_c ; 
      lsm_r <= lsm ; 
    end  
  end

  always @(csm or lsm or tfs or tls or own or set or bs1 or bs2)
  begin : csm_proc
    case (csm)
      CSM_IDLE :
        begin
          if (lsm == LSM_DES2)
          begin
            if (!set & tfs & tls)
            begin
              csm_c <= CSM_FL ; 
            end
            else if (!set & tfs & !tls)
            begin
              csm_c <= CSM_F ; 
            end
            else if (set & !tfs & !tls)
            begin
              csm_c <= CSM_SET ; 
            end
            else
            begin
              csm_c <= CSM_IDLE ; 
            end 
          end
          else
          begin
            csm_c <= CSM_IDLE ; 
          end 
        end
      CSM_FL :
        begin
          if (lsm == LSM_DES0 | lsm == LSM_IDLE)
          begin
            csm_c <= CSM_IDLE ; 
          end
          else if (lsm == LSM_DES2 &
                   bs1 == 11'b00000000000 &
                   bs2 == 11'b00000000000)
          begin
            csm_c <= CSM_BAD ; 
          end
          else
          begin
            csm_c <= CSM_FL ; 
          end 
        end
      CSM_F :
        begin
          if (tls)
          begin
            csm_c <= CSM_L ; 
          end
          else if (lsm == LSM_DES1 & !tfs)
          begin
            csm_c <= CSM_I ; 
          end
          else
          begin
            csm_c <= CSM_F ; 
          end 
        end
      CSM_L :
        begin
          if (lsm == LSM_DES0 | lsm == LSM_IDLE)
          begin
            csm_c <= CSM_IDLE ; 
          end
          else
          begin
            csm_c <= CSM_L ; 
          end 
        end
      CSM_SET :
        begin
          if (lsm == LSM_DES0 | lsm == LSM_IDLE)
          begin
            csm_c <= CSM_IDLE ; 
          end
          else
          begin
            csm_c <= CSM_SET ; 
          end 
        end
      CSM_I :
        begin
          if (tls)
          begin
            csm_c <= CSM_L ; 
          end
          else
          begin
            csm_c <= CSM_I ; 
          end 
        end
      default :
        begin
          if (lsm == LSM_NXT)
          begin
            csm_c <= CSM_IDLE ; 
          end
          else
          begin
            csm_c <= CSM_BAD ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : csm_reg_proc
    if (rst)
    begin
      csm <= CSM_IDLE ; 
    end
    else
    begin
      csm <= csm_c ; 
    end  
  end

  always @(posedge clk)
  begin : lsmcnt_reg_proc
    if (rst)
    begin
      lsmcnt <= {3{1'b1}} ; 
    end
    else
    begin
      if (lsm == LSM_NXT)
      begin
        lsmcnt <= lsmcnt - 1 ; 
      end
      else
      begin
        lsmcnt <= {3{1'b1}} ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : poll_reg_proc
    if (rst)
    begin
      poll_r <= 1'b0 ; 
    end
    else
    begin
      if (poll)
      begin
        poll_r <= 1'b1 ; 
      end
      else if (!dbadc_r)
      begin
        poll_r <= 1'b0 ; 
      end 
    end  
  end

  assign pollack = poll_r ; 

  always @(own or dmaack or dmaeob or lsm or dmadatai_max or tsprog)
  begin : own_proc
    if (dmaack & dmaeob & lsm == LSM_DES0 & !tsprog)
    begin
      own_c <= dmadatai_max[DATAWIDTH - 1] ; 
    end
    else
    begin
      own_c <= own ; 
    end 
  end

  always @(posedge clk)
  begin : own_reg_proc
    if (rst)
    begin
      own <= 1'b1 ; 
    end
    else
    begin
      own <= own_c ; 
    end  
  end

  always @(posedge clk)
  begin : des1_reg_proc
    reg ft22; 
    if (rst)
    begin
      ft22 = 1'b0; 
      tls <= 1'b0 ; 
      tfs <= 1'b0 ; 
      set <= 1'b0 ; 
      ac  <= 1'b0 ; 
      ter <= 1'b0 ; 
      tch <= 1'b0 ; 
      dpd <= 1'b0 ; 
      ic  <= 1'b0 ; 
      bs2 <= {11{1'b0}} ; 
      bs1 <= {11{1'b0}} ; 
      ft  <= {2{1'b0}} ; 
    end
    else
    begin
      if (lsm == LSM_DES1 & dmaack & !tsprog)
      begin
        case (DATAWIDTH)
          8 :
            begin
              case (dmaaddr20)
                3'b000, 3'b100 :
                  begin
                    bs1[7:0] <= dmadatai_max[7:0] ; 
                  end
                3'b001, 3'b101 :
                  begin
                    bs1[10:8] <= dmadatai_max[2:0] ; 
                    bs2[4:0]  <= dmadatai_max[7:3] ; 
                  end
                3'b010, 3'b110 :
                  begin
                    bs2[10:5] <= dmadatai_max[5:0] ; 
                    dpd       <= dmadatai_max[7] ; 
                    ft22 = dmadatai_max[6]; 
                  end
                default :
                  begin
                    ic  <= dmadatai_max[7] ; 
                    tls <= dmadatai_max[6] ; 
                    tfs <= dmadatai_max[5] ; 
                    set <= dmadatai_max[3] ; 
                    ac  <= dmadatai_max[2] ; 
                    ter <= dmadatai_max[1] ; 
                    tch <= dmadatai_max[0] ; 
                    if (dmadatai_max[3])
                    begin
                      ft <= {dmadatai_max[4], ft22} ; 
                    end 
                  end
              endcase 
            end
          16 :
            begin
              case (dmaaddr20)
                3'b000, 3'b100 :
                  begin
                    bs1[10:0] <= dmadatai_max[10:0] ; 
                    bs2[4:0] <= dmadatai_max[15:11] ; 
                  end
                default :
                  begin
                    bs2[10:5] <= dmadatai_max[5:0] ; 
                    ic  <= dmadatai_max[15] ; 
                    tls <= dmadatai_max[14] ; 
                    tfs <= dmadatai_max[13] ; 
                    set <= dmadatai_max[11] ; 
                    ac  <= dmadatai_max[10] ; 
                    ter <= dmadatai_max[9] ; 
                    tch <= dmadatai_max[8] ; 
                    dpd <= dmadatai_max[7] ; 
                    if (dmadatai_max[11])
                    begin
                      ft <= {dmadatai_max[12], dmadatai_max[6]} ; 
                    end 
                  end
              endcase 
            end
          default :
            begin
              ic  <= dmadatai_max[31] ; 
              tls <= dmadatai_max[30] ; 
              tfs <= dmadatai_max[29] ; 
              set <= dmadatai_max[27] ; 
              ac  <= dmadatai_max[26] ; 
              ter <= dmadatai_max[25] ; 
              tch <= dmadatai_max[24] ; 
              dpd <= dmadatai_max[23] ; 
              bs2 <= dmadatai_max[21:11] ; 
              bs1 <= dmadatai_max[10:0] ; 
              if (dmadatai_max[27])
              begin
                ft <= {dmadatai_max[28], dmadatai_max[22]} ; 
              end 
            end
        endcase 
      end 
    end  
  end

  always @(posedge clk)
  begin : adwrite_reg_proc
    if (rst)
    begin
      adwrite <= 1'b0 ; 
    end
    else
    begin
      if (dmaack & dmaeob & !tsprog)
      begin
        adwrite <= 1'b1 ; 
      end
      else
      begin
        adwrite <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : dbadc_reg_proc
    if (rst)
    begin
      dbadc_r <= 1'b0 ; 
    end
    else
    begin
      dbadc_r <= dbadc ; 
    end  
  end

  always @(posedge clk)
  begin : dad_reg_proc
    if (rst)
    begin
      dad <= {DATADEPTH{1'b1}} ; 
    end
    else
    begin
      if (dbadc_r)
      begin
        dad <= dbad ; 
      end
      else if (adwrite)
      begin
        case (lsm_r)
          LSM_DES3 :
            begin
              if (ter)
              begin
                dad <= dbad ; 
              end
              else if (tch)
              begin
                dad <= dataimax_r[DATADEPTH - 1:0] ; 
              end
              else
              begin
                dad <= dmaaddr + ({dsl, 2'b00}) ; 
              end 
            end
          LSM_DES0 :
            begin
              if (own)
              begin
                dad <= dmaaddr ; 
              end 
            end
          LSM_DES2 :
            begin
              dad <= dmaaddr ; 
            end
          LSM_DES1 :
            begin
              dad <= dmaaddr ; 
            end
          default :
            begin
            end
        endcase 
      end 
    end  
  end

  always @(posedge clk)
  begin : bad_reg_proc
    if (rst)
    begin
      bad <= {DATADEPTH{1'b1}} ; 
    end
    else
    begin
      if (adwrite)
      begin
        if (lsm_r == LSM_DES2 | lsm_r == LSM_DES3)
        begin
          case (DATAWIDTH)
            8 :
              begin
                bad <= dataimax_r[DATADEPTH - 1:0] ; 
              end
            16 :
              begin
                bad <= {dataimax_r[DATADEPTH - 1:1], 1'b0} ; 
              end
            default :
              begin
                bad <= {dataimax_r[DATADEPTH - 1:2], 2'b00} ; 
              end
          endcase 
        end
        else
        begin
          bad <= dmaaddr ; 
        end 
      end 
    end  
  end

  always @(posedge clk)
  begin : stataddr_reg_proc
    if (rst)
    begin
      statad <= {DATADEPTH{1'b1}} ; 
    end
    else
    begin
      if (lsm_r == LSM_DES0 & adwrite & own)
      begin
        statad <= dad ; 
      end 
    end  
  end

  assign statado = statad ; 

  assign bs_c = (lsm_r == LSM_DES2) ? bs1 : bs2 ; 

  assign addsel16 = {dataimax_r[0], bs_c[0]} ; 

  assign addsel32 = {dataimax_r10, bs_c10} ; 

  always @(addsel16 or addsel32)
  begin : badd_proc
    case (DATAWIDTH)
      8 :
        begin
          badd_c <= 2'b00 ; 
        end
      16 :
        begin
          if (addsel16 == 2'b01 |
              addsel16 == 2'b10 |
              addsel16 == 2'b11)
          begin
            badd_c <= 2'b01 ; 
          end
          else
          begin
            badd_c <= 2'b00 ; 
          end 
        end
      default :
        begin
          case (addsel32)
            4'b0000 :
              begin
                badd_c <= 2'b00 ; 
              end
            4'b1011, 4'b1110, 4'b1111 :
              begin
                badd_c <= 2'b10 ; 
              end
            default :
              begin
                badd_c <= 2'b01 ; 
              end
          endcase 
        end
    endcase 
  end

  always @(posedge clk)
  begin : bcnt_reg_proc
    if (rst)
    begin
      bcnt <= {12{1'b1}} ; 
    end
    else
    begin
      case (DATAWIDTH)
        8 :
          begin
            if (lsm_r == LSM_DES2 | lsm_r == LSM_DES3)
            begin
              bcnt <= {1'b0, bs_c} ; 
            end
            else if (dmaack & !tsprog)
            begin
              bcnt <= bcnt - 1 ; 
            end 
          end
        16 :
          begin
            if (lsm_r == LSM_DES2 | lsm_r == LSM_DES3)
            begin
              bcnt <= {(({1'b0, bs_c[10:1]}) + badd_c), 1'b0} ; 
            end
            else if (dmaack & !tsprog)
            begin
              bcnt <= {(bcnt[11:1] - 1), 1'b0} ; 
            end 
          end
        default :
          begin
            if (lsm_r == LSM_DES2 | lsm_r == LSM_DES3)
            begin
              bcnt <= {(({1'b0, bs_c[10:2]}) + badd_c), 2'b00} ; 
            end
            else if (dmaack & !tsprog)
            begin
              bcnt <= {(bcnt[11:2] - 1), 2'b00} ; 
            end 
          end
      endcase 
    end  
  end


  assign bs_c10 = bs_c[1:0] ; 

  assign dataimax_r10 = dataimax_r[1:0] ; 

  always @(posedge clk)
  begin : firstbe_reg_proc
    if (rst)
    begin
      firstbe <= {(DATAWIDTH/8){1'b1}} ; 
    end
    else
    begin
      if (lsm_r == LSM_DES2 | lsm_r == LSM_DES3)
      begin
        case (DATAWIDTH)
          8 :
            begin
              firstbe <= 1'b1 ; 
            end
          16 :
            begin
              if (dataimax_r[0])
              begin
                firstbe <= 2'b10 ; 
              end
              else
              begin
                firstbe <= 2'b11 ; 
              end 
            end
          default :
            begin
              case (dataimax_r10)
                2'b00 :
                  begin
                    firstbe <= 4'b1111 ; 
                  end
                2'b01 :
                  begin
                    firstbe <= 4'b1110 ; 
                  end
                2'b10 :
                  begin
                    firstbe <= 4'b1100 ; 
                  end
                default :
                  begin
                    firstbe <= 4'b1000 ; 
                  end
              endcase 
            end
        endcase 
      end 
    end  
  end

  always @(posedge clk)
  begin : lastbe_reg_proc
    if (rst)
    begin
      lastbe <= {(DATAWIDTH/8){1'b1}} ; 
    end
    else
    begin
      if (lsm_r == LSM_DES2 | lsm_r == LSM_DES3)
      begin
        case (DATAWIDTH)
          8 :
            begin
              lastbe <= 1'b1 ; 
            end
          16 :
            begin
              if ((!(dataimax_r[0]) & !(bs_c[0])) |
                   ((dataimax_r[0]) &  (bs_c[0])))
              begin
                lastbe <= 2'b11 ; 
              end
              else
              begin
                lastbe <= 2'b01 ; 
              end 
            end
          default :
            begin
              case (dataimax_r10)
                2'b00 :
                  begin
                    case (bs_c10)
                      2'b00 :
                        begin
                          lastbe <= 4'b1111 ; 
                        end
                      2'b01 :
                        begin
                          lastbe <= 4'b0001 ; 
                        end
                      2'b10 :
                        begin
                          lastbe <= 4'b0011 ; 
                        end
                      default :
                        begin
                          lastbe <= 4'b0111 ; 
                        end
                    endcase 
                  end
                2'b01 :
                  begin
                    case (bs_c10)
                      2'b00 :
                        begin
                          lastbe <= 4'b0001 ; 
                        end
                      2'b01 :
                        begin
                          lastbe <= 4'b0011 ; 
                        end
                      2'b10 :
                        begin
                          lastbe <= 4'b0111 ; 
                        end
                      default :
                        begin
                          lastbe <= 4'b1111 ; 
                        end
                    endcase 
                  end
                2'b10 :
                  begin
                    case (bs_c10)
                      2'b00 :
                        begin
                          lastbe <= 4'b0011 ; 
                        end
                      2'b01 :
                        begin
                          lastbe <= 4'b0111 ; 
                        end
                      2'b10 :
                        begin
                          lastbe <= 4'b1111 ; 
                        end
                      default :
                        begin
                          lastbe <= 4'b0001 ; 
                        end
                    endcase 
                  end
                default :
                  begin
                    case (bs_c10)
                      2'b00 :
                        begin
                          lastbe <= 4'b0111 ; 
                        end
                      2'b01 :
                        begin
                          lastbe <= 4'b1111 ; 
                        end
                      2'b10 :
                        begin
                          lastbe <= 4'b0001 ; 
                        end
                      default :
                        begin
                          lastbe <= 4'b0011 ; 
                        end
                    endcase 
                  end
              endcase 
            end
        endcase 
      end 
    end  
  end

  always @(posedge clk)
  begin : tfwe_reg_proc
    if (rst)
    begin
      ififowe <= 1'b0 ; 
    end
    else
    begin
      if (((DATAWIDTH == 8 & buflev_c >= 4'b0001 & bufwe) |
           (DATAWIDTH ==16 & buflev_c >= 4'b0010 & bufwe) |
           (DATAWIDTH ==32 & buflev_c >= 4'b0100 & bufwe) |
           (buflev_c != 4'b0000 & lsm == LSM_NXT & 
            (csm == CSM_L | csm == CSM_FL))) & fifonf)
      begin
        ififowe <= 1'b1 ; 
      end
      else
      begin
        ififowe <= 1'b0 ; 
      end 
    end  
  end

  assign fifoeof = ((csm == CSM_L | csm == CSM_FL) &
                    lsm == LSM_NXT & lsmcnt == 3'b001) ? 1'b1 : 1'b0 ; 

  assign fifowe = ififowe ; 

  assign firstb_c = (bufwe)                             ? 1'b0 :
                    (lsm == LSM_DES2 | lsm == LSM_DES3) ? 1'b1 :
                                                        firstb ; 

  always @(firstb or firstbe or lastbe or dmaeob or lastdma)
  begin : be_proc
    if (dmaeob & lastdma)
    begin
      be <= lastbe ; 
    end
    else if (firstb)
    begin
      be <= firstbe ; 
    end
    else
    begin
      be <= {(DATAWIDTH/8){1'b1}} ; 
    end 
  end

  always @(be or be30 or dmadatai_max)
  begin : tbuf0_proc
    reg[15:0] buf0_16; 
    reg[31:0] buf0_32; 
    buf0_c <= {DATAWIDTH{1'b0}} ; 
    case (DATAWIDTH)
      8 :
        begin
          buf0_c <= dmadatai_max[7:0]; 
        end
      16 :
        begin
          buf0_16 = {16{1'b0}}; 
          if (be == 2'b10)
          begin
            buf0_16[7:0] = dmadatai_max[15:8]; 
          end
          else
          begin
            buf0_16 = dmadatai_max[15:0]; 
          end 
          buf0_c <= buf0_16 ; 
        end
      default :
        begin
          buf0_32 = {32{1'b0}}; 
          case (be30)
            4'b1110 :
              begin
                buf0_32[23:0] = dmadatai_max[31:8]; 
              end
            4'b1100 :
              begin
                buf0_32[15:0] = dmadatai_max[31:16]; 
              end
            4'b1000 :
              begin
                buf0_32[7:0] = dmadatai_max[31:24]; 
              end
            default :
              begin
                buf0_32 = dmadatai_max[31:0]; 
              end
          endcase 
          buf0_c <= buf0_32 ; 
        end
    endcase 
  end

  always @(buflev or buf_r_max or buf0_c or bufwe or ififowe)
  begin : tbuf_proc
    reg[23:0] buf_16; 
    reg[55:0] buf_32; 
    case (DATAWIDTH)
      8 :
        begin
          buf_c <= buf0_c ; 
        end
      16 :
        begin
          buf_16 = buf_r_max[DATAWIDTH * 2 - 9:0]; 
          if (bufwe)
          begin
            case (buflev)
              4'b0000 :
                begin
                  buf_16[15:0] = buf0_c; 
                end
              4'b0001 :
                begin
                  buf_16[23:8] = buf0_c; 
                end
              4'b0010 :
                begin
                  buf_16[15:0] = buf0_c; 
                end
              default :
                begin
                  buf_16[23:8] = buf0_c; 
                  buf_16[7:0] = buf_r_max[23:16]; 
                end
            endcase 
          end
          else if (ififowe)
          begin
            buf_16 = {buf_r_max[23:8], buf_r_max[23:16]}; 
          end 
          buf_c <= buf_16 ; 
        end
      default :
        begin
          buf_32 = buf_r_max[DATAWIDTH * 2 - 9:0]; 
          if (bufwe)
          begin
            case (buflev)
              4'b0000 :
                begin
                  buf_32[31:0] = buf0_c; 
                end
              4'b0001 :
                begin
                  buf_32[39:8] = buf0_c; 
                end
              4'b0010 :
                begin
                  buf_32[47:16] = buf0_c; 
                end
              4'b0011 :
                begin
                  buf_32[55:24] = buf0_c; 
                end
              4'b0100 :
                begin
                  buf_32[31:0] = buf0_c; 
                end
              4'b0101 :
                begin
                  buf_32[39:8] = buf0_c; 
                  buf_32[7:0] = buf_r_max[39:32]; 
                end
              4'b0110 :
                begin
                  buf_32[47:16] = buf0_c; 
                  buf_32[15:0] = buf_r_max[47:32]; 
                end
              default :
                begin
                  buf_32[55:24] = buf0_c; 
                  buf_32[23:0] = buf_r_max[55:32]; 
                end
            endcase 
          end
          else if (ififowe)
          begin
            buf_32 = {buf_r_max[55:24], buf_r_max[55:32]}; 
          end 
          buf_c <= buf_32 ; 
        end
    endcase 
  end

  assign bufwe = (dmaack & !set & fifonf & !tsprog &
                  (lsm == LSM_BUF1 | lsm == LSM_BUF2)) ? 1'b1 : 1'b0 ; 
 
  assign fifodata = buf_r_max[DATAWIDTH - 1:0] ; 

  assign be10 = (DATAWIDTH == 16) ? be : {2{1'b1}} ; 

  assign be30 = (DATAWIDTH == 32) ? be : {4{1'b1}} ; 

  always @(be10 or be30)
  begin : addv_proc
    case (DATAWIDTH)
      8 :
        begin
          addv_c <= 4'b0000 ; 
        end
      16 :
        begin
          case (be10)
            2'b01, 2'b10 :
              begin
                addv_c <= 4'b0001 ; 
              end
            default :
              begin
                addv_c <= 4'b0010 ; 
              end
          endcase 
        end
      default :
        begin
          case (be30)
            4'b0001, 4'b1000 :
              begin
                addv_c <= 4'b0001 ; 
              end
            4'b0011, 4'b1100 :
              begin
                addv_c <= 4'b0010 ; 
              end
            4'b0111, 4'b1110 :
              begin
                addv_c <= 4'b0011 ; 
              end
            default :
              begin
                addv_c <= 4'b0100 ; 
              end
          endcase 
        end
    endcase 
  end

  always @(buflev or bufwe or ififowe or addv_c)
  begin : buflev_proc
    case (DATAWIDTH)
      8 :
        begin
          if (bufwe)
          begin
            buflev_c <= 4'b0001 ; 
          end
          else if (ififowe)
          begin
            buflev_c <= 4'b0000 ; 
          end
          else
          begin
            buflev_c <= buflev ; 
          end 
        end
      16 :
        begin
          if (bufwe)
          begin
            buflev_c <= ({buflev[3:2], 1'b0, buflev[0]}) + addv_c ; 
          end
          else if (ififowe & (buflev[1]))
          begin
            buflev_c <= {buflev[3:2], 1'b0, buflev[0]} ; 
          end
          else if (ififowe & !(buflev[1]))
          begin
            buflev_c <= {buflev[3:1], 1'b0} ; 
          end
          else
          begin
            buflev_c <= buflev ; 
          end 
        end
      default :
        begin
          if (bufwe)
          begin
            buflev_c <= ({buflev[3:3], 1'b0, buflev[1:0]}) + addv_c ; 
          end
          else if (ififowe & (buflev[2]))
          begin
            buflev_c <= {buflev[3:3], 1'b0, buflev[1:0]} ; 
          end
          else if (ififowe & !(buflev[2]))
          begin
            buflev_c <= {buflev[3:2], 2'b00} ; 
          end
          else
          begin
            buflev_c <= buflev ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : buf_reg_proc
    if (rst)
    begin
      buflev <= {4{1'b0}} ; 
      firstb <= 1'b1 ; 
      buf_r  <= {(DATAWIDTH*2){1'b0}} ; 
    end
    else
    begin
      buflev <= buflev_c ; 
      firstb <= firstb_c ; 
      buf_r  <= buf_c ; 
    end  
  end

  always @(posedge clk)
  begin : lbe_reg_proc
    if (rst)
    begin
      fifobe <= {(DATAWIDTH/8){1'b1}} ; 
    end
    else
    begin
      if (ififowe)
      begin
        case (DATAWIDTH)
          8 :
            begin
              fifobe <= 1'b1 ; 
            end
          16 :
            begin
              case (buflev)
                4'b0001 :
                  begin
                    fifobe <= 2'b01 ; 
                  end
                default :
                  begin
                    fifobe <= 2'b11 ; 
                  end
              endcase 
            end
          default :
            begin
              case (buflev)
                4'b0001 :
                  begin
                    fifobe <= 4'b0001 ; 
                  end
                4'b0010 :
                  begin
                    fifobe <= 4'b0011 ; 
                  end
                4'b0011 :
                  begin
                    fifobe <= 4'b0111 ; 
                  end
                default :
                  begin
                    fifobe <= 4'b1111 ; 
                  end
              endcase 
            end
        endcase 
      end 
    end  
  end

  assign es_c = ur | lc | lo | nc | ec ; 

  assign tstat = {1'b0, TDES0_RV[30:16], 
                  es_c, TDES0_RV[14:12], lo, nc, lc,
                  ec,   TDES0_RV[7],
                  cc,   TDES0_RV[2], ur, de};

  assign datao32 = (tsprog) ? tstat : (set) ? SET0_RV : TDES0_RV ; 

  always @(posedge clk)
  begin : dataimax_reg_proc
    if (rst)
    begin
      dataimax_r <= {DATADEPTH_MAX{1'b1}} ; 
    end
    else
    begin
      case (DATAWIDTH)
        8 :
          begin
            case (dmaaddr20)
              3'b000, 3'b100 :
                begin
                  dataimax_r[7:0] <= dmadatai_max[DATAWIDTH-1:0] ; 
                end
              3'b001, 3'b101 :
                begin
                  dataimax_r[15:8] <= dmadatai_max[DATAWIDTH-1:0] ; 
                end
              3'b010, 3'b110 :
                begin
                  dataimax_r[23:16] <= dmadatai_max[DATAWIDTH-1:0] ; 
                end
              default :
                begin
                  dataimax_r[31:24] <= dmadatai_max[DATAWIDTH-1:0] ; 
                end
            endcase 
          end
        16 :
          begin
            if (!(dmaaddr[1]))
            begin
              dataimax_r[15:0] <= dmadatai_max[DATAWIDTH-1:0] ; 
            end
            else
            begin
              dataimax_r[31:16] <= dmadatai_max[DATAWIDTH-1:0] ; 
            end 
          end
        default :
          begin
            dataimax_r <= dmadatai_max[31:0] ; 
          end
      endcase 
    end  
  end

  always @(datao32 or dmaaddr)
  begin : datao_proc
    reg[1:0] addr10; 
    addr10 = dmaaddr[1:0]; 
    case (DATAWIDTH)
      8 :
        begin
          case (addr10)
            2'b00 :
              begin
                dmadatao <= datao32[7:0] ; 
              end
            2'b01 :
              begin
                dmadatao <= datao32[15:8] ; 
              end
            2'b10 :
              begin
                dmadatao <= datao32[23:16] ; 
              end
            default :
              begin
                dmadatao <= datao32[31:24] ; 
              end
          endcase 
        end
      16 :
        begin
          if (!(addr10[1]))
          begin
            dmadatao <= datao32[15:0] ; 
          end
          else
          begin
            dmadatao <= datao32[31:16] ; 
          end 
        end
      default :
        begin
          dmadatao <= datao32 ; 
        end
    endcase 
  end

  assign flmax_sub = fzero_max[FIFODEPTH - 1:0] - 1 - fifolev ;

  assign flmax = {fzero_max[FIFODEPTH_MAX - 1:FIFODEPTH],
                  flmax_sub} ; 

  assign blmax = {fzero_max[FIFODEPTH_MAX - 1:6], pbl} ; 

  assign bsmax = (DATAWIDTH == 8) ? {fzero_max[FIFODEPTH_MAX - 1:12],
                                     bcnt} :
                 (DATAWIDTH ==16) ? {fzero_max[FIFODEPTH_MAX - 1:11],
                                     bcnt[11:1]} :
                                    {fzero_max[FIFODEPTH_MAX - 1:10],
                                     bcnt[11:2]} ;

  always @(posedge clk)
  begin : fifolev_reg_proc
    if (rst)
    begin
      fl_g_bs <= 1'b0 ; 
      fl_g_bl <= 1'b0 ; 
      bl_g_bs <= 1'b0 ; 
      pblz    <= 1'b0 ; 
    end
    else
    begin
      if (flmax >= bsmax)
      begin
        fl_g_bs <= 1'b1 ; 
      end
      else
      begin
        fl_g_bs <= 1'b0 ; 
      end 

      if (flmax >= blmax)
      begin
        fl_g_bl <= 1'b1 ; 
      end
      else
      begin
        fl_g_bl <= 1'b0 ; 
      end 

      if (blmax >= bsmax)
      begin
        bl_g_bs <= 1'b1 ; 
      end
      else
      begin
        bl_g_bs <= 1'b0 ; 
      end 

      if (pbl == 6'b000000)
      begin
        pblz <= 1'b1 ; 
      end
      else
      begin
        pblz <= 1'b0 ; 
      end 
    end  
  end

  always @(csm or
           lsm or
           pblz or
           tsprog or
           fl_g_bs or
           fl_g_bl or
           bl_g_bs or 
           blmax or
           bsmax or
           flmax or
           fzero_max or
           buffetch or
           dmacnt_r)
  begin : dmacnt_proc
    if (lsm == LSM_DES0 |
        lsm == LSM_DES1 |
        lsm == LSM_DES2 |
        lsm == LSM_DES3 |
        lsm == LSM_STAT | tsprog)
    begin
      case (DATAWIDTH)
        8 :
          begin
            dmacnt_c <= {fzero_max[FIFODEPTH_MAX - 1:3], 3'b100} ; 
          end
        16 :
          begin
            dmacnt_c <= {fzero_max[FIFODEPTH_MAX - 1:3], 3'b010} ; 
          end
        default :
          begin
            dmacnt_c <= {fzero_max[FIFODEPTH_MAX - 1:3], 3'b001} ; 
          end
      endcase 
    end
    else if(!buffetch)
    begin
      if (pblz)
      begin
        if (fl_g_bs | csm == CSM_SET)
        begin
          dmacnt_c <= bsmax ; 
        end
        else
        begin
          dmacnt_c <= flmax ; 
        end 
      end
      else
      begin
        if (fl_g_bl | csm == CSM_SET)
        begin
          if (bl_g_bs)
          begin
            dmacnt_c <= bsmax ; 
          end
          else
          begin
            dmacnt_c <= blmax ; 
          end 
        end
        else
        begin
          if (fl_g_bs)
          begin
            dmacnt_c <= bsmax ; 
          end
          else
          begin
            dmacnt_c <= flmax ; 
          end 
        end 
      end 
    end 
    else
    begin
      dmacnt_c <= dmacnt_r;    
    end	    
  end

  always @(posedge clk)
  begin : dmacnt_reg_proc
    if (rst)
    begin
      dmacnt_r <= {FIFODEPTH_MAX{1'b0}};
    end
    else
    begin
      dmacnt_r <= dmacnt_c;
    end
  end
  
  assign dmacnt = dmacnt_c;
   
  always @(posedge clk)
  begin : lastdma_reg_proc
    if (rst)
    begin
      lastdma <= 1'b1 ; 
    end
    else
    begin
      if (lsm == LSM_DES0 |
          lsm == LSM_DES1 |
          lsm == LSM_DES2 |
          lsm == LSM_DES3 |
          lsm == LSM_STAT | tsprog)
      begin
        lastdma <= 1'b1 ; 
      end
      else if (!buffetch)
      begin
        if (pblz)
        begin
          if (fl_g_bs | csm == CSM_SET)
          begin
            lastdma <= 1'b1 ; 
          end
          else
          begin
            lastdma <= 1'b0 ; 
          end 
        end
        else
        begin
          if (fl_g_bl | csm == CSM_SET)
          begin
            if (bl_g_bs)
            begin
              lastdma <= 1'b1 ; 
            end
            else
            begin
              lastdma <= 1'b0 ; 
            end 
          end
          else
          begin
            if (fl_g_bs)
            begin
              lastdma <= 1'b1 ; 
            end
            else
            begin
              lastdma <= 1'b0 ; 
            end 
          end 
        end 
      end 
    end  
  end

  always @(tsprog or lsm or statadi or bad or dad or statad)
  begin : dmaaddro_proc
    if (tsprog)
    begin
      dmaaddro <= statadi ; 
    end
    else
    begin
      case (lsm)
        LSM_BUF1, LSM_BUF2 :
          begin
            dmaaddro <= bad ; 
          end
        LSM_STAT :
          begin
            dmaaddro <= statad ; 
          end
        default :
          begin
            dmaaddro <= dad ; 
          end
      endcase 
    end 
  end

  always @(req or
           dmaack or
           dmaeob or
           lsm or
           tsprog or
           fifoval or
           req_r)
  begin : req_proc
    case (lsm)
      LSM_BUF1, LSM_BUF2 :
        begin
          if (dmaack & dmaeob)
          begin
            req_c <= 1'b0 ; 
          end
          else if ((fifoval & req_r == 3'b000) | tsprog)
          begin
            req_c <= 1'b1 ; 
          end
          else
          begin
            req_c <= req ; 
          end 
        end
      LSM_DES0, LSM_DES1, LSM_DES2, LSM_DES3, LSM_STAT :
        begin
          if (dmaack)
          begin
            req_c <= 1'b0 ; 
          end
          else
          begin
            req_c <= 1'b1 ; 
          end 
        end
      default :
        begin
          if (dmaack)
          begin
            req_c <= 1'b0 ; 
          end
          else if (tsprog)
          begin
            req_c <= 1'b1 ; 
          end
          else
          begin
            req_c <= 1'b0 ; 
          end 
        end
    endcase 
  end

  always @(posedge clk)
  begin : req_reg_proc
    if (rst)
    begin
      req      <= 1'b0 ;
      req_r    <= {3{1'b0 }}; 
      dmaack_r <= 1'b0 ; 
    end
    else
    begin
      req      <= req_c ; 
      req_r[0] <= req;
      req_r[1] <= req_r[0];
      req_r[2] <= req_r[1];
      dmaack_r <= dmaack & dmaeob ; 
    end  
  end

  assign dmawr = (tsprog | lsm == LSM_STAT) ? 1'b1 : 1'b0 ; 

  assign dmareq = req ; 

  always @(posedge clk)
  begin : stat_reg_proc
    if (rst)
    begin
      des      <= 1'b0 ; 
      fbuf     <= 1'b0 ; 
      stat     <= 1'b0 ; 
      tsprog   <= 1'b0 ;
      buffetch <= 1'b0 ; 
      tu       <= 1'b0 ; 
    end
    else
    begin
      if (lsm == LSM_DES0 |
          lsm == LSM_DES1 |
          lsm == LSM_DES2 |
          lsm == LSM_DES3)
            begin
        des <= 1'b1 ; 
      end
      else
      begin
        des <= 1'b0 ; 
      end 

      if (lsm == LSM_BUF1 | lsm == LSM_BUF2)
      begin
        fbuf <= 1'b1 ; 
      end
      else
      begin
        fbuf <= 1'b0 ; 
      end 

      if (tsprog)
      begin
        stat <= 1'b1 ; 
      end
      else
      begin
        stat <= 1'b0 ; 
      end 

      if ((dmaeob & dmaack) | itcomp | tcompack_r)
      begin
        tsprog <= 1'b0 ;
      end
      else if (csne & !idmareq & !icachere)
      begin
        tsprog <= 1'b1 ;
      end

      if (dmaack_r)
      begin
        buffetch <= 1'b0 ; 
      end
      else if (req_r[0] & (lsm == LSM_BUF1 | lsm == LSM_BUF2))
      begin
        buffetch <= 1'b1 ; 
      end 

      if (lsm == LSM_IDLE & !own)
      begin
        tu <= 1'b1 ; 
      end
      else if (own_c)
      begin
        tu <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : tcompack_reg_proc
    if (rst)
    begin
      tcompack_r <= 1'b0 ; 
      itcomp     <= 1'b0 ; 
    end
    else
    begin
      tcompack_r <= tcompack ; 

      if (tsprog & dmaeob & dmaack)
      begin
        itcomp <= 1'b1 ; 
      end
      else if (tcompack_r)
      begin
        itcomp <= 1'b0 ; 
      end 
    end  
  end

  assign tcomp = itcomp ; 

  always @(posedge clk)
  begin : setp_reg_proc
    if (rst)
    begin
      setp <= 1'b0 ; 
    end
    else
    begin
      if (csm == CSM_SET)
      begin
        setp <= 1'b1 ; 
      end
      else
      begin
        setp <= 1'b0 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : ifaddr_reg_proc
    if (rst)
    begin
      ifaddr <= {ADDRDEPTH{1'b0}} ; 
    end
    else
    begin
      if (csm == CSM_IDLE)
      begin
        ifaddr <= {ADDRDEPTH{1'b0}} ; 
      end
      else if (ifwe)
      begin
        ifaddr <= ifaddr + 1 ; 
      end 
    end  
  end

  always @(posedge clk)
  begin : ifwe_reg_proc
    if (rst)
    begin
      ifwe <= 1'b0 ; 
    end
    else
    begin
      case (DATAWIDTH)
        8 :
          begin
            if (csm == CSM_SET & 
                dmaack &
                dmaaddr[1:0] == 2'b11 &
                lsm == LSM_BUF1)
            begin
              ifwe <= 1'b1 ; 
            end
            else
            begin
              ifwe <= 1'b0 ; 
            end 
          end
        16 :
          begin
            if (csm == CSM_SET &
                dmaack &
                dmaaddr[1] &
                lsm == LSM_BUF1)
            begin
              ifwe <= 1'b1 ; 
            end
            else
            begin
              ifwe <= 1'b0 ; 
            end 
          end
        default :
          begin
            if (csm == CSM_SET & dmaack &
                lsm == LSM_BUF1)
            begin
              ifwe <= 1'b1 ; 
            end
            else
            begin
              ifwe <= 1'b0 ; 
            end 
          end
      endcase 
    end  
  end

  assign faddr = ifaddr ; 

  assign fwe = ifwe ; 

  assign fdata = dataimax_r[15:0] ; 

  always @(posedge clk)
  begin : stop_reg_proc
    if (rst)
    begin
      stop_r <= 1'b1 ; 
      stopo  <= 1'b1 ; 
    end
    else
    begin
      stop_r <= stopi ; 

      if (lsm == LSM_IDLE & stop_r)
      begin
        stopo <= 1'b1 ; 
      end
      else
      begin
        stopo <= 1'b0 ; 
      end 
    end  
  end

  assign fzero_max = {FIFODEPTH_MAX{1'b0}} ; 

  assign dzero_max = {DATAWIDTH_MAX{1'b0}} ; 

  assign bufzero_max = {(DATAWIDTH_MAX * 2 - 9){1'b0}} ; 

  assign dmaaddr20 = dmaaddr[2:0] ; 

  assign dmadatai_max = {dzero_max[DATAWIDTH_MAX+1:DATAWIDTH],
                         dmadatai}; 

  assign  buf_r_max = {bufzero_max[DATAWIDTH_MAX * 2 - 7:
                                   DATAWIDTH * 2 - 8],
                       buf_r}; 

endmodule

