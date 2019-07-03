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

module TFIFO (
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
