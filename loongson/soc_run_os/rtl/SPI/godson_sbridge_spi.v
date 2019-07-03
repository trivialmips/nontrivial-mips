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

module spi_flash_ctrl(
    input           aclk,
    input           aresetn,
    input [15:0]    spi_addr,
    input           power_down_req,
    output          power_down_ack,
    input           fast_startup,

    input [3:0]     s_awlen,
    input [3:0]     s_awcache,
    input [3:0]     s_awid,
    input [31:0]    s_awaddr,
    input [2:0]     s_awsize,
    input [2:0]     s_awprot,
    input [1:0]     s_awburst,
    input [1:0]     s_awlock,
    input           s_awvalid,
    output          s_awready,

    input [3:0]     s_wid,
    input [31:0]    s_wdata,
    input [3:0]     s_wstrb,
    input           s_wlast,
    input           s_wvalid,
    output          s_wready,

    output [3:0]    s_bid,
    output [1:0]    s_bresp,
    output          s_bvalid,
    input           s_bready,

    input [3:0]     s_arlen,  
    input [3:0]     s_arcache,
    input [3:0]     s_arid,
    input [31:0]    s_araddr,
    input [2:0]     s_arsize,
    input [2:0]     s_arprot,
    input [1:0]     s_arburst,
    input [1:0]     s_arlock,
    input           s_arvalid,
    output          s_arready,

    output [3:0]    s_rid,
    output [31:0]   s_rdata,
    output [1:0]    s_rresp,
    output          s_rlast,
    output          s_rvalid,
    input           s_rready,

    output [3:0]    csn_o,
    output [3:0]    csn_en, 
    output          sck_o,
    input           sdo_i,
    output          sdo_o,
    output          sdo_en, 
    input           sdi_i,
    output          sdi_o,
    output          sdi_en,
    output          inta_o
);

   wire             areset = ~aresetn;

   wire             param_memory_en;
   wire             param_burst_en;
   wire             param_fast_read;
   wire             param_dual_io;
   wire [1:0]       param_tCSH;
   wire             param_tFAST;

   reg [9:0]        rd_state;
   reg [9:0]        rd_state_nxt;

   parameter        S_IDLE   = 10'b0000000001;
   parameter        S_IOREAD = 10'b0000000010;
   parameter        S_CSTURN = 10'b0000000100;
   parameter        S_ADDR   = 10'b0000001000;
   parameter        S_DATA   = 10'b0000010000;
   parameter        S_WAITBUS= 10'b0000100000;
   parameter        S_PDENTER= 10'b0001000000;
   parameter        S_PDEXIT = 10'b0010000000;
   parameter        S_STARTUP= 10'b0100000000;
   parameter        S_PWRDOWN= 10'b1000000000;

   wire             s_idle   = rd_state[0];
   wire             s_ioread = rd_state[1];
   wire             s_csturn = rd_state[2];
   wire             s_addr   = rd_state[3];
   wire             s_data   = rd_state[4];
   wire             s_waitbus= rd_state[5];
   wire             s_pdenter= rd_state[6];
   wire             s_pdexit = rd_state[7];
   wire             s_startup= rd_state[8];
   wire             s_pwrdown= rd_state[9];

   wire             ns_idle   = rd_state_nxt[0];
   wire             ns_ioread = rd_state_nxt[1];
   wire             ns_csturn = rd_state_nxt[2];
   wire             ns_addr   = rd_state_nxt[3];
   wire             ns_data   = rd_state_nxt[4];
   wire             ns_waitbus= rd_state_nxt[5];
   wire             ns_pdenter= rd_state_nxt[6];
   wire             ns_pdexit = rd_state_nxt[7];
   wire             ns_startup= rd_state_nxt[8];
   wire             ns_pwrdown= rd_state_nxt[9];

   reg              pdreq_r;

   reg [15:0]       cs_timer;
   reg              cs;
   reg [23:0]       nxt_addr;

   wire             write_valid;
   wire             reg_acc = s_ioread | write_valid;
   wire             reg_ack;
   wire [7:0]       reg_dat_i, reg_dat_o;
   wire [7:0]       param_o;

   reg [31:0]       shift_reg;
   reg [ 1:0]       sample;
   wire [31:0]      shift_reg_nxt;
   wire             sr_shift_inst;
   wire             sr_shift_one;
   wire             sr_shift_two;
   reg              sr_shift_inst_r;
   reg              sr_shift_two_r;
   wire             sample_en;
   wire             shift_en;
   wire             dual_out;
   wire             dual_in;
   wire [1:0]       serial_out;
   wire             cyc_end;          


   reg [2:0]        bit_cnt;          
   wire             spi_pause;        
   wire             spibus_busy;      

   reg [5:0]        adbit_cnt;        
   reg              spi_run;
   reg              sck;

   reg              buf_busy;
   reg [31:0]       buf_addr;
   reg [ 3:0]       buf_len;
   reg [ 2:0]       buf_size;
   reg [ 3:0]       buf_id;
   reg              buf_write;
   reg              buf_wrap;

   assign           s_arready = s_idle & ~pdreq_r & ~buf_busy & ~s_awvalid;
   assign           s_awready = s_idle & ~pdreq_r & ~buf_busy;

   reg              buf_busy_d;
   wire             new_axireq = ~buf_busy_d & buf_busy;
   wire             io_hit =(buf_addr[31:4] == {spi_addr, 12'b0}) &
                            (buf_len  == 4'b0);

   wire [63:0]      buf_addr_t = (buf_addr[31:20]==12'h1fc)? 
                                    {12'h0, buf_addr[19:0]}: 
                                    { 8'h0, buf_addr[23:0]}; 

   wire             burst_cont   = param_burst_en & cs &
                                  (buf_addr_t[23:0] == nxt_addr[23:0]);

   wire             burst_switch = param_burst_en & cs &
                                  (buf_addr_t[23:0] != nxt_addr[23:0]);

   reg [7:0]        tot_bytes;
   wire             byte_ready;

   always @(posedge aclk) begin
      if (areset) begin
         buf_busy  <= 1'b0;
         buf_write <= 1'b0;
         tot_bytes <= 8'b0;
      end else begin
         if ((s_arvalid|s_awvalid)&~buf_busy&s_idle&~pdreq_r) begin
            buf_busy <= 1'b1;
            buf_addr <= s_awvalid ? s_awaddr : s_araddr;
            buf_size <= s_awvalid ? s_awsize : s_arsize;
            buf_len  <= s_awvalid ? s_awlen  : s_arlen;
            buf_id   <= s_awvalid ? s_awid   : s_arid;
            buf_write<= s_awvalid;
            buf_wrap <= s_arvalid & (s_arburst==2'b10) & 
                        (|s_araddr[4:2]) & (|s_arlen);
            tot_bytes<= {8{s_arvalid&~s_awvalid}}&
                        (({4'b0,s_arlen} << s_arsize)|
                         ((8'b1<<s_arsize)-8'b1));
         end else begin
            if (s_bvalid & s_bready | s_rvalid & s_rready & s_rlast)
              buf_busy <= 1'b0;
            if (s_rvalid & s_rready)
              buf_len  <= buf_len - 4'b1;
            if (s_wvalid & s_wready & s_wlast)
              buf_write <= 1'b0;
            if (byte_ready & ~s_rvalid) begin
              tot_bytes <= tot_bytes - 8'b1;
            end
         end
      end
      buf_busy_d <= buf_busy;
   end

   reg    second_write; 
   always @(posedge aclk) begin
      if (areset) second_write <= 1'b0;
      else second_write <= (s_wvalid & s_wready & io_hit & (buf_size==3'b1) & (buf_addr[2:0]==3'b10));
   end

   assign s_wready = buf_busy & buf_write & s_idle;
   assign write_valid = s_wvalid & s_wready & io_hit &
                        ((buf_size==3'b0) | (buf_size==3'b1 && buf_addr[2:0]==3'b10)) |
                        second_write;

   reg  bvalid;
   always @(posedge aclk) begin
      if      (areset                       ) bvalid <= 1'b0;
      else if (s_bvalid & s_bready          ) bvalid <= 1'b0;
      else if (s_wvalid & s_wready & s_wlast) bvalid <= 1'b1;
   end
   assign s_bvalid = bvalid;
   assign s_bid    = buf_id;
   assign s_bresp  = 2'b00;
   

   reg       rvalid;
   reg [7:0] rdata[3:0];
   always @(posedge aclk) begin
      if (areset)
        rvalid <= 1'b0;
      else if (s_rvalid & s_rready) begin
         rvalid <= 1'b0;
      end else if (new_axireq & ~buf_write & io_hit & s_idle) begin
         rvalid <= 1'b1;
         rdata[buf_addr[1:0]] <= reg_dat_o;
      end else if (s_data & byte_ready & ~rvalid) begin
         rvalid               <= (&nxt_addr[1:0]) | (~|tot_bytes);
         rdata[nxt_addr[1:0]] <= shift_reg_nxt[7:0];
      end
   end
   assign s_rvalid = rvalid;
   assign s_rdata  = {rdata[ 3], rdata[ 2], rdata[ 1], rdata[ 0]};
   assign s_rlast  = ~|buf_len;
   assign s_rid    = buf_id;
   assign s_rresp  = 2'b00;

   wire [1:0] sample_in = {2{s_data}}&(param_tFAST ? {sdi_i, sdo_i} : 
                                                      sample[1:0]  ); 

   assign shift_reg_nxt = sr_shift_inst_r?{shift_reg[30:0], 1'b0          }:
                          sr_shift_two_r ?{shift_reg[29:0], sample_in[1:0]}:
                                          {shift_reg[30:0], sample_in[1]  };

   always @(posedge aclk) begin
      if (s_pwrdown & ~ns_pwrdown) begin
         shift_reg[31:24] <= 8'hab;          
      end else if (~s_pdenter & ns_pdenter) begin
         shift_reg[31:24] <= 8'hb9;          
      end else if (~s_addr & ns_addr) begin
         shift_reg[31:24] <= param_dual_io   ? 8'hbb:
                             param_fast_read ? 8'h0b:
                                               8'h03;
         shift_reg[23: 0] <= nxt_addr[23:0];
      end else if (shift_en) begin
         shift_reg[31: 0] <= shift_reg_nxt;
      end
      if (sample_en) sample[1:0] <= {sdi_i, sdo_i};
   end
   assign serial_out = param_dual_io & dual_out ? shift_reg[31:30] :
                                           {1'b0, shift_reg[31]};

   wire [3:0] espr;
   reg [11:0] clkcnt;
   wire       clkena = ~|clkcnt & ~spi_pause;
   reg  [3:0] cswcnt;
   always @(posedge aclk)
     if (areset)
       clkcnt <= 12'h0;
     else if (~spi_pause) begin
        if ((|clkcnt) & (spi_run|s_csturn))
          clkcnt <= clkcnt - 11'h1;
        else
          case (espr) // synopsys full_case parallel_case
            4'b0000: clkcnt <= 12'h0;   
            4'b0001: clkcnt <= 12'h1;   
            4'b0010: clkcnt <= 12'h7;   
            4'b0011: clkcnt <= 12'hf;   
            4'b0100: clkcnt <= 12'h3;   
            4'b0101: clkcnt <= 12'h1f;  
            4'b0110: clkcnt <= 12'h3f;  
            4'b0111: clkcnt <= 12'h7f;  
            4'b1000: clkcnt <= 12'hff;  
            4'b1001: clkcnt <= 12'h1ff; 
            4'b1010: clkcnt <= 12'h3ff; 
            4'b1011: clkcnt <= 12'h7ff; 
            default: clkcnt <= 12'h7ff;
          endcase
     end 
   
   always @(posedge aclk)
     if (areset|~s_csturn) cswcnt <= 4'b0;
     else if (clkena)      cswcnt <= cswcnt + 4'b1;

   wire [3:0] cswcnt_w = cswcnt | (4'b1110 << param_tCSH);

   always @(posedge aclk) begin
      if      (areset         )  spi_run <= 1'b0;
      else if (ns_addr|ns_data)  spi_run <= 1'b1;
      else if (ns_idle|ns_csturn)spi_run <= 1'b0;
      else if (ns_pdexit |ns_pdenter)spi_run <= 1'b1;
      else if (ns_startup|ns_pwrdown)spi_run <= 1'b0;

      if      (s_idle |s_csturn) adbit_cnt <= 6'b0;
      else if (s_addr & cyc_end) adbit_cnt <= adbit_cnt + 6'b1;

      if      (areset          ) sck <= 1'b0;
      else if (spi_run & clkena) sck <= ~sck;

      if      (areset | s_idle ) bit_cnt <= 3'h0;
      else if (s_data & cyc_end) bit_cnt <= bit_cnt + 3'b1;
      else if (s_pdenter&cyc_end)bit_cnt <= bit_cnt + 3'b1;
      else if (s_pdexit &cyc_end)bit_cnt <= bit_cnt + 3'b1;

   end

   assign byte_ready = s_data & cyc_end & (&({param_dual_io,2'b00}|bit_cnt[2:0]));

   always @(posedge aclk) begin
      if (areset | ~param_memory_en) begin
         nxt_addr <= 24'b0;
         cs_timer <= 16'b0;
         cs       <= 1'b0;
      end else begin
         nxt_addr <= new_axireq & s_idle    ? buf_addr_t :
                     byte_ready & ~spi_pause? (buf_wrap&(&nxt_addr[4:0]) & ~(tot_bytes == 8'b0)?
                                                   nxt_addr - 24'h1f    :
                                                   nxt_addr + 24'b1) :
                                              nxt_addr;
         cs_timer <= buf_busy|(~cs&~s_startup)|s_pdexit ? 16'b0 :
                     ~&cs_timer   ? cs_timer+16'b1 :
                                    cs_timer ;
         cs <= ns_addr                             ? 1'b1 :
               ns_csturn | (~buf_busy & (&cs_timer)) ? 1'b0 :
               ~param_burst_en & ns_idle           ? 1'b0 :
               write_valid & (buf_addr[3:0]==4'h2) ? 1'b0 :
               ns_pdenter | ns_pdexit              ? 1'b1 :
               ns_pwrdown | ns_startup             ? 1'b0 :
                                                     cs;
      end
   end

   assign cyc_end       = spi_run & sck & clkena;

   assign shift_en      = spi_run & sck & clkena;
   assign sample_en     = spi_run &~sck & clkena & s_data;

   assign spi_pause     = rvalid;

   assign sr_shift_inst = s_addr & (adbit_cnt < 6'd8);
   assign sr_shift_two  =(s_addr & (adbit_cnt >=6'd8) | s_data) & param_dual_io;
   always @(posedge aclk) begin
      sr_shift_inst_r <= areset                    ? 1'b0 :
                         cyc_end|(~s_addr&ns_addr) ? ns_addr & (adbit_cnt < 6'd7) :
                                                     sr_shift_inst_r;
      sr_shift_two_r  <= areset                    ? 1'b0 :
                         cyc_end|(~s_data&ns_data) ? (s_addr & (adbit_cnt >=6'd7) | ns_data) & param_dual_io :
                                                     sr_shift_two_r;
   end

   assign sr_shift_one  = 1'bz; 
   wire addr_done;
   assign addr_done     = param_dual_io   ? adbit_cnt == 6'd23 :
                          param_fast_read ? adbit_cnt == 6'd39 :
                                            adbit_cnt == 6'd31 ;
   assign dual_out      = param_dual_io &
                          (adbit_cnt >= 6'd8 && adbit_cnt < 6'd22);
   reg    dual_in_r;
   assign dual_in       = param_dual_io &
                          (adbit_cnt >= 6'd22 | s_data | dual_in_r);
   always @(posedge aclk) begin
      dual_in_r <= areset            ? 1'b0 :
                   s_csturn&cswcnt[0]? 1'b0 :
                   ~cs               ? 1'b0 :
                   dual_in           ? 1'b1 : dual_in_r;
   end


   always @(posedge aclk) begin
      pdreq_r <= power_down_req;
   end
   wire   go_power_down  = pdreq_r & ~buf_busy;
   assign power_down_ack = s_pwrdown | s_pdexit | s_startup;

   always @(posedge aclk) begin
      rd_state <= areset ? S_PWRDOWN : rd_state_nxt;
   end

   always @(*) begin
      rd_state_nxt = rd_state;
      case (rd_state) // synopsys parallel_case
        S_IDLE  :if (new_axireq & ~buf_write) begin
                    rd_state_nxt = io_hit       ? S_IOREAD:
                                   spibus_busy  ? S_WAITBUS:
                                   burst_cont   ? S_DATA  :
                                   S_CSTURN;
                 end else if (go_power_down) begin
                    rd_state_nxt = cs ? S_CSTURN : 
                                        S_PDENTER;
                 end
        S_IOREAD: rd_state_nxt = S_IDLE;
        S_CSTURN: rd_state_nxt = clkena & (&cswcnt_w)? (go_power_down? S_PDENTER:S_ADDR):
                                                       S_CSTURN;
        S_ADDR  : rd_state_nxt = clkena & sck &
                                 addr_done ? S_DATA : S_ADDR;
        S_DATA  : rd_state_nxt = byte_ready & ~spi_pause & ~|tot_bytes     ? S_IDLE:
                                 byte_ready & ~spi_pause & buf_wrap 
                                                         & (&nxt_addr[4:0])? S_CSTURN:
                                 byte_ready & ~spi_pause & ~param_burst_en ? S_CSTURN:
                                                                             S_DATA;
        S_WAITBUS:rd_state_nxt = spibus_busy ? S_WAITBUS : S_ADDR;

        S_PWRDOWN:rd_state_nxt = go_power_down  ? S_PWRDOWN : S_PDEXIT;
        S_PDEXIT :rd_state_nxt = cyc_end & (&bit_cnt[2:0]) ? S_STARTUP : S_PDEXIT;
        S_PDENTER:rd_state_nxt = cyc_end & (&bit_cnt[2:0]) ? S_PWRDOWN : S_PDENTER;
        S_STARTUP:rd_state_nxt = &(cs_timer[10:0]|{{5{fast_startup}}, 6'b0}) ? S_IDLE :
                                                  S_STARTUP;
      endcase 
   end


   wire       ss_sck, ss_mosi, ss_miso;
   wire [7:0] param, softcs, param2;
   wire       sspi_write = buf_write | second_write;

   simple_spi_top simple_spi(
                             .clk_i  (aclk          ), 
                             .rst_i  (aresetn       ), 
                             .cyc_i  (buf_busy      ), 
                             .stb_i  (reg_acc       ), 
                             .adr_i  (buf_addr[3:0] ), 
                             .we_i   (sspi_write    ), 
                             .dat_i  (reg_dat_i     ), 
                             .dat_o  (reg_dat_o     ), 
                             .ack_o  (reg_ack       ), 
                             .inta_o (inta_o        ), 

                             .sck_o  (ss_sck        ), 
                             .mosi_o (ss_mosi       ), 
                             .miso_i (ss_miso       ), 

                             .param  (param         ),
                             .param2 (param2        ),
                             .softcs (softcs        ),
                             .busy   (spibus_busy   )
                             );
   assign     ss_miso = sdi_i;

   assign     reg_dat_i = second_write        ? s_wdata[ 31: 24] :
                          buf_addr[1:0]==2'h0 ? s_wdata[  7:  0] :
                          buf_addr[1:0]==2'h1 ? s_wdata[ 15:  8] :
                          buf_addr[1:0]==2'h2 ? s_wdata[ 23: 16] :
                                                s_wdata[ 31: 24] ;

   assign     param_memory_en = param[0];
   assign     param_burst_en  = param[1];
   assign     param_fast_read = param[2];
   assign     param_dual_io   = param[3];
   assign     espr            = param[7:4];

   assign     param_tCSH      = param2[1:0];
   assign     param_tFAST     = param2[2];
   assign     param_scs       = param2[3];  

   assign     csn_en[0] = param_memory_en? 1'b0: ~softcs[0];
   assign     csn_o [0] = param_memory_en? ~cs :  softcs[4];

   assign     csn_en[3:1] =~softcs[3:1];
   assign     csn_o [3:1] = softcs[7:5]|{3{cs|(~spibus_busy & param_scs)}}; 

   assign     sdi_en = ~spibus_busy&param_memory_en? ~dual_out     : 1'b1;
   assign     sdi_o  = ~spibus_busy&param_memory_en? serial_out[1] : 1'b0;

   assign     sdo_en = ~spibus_busy&param_memory_en? dual_in       : 1'b0;
   assign     sdo_o  = ~spibus_busy&param_memory_en? serial_out[0] | s_data
                                                                   : ss_mosi;

   assign     sck_o  = ~spibus_busy&param_memory_en? sck           : ss_sck;

endmodule 


module simple_spi_top(
  input  wire       clk_i,         
  input  wire       rst_i,         
  input  wire       cyc_i,         
  input  wire       stb_i,         
  input  wire [3:0] adr_i,         
  input  wire       we_i,          
  input  wire [7:0] dat_i,         
  output reg  [7:0] dat_o,         
  output reg        ack_o,         
  output reg        inta_o,        

  output reg        sck_o,         
  output wire       mosi_o,        
  input  wire       miso_i,        

  output reg  [7:0] param,
  output reg  [7:0] param2,
  output reg  [7:0] softcs,
  output reg        busy
);

  reg  [7:0] spcr;       
  wire [7:0] spsr;       
  reg  [7:0] sper;       
  reg  [7:0] treg, rreg; 

  wire [7:0] rfdout;
  reg        wfre, rfwe;
  wire       rfre, rffull, rfempty;
  wire [7:0] wfdout;
  wire       wfwe, wffull, wfempty;

  wire      tirq;     
  wire      wfov;     
  reg [1:0] state;    
  reg [2:0] bcnt;

  wire wb_acc = cyc_i & stb_i;       
  wire wb_wr  = wb_acc & we_i;       

  always @(posedge clk_i)
    if (~rst_i)
      begin
          spcr <= 8'h12;  
          sper <= 8'h00;
          `ifdef FAST_SIMU
          param<= 8'h1;  
          param2<=8'h07;  
          `else
          param<= 8'h1;   
          param2<=8'h03;  
          `endif
          softcs<=8'hf0;  
      end
    else if (wb_wr)
      begin
        if (adr_i == 4'b00)
          spcr <= dat_i | 8'h10; 

        if (adr_i == 4'b11)
          sper <= dat_i;

        if (adr_i == 4'b0100)
          param <= dat_i;
        if (adr_i == 4'b0101)
          softcs<= dat_i;
        if (adr_i == 4'b0110)
          param2 <= dat_i;
      end

  assign wfwe = wb_acc & (adr_i == 4'b10) & ack_o &  we_i;
  assign wfov = wfwe & wffull;

  always @(*) 
    case(adr_i) // synopsys full_case parallel_case
      4'b0000: dat_o = spcr;
      4'b0001: dat_o = spsr;
      4'b0010: dat_o = rfdout;
      4'b0011: dat_o = sper;
      4'b0100: dat_o = param;
      4'b0101: dat_o = softcs;
      4'b0110: dat_o = param2;
      default  dat_o = 8'h0;
    endcase

  assign rfre = wb_acc & (adr_i == 2'b10) & ack_o & ~we_i;

  always @(posedge clk_i)
    ack_o <= 1'b1;

  wire       spie = spcr[7];   
  wire       spe  = spcr[6];   
  wire       dwom = spcr[5];   
  wire       mstr = spcr[4];   
  wire       cpol = spcr[3];   
  wire       cpha = spcr[2];   
  wire [1:0] spr  = spcr[1:0]; 

  wire [1:0] icnt = sper[7:6]; 
  wire [1:0] spre = sper[1:0]; 
  wire     smh_spi= sper[2]; 

  wire [3:0] espr = {spre, spr};

  wire wr_spsr = wb_wr & (adr_i == 2'b01);

  reg spif;
  always @(posedge clk_i)
    if (~spe)
      spif <= 1'b0;
    else
      spif <= (tirq | spif) & ~(wr_spsr & dat_i[7]);

  reg wcol;
  always @(posedge clk_i)
    if (~spe)
      wcol <= 1'b0;
    else
      wcol <= (wfov | wcol) & ~(wr_spsr & dat_i[6]);

  assign spsr[7]   = spif;
  assign spsr[6]   = wcol;
  assign spsr[5:4] = 2'b00;
  assign spsr[3]   = wffull;
  assign spsr[2]   = wfempty;
  assign spsr[1]   = rffull;
  assign spsr[0]   = rfempty;
  

  always @(posedge clk_i)
    inta_o <= spif & spie;

  spi_fifo4 #(8)
  rfifo(
        .clk   ( clk_i   ),
        .rst   ( rst_i   ),
        .clr   ( ~spe    ),
        .din   ( treg    ),
        .we    ( rfwe    ),
        .dout  ( rfdout  ),
        .re    ( rfre    ),
        .full  ( rffull  ),
        .empty ( rfempty )
  ),
  wfifo(
        .clk   ( clk_i   ),
        .rst   ( rst_i   ),
        .clr   ( ~spe    ),
        .din   ( dat_i   ),
        .we    ( wfwe    ),
        .dout  ( wfdout  ),
        .re    ( wfre    ),
        .full  ( wffull  ),
        .empty ( wfempty )
  );

  reg [11:0] clkcnt;
  always @(posedge clk_i)
    if(spe & (|clkcnt & |state))
      clkcnt <= clkcnt - 11'h1;
    else
      case (espr) // synopsys full_case parallel_case
        4'b0000: clkcnt <= 12'h0;   
        4'b0001: clkcnt <= 12'h1;   
        4'b0010: clkcnt <= 12'h7;   
        4'b0011: clkcnt <= 12'hf;   
        4'b0100: clkcnt <= 12'h3;   
        4'b0101: clkcnt <= 12'h1f;  
        4'b0110: clkcnt <= 12'h3f;  
        4'b0111: clkcnt <= 12'h7f;  
        4'b1000: clkcnt <= 12'hff;  
        4'b1001: clkcnt <= 12'h1ff; 
        4'b1010: clkcnt <= 12'h3ff; 
        4'b1011: clkcnt <= 12'h7ff; 
        default:;
      endcase

  wire ena = ~|clkcnt;
  reg sample;
  always @(posedge clk_i)
    if (~spe)
      begin
          state <= 2'b00; 
          bcnt  <= 3'h0;
          treg  <= 8'h00;
          wfre  <= 1'b0;
          rfwe  <= 1'b0;
          sck_o <= 1'b0;
      end
    else if (smh_spi)
      begin
         wfre <= 1'b0;
         rfwe <= 1'b0;

         case (state) //synopsys full_case parallel_case
           2'b00: 
              begin
                  bcnt  <= 3'h7;   
                  treg  <= wfdout; 
                  sck_o <= cpol;   

                  if (~wfempty) begin
                    wfre  <= 1'b1;
                    state <= 2'b01;
                  end
              end

           2'b01: 
              if (ena) begin
                sck_o   <= ~sck_o; 
                state   <= 2'b10;
                if (cpha==0) sample <= miso_i;
              end

           2'b10: 
              if (ena) begin
                sck_o <= ~sck_o;
                state <= 2'b11;
                if (cpha==0) begin
                   treg   <= {treg[6:0], sample};
                end else begin
                   sample <= miso_i;
                end
              end

           2'b11: 
              if (ena) begin
                bcnt <= bcnt -3'h1;
                if (cpha==0) begin
                   sample <= miso_i;
                end else begin
                   treg   <= {treg[6:0], sample};
                end

                if (~|bcnt) begin
                  state <= 2'b00;
                  sck_o <= cpol;
                  rfwe  <= 1'b1;
                end else begin
                  state <= 2'b10;
                  sck_o <= ~sck_o;
                end

              end

         endcase
      end
    else
    begin
        wfre <= 1'b0;
        rfwe <= 1'b0;

        case (state) //synopsys full_case parallel_case
        2'b00: 
        begin
            bcnt  <= 3'h7;   
            treg  <= wfdout; 
            sck_o <= cpol;   

            if (~wfempty) begin
                wfre  <= 1'b1;
                state <= 2'b01;
                if (cpha) sck_o <= ~sck_o;
            end
        end

        2'b01: 
        if (ena) begin
            sck_o <= ~sck_o;
            state <= 2'b11;
        end

        2'b11: 
        if (ena) begin
            treg <= {treg[6:0], miso_i};
            bcnt <= bcnt -3'h1;

            if (~|bcnt) begin
                state <= 2'b00;
                sck_o <= cpol;
                rfwe  <= 1'b1;
            end
            else begin
                state <= 2'b01;
                sck_o <= ~sck_o;
            end
        end

        2'b10: state <= 2'b00;
        default: state <=2'b00;
        endcase
    end

  assign mosi_o = treg[7];

  reg [1:0] tcnt; 
  always @(posedge clk_i)
    if (~spe)
      tcnt <= icnt;
    else if (rfwe) begin
      if (|tcnt)
        tcnt <= tcnt - 2'h1;
      else
        tcnt <= icnt;
    end

  assign tirq = ~|tcnt & rfwe;

  always @(posedge clk_i)
    busy <= ~wfempty | (|state);
endmodule

module spi_fifo4(clk, rst, clr,  din, we, dout, re, full, empty);

parameter dw = 8;

input           clk, rst;
input           clr;
input   [dw:1]  din;
input           we;
output  [dw:1]  dout;
input           re;
output          full, empty;

reg     [dw:1]  mem[0:3];
reg     [1:0]   wp;
reg     [1:0]   rp;
wire    [1:0]   wp_p1;
wire    [1:0]   wp_p2;
wire    [1:0]   rp_p1;
wire            full, empty;
reg             gb;

always @(posedge clk)
        if(!rst)        wp <=  2'h0;
        else
        if(clr)         wp <=  2'h0;
        else
        if(we)          wp <=  wp_p1;

assign wp_p1 = wp + 2'h1;
assign wp_p2 = wp + 2'h2;

always @(posedge clk)
        if(!rst)        rp <=  2'h0;
        else
        if(clr)         rp <=  2'h0;
        else
        if(re)          rp <=  rp_p1;

assign rp_p1 = rp + 2'h1;

assign  dout = mem[ rp ];

always @(posedge clk)
        if(we)  mem[ wp ] <=  din;

assign empty = (wp == rp) & !gb;
assign full  = (wp == rp) &  gb;

always @(posedge clk)
        if(!rst)                        gb <=  1'b0;
        else
        if(clr)                         gb <=  1'b0;
        else
        if((wp_p1 == rp) & we)          gb <=  1'b1;
        else
        if(re)                          gb <=  1'b0;

endmodule
