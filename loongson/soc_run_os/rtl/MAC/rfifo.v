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

module RFIFO (
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
