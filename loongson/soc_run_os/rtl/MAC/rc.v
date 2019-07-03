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

module RC (
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
  rcsreq,
  insert_en_i
);

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
  
  input     insert_en_i;


  reg       insert_en_0_r;
  reg       insert_en_r;

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

  wire [2:0] n_offset;
  assign n_offset = (insert_en_r) ? ((ncnt20 + 3'b100) & 3'b111) : ncnt20;

  always @(ncnt or ncnt10 or n_offset or rxd_r_max or data)
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
          case (n_offset)
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
	  insert_en_0_r <= 1'b0;
	  insert_en_r <= 1'b0;
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

	  insert_en_0_r <= insert_en_i;
	  insert_en_r <= insert_en_0_r;

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
                      (DATAWIDTH == 32 & n_offset[2:0] == 3'b111))) |
           (!rxdv_r & !we & 
             (
               (DATAWIDTH==32 & n_offset[2:1]!=2'b00) |
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

  wire [13:0] new_lcnt;
  assign new_lcnt = (insert_en_r) ? (lcnt + 2'b10) : lcnt;

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

      length[13] <= new_lcnt[13] ; 
      begin : length_loop
        integer i;
        for(i = 12; i >= 0; i = i - 1)
        begin
          length[i] <= new_lcnt[i + 1] ^ new_lcnt[i] ; 
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
