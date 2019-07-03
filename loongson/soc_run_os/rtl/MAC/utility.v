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

  //-----------------------------------------------------------------
  // 802.3 parameters
  //-----------------------------------------------------------------
  // interframe space 1 interval = 60 bit times
  parameter [3:0] IFS1_TIME = 4'b1110; 
  // interframe space 2 interval = 36 bit times
  //parameter [3:0] IFS2_TIME = 4'b1000; 
  parameter [3:0] IFS2_TIME = 4'b0110; 
  // slot time interfal =  512 bit times
  parameter [8:0] SLOT_TIME = 9'b001111111; 
  // maximum number of retransmission attempts = 16
  parameter [4:0] ATT_MAX = 5'b10000; 
  // proper crc remainder value = 0xc704dd7b
  parameter [31:0] CRCVAL = 32'b11000111000001001101110101111011; 
  // minimum frame size = 64
  parameter [6:0] MIN_FRAME = 7'b1000000; 
  // maximum ethernet frame length field value = 1500
  parameter [15:0] MAX_SIZE = 16'b0000010111011100; 
  // maximum frame size
  parameter [13:0] MAX_FRAME = 14'b00010111101111; // 1519

  //_________________________________________________________________
  // Control and Status Register summary
  //_________________________________________________________________
  // Register | ID  |      RV       | Description
  //_________________________________________________________________
  // CSR0     | 00h | fe000000h     | Bus mode
  // CSR1     | 08h | ffffffffh     | Transmit pool demand
  // CSR2     | 10h | ffffffffh     | Teceive pool demand
  // CSR3     | 18h | ffffffffh     | Receive list base address
  // CSR4     | 20h | ffffffffh     | Rransmit list base address
  // CSR5     | 28h | f0000000h     | Status
  // CSR6     | 30h | 32000040h     | Operation mode
  // CSR7     | 38h | f3fe0000h     | Interrupt enable
  // CSR8     | 40h | e0000000h     | Missed frames and overflow cnt
  // CSR9     | 48h | fff483ffh     | MII management
  // CSR11    | 58h | fffe0000h     | Timer and interrupt mitigation
  //_________________________________________________________________

  //-----------------------------------------------------------------
  // Special Function Register locations and reset values
  //-----------------------------------------------------------------
  // CSR0     : 00h : fe000000h     : Bus mode
  parameter [5:0] CSR0_ID = 6'b000000; 
  // CSR0 reset value
  parameter [31:0] CSR0_RV = 32'b11111110000000000000000000000000; 

  // CSR1     : 08h : ffffffffh     : Transmit pool demand
  parameter [5:0] CSR1_ID = 6'b000010; 
  // CSR1 reset value
  parameter [31:0] CSR1_RV = 32'b11111111111111111111111111111111; 

  // CSR2     : 10h : ffffffffh     : Receive pool demand
  parameter [5:0] CSR2_ID = 6'b000100; 
  // CSR2 reset value
  parameter [31:0] CSR2_RV = 32'b11111111111111111111111111111111; 

  // CSR3     : 18h : ffffffffh     : Receive list base address
  parameter [5:0] CSR3_ID = 6'b000110; 
  // CSR3 reset value
  parameter [31:0] CSR3_RV = 32'b11111111111111111111111111111111; 

  // CSR4     : 20h : ffffffffh     : Transmit list base address
  parameter [5:0] CSR4_ID = 6'b001000; 
  // CSR4 reset value
  parameter [31:0] CSR4_RV = 32'b11111111111111111111111111111111; 

  // CSR5     : 28h : f0000000h     : Status
  parameter [5:0] CSR5_ID = 6'b001010; 
  // CSR5 reset value
  parameter [31:0] CSR5_RV = 32'b11110000000000000000000000000000; 

  // CSR6     : 30h : 32000040h     : Operation mode
  parameter [5:0] CSR6_ID = 6'b001100; 
  // CSR6 reset value
  parameter [31:0] CSR6_RV = 32'b00110010000000000000000001000000; 

  // CSR7     : 38h : f3fe0000h     : Interrupt enable
  parameter [5:0] CSR7_ID = 6'b001110; 
  // CSR7 reset value
  parameter [31:0] CSR7_RV = 32'b11110011111111100000000000000000; 

  // CSR8     : 40h : e0000000h     : Missed frames and overflow cnt
  parameter [5:0] CSR8_ID = 6'b010000; 
  // CSR8 reset value
  parameter [31:0] CSR8_RV = 32'b11100000000000000000000000000000; 

  // CSR9     : 48h : fff483ffh     : MII menagement
  parameter [5:0] CSR9_ID = 6'b010010; 
  // CSR9 reset value
  parameter [31:0] CSR9_RV = 32'b11111111111101001000001111111111; 

  // CSR10    : 50h : 00000000h     : Insert function enable
  parameter [5:0] CSR10_ID = 6'b010100; 
  // CSR11 reset value
  parameter [31:0] CSR10_RV = 32'b00000000000000000000000000000000; 

  // CSR11    : 58h : fffe0000h     : Timer and interrupt mitigation
  parameter [5:0] CSR11_ID = 6'b010110; 
  // CSR11 reset value
  parameter [31:0] CSR11_RV = 32'b11111111111111100000000000000000; 

  // TDES0
  parameter [31:0] TDES0_RV = 32'b00000000000000000000000000000000; 

  // SET0
  parameter [31:0] SET0_RV = 32'b00000000000000000000000000000000; 

  // RDES0
  parameter [31:0] RDES0_RV = 32'b00000000000000000000000000000000; 

  //-----------------------------------------------------------------
  // Internal interface parameters
  //-----------------------------------------------------------------
  // CSR interface address width
  parameter CSRDEPTH = 8; 
  // Filtering RAM address width
  parameter ADDRDEPTH = 6; 
  // Filtering RAM data width
  parameter ADDRWIDTH = 16; 
  // Maximum FIFO depth
  parameter FIFODEPTH_MAX = 15; 
  // Maximum Data interface address width
  parameter DATADEPTH_MAX = 32; 
  // Maximum Data interface width
  parameter DATAWIDTH_MAX = 32;
  // Maximum CSR interface width
  parameter CSRWIDTH_MAX = 32;
  // MII width
  parameter MIIWIDTH = 4;
  parameter MIIWIDTH_MAX = 8;


  //-----------------------------------------------------------------
  // Filtering modes
  //-----------------------------------------------------------------
  // Filtering mode - PREFECT --
  parameter [1:0] FT_PERFECT = 2'b00; 
  // Filtering mode - HASH --
  parameter [1:0] FT_HASH    = 2'b01; 
  // Filtering mode - INVERSE --
  parameter [1:0] FT_INVERSE = 2'b10; 
  // Filtering mode - HONLY --
  parameter [1:0] FT_HONLY   = 2'b11; 

  //-----------------------------------------------------------------
  // Phisical address position in setup frame
  //-----------------------------------------------------------------
  parameter [5:0] PERF1_ADDR = 6'b100111; 

  //-----------------------------------------------------------------
  // Ethernet frame fields
  //-----------------------------------------------------------------
  // jam field pattern
  parameter [63:0] JAM_PATTERN = 64'b1010101010101010101010101010101010101010101010101010101010101010;
  // preamble field pattern
  parameter [63:0] PRE_PATTERN = 64'b0101010101010101010101010101010101010101010101010101010101010101;
  // start of frame delimiter pattern
  parameter [63:0] SFD_PATTERN = 64'b1101010111010101110101011101010111010101110101011101010111010101;
  // padding field pattern
  parameter [63:0] PAD_PATTERN = 64'b0000000000000000000000000000000000000000000000000000000000000000;
  // carrier extension pattern
  parameter [63:0] EXT_PATTERN = 64'b0000111100001111000011110000111100001111000011110000111100001111;

  //-----------------------------------------------------------------
  // Enumeration types
  //-----------------------------------------------------------------

  // DMA state machine
  parameter [1:0] DSM_IDLE = 0; 
  parameter [1:0] DSM_CH1  = 1; 
  parameter [1:0] DSM_CH2  = 2; 

  // process state machine type for HC
  parameter [1:0] PSM_RUN     = 0; 
  parameter [1:0] PSM_SUSPEND = 1; 
  parameter [1:0] PSM_STOP    = 2; 

  // receive state machine for HC
  parameter [2:0] RSM_IDLE  = 0; 
  parameter [2:0] RSM_ACQ1  = 1; // trying to acquire free descriptor
  parameter [2:0] RSM_ACQ2  = 2; // trying to acquire free descriptor
  parameter [2:0] RSM_REC   = 3; // receiving frame
  parameter [2:0] RSM_STORE = 4; // storing frame
  parameter [2:0] RSM_STAT  = 5; // status of the frame

  // linked list state machine for HC
  parameter [3:0] LSM_IDLE  =  0; 
  parameter [3:0] LSM_DES0P =  1; // des0 prefetching
  parameter [3:0] LSM_DES0  =  2; // des0 fetching
  parameter [3:0] LSM_DES1  =  3; // des1 fetching
  parameter [3:0] LSM_DES2  =  4; // des2 fetching
  parameter [3:0] LSM_DES3  =  5; // des3 fetching
  parameter [3:0] LSM_BUF1  =  6; // buffer 1 fetching
  parameter [3:0] LSM_BUF2  =  7; // buffer 2 fetching
  parameter [3:0] LSM_STAT  =  8; // descriptor status storing
  parameter [3:0] LSM_FSTAT =  9; // frame status storing
  parameter [3:0] LSM_NXT   = 10; // next descriptor's address computing

  // descriptor's control state machine for HC
  parameter [2:0] CSM_IDLE = 0; 
  parameter [2:0] CSM_F    = 1; // first descriptor
  parameter [2:0] CSM_I    = 2; // intermediate descriptor
  parameter [2:0] CSM_L    = 3; // last descriptor
  parameter [2:0] CSM_FL   = 4; // first and last descriptor
  parameter [2:0] CSM_SET  = 5; // setup frame descriptor
  parameter [2:0] CSM_BAD  = 6; // invalid descriptor

  // master interface state machine for HC
  parameter [1:0] MSM_IDLE  = 0; 
  parameter [1:0] MSM_REQ   = 1; 
  parameter [1:0] MSM_BURST = 2; 

  // receive state machine for RC
  parameter [3:0] RSM_IDLE_RCSMT = 0; 
  parameter [3:0] RSM_SFD        = 1; 
  parameter [3:0] RSM_DEST       = 2; 
  parameter [3:0] RSM_SOURCE     = 3; 
  parameter [3:0] RSM_LENGTH     = 4; 
  parameter [3:0] RSM_INFO       = 5; 
  parameter [3:0] RSM_SUCC       = 6; 
  parameter [3:0] RSM_INT        = 7; 
  parameter [3:0] RSM_INT1       = 8; 
  parameter [3:0] RSM_BAD        = 9; // flushing received frame from fifo

  // address filtering state machine
  parameter [2:0] FSM_IDLE   = 0; 
  parameter [2:0] FSM_PERF1  = 1; // checking single physical address
  parameter [2:0] FSM_PERF16 = 2; // checking 16 addresses
  parameter [2:0] FSM_HASH   = 3; // hash fitering
  parameter [2:0] FSM_MATCH  = 4; // address match
  parameter [2:0] FSM_FAIL   = 5; // address failed

  // deffering state machine for TC
  parameter [1:0] DSM_WAIT = 0; // end of IFS, waiting for pending frame
  parameter [1:0] DSM_IFS1 = 1; // calculating interframe space time 1
  parameter [1:0] DSM_IFS2 = 2; // calculating interframe space time 2

  // transmit state machine for TC
  parameter [3:0] TSM_IDLE_TCSMT = 0; 
  parameter [3:0] TSM_PREA       = 1; 
  parameter [3:0] TSM_SFD        = 2; 
  parameter [3:0] TSM_INFO       = 3; 
  parameter [3:0] TSM_PAD        = 4; 
  parameter [3:0] TSM_CRC        = 5; 
  parameter [3:0] TSM_BURST      = 6; 
  parameter [3:0] TSM_JAM        = 7; 
  parameter [3:0] TSM_FLUSH      = 8; 
  parameter [3:0] TSM_INT        = 9; 
