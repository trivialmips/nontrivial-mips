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

  // HTRANS states 
  parameter [1:0] IDLE   = 0; 
  parameter [1:0] NONSEQ = 1; 
  parameter [1:0] SEQ    = 2; 
  parameter [1:0] HTRANS_IDLE   = 2'b00; 
  parameter [1:0] HTRANS_BUSY   = 2'b01; 
  parameter [1:0] HTRANS_NONSEQ = 2'b10; 
  parameter [1:0] HTRANS_SEQ    = 2'b11; 
 
  // HBURST states
  parameter SINGLE = 1'b0; 
  parameter INCR   = 1'b1; 
  parameter [2:0] HBURST_SINGLE = 3'b000; 
  parameter [2:0] HBURST_INCR   = 3'b001; 

  // HSIZE states
  parameter [2:0] HSIZE8BIT    = 0; 
  parameter [2:0] HSIZE16BIT   = 1; 
  parameter [2:0] HSIZE32BIT   = 2; 
  parameter [2:0] HSIZE64BIT   = 3; 
  parameter [2:0] HSIZE256BIT  = 4; 
  parameter [2:0] HSIZE512BIT  = 5; 
  parameter [2:0] HSIZE1024BIT = 6; 
  parameter [2:0] UNSUPPORTED  = 7; 

  parameter [2:0] HSIZE_8BIT    = 3'b000; 
  parameter [2:0] HSIZE_16BIT   = 3'b001; 
  parameter [2:0] HSIZE_32BIT   = 3'b010; 
  parameter [2:0] HSIZE_64BIT   = 3'b011; 
  parameter [2:0] HSIZE_128BIT  = 3'b100; 
  parameter [2:0] HSIZE_256BIT  = 3'b101; 
  parameter [2:0] HSIZE_512BIT  = 3'b110; 
  parameter [2:0] HSIZE_1024BIT = 3'b111; 

  // HRESP states 
  parameter [1:0] OKAY  = 0; 
  parameter [1:0] ERROR = 1; 
  parameter [1:0] RETRY = 2; 
  parameter [1:0] SPLIT = 3; 
  parameter [1:0] HRESP_OKAY  = 2'b00; 
  parameter [1:0] HRESP_ERROR = 2'b01; 
  parameter [1:0] HRESP_RETRY = 2'b10; 
  parameter [1:0] HRESP_SPLIT = 2'b11; 

  // HPROT subvalue 
  parameter HPROT_0_OPCODEFETCH      = 1'b0; 
  parameter HPROT_0_DATAACCESS       = 1'b1; 
  parameter HPROT_1_USERACCESS       = 1'b0; 
  parameter HPROT_1_PRIVILAGEDACCESS = 1'b1; 
  parameter HPROT_2_NOTBUFFERABLE    = 1'b0; 
  parameter HPROT_2_BUFFERABLE       = 1'b1; 
  parameter HPROT_3_NOTCACHEABLE     = 1'b0; 
  parameter HPROT_3_CACHEABLE        = 1'b1; 

  // HPROT default value 
  parameter [3:0] HPROT_MACPROTECTIONCONTROL = {HPROT_3_NOTCACHEABLE,
                                                HPROT_2_NOTBUFFERABLE,
                                                HPROT_1_USERACCESS,
                                                HPROT_0_DATAACCESS}; 

  // MACDATA2AHB FSM states 
  parameter [1:0] AHBM_ADDR     = 0; 
  parameter [1:0] AHBM_ADDRDATA = 1; 
  parameter [1:0] AHBM_IDLE     = 2; 
  parameter [1:0] AHBM_DATA     = 3; 
