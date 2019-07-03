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

module TLSM (
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
