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

module DMA (
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
