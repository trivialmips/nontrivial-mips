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

module CSR (
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
  mden,

  insert_en_o
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


  output    insert_en_o;
  wire      insert_en_o;

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
  wire      [31:0] csr10;
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

  reg       csr10_insert_en;

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
  begin : csr10_reg_proc
    if (rst)
    begin
      csr10_insert_en <= CSR10_RV[0];
    end
    else
    begin
      if (!csrrw & csrreq & csraddr72 == CSR10_ID)
      begin
	    csr10_insert_en <= csrdata_c[0];
      end
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

  assign csr10 = {CSR10_RV[31:1], csr10_insert_en};
  
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
		   csr10 or 
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
                  CSR10_ID :
                    begin
                      csrdatao <= csr10[7:0] ; 
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
                  CSR10_ID :
                    begin
                      csrdatao <= csr10[15:8] ; 
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
                  CSR10_ID :
                    begin
                      csrdatao <= csr10[23:16] ; 
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
                  CSR10_ID :
                    begin
                      csrdatao <= csr10[31:24] ; 
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
                  CSR10_ID :
                    begin
                      csrdatao <= csr10[15:0] ; 
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
                  CSR10_ID :
                    begin
                      csrdatao <= csr10[31:16] ; 
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
            CSR10_ID :
              begin
                csrdatao <= csr10 ; 
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


  assign insert_en_o = csr10_insert_en;

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
