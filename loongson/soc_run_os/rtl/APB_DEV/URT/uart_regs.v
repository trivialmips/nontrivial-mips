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

`include "uart_defines.h"

`define UART_DL1 7:0
`define UART_DL2 15:8
`define UART_DL3 23:16
module uart_regs (clk, rst, clk_carrier,
    addr, dat_i, dat_o, we, re, 

    modem_inputs,
    rts_pad_o, dtr_pad_o, 
    stx_pad_o,TXD_i,srx_pad_i,RXD_o,
    int_o,
    usart_mode,
    rx_en,
    tx2rx_en
);
input        clk;
input        rst ;
input        clk_carrier;
input  [2:0] addr;
input  [7:0] dat_i;
output [7:0] dat_o;
input        we;
input        re;

output       stx_pad_o;
input        srx_pad_i;
input        TXD_i;
output       RXD_o;

input [3:0]  modem_inputs;
output       rts_pad_o;
output       dtr_pad_o;
output       int_o;

output       usart_mode;
output       tx2rx_en;
output       rx_en;

wire [3:0]   modem_inputs;
reg 	     enable;

wire  stx_pad_o;		
wire  srx_pad_i;
wire  srx_pad;

reg  [7:0] dat_o;

wire [2:0] addr;
wire [7:0] dat_i;

reg  [3:0] ier;
reg  [3:0] iir;
reg  [1:0] fcr;  
reg  [4:0] mcr;
reg        infrared;
reg        rx_pol;
reg  [7:0] lcr;
reg  [7:0] msr;
reg [23:0] dl;        
reg 	   start_dlc; 
reg        lsr_mask_d;
reg 	   msi_reset; 

reg [15:0] dlc;  
reg 	   int_o;

reg [3:0]  trigger_level; 
reg 	   rx_reset;
reg 	   tx_reset;
wire   dlab;			   

wire      usart_mode;
wire      usart_rx_en;
wire      usart_tx_en;
wire      tx2rx_en;
reg       sclk_reg;
reg       sclk_en_reg;
reg [7:0] mode_reg;
reg [7:0] fi_di_reg;
reg [7:0] sclk_count;
reg [2:0] repeat_reg;

wire   usart_normal;
wire   usart_irda;
wire   usart_t0;
wire   usart_t1;
wire   rx_en;
wire   tx_en;
wire   sclk_por;

assign usart_normal = mode_reg[1:0]==2'h0;
assign usart_irda   = mode_reg[1:0]==2'h1;
assign usart_t0     = mode_reg[1:0]==2'h2;
assign usart_t1     = mode_reg[1:0]==2'h3;
assign usart_tx_en  = mode_reg[2]==1'b0;
assign usart_rx_en  = mode_reg[2]==1'b1;
assign sclk_por     = mode_reg[3];
assign RXD_o        = sclk_reg^sclk_por;

assign usart_mode  = usart_t0 || usart_t1;
assign rx_en       = usart_normal || usart_irda || usart_mode && usart_rx_en;
assign tx_en       = usart_normal || usart_irda || usart_mode && usart_tx_en;


always @(posedge clk )
begin
    if (rst) begin
        mode_reg  <= 8'h0; 
        fi_di_reg <= 8'h0; 
        repeat_reg<= 3'h4;
        sclk_en_reg<= 1'b0;
    end 
    else if (we && addr==`UART_REG_SR)begin
        if(dlab) 
            fi_di_reg <= dat_i; 
        else
            mode_reg  <= dat_i;
    end
    else begin 
        if(enable) sclk_en_reg   <= mode_reg[4];
        repeat_reg <= mode_reg[7:5];
    end
end

always @(posedge clk)
begin
    if(rst) begin
        sclk_count <= 8'b0;
        sclk_reg   <=1'b0;  
    end      
    else if(usart_mode&&(fi_di_reg>8'h1)&&sclk_en_reg) begin
        if(sclk_count == fi_di_reg[7:1]) begin
            sclk_reg   <= 1'b1;
            sclk_count <= sclk_count + 1'b1;
        end
        else if(sclk_count == fi_di_reg) begin
            sclk_reg   <= 1'b0;
            sclk_count <= 8'b0;
        end
        else begin 
            sclk_count <= sclk_count + 1'b1;
        end
    end
    else begin
        sclk_reg   <=1'b0;  
        sclk_count <= 8'b0;
    end
end 

wire   cts_pad_i, dsr_pad_i, ri_pad_i, dcd_pad_i; 
wire   loopback;		   
wire   cts, dsr, ri, dcd;	   
wire   cts_c, dsr_c, ri_c, dcd_c; 
wire   rts_pad_o, dtr_pad_o;		   

wire [7:0]   lsr;
wire 	     lsr0, lsr1, lsr2, lsr3, lsr4, lsr5, lsr6, lsr7;
reg	     lsr0r, lsr1r, lsr2r, lsr3r, lsr4r, lsr5r, lsr6r, lsr7r;
wire 	     lsr_mask; 

assign    lsr[7:0] = { lsr7r, lsr6r, lsr5r, lsr4r, lsr3r, lsr2r, lsr1r, lsr0r };

assign    {cts_pad_i, dsr_pad_i, ri_pad_i, dcd_pad_i} = modem_inputs;
assign 	  {cts, dsr, ri, dcd} = ~{cts_pad_i,dsr_pad_i,ri_pad_i,dcd_pad_i};

assign    {cts_c, dsr_c, ri_c, dcd_c} = loopback ? {mcr[`UART_MC_RTS],mcr[`UART_MC_DTR],mcr[`UART_MC_OUT1],mcr[`UART_MC_OUT2]}
                                                   : {cts_pad_i,dsr_pad_i,ri_pad_i,dcd_pad_i};

assign    dlab = lcr[`UART_LC_DL];
assign 	  loopback = mcr[4];

assign 	  rts_pad_o = mcr[`UART_MC_RTS];
assign 	  dtr_pad_o = mcr[`UART_MC_DTR];

wire 	  rls_int;  
wire 	  rda_int;  
wire 	  ti_int;   
wire	  thre_int; 
wire 	  ms_int;   

wire tf_push;
reg  rf_pop;
wire [`UART_FIFO_REC_WIDTH-1:0] 	rf_data_out;
wire rf_error_bit; 
wire [`UART_FIFO_COUNTER_W-1:0] 	rf_count;
wire [`UART_FIFO_COUNTER_W-1:0] 	tf_count;
wire [2:0] 	tstate;
wire [3:0] 	rstate;
wire [9:0] 	counter_t;

wire        thre_set_en; 
reg  [7:0]  block_cnt;   
reg  [7:0]  block_value; 
wire        current_finish;
wire        max_repeat_time; 

wire serial_out;
wire serial_out_modulated = ~ (clk_carrier & serial_out); 

uart_transmitter transmitter(.clk(clk), .wb_rst_i(rst), .lcr(lcr), .tf_push(tf_push), .wb_dat_i(dat_i), 

                             .tx2rx_en  (tx2rx_en), 
                             .usart_mode(usart_mode),
                             .srx_pad_i(TXD_i),
                             .enable   (enable && tx_en),
                             .usart_t0(usart_t0),
                             .repeat_time(repeat_reg ),
                             .current_finish(current_finish),
                             .max_repeat_time(max_repeat_time),
                           
                             .stx_pad_o(serial_out), .tstate(tstate), .tf_count(tf_count), 
                             .tx_reset(tx_reset), .lsr_mask(lsr_mask));
wire  rcv_pad_i;
assign rcv_pad_i = ~usart_mode ? srx_pad_i : (rx_en ? TXD_i : 1'b1);
  
uart_sync_flops    i_uart_sync_flops(
    .rst_i           (rst),
    .clk_i           (clk),
    .stage1_rst_i    (1'b0),
    .stage1_clk_en_i (1'b1),
    .async_dat_i     (rcv_pad_i),
    .sync_dat_o      (srx_pad)
  );

  defparam i_uart_sync_flops.width      = 1;
  defparam i_uart_sync_flops.init_value = 1'b1;
wire   serial_in = loopback ? serial_out : rx_pol ? ~srx_pad : srx_pad;
assign stx_pad_o = loopback ? 1'b1 : infrared ? serial_out_modulated : serial_out;

wire  rf_overrun;
wire  rf_push_pulse;
uart_receiver receiver(.clk(clk), .wb_rst_i(rst), .lcr(lcr), .rf_pop(rf_pop), .srx_pad_i(serial_in),
                       .enable(enable && rx_en),
                       .counter_t(counter_t), .rf_count(rf_count), .rf_data_out(rf_data_out), .rf_error_bit(rf_error_bit), 
                       .rf_overrun(rf_overrun), .rx_reset(rx_reset), .lsr_mask(lsr_mask), .rstate(rstate), .rf_push_pulse(rf_push_pulse));


always @(dl or dlab or ier or iir  or fi_di_reg or  mode_reg
    or lcr or lsr or msr or rf_data_out or addr )   
begin
    case (addr)
    `UART_REG_RB : dat_o = dlab ? dl[`UART_DL1] : rf_data_out[10:3];
    `UART_REG_IE : dat_o = dlab ? dl[`UART_DL2] : ier;
    `UART_REG_II : dat_o = dlab ? dl[`UART_DL3] : {4'b1100,iir};
    `UART_REG_LC : dat_o = lcr;
    `UART_REG_LS : dat_o = lsr;
    `UART_REG_MS : dat_o = msr;
    `UART_REG_SR : dat_o = dlab ? fi_di_reg : mode_reg;
     default     : dat_o = 8'b0; 
     endcase 
end

always @(posedge clk )
begin
	if (rst)
		rf_pop <= 0; 
	else
	if (rf_pop)	
		rf_pop <= 0;
	else
	if (re && addr == `UART_REG_RB && !dlab)
		rf_pop <= 1; 
end

wire 	lsr_mask_condition;
wire 	iir_read;
wire    msr_read;
wire	fifo_read;
wire	fifo_write;

assign lsr_mask_condition = (re && addr == `UART_REG_LS && !dlab);
assign iir_read           = (re && addr == `UART_REG_II && !dlab);
assign msr_read           = (re && addr == `UART_REG_MS && !dlab);
assign fifo_read          = (re && addr == `UART_REG_RB && !dlab);
assign fifo_write         = (we && addr == `UART_REG_TR && !dlab);

always @(posedge clk )
begin
  if (rst)
      lsr_mask_d <= 0;
  else 
      lsr_mask_d <= lsr_mask_condition;
end

assign lsr_mask = lsr_mask_condition && ~lsr_mask_d;

always @(posedge clk )
begin
  if (rst)
      msi_reset <= 1;
  else
  if (msi_reset)
      msi_reset <= 0;
  else
  if (msr_read)
      msi_reset <= 1; 
end

always @(posedge clk )
  if (rst)
      lcr <= 8'b00000011; 
  else
  if (we && addr==`UART_REG_LC)
      lcr <= dat_i;

always @(posedge clk )
  if (rst)
  begin
    ier <= 4'b0000; 
    dl[`UART_DL2] <= 8'b0;
  end
  else
    if (we && addr==`UART_REG_IE)
       if (dlab)
       begin
         dl[`UART_DL2] <= dat_i;
	  end
       else
         ier <= dat_i[3:0]; 
    else 
	ier<= ier;

always @(posedge clk )
  if (rst) begin
      fcr      <= 2'b11; 
      rx_reset <= 0;
      tx_reset <= 0;
      dl[`UART_DL3] <= 8'h0;
  end else
  if (we && addr==`UART_REG_FC) begin
    if(dlab) dl[`UART_DL3] <= dat_i;
    else begin
      fcr      <= dat_i[7:6];
      rx_reset <= dat_i[1];
      tx_reset <= dat_i[2];
    end
  end else begin
      rx_reset <= 0;
      tx_reset <= 0;
  end

always @(posedge clk )
  if (rst) begin
      mcr <= 5'b0;
      infrared <= 1'b0; 
      rx_pol <= 1'b0;                  end 
  else
    if(we && addr==`UART_REG_MC) begin
      mcr <= dat_i[4:0];
      infrared <= dat_i[7]; 
      rx_pol <= dat_i[6];      end 

assign tf_push = we & addr==`UART_REG_TR & !dlab;
always @(posedge clk )
  if (rst)
  begin
    dl[`UART_DL1]  <= 8'b0;
    start_dlc      <= 1'b0;
  end
  else
  if (we && addr==`UART_REG_TR)
    if (dlab)
    begin
      dl[`UART_DL1] <= dat_i;
      start_dlc     <= 1'b1; 
    end
    else
    begin
      start_dlc <= 1'b0;
    end 
  else
  begin
	  start_dlc <= 1'b0;
  end 

always @(fcr)
    case (fcr[`UART_FC_TL])
    2'b00 : trigger_level = 1;
    2'b01 : trigger_level = 4;
    2'b10 : trigger_level = 8;
    2'b11 : trigger_level = 14;
    endcase 
	
reg [3:0] delayed_modem_signals;
always @(posedge clk )
begin
  if (rst)
  begin
    msr <= 0;
    delayed_modem_signals[3:0] <= 0;
  end
  else begin
       msr[`UART_MS_DDCD:`UART_MS_DCTS] <= msi_reset ? 4'b0 :
			                      msr[`UART_MS_DDCD:`UART_MS_DCTS] | ({dcd, ri, dsr, cts} ^ delayed_modem_signals[3:0]);
       msr[`UART_MS_CDCD:`UART_MS_CCTS] <= {dcd_c, ri_c, dsr_c, cts_c};
       delayed_modem_signals[3:0] <= {dcd, ri, dsr, cts};
  end
end

assign lsr0 = (rf_count==0 && rf_push_pulse);  
assign lsr1 = rf_overrun;     
assign lsr2 = rf_data_out[1]; 
assign lsr3 = rf_data_out[0]; 
assign lsr4 = rf_data_out[2]; 
assign lsr5 = current_finish && (tf_count==5'b0 && thre_set_en);  
assign lsr6 = (tf_count==5'b0 && thre_set_en && (tstate == 3'd0)); 
assign lsr7 = rf_error_bit | rf_overrun;

reg 	 lsr0_d;

always @(posedge clk )
    if (rst) lsr0_d <= 0;
    else     lsr0_d <= lsr0;

always @(posedge clk )
    if (rst) lsr0r <= 0;
    else     lsr0r <= (rf_count==1 && rf_pop && !rf_push_pulse || rx_reset) ? 0 : 
					                lsr0r || (lsr0 && ~lsr0_d); 

reg lsr1_d; 

always @(posedge clk ) 
    if (rst) lsr1_d <= 0;
    else     lsr1_d <= lsr1;

always @(posedge clk )
    if (rst) lsr1r <= 0;
    else	   lsr1r <= lsr_mask ? 0 : lsr1r || (lsr1 && ~lsr1_d); 

reg lsr2_d; 

always @(posedge clk )
    if (rst) lsr2_d <= 0;
    else     lsr2_d <= lsr2;

always @(posedge clk )
    if (rst) lsr2r <= 0;
    else     lsr2r <= lsr_mask ? 0 : lsr2r || (lsr2 && ~lsr2_d); 

reg lsr3_d; 

always @(posedge clk )
    if (rst) lsr3_d <= 0;
    else     lsr3_d <= lsr3;

always @(posedge clk )
    if (rst) lsr3r <= 0;
    else     lsr3r <= lsr_mask ? 0 : lsr3r || (lsr3 && ~lsr3_d); 

reg lsr4_d; 

always @(posedge clk )
    if (rst) lsr4_d <= 0;
    else     lsr4_d <= lsr4;

always @(posedge clk )
    if (rst) lsr4r <= 0;
    else     lsr4r <= lsr_mask ? 0 : lsr4r || (lsr4 && ~lsr4_d);

reg lsr5_d;
always @(posedge clk )
    if (rst) lsr5_d <= 1;
    else     lsr5_d <= lsr5;

always @(posedge clk )
	if (rst) lsr5r <= 1;
	else     lsr5r <= (fifo_write) ? 0 :  lsr5r || (lsr5 && ~lsr5_d);

reg lsr6_d;

always @(posedge clk ) 
    if (rst) lsr6_d <= 1;
    else     lsr6_d <= lsr6;

always @(posedge clk )
    if (rst) lsr6r <= 1;
    else     lsr6r <= (fifo_write) ? 0 : lsr6r || (lsr6 && ~lsr6_d);

reg lsr7_d;

always @(posedge clk )
    if (rst) lsr7_d <= 0;
    else     lsr7_d <= lsr7;

always @(posedge clk )
    if (rst) lsr7r <= 0;
    else     lsr7r <= lsr_mask ? 0 : lsr7r || (lsr7 && ~lsr7_d);

reg [8:0] M_cnt;
wire [8:0] M_next = M_cnt + dl[`UART_DL3];
wire M_toggle = M_cnt[8] ^ M_next[8];

always @(posedge clk ) 
begin
    if (rst) begin
       dlc <= 0;
       M_cnt <= 8'h0;
    end
    else if (start_dlc | ~ (|dlc)) begin
       dlc <= dl - 1 + M_toggle;    
       M_cnt <= M_next;
    end
    else
       dlc <= dlc - 1;              
end

always @(posedge clk )
begin
    if (rst)
	      enable <= 1'b0;
    else  if (|dl & ~(|dlc))     
        enable <= 1'b1;
    else
	enable <= 1'b0;
end

always @(lcr)
  case (lcr[3:0])
    4'b0000                             : block_value =  95; 
    4'b0100                             : block_value = 103; 
    4'b0001, 4'b1000                    : block_value = 111; 
    4'b1100                             : block_value = 119; 
    4'b0010, 4'b0101, 4'b1001           : block_value = 127; 
    4'b0011, 4'b0110, 4'b1010, 4'b1101  : block_value = 143; 
    4'b0111, 4'b1011, 4'b1110           : block_value = 159; 
    4'b1111                             : block_value = 175; 
  endcase 

always @(posedge clk )
begin
  if (rst)
    block_cnt <= 8'd0;
  else
  if(lsr5r & fifo_write)  
    block_cnt <= usart_t0  ? (block_value + 8'h16) : block_value;
  else
  if (enable & block_cnt != 8'b0)  
    block_cnt <= block_cnt - 1;  
end 

assign thre_set_en = ~(|block_cnt);

assign rls_int  = ier[`UART_IE_RLS] && (lsr[`UART_LS_OE] || lsr[`UART_LS_PE] || lsr[`UART_LS_FE] || lsr[`UART_LS_BI]);
assign rda_int  = ier[`UART_IE_RDA] && (rf_count >= {1'b0,trigger_level});
assign thre_int = ier[`UART_IE_THRE]&& lsr[`UART_LS_TFE];
assign ms_int   = ier[`UART_IE_MS]  && (usart_t0 ? max_repeat_time : (| msr[3:0]));
assign ti_int   = ier[`UART_IE_RDA] && (counter_t == 10'b0) && (|rf_count);

reg 	 rls_int_d;
reg 	 thre_int_d;
reg 	 ms_int_d;
reg 	 ti_int_d;
reg 	 rda_int_d;

always  @(posedge clk )
  if (rst) rls_int_d <= 0;
  else     rls_int_d <= rls_int;

always  @(posedge clk )
  if (rst) rda_int_d <= 0;
  else     rda_int_d <= rda_int;

always  @(posedge clk )
  if (rst) thre_int_d <= 0;
  else     thre_int_d <= thre_int;

always  @(posedge clk )
  if (rst) ms_int_d <= 0;
  else     ms_int_d <= ms_int;

always  @(posedge clk )
  if (rst) ti_int_d <= 0;
  else     ti_int_d <= ti_int;


wire 	 rls_int_rise;
wire 	 thre_int_rise;
wire 	 ms_int_rise;
wire 	 ti_int_rise;
wire 	 rda_int_rise;

assign rda_int_rise   = rda_int & ~rda_int_d;
assign rls_int_rise 	 = rls_int & ~rls_int_d;
assign thre_int_rise  = thre_int & ~thre_int_d;
assign ms_int_rise 	  = ms_int & ~ms_int_d;
assign ti_int_rise 	  = ti_int & ~ti_int_d;

reg rls_int_pnd;
reg rda_int_pnd;
reg thre_int_pnd;
reg ms_int_pnd;
reg ti_int_pnd;

always  @(posedge clk )
  if (rst) rls_int_pnd <= 0; 
  else 
		rls_int_pnd <= lsr_mask ? 0 :  						
			      rls_int_rise ? 1 :						
			      rls_int_pnd && ier[`UART_IE_RLS];	

reg d1_fifo_read;
always @( posedge clk ) d1_fifo_read <= fifo_read;

always  @(posedge clk)
  if (rst) rda_int_pnd <= 0; 
  else     rda_int_pnd <= ((rf_count == {1'b0,trigger_level}) && d1_fifo_read) ? 0 :  	
							rda_int_rise ? 1 :						
							rda_int_pnd && ier[`UART_IE_RDA];	

always  @(posedge clk )
  if (rst) thre_int_pnd <= 0; 
  else 
		thre_int_pnd <= fifo_write || (iir_read & ~iir[`UART_II_IP] & iir[`UART_II_II] == `UART_II_THRE)? 0 : 
							thre_int_rise ? 1 :
							thre_int_pnd && ier[`UART_IE_THRE];

always  @(posedge clk )
  if (rst) ms_int_pnd <= 0; 
  else 
		ms_int_pnd <= msr_read ? 0 : ms_int_rise ? 1 :
		                                ms_int_pnd && ier[`UART_IE_MS];

always  @(posedge clk )
  if (rst) ti_int_pnd <= 0; 
  else 
		ti_int_pnd <= fifo_read ? 0 : ti_int_rise ? 1 :
						 ti_int_pnd && ier[`UART_IE_RDA];

always @(posedge clk )
begin
  if (rst) int_o <= 1'b0;
  else     int_o <= rls_int_pnd ? ~lsr_mask :
                       rda_int_pnd ? 1         :
                       ti_int_pnd  ? ~fifo_read:
                       thre_int_pnd? !(fifo_write & iir_read) :
                       ms_int_pnd  ? ~msr_read :
                       0;	
end


always @(posedge clk )
begin
  if (rst)
      iir <= 1;
  else
  if (rls_int_pnd)  
  begin
    iir[`UART_II_II] <= `UART_II_RLS;	
    iir[`UART_II_IP] <= 1'b0;		
  end else 
  if (rda_int_pnd)
  begin
    iir[`UART_II_II] <= `UART_II_RDA;
    iir[`UART_II_IP] <= 1'b0;
  end
  else if (ti_int_pnd)
  begin
    iir[`UART_II_II] <= `UART_II_TI;
    iir[`UART_II_IP] <= 1'b0;
  end
  else if (thre_int_pnd)
  begin
    iir[`UART_II_II] <= `UART_II_THRE;
    iir[`UART_II_IP] <= 1'b0;
  end
  else if (ms_int_pnd)
  begin
    iir[`UART_II_II] <= `UART_II_MS;
    iir[`UART_II_IP] <= 1'b0;
  end else	
  begin
    iir[`UART_II_II] <= 0;
    iir[`UART_II_IP] <= 1'b1;
  end
end

endmodule
