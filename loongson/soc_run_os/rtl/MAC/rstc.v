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

module RSTC (
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
