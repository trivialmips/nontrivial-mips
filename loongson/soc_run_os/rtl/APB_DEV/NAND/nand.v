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

module NAND_top(
	nand_type,

    pclk,
	prst_,
	psel,
	penable,
	pwrite,
    ADDR,
    DAT_I,
    DAT_O,

    NAND_CE_o,
    NAND_REQ,
    NAND_I,
    NAND_O,
    NAND_EN_, 
    NAND_ALE,
    NAND_CLE,
    NAND_WR_,
    NAND_RD_,
    NAND_IORDY_i,

	nand_int
);
input  [1:0]nand_type;

input  pclk;
input  prst_;
input  pwrite;
input  psel;
input  penable;
input  [10:0]ADDR;
input  [31:0]DAT_I;
output [31:0]DAT_O;

output [3:0]NAND_CE_o;
output NAND_REQ;
input  [7:0]NAND_I;
output [7:0]NAND_O;
output NAND_EN_;
output NAND_ALE;
output NAND_CLE;
output NAND_WR_;
output NAND_RD_;
input  [3:0]NAND_IORDY_i;
output nand_int;

/************************************************************/       

reg  [31:0]REG_DAT_T;
reg  [13:0]nand_addr_c;
reg  [24:0]nand_addr_r;
reg  [31:0]nand_op_num;
reg  [31:0]nand_parameter;
reg  [31:0]nand_ce_map0;
reg  [31:0]nand_ce_map1;
reg  [31:0]nand_rdy_map0;
reg  [31:0]nand_rdy_map1;
reg  [31:0]nand_command;
reg  [15:0]  nand_timing;
reg  [37:0]  addr_in_die;
reg  [4:0]   NAND_STATE;
reg  [31:0]  NAND_OP_NUM;
reg  [13:0]  WRITE_MAX_COUNT;
reg  [13:0]  READ_MAX_COUNT;
reg          nand_clr_ack;
reg          NAND_DONE;
reg          NAND_CE_;
reg          nand_int;

wire  [13:0]  op_scope;
wire  [2:0]   nand_id_num;
wire  [3:0]   nand_size;
wire          main_op;
wire          spare_op;
wire          nand_int_en;
wire          nand_dma_ack_i;
wire          NANDtag;
wire          NAND_IORDY;


wire HIT0 =psel & ADDR[10:0] == 11'h00;      
wire HIT1 =psel & ADDR[10:0] == 11'h04;      
wire HIT2 =psel & ADDR[10:0] == 11'h08;      
wire HIT3 =psel & ADDR[10:0] == 11'h0c;      
wire HIT4 =psel & ADDR[10:0] == 11'h10;      
wire HIT5 =psel & ADDR[10:0] == 11'h14;      
wire HIT6 =psel & ADDR[10:0] == 11'h18;      
wire HIT7 =psel & ADDR[10:0] == 11'h1c;      
wire HIT8 =psel & ADDR[10:0] == 11'h20;      
wire HIT9 =psel & ADDR[10:0] == 11'h24;      
wire HIT10=psel & ADDR[10:0] == 11'h28;      
wire HIT11=psel & ADDR[10:0] == 11'h2c;      
wire NAND_HIT =penable & ADDR[10:0] == 11'h40;   
assign nand_dma_ack_i=psel & ADDR[10:0] == 11'h40;

assign DAT_O = REG_DAT_T;
reg    	   NAND_DMA_REQ;
reg        nand_cmd_valid;

always @(posedge pclk)
begin
    if(~prst_)
    begin
        nand_int <= 1'b0;
    end
	else
    begin
        nand_int <= NAND_DONE&nand_int_en;
    end
end



always @(posedge pclk)
begin
     if(~prst_)
     begin
          nand_clr_ack <= 1'b1;
          nand_command <= {1'b0,1'b0,1'b0,1'b0,9'b0,1'b0,NANDtag};
          nand_timing  <= {8'h4,8'h12};
	      nand_op_num  <= 2048;
          nand_addr_c  <= 14'h0;
          nand_addr_r  <= 25'h0;
          nand_parameter<= (nand_type==2'h3) ? 32'h800_5100:             
                           (nand_type==2'h2) ? 32'h800_5000:             //2'h2 means 1Gbit
                           (nand_type==2'h1) ? 32'h200_4b00:32'h200_4c00;
          nand_ce_map0  <= 32'h0;
          nand_ce_map1  <= 32'h0;
          nand_rdy_map0 <= 32'h0;
          nand_rdy_map1 <= 32'h0; 
          nand_cmd_valid<=nand_command[0];
     end 
     else 
     begin
          nand_cmd_valid<=nand_command[0];
       if(pwrite& HIT0) begin 
           nand_command[15:0] <= DAT_I[15:0];
       end
       else if(NAND_DONE && nand_command[0]) begin
              nand_command [0]  <= 1'b0;
              nand_command [10] <= 1'b1;
              nand_clr_ack 	<= 1'b1;
       end
       else begin
           nand_command[31:16] <={NAND_DMA_REQ,1'b0,1'b0,NAND_STATE,NAND_CE_o,NAND_IORDY_i};
           if(~NAND_DONE)     nand_clr_ack <= 1'b0;
       end

       	if(pwrite& HIT1) nand_addr_c <= DAT_I[13:0];
 	if(pwrite& HIT2) nand_addr_r <= DAT_I[24:0];
 	if(pwrite& HIT3) begin 
            nand_timing[7:0]  <= (DAT_I[7:0]<5)  ? 8'h5: DAT_I[7:0];
            nand_timing[15:8] <= (DAT_I[15:8]<2) ? 8'h2: DAT_I[15:8];
       end
       if(pwrite& HIT6)  nand_parameter<= DAT_I;
       if(pwrite& HIT7)  nand_op_num   <= DAT_I;
       if(pwrite& HIT8)  nand_ce_map0  <= DAT_I;
       if(pwrite& HIT9)  nand_ce_map1  <= DAT_I;
       else nand_ce_map1  <= {READ_MAX_COUNT,NAND_OP_NUM[15:0]};
       if(pwrite& HIT10) nand_rdy_map0 <= DAT_I;
       if(pwrite& HIT11) nand_rdy_map1 <= DAT_I;
       else nand_rdy_map1  <= {WRITE_MAX_COUNT,NAND_OP_NUM[15:0]};
     end
end


assign NANDtag	   = ~prst_  ? 1'b0 : nand_cmd_valid;
assign op_scope    = nand_parameter[29:16];
assign nand_id_num = nand_parameter[14:12];
assign nand_size   = nand_parameter[11:8];
assign main_op     = nand_command[8];
assign spare_op    = nand_command[9];
assign nand_int_en = nand_command[13];

reg     [7:0]   status;
reg     [1:0]   nand_number;
reg     [47:0]  ID_INFORM;
reg     [31:0]  NAND_DAT_O_RD;
wire    [3:0]   NAND_CE_pre_o;
wire    [3:0]   NAND_IORDY_post_i;

always @(posedge pclk)
begin
     if(~prst_)
     begin
        addr_in_die  <= 38'h0; 
	nand_number  <= 2'h0;
	end
	else begin
    case(nand_size)
           4'h0: begin                                                                                      
                   nand_number  <= nand_addr_r[17:16];           // 1Gb in a single die , page 2048
       		   addr_in_die  <= {9'h0,nand_addr_r[15:0],4'b0,nand_addr_c[11:0]};
              end                                
           4'h1: begin                                                                                      
                   nand_number  <= nand_addr_r[18:17];           
       		   addr_in_die  <= {5'h0,nand_addr_r[16:0],4'b0,nand_addr_c[11:0]};
              end                                
           4'h2: begin                          
                   nand_number  <= nand_addr_r[19:18];           
       		   addr_in_die  <= {4'h0,nand_addr_r[17:0],4'b0,nand_addr_c[11:0]};
              end                                
           4'h3: begin 
                   nand_number  <= nand_addr_r[20:19];           
       		   addr_in_die  <= {3'h0,nand_addr_r[18:0],4'b0,nand_addr_c[11:0]};
              end                                                                                           
           4'h4: begin                                                                                      
                   nand_number  <= nand_addr_r[20:19];           
       		   addr_in_die  <= {3'h0,nand_addr_r[18:0],3'b0,nand_addr_c[12:0]};
              end
           4'h5: begin
                   nand_number  <= nand_addr_r[20:19];           
       		   addr_in_die  <= {3'h0,nand_addr_r[18:0],2'b0,nand_addr_c[13:0]};
              end
           4'h6: begin
                   nand_number  <= nand_addr_r[21:20];           
       		   addr_in_die  <= {2'h0,nand_addr_r[19:0],2'b0,nand_addr_c[13:0]};
              end
           4'h7: begin
                   nand_number  <= nand_addr_r[22:21];           
       		   addr_in_die  <= {1'h0,nand_addr_r[20:0],2'b0,nand_addr_c[13:0]};
              end
           4'h9: begin                                                                                      
                   nand_number  <= nand_addr_r[15:14];           
       		   addr_in_die  <= {15'h0,nand_addr_r[13:0],nand_addr_c[8:0]};
              end                                
           4'ha: begin                                                                                      
                   nand_number  <= nand_addr_r[16:15];           
       		   addr_in_die  <= {14'h0,nand_addr_r[14:0],nand_addr_c[8:0]};
              end                                
           4'hb: begin                                                                                      
                   nand_number  <= nand_addr_r[17:16];           
       		   addr_in_die  <= {13'h0,nand_addr_r[15:0],nand_addr_c[8:0]};
              end                                
           4'hc: begin                                                                                      
                   nand_number  <= nand_addr_r[18:17];           
       		   addr_in_die  <= {12'h0,nand_addr_r[16:0],nand_addr_c[8:0]};
              end                                
           4'hd: begin                                                                                      
                   nand_number  <= nand_addr_r[19:18];           
       		   addr_in_die  <= {11'h0,nand_addr_r[17:0],nand_addr_c[8:0]};
              end                                
           default: begin
                   nand_number  <= 2'b0;
       		   addr_in_die  <= 38'b0;
           end
   endcase
 end
end

assign   NAND_CE_pre_o[0] = (nand_number ==4'h0) ? NAND_CE_ : 1'b1;
assign   NAND_CE_pre_o[1] = (nand_number ==4'h1) ? NAND_CE_ : 1'b1;
assign   NAND_CE_pre_o[2] = (nand_number ==4'h2) ? NAND_CE_ : 1'b1;
assign   NAND_CE_pre_o[3] = (nand_number ==4'h3) ? NAND_CE_ : 1'b1;
assign   NAND_IORDY   = (nand_number ==4'h0) ? NAND_IORDY_post_i[0]:
                        (nand_number ==4'h1) ? NAND_IORDY_post_i[1]:
                        (nand_number ==4'h2) ? NAND_IORDY_post_i[2]:
                        (nand_number ==4'h3) ? NAND_IORDY_post_i[3]:1'b1;

assign NAND_CE_o[0] =   NAND_CE_pre_o[0];
assign NAND_IORDY_post_i[0] =  NAND_IORDY_i[0];
assign NAND_CE_o[1] =           nand_ce_map0[8 ] ? NAND_CE_pre_o[0]:
                                nand_ce_map0[9 ] ? NAND_CE_pre_o[1]:
                                nand_ce_map0[10] ? NAND_CE_pre_o[2]:
                                nand_ce_map0[11] ? NAND_CE_pre_o[3]:1'b1;


assign NAND_IORDY_post_i[1] =   nand_ce_map0[12] ? NAND_IORDY_i[0]:
                                nand_ce_map0[13] ? NAND_IORDY_i[1]:
                                nand_ce_map0[14] ? NAND_IORDY_i[2]:
                                nand_ce_map0[15] ? NAND_IORDY_i[3]:1'b1;

assign NAND_CE_o[2] =           nand_ce_map0[16] ? NAND_CE_pre_o[0]:
                                nand_ce_map0[17] ? NAND_CE_pre_o[1]:
                                nand_ce_map0[18] ? NAND_CE_pre_o[2]:
                                nand_ce_map0[19] ? NAND_CE_pre_o[3]:1'b1;

assign NAND_IORDY_post_i[2] =   nand_ce_map0[20] ? NAND_IORDY_i[0]:
                                nand_ce_map0[21] ? NAND_IORDY_i[1]:
                                nand_ce_map0[22] ? NAND_IORDY_i[2]:
                                nand_ce_map0[23] ? NAND_IORDY_i[3]:1'b1;

assign NAND_CE_o[3] =           nand_ce_map0[24] ? NAND_CE_pre_o[0]:
                                nand_ce_map0[25] ? NAND_CE_pre_o[1]:
                                nand_ce_map0[26] ? NAND_CE_pre_o[2]:
                                nand_ce_map0[27] ? NAND_CE_pre_o[3]:1'b1;

assign NAND_IORDY_post_i[3] =   nand_ce_map0[28] ? NAND_IORDY_i[0]:
                                nand_ce_map0[29] ? NAND_IORDY_i[1]:
                                nand_ce_map0[30] ? NAND_IORDY_i[2]:
                                nand_ce_map0[31] ? NAND_IORDY_i[3]:1'b1;

always @(pwrite or penable or NAND_HIT or
        HIT0 or HIT1 or HIT2 or HIT3 or 
        HIT4 or HIT5 or HIT6 or HIT7 or 
        HIT8 or HIT9 or HIT10 or HIT11 or 
        nand_command or  nand_op_num or nand_addr_c or  nand_addr_r or 
        nand_ce_map0 or nand_ce_map1  or nand_rdy_map0 or nand_rdy_map1 or 
        nand_timing  or nand_parameter or status or ID_INFORM or NAND_DAT_O_RD)
begin
      if(~pwrite & HIT0 &penable)
           REG_DAT_T = nand_command;
     else if(~pwrite & HIT1&penable)
           REG_DAT_T = {20'b0,nand_addr_c};
     else if(~pwrite & HIT2&penable)
           REG_DAT_T = {7'b0,nand_addr_r};
     else if(~pwrite & HIT3&penable)
           REG_DAT_T = nand_timing;
     else if(~pwrite & HIT4&penable)
           REG_DAT_T = ID_INFORM[31:0];
     else if(~pwrite & HIT5&penable)
           REG_DAT_T = {status,ID_INFORM[47:32]};
     else if(~pwrite & HIT6&penable)
           REG_DAT_T = nand_parameter;
     else if(~pwrite & HIT7&penable)
           REG_DAT_T = nand_op_num;
     else if(~pwrite & HIT8&penable)
           REG_DAT_T = nand_ce_map0 ;
     else if(~pwrite & HIT9&penable)
           REG_DAT_T = nand_ce_map1;
     else if(~pwrite & HIT10&penable)
           REG_DAT_T = nand_rdy_map0 ;
     else if(~pwrite & HIT11&penable)
           REG_DAT_T = nand_rdy_map1 ;
     else if(~pwrite & NAND_HIT &penable)
           REG_DAT_T = NAND_DAT_O_RD;
     else  REG_DAT_T = 0;
end

reg    	[1:0]   ADDR_pointer;
reg    	[7:0]   NAND_O;
reg    	[2:0]   NAND_ADDR_COUNT;
reg    	[7:0]   WAIT_NUM;
reg    	[7:0]   HOLD_NUM;
reg    	[7:0]   COMMAND;
reg    	[4:0]   PRE_STATE;
reg    	[2:0]   READ_ID_NUM;
reg    	[13:0]  data_count;
reg    	[37:0]  NAND_ADDR;
reg    	[31:0]  NAND_DAT_I_WR;

reg    	NAND_WR_;
reg    	NAND_RD_;
reg    	NAND_CLE;
reg    	NAND_ALE;
reg    	NAND_GO;
reg    	NAND_ACK;
reg    	DMA_OP_DONE;
reg    	ERASE_SERIAL;
reg    	NAND_EN_;

reg     now_up_half;
reg     now_oob;
assign NAND_REQ =NAND_DMA_REQ;

parameter	
     	NAND_IDLE     = 5'b00000, 
	COMMAND_IN    = 5'b00001,
	
	ADDR_4_RD_WR  = 5'b00010,
	ADDR_4_ERASE_ID = 5'b01010,
	
	READ_START    = 5'b00011,
	READ_WAIT     = 5'b00100,
	READ_WAIT_2   = 5'b00110,
	READ_TRANSFER = 5'b00111,
	
	WRITE_START   = 5'b10000,
	WRITE_DATA    = 5'b10001,
	PROGRAM       = 5'b10010,
	PROGRAM_FAIL  = 5'b10011,
	
	READ_ID       = 5'b10100,
	READ_STATUS   = 5'b10101, 
	ID_TO_STATUS  = 5'b10110, 

	ERASE         = 5'b10111,
	WAIT_ERASE    = 5'b11000,
	ERASE_FAIL    = 5'b11001,
	
	RESET         = 5'b11010,
	WAIT_RESET    = 5'b11011;
always  @(posedge  pclk)
begin
    if  (~prst_||~NANDtag)
        begin 
            now_up_half         <= 1'b0;
            now_oob             <= 1'b0;
            NAND_ACK    	<= 1'b0;
            NAND_CLE    	<= 1'b0;
            NAND_ALE    	<= 1'b0;
            NAND_CE_    	<= 1'b1;
            NAND_WR_    	<= 1'b1;
            NAND_RD_    	<= 1'b1;
            NAND_O      	<= 8'b0;   
            COMMAND     	<= 8'h55; 
            data_count  	<= 14'b0;
            NAND_ADDR   	<= 38'b0;
            NAND_DONE   	<= 1'b0;
            NAND_GO     	<= 1'b0;
            if(~prst_)          status      	<= 8'b0;
            if(~prst_)          ID_INFORM   	<= 48'h0;
            WAIT_NUM    	<= 8'h14;
            HOLD_NUM    	<= 8'h4; 
            PRE_STATE   	<= 5'b0;
            ADDR_pointer    	<= 2'b0;
            NAND_DMA_REQ    	<= 1'b0;
            ERASE_SERIAL    	<= 1'b0;
            NAND_OP_NUM     	<= 32'h0;
            NAND_EN_        	<= 1'b0;
            NAND_ADDR_COUNT 	<= 3'b0;
            READ_MAX_COUNT  	<= 14'b0;
            WRITE_MAX_COUNT 	<= 14'b0;
            DMA_OP_DONE     	<= 1'b0;
            NAND_DAT_I_WR   	<= 32'b0;
            NAND_DAT_O_RD   	<= 32'h12345678; 
	    READ_ID_NUM     	<= 3'b100;
            NAND_STATE      	<= NAND_IDLE;
        end
      else
          begin
              case(NAND_STATE)
              NAND_IDLE:
                    begin
                        HOLD_NUM    <= nand_timing[15:8];
                        if(nand_command[0])
                           begin
                           DMA_OP_DONE <= 1'b0;
                           if(nand_clr_ack) 
                               	NAND_DONE <= 1'b0; 
                           if(NAND_OP_NUM==32'b0) begin 
				NAND_ADDR   <= addr_in_die;
                               	NAND_OP_NUM <= nand_op_num;
                           end
                           if(nand_command[1] &&NAND_GO && ~NAND_DONE&& (nand_size[3])&&(~main_op||main_op&&NAND_ADDR[8]&&now_up_half)&&spare_op) 
                              begin
                                     COMMAND   <= 8'h50;
                                     NAND_EN_  <= 1'b0;
                                     NAND_GO   <= 1'b0; 
                                     now_oob   <= 1'b1;
                                     now_up_half    <= 1'b0;
                              end
                           else if(nand_command[1] && NAND_ADDR[8]&&nand_size[3]&&NAND_GO && ~NAND_DONE)   
                              begin
                                     COMMAND   <= 8'h01;
                                     NAND_EN_  <= 1'b0;
                                     NAND_GO   <= 1'b0; 
                                     now_oob   <= 1'b0;
                                     now_up_half    <= main_op&spare_op;
                              end
                           else if(nand_command[1] && NAND_GO && ~NAND_DONE)   
                              begin
                                     COMMAND   <= 8'h00;
                                     NAND_EN_  <= 1'b0;
                                     NAND_GO   <= 1'b0; 
                                     now_oob   <= 1'b0;
                                     now_up_half    <= 1'b0;
                              end
                            else if(nand_command[2]&&NAND_GO && ~NAND_DONE&& nand_size[3]&&(~main_op||main_op&&NAND_ADDR[8]&&now_up_half)&&spare_op)   
                                begin
                                     COMMAND   <= 8'h50;
                                     NAND_GO   <= 1'b0; 
                                     now_oob   <= 1'b1;
                                     now_up_half    <= 1'b0;
                               end
                            else if(nand_command[2]&&NAND_GO && ~NAND_DONE&& nand_size[3]&&NAND_ADDR[8])     
                                begin
                                     COMMAND   <= 8'h01;
                                     NAND_GO   <= 1'b0; 
                                     now_oob   <= 1'b0;
                                     now_up_half    <= main_op&spare_op;
                               end
                            else if(nand_command[2]&&NAND_GO && ~NAND_DONE&& nand_size[3]&&~NAND_ADDR[8])     
                                begin
                                     COMMAND   <= 8'h0;
                                     NAND_GO   <= 1'b0; 
                                     now_oob   <= 1'b0;
                                     now_up_half    <= 1'b0;
                               end
                            else if(nand_command[2]&&NAND_GO && ~NAND_DONE)     
                                begin
                                     COMMAND   <= 8'h80;
                                     NAND_GO   <= 1'b0; 
                               end
                             else if(nand_command[3]&&NAND_GO&& ~NAND_DONE )    
                                 begin
                                     COMMAND    <= 8'h60; 
                                     NAND_GO    <= 1'b0; 
                                     ERASE_SERIAL <= nand_command[4];
                                 end
                             else if(nand_command[5]&&NAND_GO&& ~NAND_DONE)     
                                 begin
                                     COMMAND    <= 8'h90; 
                                     NAND_GO    <= 1'b0;
                                 end
                             else if(nand_command[6]&&NAND_GO&& ~NAND_DONE)     
                                 begin
                                     COMMAND    <= 8'hFF;
                                     NAND_GO    <= 1'b0;
                                 end
                             else if(nand_command[7]&&NAND_GO&& ~NAND_DONE)     
                                 begin
                                     COMMAND    <= 8'h70;
                                     NAND_GO    <= 1'b0;
                                 end
                           else  if((COMMAND==8'h00 ||  COMMAND==8'h70  ||  COMMAND==8'h80  ||  COMMAND==8'h01  ||  COMMAND==8'h50  ||  
                                     COMMAND==8'h60 ||  COMMAND==8'h90  ||  COMMAND==8'hFF)&& ~NAND_DONE) begin
                                         NAND_STATE<= COMMAND_IN;
                                         PRE_STATE <= NAND_IDLE;
                                         WAIT_NUM  <= nand_timing[7:0];
                                         NAND_CE_  <= 1'b0;
                                         NAND_CLE  <= 1'b0;
                                         NAND_ALE  <= 1'b0;
                                         NAND_WR_  <= 1'b1;
                                         NAND_RD_  <= 1'b1;
                                         NAND_EN_  <= 1'b0;
                                 end
                           else begin
                                       COMMAND <= 8'h55;
                                       NAND_GO <= ~NAND_DONE & nand_command[0];
                                       if (~nand_command[0]) NAND_DONE <=1'b0;
                             end
                         end else begin
                                COMMAND     <= 8'h55;
                                NAND_CE_    <= 1'b1;
                                NAND_WR_    <= 1'b1;
                                NAND_RD_    <= 1'b1;
                                NAND_STATE  <= NAND_IDLE;
                                NAND_GO     <= ~NAND_DONE&nand_command[0]; 
                                if(~NAND_GO) begin
				    NAND_ADDR   <= nand_command[0] ? addr_in_die : 38'h3f_ffff_ffff;
                                    NAND_OP_NUM <= nand_command[0] ? nand_op_num : 32'b0;
                                end
                                if(nand_clr_ack) 
                                    NAND_DONE <= 1'b0;
                              end
                      end
              COMMAND_IN:  
                        begin
                                  if(WAIT_NUM == nand_timing[7:0]) begin
                                            NAND_CLE  <= 1'b0;
                                            NAND_WR_  <= 1'b1;
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                        end
                                  else if(WAIT_NUM == (nand_timing[7:0]-1)) begin
                                            NAND_CLE  <= 1'b1;
                                            NAND_WR_  <= 1'b1;
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                        end
                                  else  if(WAIT_NUM < nand_timing[7:0] && WAIT_NUM>HOLD_NUM) begin
                                                NAND_O    <= COMMAND; 
                                                NAND_CLE  <= 1'b1;
                                                NAND_WR_  <= 1'b0;
                                                WAIT_NUM  <= WAIT_NUM - 1'b1;
                                            end
                                  else  if(WAIT_NUM<=HOLD_NUM && WAIT_NUM) begin
                                             NAND_CLE  <= 1'b1;
                                             NAND_WR_  <= 1'b1;
                                             WAIT_NUM  <= WAIT_NUM - 1'b1;
                                      end
                                  else
                                          begin
                                              if(PRE_STATE==NAND_IDLE) begin
                                                     NAND_CE_  <= 1'b0;
                                                     NAND_CLE  <= 1'b0;
                                                     NAND_WR_  <= 1'b1;
                                                     NAND_ALE  <= 1'b0;
                                                     NAND_DONE <= 1'b0; 
                                                     NAND_O    <= 8'b0; 
                                                     PRE_STATE <= COMMAND_IN;
                                                     if((nand_command[1]||nand_command[2])&&(COMMAND==8'h00||COMMAND==8'h01||COMMAND==8'h50)) begin
                                                            NAND_STATE  <= nand_command[1] ? READ_START:WRITE_START; 
                                                            WAIT_NUM    <= nand_timing[7:0];
                                                        end  
                                                      else if(nand_command[2]&&(COMMAND==8'h80)) begin
                                                            NAND_STATE  <= WRITE_START;
                                                            WAIT_NUM    <= nand_timing[7:0];
                                                        end
                                                      else  if((COMMAND==8'h60)) begin
                                                            NAND_STATE  <= ERASE;
                                                            PRE_STATE   <= COMMAND_IN;
                                                            WAIT_NUM    <= nand_timing[7:0]+2'b11;
                                                        end
                                                      else  if((COMMAND==8'h70)) begin
                                                            NAND_STATE  <= READ_STATUS;
                                                            WAIT_NUM    <= nand_timing[7:0]+2'b11;
                                                        end
                                                      else  if((COMMAND==8'h90)) begin
                                                            NAND_STATE  <= READ_ID;
                                                            WAIT_NUM    <= nand_timing[7:0]+2'b11;
                                                        end
                                                      else  if((COMMAND==8'hFF)) begin
                                                            NAND_STATE  <= RESET;
                                                            WAIT_NUM    <= nand_timing[7:0]+2'b11;
                                                        end
                                                      else begin
                                                            NAND_STATE  <= NAND_IDLE;
                                       			    NAND_OP_NUM <= 32'b0;
                                                            NAND_CE_    <= 1'b1;
                                                            NAND_DONE   <= 1'b1;
                                                       end
                                               end
                                              else
                                                    begin
                                                          NAND_CLE   <= 1'b0;
                                                          NAND_ALE   <= 1'b0;
                                                          NAND_WR_   <= 1'b1; 
                                                          NAND_GO    <= 1'b1; 
                                                          NAND_STATE <= PRE_STATE;
                                                          PRE_STATE  <= COMMAND_IN;
                                                          WAIT_NUM   <= nand_timing[7:0];
                                                    end
                                      end  
                          end  
            ADDR_4_ERASE_ID:
                        begin
                            if(NAND_ADDR_COUNT  !=  3'b0)
                                begin
                                  if(WAIT_NUM > (nand_timing[7:0] - HOLD_NUM+1'b1))
                                        begin
                                            NAND_ALE  <= 1'b0; 
                                            NAND_WR_  <= 1'b1; 
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                        end
                                  else if(WAIT_NUM > (nand_timing[7:0] - HOLD_NUM))
                                        begin
                                            NAND_ALE  <= 1'b1; 
                                            NAND_WR_  <= 1'b1; 
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                        end
                                  else  if(WAIT_NUM>=HOLD_NUM)
                                        begin      
                                            NAND_ALE  <= 1'b1; 
                                            NAND_WR_  <= 1'b0; 
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                            if(NAND_ADDR_COUNT == 2'b11) begin 
                                                    if(nand_size==4'hc||nand_size==4'hd) NAND_O   <= NAND_ADDR[16:9];
                                                    else  NAND_O   <= NAND_ADDR[23:16];
                                             end
                                             else  if(NAND_ADDR_COUNT==2'b10) begin 
                                                    if(nand_size==4'h9||nand_size==4'ha||nand_size==4'hb) NAND_O   <= NAND_ADDR[16:9];
                                                    else if(nand_size==4'hc||nand_size==4'hd) NAND_O   <= NAND_ADDR[24:17];
                                                    else if(nand_size==4'h0) NAND_O   <= NAND_ADDR[23:16];
                                                    else  NAND_O   <= NAND_ADDR[31:24];
                                                end
                                            else  if(NAND_ADDR_COUNT==3'b001) begin
                                                if(PRE_STATE == READ_ID) 
                                                    NAND_O   <= NAND_ADDR[7:0];
                                                else 
                                                    if(nand_size==4'h9||nand_size==4'ha||nand_size==4'hb) NAND_O   <= NAND_ADDR[24:17];
                                                    else if(nand_size==4'hc||nand_size==4'hd) NAND_O   <= NAND_ADDR[32:25];
                                                    else if(nand_size==4'h0) NAND_O   <= NAND_ADDR[31:24];
                                                    else  NAND_O   <= NAND_ADDR[35:32];
                                               end
                                        end
                                      else  if((WAIT_NUM<HOLD_NUM) && WAIT_NUM) begin
                                                NAND_ALE  <= 1'b1; 
                                                NAND_WR_  <= 1'b1; 
                                                WAIT_NUM  <= WAIT_NUM - 1;
                                          end
                                      else
                                          begin
                                              NAND_ALE      <= 1'b0; 
                                              NAND_WR_      <= 1'b1; 
                                              WAIT_NUM      <= nand_timing[7:0] + 2'b10;
                                              NAND_ADDR_COUNT  <= NAND_ADDR_COUNT  -  1'b1;
                                          end
                                end
                              else
                                  begin
                                    NAND_CE_  <= 1'b0;
                                    NAND_CLE  <= 1'b0;
                                    NAND_ALE  <= 1'b0;
                                    NAND_WR_  <= 1'b1;
                                    NAND_RD_  <= 1'b1;  
                                    NAND_STATE<= PRE_STATE;  
                                    PRE_STATE <= ADDR_4_ERASE_ID;
                                    WAIT_NUM  <= nand_timing[7:0]+1'b1;
                                  end
                            end
             ADDR_4_RD_WR:
                        begin
                            if(NAND_ADDR_COUNT != 3'b0) begin
                                  if(WAIT_NUM > (nand_timing[7:0] - HOLD_NUM + 1'b1)) begin
                                            NAND_ALE  <= 1'b0; 
                                            NAND_WR_  <= 1'b1;
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                    end
                                  else if(WAIT_NUM > (nand_timing[7:0]- HOLD_NUM)) begin
                                            NAND_ALE  <= 1'b1; 
                                            NAND_WR_  <= 1'b1;
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                    end
                                  else  if(WAIT_NUM>=HOLD_NUM) begin
                                            NAND_ALE  <= 1'b1;
                                            NAND_WR_  <= 1'b0;
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                            if(NAND_ADDR_COUNT==3'b101)
                                                  NAND_O    <= NAND_ADDR[7:0];
                                            else if(NAND_ADDR_COUNT==3'b100) begin
                                                    if(nand_size==4'hc||nand_size==4'hd) NAND_O    <= NAND_ADDR[7:0];
                                                    else if(nand_size==4'h0) NAND_O    <= NAND_ADDR[7:0];
                                                    else  NAND_O    <= NAND_ADDR[15:8];
                                            end
                                            else  if(NAND_ADDR_COUNT==3'b11) begin
                                                    if(nand_size==4'h9||nand_size==4'ha||nand_size==4'hb) NAND_O    <= NAND_ADDR[7:0];
                                                    else if(nand_size==4'hc||nand_size==4'hd) NAND_O    <= NAND_ADDR[16:9];
                                                    else if(nand_size==4'h0) NAND_O    <= NAND_ADDR[15:8];
                                                    else  NAND_O    <= NAND_ADDR[23:16];
                                            end
                                            else  if(NAND_ADDR_COUNT==3'b10)begin
                                                    if(nand_size==4'h9||nand_size==4'ha||nand_size==4'hb) NAND_O    <= NAND_ADDR[16:9];
                                                    else if(nand_size==4'hc||nand_size==4'hd) NAND_O    <= NAND_ADDR[24:17];
                                                    else if(nand_size==4'h0) NAND_O    <= NAND_ADDR[23:16];
                                                    else  NAND_O    <= NAND_ADDR[31:24];
                                            end
                                            else  if(NAND_ADDR_COUNT==3'b1) begin
                                                    if(nand_size==4'h9||nand_size==4'ha||nand_size==4'hb) NAND_O    <= NAND_ADDR[24:17];
                                                    else if(nand_size==4'hc||nand_size==4'hd) NAND_O    <= NAND_ADDR[32:25];
                                                    else if(nand_size==4'h0) NAND_O    <= NAND_ADDR[31:24];
                                                    else  NAND_O    <= NAND_ADDR[37:32];
                                            end
                                        end
                                  else  if((WAIT_NUM<HOLD_NUM) && WAIT_NUM) begin
                                                NAND_ALE  <= 1'b1; 
                                                NAND_WR_  <= 1'b1;
                                                WAIT_NUM  <= WAIT_NUM - 1'b1;
                                          end
                                  else  begin
                                                NAND_ALE  <= 1'b0; 
                                                NAND_WR_  <= 1'b1;
                                                WAIT_NUM  <= nand_timing[7:0]+2'b10; 
                                                NAND_ADDR_COUNT  <= NAND_ADDR_COUNT - 1'b1;
                                  end 
                              end
                              else begin
                                    NAND_CE_   <= 1'b0;
                                    NAND_CLE   <= 1'b0;
                                    NAND_ALE   <= 1'b0;
                                    NAND_WR_   <= 1'b1;
                                    NAND_RD_   <= 1'b1;  
                                    NAND_STATE <= PRE_STATE;  
                                    PRE_STATE  <= ADDR_4_RD_WR;
                                    WAIT_NUM  <= nand_timing[7:0]+1'b1;
                                  end
                            end
             READ_START: 
                        begin
                            if( (PRE_STATE==COMMAND_IN) && (COMMAND == 8'h30)||(PRE_STATE==ADDR_4_RD_WR)&&nand_size[3] ) begin
                                    NAND_CE_  <= 1'b0;
                                    NAND_CLE  <= 1'b0;
                                    NAND_ALE  <= 1'b0;
                                    NAND_WR_  <= 1'b1;
                                    NAND_STATE<= NAND_IORDY ? READ_START : READ_WAIT;
                                end
                            else if((PRE_STATE==ADDR_4_RD_WR) && (COMMAND != 8'h30) ) begin
                                      NAND_CE_  <= 1'b0;
                                      NAND_CLE  <= 1'b0;
                                      NAND_ALE  <= 1'b0;
                                      NAND_WR_  <= 1'b1; 
                                      WAIT_NUM  <= nand_timing[7:0];
                                      PRE_STATE <= READ_START; 
                                      NAND_STATE<= COMMAND_IN;
                                      COMMAND   <= 8'h30;
                                end
                             else begin
                                      NAND_CE_  <= 1'b0;
                                      NAND_CLE  <= 1'b0;
                                      NAND_ALE  <= 1'b0;
                                      NAND_WR_  <= 1'b1;
                                      WAIT_NUM  <= nand_timing[7:0];
                                      PRE_STATE <= READ_START;
                                      NAND_STATE<= ADDR_4_RD_WR;
                                      NAND_ADDR_COUNT  <= (nand_size==4'h9||nand_size==4'ha||nand_size==4'hb) ? 3'b011 : (nand_size==4'h0||nand_size==4'hc||nand_size==4'hd) ? 3'b100:3'b101;
                                end
                        end
            READ_WAIT:  
                        begin
                           if(NAND_IORDY==1'b0) begin
                                    NAND_STATE  <= READ_WAIT;
                            end
                            else    begin
                                    NAND_RD_    <= 1'b1;    
                                    NAND_STATE  <= READ_WAIT_2;
                            end
                        end
            READ_WAIT_2:  
                        begin
                             	data_count 	<= 14'b0;
                             	ADDR_pointer 	<= 2'b0;
                             	NAND_EN_     	<= 1'b1;
                             	DMA_OP_DONE  	<= 1'b1; 
                             	NAND_STATE   	<= READ_TRANSFER;
                             	WAIT_NUM     	<= nand_timing[7:0];
                                case(nand_size)
                                4'h9,
                                4'ha,
                                4'hb,
                                4'hc,
                                4'hd: 
                                     begin 
                                          NAND_ADDR[7:0]  <= 8'h0;
                                          NAND_ADDR[30:8] <= spare_op&& (~main_op)? (NAND_ADDR[30:8] +2'b10) : now_up_half ? NAND_ADDR[30:8] : (NAND_ADDR[30:8] +1'b1);
                                         if(spare_op && main_op&&~now_oob)
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(256-NAND_ADDR[7:0]))? (256-NAND_ADDR[7:0]) : NAND_OP_NUM; 
                                         else if(now_oob)
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(16-NAND_ADDR[3:0]))? (16-NAND_ADDR[3:0]) : NAND_OP_NUM;
                                         else
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(256-NAND_ADDR[7:0]))? (256-NAND_ADDR[7:0]) : NAND_OP_NUM;
                                   end

                                4'h0, 
                                4'h1, 
                                4'h2, 
                                4'h3: begin  
                                          NAND_ADDR[10:0]  <= 11'h0; 
                                          NAND_ADDR[11]    <= spare_op&(~main_op); 
                                          NAND_ADDR[35:16] <= NAND_ADDR[35:16] +1'b1;
                                         if(spare_op && main_op)
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[11:0]))? (op_scope-NAND_ADDR[11:0]) : NAND_OP_NUM; 
                                         else if(spare_op)
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[5:0])) ? (op_scope-NAND_ADDR[5:0]) : NAND_OP_NUM;
                                         else
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[10:0]))? (op_scope-NAND_ADDR[10:0]) : NAND_OP_NUM;
                                       end
                                4'h4: begin 
                                          NAND_ADDR[11:0]  <= 12'h0;
                                          NAND_ADDR[12]    <= spare_op&(~main_op);
                                          NAND_ADDR[35:16] <= NAND_ADDR[35:16] +1'b1;
                                         if(spare_op && main_op)
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[12:0]))? (op_scope-NAND_ADDR[12:0]) : NAND_OP_NUM; 
                                         else if(spare_op)
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[6:0])) ? (op_scope-NAND_ADDR[6:0]) : NAND_OP_NUM;
                                         else
                                             READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[11:0]))? (op_scope-NAND_ADDR[11:0]) : NAND_OP_NUM;
                                       end
                                4'h5, 
                                4'h6, 
                                4'h7: begin 
                                          NAND_ADDR[12:0]  <= 13'h0; 
                                          NAND_ADDR[13]    <= spare_op&(~main_op); 
                                          NAND_ADDR[35:16] <= NAND_ADDR[35:16] +1'b1;
                                          if(spare_op && main_op)
                                              READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[13:0]))? (op_scope-NAND_ADDR[13:0]) : NAND_OP_NUM; 
                                          else if(spare_op)
                                              READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[7:0])) ? (op_scope-NAND_ADDR[7:0]) : NAND_OP_NUM;
                                          else
                                              READ_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[12:0]))? (op_scope-NAND_ADDR[12:0]) : NAND_OP_NUM;
                                       end
                                default: begin end
                                endcase
                        end

              READ_TRANSFER:  
                        begin
                          if(~NAND_IORDY)
                             begin
                                    if (~DMA_OP_DONE && ~NAND_HIT)
                                      begin
                                          NAND_DMA_REQ <= 1'b1;
                                      end
                                     else if(NAND_DMA_REQ && NAND_HIT) 
                                        begin
                                          NAND_DMA_REQ 	<= 1'b0;
                                          DMA_OP_DONE  	<= 1'b1;
                                          ADDR_pointer 	<= 2'b0;
                                          WAIT_NUM 	<= nand_timing[7:0];
                                        end
                             end
                          else if((data_count != READ_MAX_COUNT) && ~NAND_CE_)
                                begin
                                    if ((~DMA_OP_DONE||DMA_OP_DONE &&ADDR_pointer==2'h3&&WAIT_NUM==2&&(data_count < (READ_MAX_COUNT-3'h4))) && ~NAND_HIT )
                                      begin
                                          NAND_DMA_REQ <= 1'b1;
                                      end
                                     else if(NAND_HIT && NAND_DMA_REQ) begin
                                          NAND_DMA_REQ  <= 1'b0;
                                          DMA_OP_DONE  	<= 1'b1;
                                          if(data_count == READ_MAX_COUNT -1'b1) begin
                                                data_count      <= READ_MAX_COUNT;
                                          end
                                        end
                                
                                    if ((WAIT_NUM > (nand_timing[7:0]-HOLD_NUM+1'b1))&&(DMA_OP_DONE||NAND_HIT)) begin
                                                NAND_RD_    <= 1'b1;
                                                WAIT_NUM    <= WAIT_NUM - 1'b1;
                                        end
                                    else if ((WAIT_NUM > 1) && (DMA_OP_DONE&&~NAND_DMA_REQ) )
                                        begin
                                                NAND_RD_    <= 1'b0;
                                                WAIT_NUM    <= WAIT_NUM - 1'b1;
                                        end
                                     else  if((WAIT_NUM==1)&& (DMA_OP_DONE))
                                         begin
                                            NAND_RD_        <= 1'b1;  
                                            WAIT_NUM        <= nand_timing[7:0];
                                            ADDR_pointer    <= ADDR_pointer + 1'b1;
                                            if(data_count!=READ_MAX_COUNT -1'b1) data_count  <= data_count + 1'b1;
                                            if(NAND_OP_NUM!=32'b0) NAND_OP_NUM <= NAND_OP_NUM - 1'b1;
                                            if(ADDR_pointer==2'b0) NAND_DAT_O_RD[7:0]  <= NAND_I;
                                            else if(ADDR_pointer==2'b01) NAND_DAT_O_RD[15:8]  <= NAND_I;
                                            else if(ADDR_pointer==2'b10) NAND_DAT_O_RD[23:16]  <= NAND_I;
                                            else if(ADDR_pointer==2'b11) begin
                                                NAND_DAT_O_RD[31:24]  <= NAND_I;
                                                DMA_OP_DONE 	<= 1'b0;
                                            end
                                        end 
                                end
                            else
                              begin
                                NAND_DMA_REQ <= 1'b0;
                                data_count   <= 14'b0;
                                NAND_STATE   <= NAND_IDLE; 
                                WAIT_NUM     <= nand_timing[7:0];
                                if(NAND_OP_NUM==32'b0) begin
                                     NAND_GO    <= 1'b0;
                                     NAND_DONE  <= 1'b1;
                                     NAND_CE_   <= 1'b1;
                                  end
                                else begin
                                     NAND_GO   <= 1'b1;
                                     NAND_DONE <= 1'b0;
                                     NAND_CE_  <= 1'b0;
                                end
                              end
                        end

              WRITE_START: begin  
                             if(PRE_STATE == COMMAND_IN&&COMMAND!=8'h80) begin
                                      NAND_CE_  <= 1'b0;
                                      NAND_CLE  <= 1'b0;
                                      NAND_ALE  <= 1'b0;
                                      NAND_WR_  <= 1'b1;
                                      WAIT_NUM  <= nand_timing[7:0];
                                      PRE_STATE <= WRITE_START;
                                      NAND_STATE<= COMMAND_IN;
                                      COMMAND   <= 8'h80;
                              end
                             else if(PRE_STATE == COMMAND_IN) begin
                                      NAND_CE_  <= 1'b0;
                                      NAND_CLE  <= 1'b0;
                                      NAND_ALE  <= 1'b0;
                                      NAND_WR_  <= 1'b1;
                                      WAIT_NUM  <= nand_timing[7:0];
                                      PRE_STATE <= WRITE_START;
                                      NAND_STATE<= ADDR_4_RD_WR;
                                      NAND_ADDR_COUNT  <= (nand_size==4'h9||nand_size==4'ha||nand_size==4'hb) ? 3'b011 : (nand_size==4'h0||nand_size==4'hc||nand_size==4'hd) ? 3'b100:3'b101;
                              end
                            else  if(PRE_STATE==ADDR_4_RD_WR) begin
                                NAND_CE_    <= 1'b0;
                                NAND_CLE    <= 1'b0;
                                NAND_ALE    <= 1'b0;
                                NAND_WR_    <= 1'b1;
                                ADDR_pointer<= 2'b0;
                                data_count  <= 14'h0;
                                WAIT_NUM    <= nand_timing[7:0];
                                NAND_STATE  <= WRITE_DATA;
                                case(nand_size)
                                4'h9,
                                4'ha,
                                4'hb,
                                4'hc,
                                4'hd:
                                     begin 
                                          NAND_ADDR[7:0]  <= 8'h0;
                                          NAND_ADDR[30:8] <= spare_op&& (~main_op)? (NAND_ADDR[30:8] +2'b10) : now_up_half ? NAND_ADDR[30:8] : (NAND_ADDR[30:8] +1'b1);
                                         if(spare_op && main_op&&~now_oob)
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(256-NAND_ADDR[7:0]))? (256-NAND_ADDR[7:0]) : NAND_OP_NUM; 
                                         else if(now_oob)
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(16-NAND_ADDR[3:0])) ? (16-NAND_ADDR[3:0]) : NAND_OP_NUM;
                                         else
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(256-NAND_ADDR[7:0]))? (256-NAND_ADDR[7:0]) : NAND_OP_NUM;
                                   end

                                4'h0, 
                                4'h1, 
                                4'h2, 
                                4'h3: begin 
                                          NAND_ADDR[10:0]  <= 11'h0; 
                                          NAND_ADDR[11]    <= spare_op&(~main_op); 
                                          NAND_ADDR[35:16] <= NAND_ADDR[35:16] +1'b1;
                                         if(spare_op && main_op)
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[11:0]))? (op_scope-NAND_ADDR[11:0]) : NAND_OP_NUM; 
                                         else if(spare_op)
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[5:0])) ? (op_scope-NAND_ADDR[5:0]) : NAND_OP_NUM;
                                         else
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[10:0]))? (op_scope-NAND_ADDR[10:0]) : NAND_OP_NUM;
                                       end
                                4'h4: begin 
                                          NAND_ADDR[11:0]  <= 12'h0;
                                          NAND_ADDR[12]    <= spare_op&(~main_op);
                                          NAND_ADDR[35:16] <= NAND_ADDR[35:16] +1'b1;
                                         if(spare_op && main_op)
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[12:0]))? (op_scope-NAND_ADDR[12:0]) : NAND_OP_NUM; 
                                         else if(spare_op)
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[6:0])) ? (op_scope-NAND_ADDR[6:0]) : NAND_OP_NUM;
                                         else
                                             WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[11:0]))? (op_scope-NAND_ADDR[11:0]) : NAND_OP_NUM;
                                       end
                                4'h5, 
                                4'h6, 
                                4'h7: begin 
                                          NAND_ADDR[12:0]  <= 13'h0; 
                                          NAND_ADDR[13]    <= spare_op&(~main_op); 
                                          NAND_ADDR[35:16] <= NAND_ADDR[35:16] +1'b1;
                                          if(spare_op && main_op)
                                              WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[13:0]))? (op_scope-NAND_ADDR[13:0]) : NAND_OP_NUM; 
                                          else if(spare_op)
                                              WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[7:0])) ? (op_scope-NAND_ADDR[7:0]) : NAND_OP_NUM;
                                          else
                                              WRITE_MAX_COUNT <= (NAND_OP_NUM>(op_scope-NAND_ADDR[12:0]))? (op_scope-NAND_ADDR[12:0]) : NAND_OP_NUM;
                                       end
                                default: begin end
                                endcase

                                end
                       end
                       
              WRITE_DATA:
                        begin
                            if(data_count != WRITE_MAX_COUNT )
                                begin
                                    if(~DMA_OP_DONE&&~NAND_HIT)
                                          NAND_DMA_REQ <=  1'b1;
                                    else if(DMA_OP_DONE&&~NAND_HIT&&ADDR_pointer==2'h3&&WAIT_NUM==2&&(data_count < (WRITE_MAX_COUNT-3'h4)))
                                          NAND_DMA_REQ <=  1'b1;
                                     else if(NAND_DMA_REQ && NAND_HIT) begin
                                          NAND_DMA_REQ  <= 1'b0;
                                          ADDR_pointer  <= 2'b0;
                                          DMA_OP_DONE   <= 1'b1;
                                          NAND_DAT_I_WR <= DAT_I;
                                        end

                                    if ((WAIT_NUM > (nand_timing[7:0]-HOLD_NUM+1'b1))&&(DMA_OP_DONE||NAND_HIT)) begin
                                            NAND_WR_  <= 1'b1; 
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                        end
                                    else if ((WAIT_NUM > 1'b1) && DMA_OP_DONE) begin
                                            NAND_WR_  <= 1'b0;
                                            WAIT_NUM  <= WAIT_NUM - 1'b1;
                                              if  (ADDR_pointer  ==2'b0)
                                                  NAND_O  <= NAND_DAT_I_WR[7:0]; 
                                              else if  (ADDR_pointer  ==2'b1)
                                                  NAND_O  <= NAND_DAT_I_WR[15:8]; 
                                              else if  (ADDR_pointer  ==2'b10)
                                                  NAND_O<= NAND_DAT_I_WR[23:16];
                                              else if  (ADDR_pointer  ==2'b11)
                                                  begin
                                                      NAND_O      <= NAND_DAT_I_WR[31:24];
                                                  end
                                        end
                                     else  if((WAIT_NUM == 1'b1)&&DMA_OP_DONE) begin
                                                NAND_WR_     <= 1'b1;
                                                WAIT_NUM     <= nand_timing[7:0];
                                                ADDR_pointer <= ADDR_pointer + 1'b1;
                                                if(ADDR_pointer ==2'b11) begin
                                                    DMA_OP_DONE   <= 1'b0;
                                                    if(NAND_OP_NUM >=32'h4)
                                                        NAND_OP_NUM <= NAND_OP_NUM - 3'b100; 
                                                    else 
                                                        NAND_OP_NUM <= 32'h0;
                                                    if(NAND_OP_NUM == 32'h4)
                                                        data_count  <= WRITE_MAX_COUNT; 
                                                    else
                                                        data_count  <= data_count + 3'b100;
                                               end
                                        end
                                end
                            else  if(PRE_STATE !=  COMMAND_IN && COMMAND==8'h80)
                                begin
                                     NAND_CE_    <= 1'b0;
                                     NAND_CLE    <= 1'b0;
                                     NAND_ALE    <= 1'b0;
                                     NAND_WR_    <= 1'b1;
                                     NAND_STATE  <= COMMAND_IN;
                                     PRE_STATE   <= WRITE_DATA;
                                     COMMAND     <= 8'h10; 
                                     DMA_OP_DONE <= 1'b0;
                                     WAIT_NUM    <= nand_timing[7:0];
                                end
                            else  if(PRE_STATE == COMMAND_IN  &&  COMMAND==8'h10) begin
                                     NAND_CE_    <= 1'b0;
                                     NAND_STATE  <= NAND_IORDY ? WRITE_DATA:PROGRAM;
                                end
                           else  if(PRE_STATE == PROGRAM && COMMAND==8'h10) begin
                                    NAND_STATE <= COMMAND_IN;
                                    PRE_STATE  <= WRITE_DATA;
                                    COMMAND    <= 8'h70; 
                                    WAIT_NUM   <= nand_timing[7:0];
                                    NAND_CE_   <= 1'b0;
                                end
                            else  if(PRE_STATE == COMMAND_IN  &&  COMMAND==8'h70) begin
                                     NAND_CE_  <= 1'b0;
                                     NAND_CLE  <= 1'b0;
                                     NAND_ALE  <= 1'b0;
                                     NAND_WR_  <= 1'b1;
                                     NAND_RD_  <= 1'b1;  
                                     NAND_STATE<= READ_STATUS;
                                     PRE_STATE <= WRITE_DATA;
                                     WAIT_NUM  <= nand_timing[7:0]+2'b11;
                                     NAND_EN_  <= 1'b1;
                                end
                            else  if(PRE_STATE == READ_STATUS)
                                begin
                                    if(status[0]==0 && NAND_OP_NUM ==32'b0)
                                      begin
                                          NAND_STATE   <= NAND_IDLE;
                                          NAND_DONE    <= 1'b1;
                                          NAND_DMA_REQ <= 1'b0;
                                      end
                                    else if(status[0]==0) 
                                    begin
                                          NAND_STATE   <= NAND_IDLE;
                                          NAND_DONE    <= 1'b0;
                                      end
                                   else
                                       begin
                                           NAND_STATE  <= PROGRAM_FAIL;
                                           NAND_DONE   <= 1'b1;
                                           NAND_DMA_REQ<= 1'b0;
                                        end                               
                                    end
                            else
                                begin
                                    NAND_STATE  <= NAND_IDLE;
                                    NAND_DONE <=1;
                                    NAND_DMA_REQ <= 1'b0;
                                end
                        end
               PROGRAM:
                        begin
                                    if(NAND_IORDY==1'b0) begin
                                            NAND_STATE <= PROGRAM;
                                        end
                                    else begin
                                            PRE_STATE  <= PROGRAM;
                                            NAND_STATE <= WRITE_DATA;
                                            DMA_OP_DONE <= 1'b0;
                                        end
                        end
               RESET:
                        begin
                                    if(NAND_IORDY==1'b1) begin
                                            NAND_STATE  <= RESET;
                                        end
                                    else begin
                                            NAND_STATE  <= WAIT_RESET;
                                            PRE_STATE   <= RESET;
                                        end
                        end
                WAIT_RESET:
                        begin
                             if(NAND_IORDY) begin
                                NAND_STATE  <= NAND_IDLE;
                                PRE_STATE   <= WAIT_RESET;
                                NAND_CE_    <= 1'b1; 
				                NAND_DONE   <= 1'b1;
                                NAND_GO     <= 1'b0;
                             end
                             else 
                                 NAND_STATE  <= WAIT_RESET;
                        end
             
                READ_STATUS:
                        begin 
                            if(WAIT_NUM  >= (nand_timing[7:0]- HOLD_NUM+1'b1)) begin
                                    WAIT_NUM    <= WAIT_NUM - 1'b1;
                                    NAND_STATE  <= READ_STATUS;
                                    NAND_RD_    <= 1'b1;
                                    NAND_EN_    <= 1'b1;
                             end
                            else if(WAIT_NUM && WAIT_NUM >1 ) begin
                                    WAIT_NUM    <= WAIT_NUM - 1'b1;
                                    NAND_STATE  <= READ_STATUS;
                                    NAND_RD_    <= 1'b0;
                                    NAND_EN_    <= 1'b1;
                             end
                            else if(WAIT_NUM == 1) begin
                                    WAIT_NUM    <= WAIT_NUM - 1'b1;
                                    NAND_STATE  <= READ_STATUS;
                                    status      <= NAND_I;
                                    NAND_RD_    <= 1'b1;
                                    NAND_EN_    <= 1'b1;
                             end
                            else  if(WAIT_NUM==8'b0) begin
                                    NAND_RD_    <= 1'b1;
                                    NAND_CE_    <= 1'b0;
                                    PRE_STATE   <= READ_STATUS;
                                    NAND_STATE  <= PRE_STATE;
                                    WAIT_NUM    <= nand_timing[7:0];
                                    if(PRE_STATE == 5'h1)
                                        NAND_DONE <= 1'b1;
                             end
                            else begin
                                  WAIT_NUM    <= WAIT_NUM - 1'b1;
                                  NAND_STATE  <= READ_STATUS;
                                  NAND_RD_    <= 1'b1;
                                  NAND_EN_    <= 1'b1;
                             end
                        end
              
              PROGRAM_FAIL,ERASE_FAIL:
                        begin
                            NAND_STATE  <= NAND_IDLE;
                            NAND_CE_    <= 1'b1;
                            NAND_DONE   <= 1'b1;
                        end
              ERASE:
                        begin
                            if( (PRE_STATE != ADDR_4_ERASE_ID) && (COMMAND ==  8'h60) )
                                begin
                                      NAND_STATE    <= ADDR_4_ERASE_ID;
                                      PRE_STATE     <= ERASE;
                                      WAIT_NUM      <= nand_timing[7:0];
                                      NAND_ADDR_COUNT  <= (nand_size==4'h9||nand_size==4'ha||nand_size==4'hb||nand_size==4'h0) ? 3'b10:3'b011;
                                end
                            else  if( (PRE_STATE != COMMAND_IN) && (COMMAND ==  8'h60) )
                                begin
                                    NAND_STATE  <= COMMAND_IN;
                                    PRE_STATE   <= ERASE;
                                    COMMAND     <= 8'hD0;
                                    WAIT_NUM    <= nand_timing[7:0];
                                end
                            else  if(PRE_STATE==COMMAND_IN  &&  COMMAND==  8'hd0)
                                begin
                                    NAND_STATE  <= NAND_IORDY ? ERASE : WAIT_ERASE;
                                end
                        end
              WAIT_ERASE:
                    begin
                            if(NAND_IORDY==1'b0) begin
                                    NAND_STATE  <= WAIT_ERASE;
                                end
                            else  if(NAND_IORDY && PRE_STATE == COMMAND_IN && COMMAND == 8'h60)
                               begin
                                    NAND_STATE <= ERASE;
                                    PRE_STATE  <= WAIT_ERASE;
                               end 
                            else  if(NAND_IORDY && COMMAND ==8'hd0 )
                               begin
                                    NAND_OP_NUM <= NAND_OP_NUM - 1'b1;
                                    NAND_STATE  <= COMMAND_IN;
                                    PRE_STATE   <= WAIT_ERASE;
                                    COMMAND     <= 8'h70;
                                    WAIT_NUM    <= nand_timing[7:0];
                                    NAND_CE_    <= 1'b0;
                                end
                            else  if(NAND_IORDY && PRE_STATE == COMMAND_IN  &&  COMMAND==8'h70)
                                 begin     
                                            NAND_CE_  <= 1'b0;
                                            NAND_CLE  <= 1'b0;
                                            NAND_ALE  <= 1'b0;
                                            NAND_WR_  <= 1'b1;
                                            NAND_RD_  <= 1'b1;  
                                            NAND_STATE<= READ_STATUS;
                                            PRE_STATE <= WAIT_ERASE;
                                            WAIT_NUM  <= nand_timing[7:0]+2'b11;
                                            NAND_EN_  <= 1'b1;
                                end
                          else  if(NAND_IORDY && PRE_STATE == READ_STATUS)
                                begin
                                    if(status[0]==1'b0 && (NAND_OP_NUM==32'b0 || ERASE_SERIAL == 1'b0) )
                                      begin
                                          NAND_STATE  <= NAND_IDLE;
                                          NAND_CE_    <= 1'b1;
                                          NAND_DONE   <= 1'b1;
                                          NAND_ADDR   <= 36'h0;
                                          ERASE_SERIAL<= 1'b0;
                                      end
                                   else if(status[0]== 1'b0 && NAND_OP_NUM!=32'b0)
                                      begin
                                          NAND_STATE  <= COMMAND_IN;
                                          PRE_STATE   <= WAIT_ERASE;
                                          COMMAND     <= 8'h60;
                                          NAND_DONE   <= 1'b0; 
                                          WAIT_NUM    <= nand_timing[7:0];
                                          NAND_CE_    <= 1'b0;
                                          NAND_EN_    <= 1'b0;
                                          if(nand_size[3]) NAND_ADDR[27:14] <= NAND_ADDR[27:14] + 1'b1;
                                          else  if(nand_size==4'h1||nand_size==4'h2||nand_size==4'h3)  NAND_ADDR[35:22] <= NAND_ADDR[35:22] + 1'b1;
                                          else  if(nand_size==4'h4)  NAND_ADDR[33:22] <= NAND_ADDR[33:22] + 1'b1;
                                          else  if(nand_size==4'h5)  NAND_ADDR[33:24] <= NAND_ADDR[33:24] + 1'b1;
                                          else                      NAND_ADDR[35:25] <= NAND_ADDR[35:25] + 1'b1;
                                      end
                                    else
                                        begin
                                           NAND_STATE <= ERASE_FAIL;
                                           NAND_DONE  <= 1'b1;
                                        end
                                end
                               else begin
                                    NAND_STATE  <= NAND_IDLE;
                                    NAND_CE_    <= 1'b1;
                                    NAND_DONE   <= 1'b1;
                                  end
                    end
                READ_ID:
                        begin
                            if((PRE_STATE !=  ADDR_4_ERASE_ID)  &&  COMMAND ==  8'h90)
                                begin
                                      NAND_STATE        <= ADDR_4_ERASE_ID;
                                      PRE_STATE         <= READ_ID;
                                      WAIT_NUM          <= nand_timing[7:0]+1'b1;
                                      READ_ID_NUM       <= nand_id_num;
                                      NAND_ADDR_COUNT   <= 3'b1;
                                end
                            else if (COMMAND !=  8'h70)
                                begin
                                    if (READ_ID_NUM!=3'b0)
                                        begin
                                             NAND_EN_  <= 1'b1;
                                            if(WAIT_NUM>(nand_timing[7:0]+1'b1-HOLD_NUM))
                                                begin 
                                                    NAND_RD_  <= 1'b1;
                                                    WAIT_NUM  <= WAIT_NUM - 1'b1;
                                                    NAND_STATE<= READ_ID;
                                                end
                                            else if (WAIT_NUM > 1)
                                                begin
                                                    WAIT_NUM  <= WAIT_NUM  -  1'b1;
                                                    NAND_RD_  <= 1'b0;
                                                    NAND_STATE<= READ_ID;
                                                end
                                            else  if(WAIT_NUM==1)
                                                begin
                                                    NAND_STATE <= READ_ID;
                                                    NAND_RD_   <= 1'b1;
                                                    WAIT_NUM <= nand_timing[7:0];
                                                    READ_ID_NUM <= READ_ID_NUM - 2'b1;
                                                    if  (READ_ID_NUM==3'b01)
                                                            ID_INFORM[7:0]      <= NAND_I;
                                                    else  if  (READ_ID_NUM==3'b10)
                                                            ID_INFORM[15:8]     <= NAND_I;
                                                    else  if  (READ_ID_NUM==3'b11)
                                                            ID_INFORM[23:16]    <= NAND_I;
                                                    else  if  (READ_ID_NUM==3'b100)
                                                            ID_INFORM[31:24]    <= NAND_I;
                                                    else  if  (READ_ID_NUM==3'b101)
                                                            ID_INFORM[39:32]    <= NAND_I;
                                                    else  if  (READ_ID_NUM==3'b110)
                                                            ID_INFORM[47:40]    <= NAND_I;
                                                end
                                        end
                                    else
                                        begin
                                           NAND_STATE   <= COMMAND_IN;
                                           PRE_STATE    <= READ_ID;
                                           COMMAND      <= 8'h70;
                                           WAIT_NUM     <= nand_timing[7:0];
                                           NAND_CE_     <= 1'b0;
                                           NAND_EN_     <= 1'b0;
                                        end
                                end
                              else
                                 begin
                                    NAND_STATE  <= ID_TO_STATUS;
                                    PRE_STATE   <= READ_ID;
                                    NAND_EN_    <= 1'b1;
                                    COMMAND     <= 8'h70;
                                 end
                        end
                    ID_TO_STATUS:
                         begin
                            if(PRE_STATE != READ_STATUS) 
                              begin
                                 NAND_CE_  <= 1'b0;
                                 NAND_CLE  <= 1'b0;
                                 NAND_ALE  <= 1'b0;
                                 NAND_WR_  <= 1'b1;
                                 NAND_RD_  <= 1'b1;  
                                 NAND_STATE<= READ_STATUS;
                                 PRE_STATE <= ID_TO_STATUS; 
                                 WAIT_NUM  <= nand_timing[7:0]+2'b11;
                                 NAND_EN_  <= 1'b1;
                               end
                             else
                               begin
                                  NAND_DONE    <= 1'b1;
                                  NAND_GO      <= 1'b0; 
                                  NAND_STATE   <= NAND_IDLE;
                                  NAND_CE_     <= 1'b1;
                               end
                         end
                    default :
                          begin
                             NAND_STATE     <= NAND_IDLE; 
                             NAND_CE_       <= 1'b1;
                             NAND_GO        <= 1'b0;
                             NAND_DONE      <= 1'b0;
                             NAND_DMA_REQ   <= 1'b0;
                          end
              endcase
          end
end
endmodule
