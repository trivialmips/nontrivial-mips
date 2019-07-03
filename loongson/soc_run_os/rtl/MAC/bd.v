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

module BD (
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
