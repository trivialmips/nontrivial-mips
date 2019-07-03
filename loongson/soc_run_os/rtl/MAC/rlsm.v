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

module RLSM (
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
  stopo,
  insert_en_i
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
  
  input     insert_en_i;



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

  wire  [13:0] real_length;
  assign real_length = (insert_en_i) ? (length - 2'b10) : length;

  assign fstat = {1'b0, ff, real_length, res_c, rde,
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
