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

`timescale 1ns/1ps

`define APP_FLASH   "../../../../../../simu/soft/func/flash.vlog"

`define UART_CLK    soc_up_top.APB_DEV.uart0.regs.enable

module godson_system;
// ========================================================================== //
// Signal Declarations                                                        //
// ========================================================================== //
// Clocks
reg clk,resetn;
reg mac_clk;
initial begin
    clk     = 1'b0;
    mac_clk = 1'b0;
    resetn  = 1'b0;
    #1000;
    resetn  = 1'b1;
end

always #15.15 clk     = ~clk;
always #20   mac_clk = ~mac_clk;

//------DDR3 interface------
wire [15:0] ddr3_dq;
wire [12:0] ddr3_addr;
wire [2 :0] ddr3_ba;
wire        ddr3_ras_n;
wire        ddr3_cas_n;
wire        ddr3_we_n;
wire        ddr3_odt;
wire        ddr3_reset_n;
wire        ddr3_cke;
wire [1:0]  ddr3_dm;
wire [1:0]  ddr3_dqs_p;
wire [1:0]  ddr3_dqs_n;
wire        ddr3_ck_p;
wire        ddr3_ck_n;

//----mac controller------
//I/O pad interface signals
// Tx
wire          mtxclk_0;  // Transmit clock (from PHY)
wire  [3:0]   mtxd_0;    // Transmit nibble (to PHY)
wire          mtxen_0;   // Transmit enable (to PHY)
wire          mtxerr_0;  // Transmit error (to PHY)
assign mtxclk_0 = mac_clk;
// Rx
wire          mrxclk_0;  // Receive clock (from PHY)
wire  [3:0]   mrxd_0;    // Receive nibble (from PHY)
wire          mrxdv_0;   // Receive data valid (from PHY)
wire          mrxerr_0;  // Receive data error (from PHY)
assign mrxclk_0 = mac_clk;
// MII Management interface
wire          mdc_0;     // MII Management data clock (to PHY)
wire          mdio_0;    // MII data inout 
wire          phy_rstn;

wire [7:0] LED;
wire UART_RX,    UART_TX;
wire UART_CTS,   UART_RTS;
wire UART_DTR,   UART_DSR;
wire UART_RI,    UART_DCD;

//nand
wire NAND_CLE ;
wire NAND_ALE ;
wire NAND_RDY ;
wire [7:0] NAND_DATA;
wire NAND_RD  ;
wire NAND_CE  ;  //low active
wire NAND_WR  ;  

wire SPI_CLK,   SPI_CS, SPI_MISO,  SPI_MOSI;

wire TDI;
wire TDO;
wire TCK;
wire TRST;
wire TMS;

soc_up_top soc_up_top (
    .clk             (clk         ),
    .resetn          (resetn      ), 

    .ddr3_dq         (ddr3_dq     ),
    .ddr3_addr       (ddr3_addr   ),
    .ddr3_ba         (ddr3_ba     ),
    .ddr3_ras_n      (ddr3_ras_n  ),
    .ddr3_cas_n      (ddr3_cas_n  ),
    .ddr3_we_n       (ddr3_we_n   ),
    .ddr3_odt        (ddr3_odt    ),
    .ddr3_reset_n    (ddr3_reset_n),
    .ddr3_cke        (ddr3_cke    ),
    .ddr3_dm         (ddr3_dm     ),
    .ddr3_dqs_p      (ddr3_dqs_p  ),
    .ddr3_dqs_n      (ddr3_dqs_n  ),
    .ddr3_ck_p       (ddr3_ck_p   ),
    .ddr3_ck_n       (ddr3_ck_n   ),

    //------gpio----------------
    .led                  (),
    .led_rg0              (),
    .led_rg1              (),
    .num_csn              (),
    .num_a_g              (),
    .switch               (8'd0), 
    .btn_key_col          (),
    .btn_key_row          (4'd0),
    .btn_step             (2'd0),
    
    //------mac controller-------
    // I/O pad interface signals
    //TX
    .mtxclk_0             (mtxclk_0   ),     
    .mtxen_0              (mtxen_0    ),      
    .mtxd_0               (mtxd_0     ),       
    .mtxerr_0             (mtxerr_0   ),
    //RX
    .mrxclk_0             (mrxclk_0  ),      
    .mrxdv_0              (mrxdv_0   ),     
    .mrxd_0               (mrxd_0    ),        
    .mrxerr_0             (mrxerr_0  ),
    .mcoll_0              (1'b0      ),
    .mcrs_0               (1'b0      ),
    // MIIM
    .mdc_0                (mdc_0     ),
    .mdio_0               (mdio_0    ),

    .phy_rstn             (phy_rstn  ),

    .UART_RX(UART_RX),
    .UART_TX(UART_TX),

    //NAND
    .NAND_CLE (NAND_CLE ),
    .NAND_ALE (NAND_ALE ),
    .NAND_RDY (NAND_RDY ),
    .NAND_DATA(NAND_DATA),
    .NAND_RD  (NAND_RD  ),
    .NAND_CE  (NAND_CE  ),  //low active
    .NAND_WR  (NAND_WR  ),  

    .EJTAG_TRST(TRST),
    .EJTAG_TCK(TCK),
    .EJTAG_TMS(TMS),
    .EJTAG_TDI(TDI),
    .EJTAG_TDO(TDO),

    .SPI_CLK(SPI_CLK),
    .SPI_CS(SPI_CS),
    .SPI_MISO(SPI_MISO),
    .SPI_MOSI(SPI_MOSI)
    );

pullup  (NAND_RDY);
//nand module
s30ml08gp00 nand_model0
(
    .IO7   (NAND_DATA[7]) ,
    .IO6   (NAND_DATA[6]) ,
    .IO5   (NAND_DATA[5]),
    .IO4   (NAND_DATA[4]),
    .IO3   (NAND_DATA[3]),
    .IO2   (NAND_DATA[2]),
    .IO1   (NAND_DATA[1]),
    .IO0   (NAND_DATA[0]),
    .CLE   (NAND_CLE    ),
    .ALE   (NAND_ALE    ),
    .CE1Neg(NAND_CE     ),
    .RENeg (NAND_RD     ),
    .WENeg (NAND_WR     ),
    .RY1   (NAND_RDY    ),
    .CE2Neg(1'b1        ),
    .WPNeg (1'b1        ),
    .RY2   (            ),
    .FP    (1'b1        )
);

ejtag_virtual_host ejtag
    (
    .TCK (TCK ),
    .TMS (TMS ),
    .TDO (TDO ),
    .TDI (TDI ),
    .TRST(TRST)
    );


MX25L6405D #
    (
    .Init_File(`APP_FLASH)
    )
    spi_flash  
    (
    .SCLK (SPI_CLK ), 
    .CS   (SPI_CS  ), 
    .SI   (SPI_MOSI), 
    .SO   (SPI_MISO), 
    .WP   (1'b1    ), 
    .HOLD (1'b1    )
    );

uart_dev #
    (
    .uart_number    (0),
    .STRLEN         (80)
    ) 
    uart_dev0
    (
    .clk    (`UART_CLK),
    .rst_n  (resetn),
    .rx     (UART_TX),
    .tx     (UART_RX)
    );

ddr3_model u_comp_ddr3
  (
   .rst_n   (ddr3_reset_n),
   .ck      (ddr3_ck_p),
   .ck_n    (ddr3_ck_n),
   .cke     (ddr3_cke ),
   .cs_n    (1'b0     ),
   .ras_n   (ddr3_ras_n),
   .cas_n   (ddr3_cas_n),
   .we_n    (ddr3_we_n),
   .dm_tdqs (ddr3_dm),
   .ba      (ddr3_ba),
   .addr    (ddr3_addr),
   .dq      (ddr3_dq),
   .dqs     (ddr3_dqs_p),
   .dqs_n   (ddr3_dqs_n),
   .tdqs_n  (),
   .odt     (ddr3_odt)
   );

virtual_mac VIRTUAL_MAC(
    .hclk   (clk),
    .hrst_n (resetn),
    .mtxclk (mrxclk_0  ),
    .mtxen  (mrxdv_0   ),
    .mtxd   (mrxd_0    ),
    .mtxerr (mrxerr_0  ),

    .mrxclk (mtxclk_0  ),
    .mrxdv  (mtxen_0   ),
    .mrxd   (mtxd_0    ),
    .mrxerr (mtxerr_0  ),
    .mcoll  (1'b0      ),
    .mcrs   (1'b0      ),
    .mdc    (),
    .md_io  (),
    .gpio   (LED[4]) 
);

`ifdef DUMPDUMP
initial 
begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, godson_system);
    #57888881
    $fsdbDumpon;
    #100000000
    $fsdbDumpoff;
end
`endif

initial begin
  forever begin
    #500000;
    $display("\t\t@%0t: CPU commit PC is %x", $time, godson_system.soc_up_top.cpu_mid.cpu_core.commitbus0[41:10]);
  end
end


endmodule
