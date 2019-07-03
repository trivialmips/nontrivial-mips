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

module TC (
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
