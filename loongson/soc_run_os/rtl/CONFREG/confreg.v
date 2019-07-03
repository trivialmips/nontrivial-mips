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

`define ORDER_REG_ADDR 16'h1160   //32'hbfd0_1160
`define LED_ADDR       16'hf000   //32'hbfd0_f000 
`define LED_RG0_ADDR   16'hf004   //32'hbfd0_f004 
`define LED_RG1_ADDR   16'hf008   //32'hbfd0_f008 
`define NUM_ADDR       16'hf010   //32'hbfd0_f010 
`define SWITCH_ADDR    16'hf020   //32'hbfd0_f020 
`define BTN_KEY_ADDR   16'hf024   //32'hbfd0_f024
`define BTN_STEP_ADDR  16'hf028   //32'hbfd0_f028
`define TIMER_ADDR     16'he000   //32'hbfd0_e000 
module confreg(
    aclk,
    aresetn,

    s_awid,
    s_awaddr,
    s_awlen,
    s_awsize,
    s_awburst,
    s_awlock,
    s_awcache,
    s_awprot,
    s_awvalid,
    s_awready,
    s_wid,
    s_wdata,
    s_wstrb,
    s_wlast,
    s_wvalid,
    s_wready,
    s_bid,
    s_bresp,
    s_bvalid,
    s_bready,
    s_arid,
    s_araddr,
    s_arlen,
    s_arsize,
    s_arburst,
    s_arlock,
    s_arcache,
    s_arprot,
    s_arvalid,
    s_arready,
    s_rid,
    s_rdata,
    s_rresp,
    s_rlast,
    s_rvalid,
    s_rready,
    
    order_addr_reg,
    finish_read_order,
    write_dma_end, 

    cr00,
    cr01,
    cr02,
    cr03,
    cr04,
    cr05,
    cr06,
    cr07,

    led,
    led_rg0,
    led_rg1,
    num_csn,
    num_a_g,
    switch,
    btn_key_col,
    btn_key_row,
    btn_step
);
    input           aclk;
    input           aresetn;

    input  [3 :0] s_awid;
    input  [31:0] s_awaddr;
    input  [7 :0] s_awlen;
    input  [2 :0] s_awsize;
    input  [1 :0] s_awburst;
    input         s_awlock;
    input  [3 :0] s_awcache;
    input  [2 :0] s_awprot;
    input         s_awvalid;
    output        s_awready;
    input  [3 :0] s_wid;
    input  [31:0] s_wdata;
    input  [3 :0] s_wstrb;
    input         s_wlast;
    input         s_wvalid;
    output        s_wready;
    output [3 :0] s_bid;
    output [1 :0] s_bresp;
    output        s_bvalid;
    input         s_bready;
    input  [3 :0] s_arid;
    input  [31:0] s_araddr;
    input  [7 :0] s_arlen;
    input  [2 :0] s_arsize;
    input  [1 :0] s_arburst;
    input         s_arlock;
    input  [3 :0] s_arcache;
    input  [2 :0] s_arprot;
    input         s_arvalid;
    output        s_arready;
    output [3 :0] s_rid;
    output [31:0] s_rdata;
    output [1 :0] s_rresp;
    output        s_rlast;
    output        s_rvalid;
    input         s_rready;
    
    output reg [31:0] order_addr_reg;
    input         finish_read_order;
    input         write_dma_end;

    output [31:0]    cr00;
    output [31:0]    cr01;
    output [31:0]    cr02;
    output [31:0]    cr03;
    output [31:0]    cr04;
    output [31:0]    cr05;
    output [31:0]    cr06;
    output [31:0]    cr07;

    output     [15:0] led;
    output     [1 :0] led_rg0;
    output     [1 :0] led_rg1;
    output reg [7 :0] num_csn;
    output reg [6 :0] num_a_g;
    input      [7 :0] switch;
    output     [3 :0] btn_key_col;
    input      [3 :0] btn_key_row;
    input      [1 :0] btn_step;

//
reg  [31:0] led_data;
reg  [31:0] led_rg0_data;
reg  [31:0] led_rg1_data;
reg  [31:0] num_data;
wire [31:0] switch_data;
wire [31:0] btn_key_data;
wire [31:0] btn_step_data;
reg  [31:0] timer;

reg [31:0] cr00,cr01,cr02,cr03,cr04,cr05,cr06,cr07;
reg busy,write,R_or_W;
reg s_wready;

wire ar_enter = s_arvalid & s_arready;
wire r_retire = s_rvalid & s_rready & s_rlast;
wire aw_enter = s_awvalid & s_awready;
wire w_enter  = s_wvalid & s_wready & s_wlast;
wire b_retire = s_bvalid & s_bready;

wire s_arready = ~busy & (!R_or_W| !s_awvalid);
wire s_awready = ~busy & ( R_or_W| !s_arvalid);

always@(posedge aclk)
    if(~aresetn) busy <= 1'b0;
    else if(ar_enter|aw_enter) busy <= 1'b1;
    else if(r_retire|b_retire) busy <= 1'b0;

reg [3 :0] buf_id;
reg [31:0] buf_addr;
reg [7 :0] buf_len;
reg [2 :0] buf_size;
reg [1 :0] buf_burst;
reg        buf_lock;
reg [3 :0] buf_cache;
reg [2 :0] buf_prot;

always@(posedge aclk)
    if(~aresetn) begin
        R_or_W      <= 1'b0;
        buf_id      <= 'b0;
        buf_addr    <= 'b0;
        buf_len     <= 'b0;
        buf_size    <= 'b0;
        buf_burst   <= 'b0;
        buf_lock    <= 'b0;
        buf_cache   <= 'b0;
        buf_prot    <= 'b0;
    end
    else
    if(ar_enter | aw_enter) begin
        R_or_W      <= ar_enter;
        buf_id      <= ar_enter ? s_arid   : s_awid   ;
        buf_addr    <= ar_enter ? s_araddr : s_awaddr ;
        buf_len     <= ar_enter ? s_arlen  : s_awlen  ;
        buf_size    <= ar_enter ? s_arsize : s_awsize ;
        buf_burst   <= ar_enter ? s_arburst: s_awburst;
        buf_lock    <= ar_enter ? s_arlock : s_awlock ;
        buf_cache   <= ar_enter ? s_arcache: s_awcache;
        buf_prot    <= ar_enter ? s_arprot : s_awprot ;
    end

always@(posedge aclk)
    if(~aresetn) write <= 1'b0;
    else if(aw_enter) write <= 1'b1;
    else if(ar_enter)  write <= 1'b0;

always@(posedge aclk)
    if(~aresetn) s_wready <= 1'b0;
    else if(aw_enter) s_wready <= 1'b1;
    else if(w_enter & s_wlast) s_wready <= 1'b0;

always@(posedge aclk)
    if(~aresetn) begin
        cr00 <= 32'd0;  
        cr01 <= 32'd0;  
        cr02 <= 32'd0;  
        cr03 <= 32'd0;
        cr04 <= 32'd0;
        cr05 <= 32'd0;
        cr06 <= 32'd0;
        cr07 <= 32'd0;
    end
    else if(w_enter) begin
        case (buf_addr[15:2])
            14'd0: cr00 <= s_wdata;
            14'd1: cr01 <= s_wdata;
            14'd2: cr02 <= s_wdata;
            14'd3: cr03 <= s_wdata;
            14'd4: cr04 <= s_wdata;
            14'd5: cr05 <= s_wdata;
            14'd6: cr06 <= s_wdata;
            14'd7: cr07 <= s_wdata;
        endcase
    end

reg [31:0] s_rdata;
reg s_rvalid,s_rlast;
wire [31:0] rdata_d = buf_addr[15:2] == 14'd0 ? cr00 :
                      buf_addr[15:2] == 14'd1 ? cr01 :
                      buf_addr[15:2] == 14'd2 ? cr02 :
                      buf_addr[15:2] == 14'd3 ? cr03 :
                      buf_addr[15:2] == 14'd4 ? cr04 :
                      buf_addr[15:2] == 14'd5 ? cr05 :
                      buf_addr[15:2] == 14'd6 ? cr06 :
                      buf_addr[15:2] == 14'd7 ? cr07 :
                      buf_addr[15:0] == `ORDER_REG_ADDR ? order_addr_reg : 
                      buf_addr[15:0] == `LED_ADDR       ? led_data       :
                      buf_addr[15:0] == `LED_RG0_ADDR   ? led_rg0_data   :
                      buf_addr[15:0] == `LED_RG1_ADDR   ? led_rg1_data   :
                      buf_addr[15:0] == `NUM_ADDR       ? num_data       :
                      buf_addr[15:0] == `SWITCH_ADDR    ? switch_data    :
                      buf_addr[15:0] == `BTN_KEY_ADDR   ? btn_key_data   :
                      buf_addr[15:0] == `BTN_STEP_ADDR  ? btn_step_data  :
                      buf_addr[15:0] == `TIMER_ADDR     ? timer          : 32'd0;

always@(posedge aclk)
    if(~aresetn) begin
        s_rdata  <= 'b0;
        s_rvalid <= 1'b0;
        s_rlast  <= 1'b0;
    end
    else if(busy & !write & !r_retire)
    begin
        s_rdata <= rdata_d;
        s_rvalid <= 1'b1;
        s_rlast <= 1'b1; 
    end
    else if(r_retire)
    begin
        s_rvalid <= 1'b0;
    end

reg s_bvalid;
always@(posedge aclk)   
    if(~aresetn) s_bvalid <= 1'b0;
    else if(w_enter) s_bvalid <= 1'b1;
    else if(b_retire) s_bvalid <= 1'b0;

assign s_rid   = buf_id;
assign s_bid   = buf_id;
assign s_bresp = 2'b0;
assign s_rresp = 2'b0;

wire write_order_reg = w_enter & (buf_addr[15:0]==`ORDER_REG_ADDR);
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        order_addr_reg <= 32'h0;
    end
    else if(write_order_reg)
    begin
        order_addr_reg <= s_wdata[31:0];
    end
    else if(write_dma_end | finish_read_order)
    begin
        order_addr_reg[2] <= write_dma_end ? 1'b0 : order_addr_reg[2];
        order_addr_reg[3] <= finish_read_order ? 1'b0 : order_addr_reg[3];
    end
end     
//-------------------------------{timer}begin----------------------------//
wire write_timer = w_enter & (buf_addr[15:0]==`TIMER_ADDR);
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        timer <= 32'd0;
    end
    else if (write_timer)
    begin
        timer <= s_wdata[31:0];
    end
    else
    begin
        timer <= timer + 1'b1;
    end
end
//--------------------------------{timer}end-----------------------------//

//--------------------------------{led}begin-----------------------------//
//led display
//led_data[31:0]
wire write_led = w_enter & (buf_addr[15:0]==`LED_ADDR);
assign led = led_data[15:0];
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        led_data <= 32'h0;
    end
    else if(write_led)
    begin
        led_data <= s_wdata[31:0];
    end
end
//---------------------------------{led}end------------------------------//

//-------------------------------{switch}begin---------------------------//
//switch data
//switch_data[7:0]
assign switch_data = {24'd0,switch};
//--------------------------------{switch}end----------------------------//

//------------------------------{btn key}begin---------------------------//
//btn key data
reg [15:0] btn_key_r;
assign btn_key_data = {16'd0,btn_key_r};

//state machine
reg  [2:0] state;
wire [2:0] next_state;

//eliminate jitter
reg        key_flag;
reg [19:0] key_count;
reg [3:0] state_count;
wire key_start = (state==3'b000) && !(&btn_key_row);
wire key_end   = (state==3'b111) &&  (&btn_key_row);
wire key_sample= key_count[19];
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        key_flag <= 1'd0;
    end
    else if (key_sample && state_count[3]) 
    begin
        key_flag <= 1'b0;
    end
    else if( key_start || key_end )
    begin
        key_flag <= 1'b1;
    end

    if(!aresetn || !key_flag)
    begin
        key_count <= 20'd0;
    end
    else
    begin
        key_count <= key_count + 1'b1;
    end
end

always @(posedge aclk)
begin
    if(!aresetn || state_count[3])
    begin
        state_count <= 4'd0;
    end
    else
    begin
        state_count <= state_count + 1'b1;
    end
end

always @(posedge aclk)
begin
    if(!aresetn)
    begin
        state <= 3'b000;
    end
    else if (state_count[3])
    begin
        state <= next_state;
    end
end

assign next_state = (state == 3'b000) ? ( (key_sample && !(&btn_key_row)) ? 3'b001 : 3'b000 ) :
                    (state == 3'b001) ? (                !(&btn_key_row)  ? 3'b111 : 3'b010 ) :
                    (state == 3'b010) ? (                !(&btn_key_row)  ? 3'b111 : 3'b011 ) :
                    (state == 3'b011) ? (                !(&btn_key_row)  ? 3'b111 : 3'b100 ) :
                    (state == 3'b100) ? (                !(&btn_key_row)  ? 3'b111 : 3'b000 ) :
                    (state == 3'b111) ? ( (key_sample &&  (&btn_key_row)) ? 3'b000 : 3'b111 ) :
                                                                                        3'b000;
assign btn_key_col = (state == 3'b000) ? 4'b0000:
                     (state == 3'b001) ? 4'b1110:
                     (state == 3'b010) ? 4'b1101:
                     (state == 3'b011) ? 4'b1011:
                     (state == 3'b100) ? 4'b0111:
                                         4'b0000;
wire [15:0] btn_key_tmp;
always @(posedge aclk) begin
    if(!aresetn) begin
        btn_key_r   <= 16'd0;
    end
    else if(next_state==3'b000)
    begin
        btn_key_r   <=16'd0;
    end
    else if(next_state == 3'b111 && state != 3'b111) begin
        btn_key_r   <= btn_key_tmp;
    end
end

assign btn_key_tmp = (state == 3'b001)&(btn_key_row == 4'b1110) ? 16'h0001:
                     (state == 3'b001)&(btn_key_row == 4'b1101) ? 16'h0010:
                     (state == 3'b001)&(btn_key_row == 4'b1011) ? 16'h0100:
                     (state == 3'b001)&(btn_key_row == 4'b0111) ? 16'h1000:
                     (state == 3'b010)&(btn_key_row == 4'b1110) ? 16'h0002:
                     (state == 3'b010)&(btn_key_row == 4'b1101) ? 16'h0020:
                     (state == 3'b010)&(btn_key_row == 4'b1011) ? 16'h0200:
                     (state == 3'b010)&(btn_key_row == 4'b0111) ? 16'h2000:
                     (state == 3'b011)&(btn_key_row == 4'b1110) ? 16'h0004:
                     (state == 3'b011)&(btn_key_row == 4'b1101) ? 16'h0040:
                     (state == 3'b011)&(btn_key_row == 4'b1011) ? 16'h0400:
                     (state == 3'b011)&(btn_key_row == 4'b0111) ? 16'h4000:
                     (state == 3'b100)&(btn_key_row == 4'b1110) ? 16'h0008:
                     (state == 3'b100)&(btn_key_row == 4'b1101) ? 16'h0080:
                     (state == 3'b100)&(btn_key_row == 4'b1011) ? 16'h0800:
                     (state == 3'b100)&(btn_key_row == 4'b0111) ? 16'h8000:16'h0000;
//-------------------------------{btn key}end----------------------------//

//-----------------------------{btn step}begin---------------------------//
//btn step data
reg btn_step0_r; //0:press
reg btn_step1_r; //0:press
assign btn_step_data = {30'd0,~btn_step0_r,~btn_step1_r}; //1:press

//-----step0
//eliminate jitter
reg        step0_flag;
reg [19:0] step0_count;
wire step0_start = btn_step0_r && !btn_step[0];
wire step0_end   = !btn_step0_r && btn_step[0];
wire step0_sample= step0_count[19];
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        step0_flag <= 1'd0;
    end
    else if (step0_sample) 
    begin
        step0_flag <= 1'b0;
    end
    else if( step0_start || step0_end )
    begin
        step0_flag <= 1'b1;
    end

    if(!aresetn || !step0_flag)
    begin
        step0_count <= 20'd0;
    end
    else
    begin
        step0_count <= step0_count + 1'b1;
    end

    if(!aresetn)
    begin
        btn_step0_r <= 1'b1;
    end
    else if(step0_sample)
    begin
        btn_step0_r <= btn_step[0];
    end
end

//-----step1
//eliminate jitter
reg        step1_flag;
reg [19:0] step1_count;
wire step1_start = btn_step1_r && !btn_step[1];
wire step1_end   = !btn_step1_r && btn_step[1];
wire step1_sample= step1_count[19];
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        step1_flag <= 1'd0;
    end
    else if (step1_sample) 
    begin
        step1_flag <= 1'b0;
    end
    else if( step1_start || step1_end )
    begin
        step1_flag <= 1'b1;
    end

    if(!aresetn || !step1_flag)
    begin
        step1_count <= 20'd0;
    end
    else
    begin
        step1_count <= step1_count + 1'b1;
    end

    if(!aresetn)
    begin
        btn_step1_r <= 1'b1;
    end
    else if(step1_sample)
    begin
        btn_step1_r <= btn_step[1];
    end
end
//------------------------------{btn step}end----------------------------//

//-------------------------------{led rg}begin---------------------------//
//led_rg0_data[31:0]  led_rg0_data[31:0]
//bfd0_f010           bfd0_f014
wire write_led_rg0 = w_enter & (buf_addr[15:0]==`LED_RG0_ADDR);
wire write_led_rg1 = w_enter & (buf_addr[15:0]==`LED_RG1_ADDR);
assign led_rg0 = led_rg0_data[1:0];
assign led_rg1 = led_rg1_data[1:0];
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        led_rg0_data <= 32'h0;
    end
    else if(write_led_rg0)
    begin
        led_rg0_data <= s_wdata[31:0];
    end

    if(!aresetn)
    begin
        led_rg1_data <= 32'h0;
    end
    else if(write_led_rg1)
    begin
        led_rg1_data <= s_wdata[31:0];
    end
end
//--------------------------------{led rg}end----------------------------//

//---------------------------{digital number}begin-----------------------//
//digital number display
//num_data[31:0]
wire write_num = w_enter & (buf_addr[15:0]==`NUM_ADDR);
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        num_data <= 32'h0;
    end
    else if(write_num)
    begin
        num_data <= s_wdata[31:0];
    end
end


reg [19:0] count;
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        count <= 20'd0;
    end
    else
    begin
        count <= count + 1'b1;
    end
end
//scan data
reg [3:0] scan_data;
always @ ( posedge aclk )  
begin
    if ( !aresetn )
    begin
        scan_data <= 32'd0;  
        num_csn   <= 8'b1111_1111;
    end
    else
    begin
        case(count[19:17])
            3'b000 : scan_data <= num_data[31:28];
            3'b001 : scan_data <= num_data[27:24];
            3'b010 : scan_data <= num_data[23:20];
            3'b011 : scan_data <= num_data[19:16];
            3'b100 : scan_data <= num_data[15:12];
            3'b101 : scan_data <= num_data[11: 8];
            3'b110 : scan_data <= num_data[7 : 4];
            3'b111 : scan_data <= num_data[3 : 0];
        endcase

        case(count[19:17])
            3'b000 : num_csn <= 8'b0111_1111;
            3'b001 : num_csn <= 8'b1011_1111;
            3'b010 : num_csn <= 8'b1101_1111;
            3'b011 : num_csn <= 8'b1110_1111;
            3'b100 : num_csn <= 8'b1111_0111;
            3'b101 : num_csn <= 8'b1111_1011;
            3'b110 : num_csn <= 8'b1111_1101;
            3'b111 : num_csn <= 8'b1111_1110;
        endcase
    end
end

always @(posedge aclk)
begin
    if ( !aresetn )
    begin
        num_a_g <= 7'b0000000;
    end
    else
    begin
        case ( scan_data )
            4'd0 : num_a_g <= 7'b1111110;   //0
            4'd1 : num_a_g <= 7'b0110000;   //1
            4'd2 : num_a_g <= 7'b1101101;   //2
            4'd3 : num_a_g <= 7'b1111001;   //3
            4'd4 : num_a_g <= 7'b0110011;   //4
            4'd5 : num_a_g <= 7'b1011011;   //5
            4'd6 : num_a_g <= 7'b1011111;   //6
            4'd7 : num_a_g <= 7'b1110000;   //7
            4'd8 : num_a_g <= 7'b1111111;   //8
            4'd9 : num_a_g <= 7'b1111011;   //9
            4'd10: num_a_g <= 7'b1110111;   //a
            4'd11: num_a_g <= 7'b0011111;   //b
            4'd12: num_a_g <= 7'b1001110;   //c
            4'd13: num_a_g <= 7'b0111101;   //d
            4'd14: num_a_g <= 7'b1001111;   //e
            4'd15: num_a_g <= 7'b1000111;   //f
        endcase
    end
end
//----------------------------{digital number}end------------------------//
endmodule
