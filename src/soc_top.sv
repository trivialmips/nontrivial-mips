`include "common_defs.svh"
`include "iobuf_helper.svh"

module nscscc_soc_top(
    // clocking
    input  wire clk,
    input  wire rst_n,
    // UART
    input  wire UART_rxd,
    output wire UART_txd,
    // plugable SPI flash
    inout  wire SPI_FLASH_mosi,
    inout  wire SPI_FLASH_miso,
    inout  wire SPI_FLASH_ss,
    inout  wire SPI_FLASH_sck,
    inout  wire SPI_FLASH_io2,
    inout  wire SPI_FLASH_io3,
    // non-plugable CFG SPI flash
    inout  wire CFG_FLASH_mosi,
    inout  wire CFG_FLASH_miso,
    inout  wire CFG_FLASH_ss,
    // NAND flash
    inout  wire [7:0] NAND_data,
    input  wire       NAND_ready,
    output wire       NAND_cle,
    output wire       NAND_ale,
    output wire       NAND_re_n,
    output wire       NAND_ce_n,
    output wire       NAND_we_n,
    // VGA (use inout for high-Z output)
    inout  wire [3:0] VGA_r,
    inout  wire [3:0] VGA_g,
    inout  wire [3:0] VGA_b,
    output wire       VGA_hsync,
    output wire       VGA_vsync,
    // GPIO
    output wire [15:0] led,
    output wire [ 1:0] led_rg0,
    output wire [ 1:0] led_rg1,
    output wire [ 7:0] num_csn,
    output wire [ 6:0] num_a_g,
    output wire        num_a_g_dp,
    output wire [ 3:0] btn_key_col,
    input  wire [ 3:0] btn_key_row,
    input  wire [ 1:0] btn_step,
    input  wire [ 7:0] switch,
    // PS/2
    inout  wire PS2_dat,
    inout  wire PS2_clk,
    // DDR3
    inout  wire [15:0] DDR3_dq,
    output wire [12:0] DDR3_addr,
    output wire [ 2:0] DDR3_ba,
    output wire        DDR3_ras_n,
    output wire        DDR3_cas_n,
    output wire        DDR3_we_n,
    output wire        DDR3_odt,
    output wire        DDR3_reset_n,
    output wire        DDR3_cke,
    output wire [1:0]  DDR3_dm,
    inout  wire [1:0]  DDR3_dqs_p,
    inout  wire [1:0]  DDR3_dqs_n,
    output wire        DDR3_ck_p,
    output wire        DDR3_ck_n,
    // ethernet
    output wire       MDIO_mdc,
    inout  wire       MDIO_mdio,
    input  wire       MII_col,
    input  wire       MII_crs,
    output wire       MII_rst_n,
    input  wire       MII_rx_clk,
    input  wire       MII_rx_dv,
    input  wire       MII_rx_er,
    input  wire [3:0] MII_rxd,
    input  wire       MII_tx_clk,
    output wire       MII_tx_en,
    output wire       MII_tx_er,
    output wire [3:0] MII_txd,
    // LCD
    inout  wire [15:0] LCD_data,
    output wire        LCD_nrst,
    output wire        LCD_csel,
    output wire        LCD_rd,
    output wire        LCD_rs,
    output wire        LCD_wr,
    output wire        LCD_lighton,
    // EJTAG
    input  wire EJTAG_trst,
    input  wire EJTAG_tck,
    input  wire EJTAG_tdi,
    input  wire EJTAG_tms,
    output wire EJTAG_tdo
);

    // plugable SPI flash
    `IOBUF_GEN(SPI_FLASH_mosi, SPI_FLASH_io0);
    `IOBUF_GEN(SPI_FLASH_miso, SPI_FLASH_io1);
    `IOBUF_GEN_SIMPLE(SPI_FLASH_io2);
    `IOBUF_GEN_SIMPLE(SPI_FLASH_io3);
    `IOBUF_GEN_SIMPLE(SPI_FLASH_ss);
    `IOBUF_GEN_SIMPLE(SPI_FLASH_sck);

    // non-plugable CFG SPI flash
    `IOBUF_GEN(CFG_FLASH_mosi, CFG_FLASH_io0);
    `IOBUF_GEN(CFG_FLASH_miso, CFG_FLASH_io1);
    `IOBUF_GEN_SIMPLE(CFG_FLASH_ss);

    // NAND flash
    `IOBUF_GEN_VEC_SIMPLE(NAND_data);

    // PS/2
    `IOBUF_GEN(PS2_clk, PS2_clk_tri);
    `IOBUF_GEN(PS2_dat, PS2_dat_tri);

    // Ethernet
    `IOBUF_GEN_SIMPLE(MDIO_mdio);
    assign MII_tx_er = 1'b0; // not provided in Ethernet Lite

    // GPIO
    assign num_a_g_dp = 1'b0; // not provided in confreg IP

    // LCD
    `IOBUF_GEN_VEC(LCD_data, LCD_data_tri);

    // VGA
    wire [5:0] VGA_red, VGA_green, VGA_blue;
    genvar VGA_i;
    generate
    for (VGA_i = 0; VGA_i < 4; VGA_i = VGA_i+1) begin : VGA_gen
        //match on-board DAC built by resistor
        assign VGA_r[VGA_i] = VGA_red[VGA_i+2] ? 1'b1 : 1'bZ;
        assign VGA_g[VGA_i] = VGA_green[VGA_i+2] ? 1'b1 : 1'bZ;
        assign VGA_b[VGA_i] = VGA_blue[VGA_i+2] ? 1'b1 : 1'bZ;
    end
    endgenerate

    // initialize block design
    bd_soc bd_soc_inst(
        .clk,
        .rst_n,
        // UART
        .UART_txd,
        .UART_rxd,
        .UART_ctsn(1'b0),
        .UART_dcdn(1'b0),
        .UART_dsrn(1'b0),
        .UART_ri  (1'b1), //actually rin
        // plugable SPI flash
        .SPI_FLASH_io0_i,
        .SPI_FLASH_io0_o,
        .SPI_FLASH_io0_t,
        .SPI_FLASH_io1_i,
        .SPI_FLASH_io1_o,
        .SPI_FLASH_io1_t,
        .SPI_FLASH_io2_i,
        .SPI_FLASH_io2_o,
        .SPI_FLASH_io2_t,
        .SPI_FLASH_io3_i,
        .SPI_FLASH_io3_o,
        .SPI_FLASH_io3_t,
        .SPI_FLASH_sck_i,
        .SPI_FLASH_sck_o,
        .SPI_FLASH_sck_t,
        .SPI_FLASH_ss_i,
        .SPI_FLASH_ss_o,
        .SPI_FLASH_ss_t,
        // non-plugable CFG SPI flash
        .CFG_FLASH_io0_i,
        .CFG_FLASH_io0_o,
        .CFG_FLASH_io0_t,
        .CFG_FLASH_io1_i,
        .CFG_FLASH_io1_o,
        .CFG_FLASH_io1_t,
        .CFG_FLASH_ss_i,
        .CFG_FLASH_ss_o,
        .CFG_FLASH_ss_t,
        // VGA
        .VGA_hsync,
        .VGA_vsync,
        .VGA_red,
        .VGA_green,
        .VGA_blue,
        .VGA_clk(),
        .VGA_de (),
        .VGA_dps(),
        // GPIO
        .led,
        .led_rg0,
        .led_rg1,
        .num_csn,
        .num_a_g,
        .btn_key_col,
        .btn_key_row,
        .btn_step,
        .switch,
        // PS/2
        .PS2_clk_tri_i,
        .PS2_clk_tri_o,
        .PS2_clk_tri_t,
        .PS2_dat_tri_i,
        .PS2_dat_tri_o,
        .PS2_dat_tri_t,
        // DDR3,
        .DDR3_dq,
        .DDR3_addr,
        .DDR3_ba,
        .DDR3_ras_n,
        .DDR3_cas_n,
        .DDR3_we_n,
        .DDR3_odt,
        .DDR3_reset_n,
        .DDR3_cke,
        .DDR3_dm,
        .DDR3_dqs_p,
        .DDR3_dqs_n,
        .DDR3_ck_p,
        .DDR3_ck_n,
        // ethernet
        // .MII_tx_er is not connected
        .MDIO_mdc,
        .MDIO_mdio_i,
        .MDIO_mdio_o,
        .MDIO_mdio_t,
        .MII_col,
        .MII_crs,
        .MII_rst_n,
        .MII_rx_clk,
        .MII_rx_dv,
        .MII_rx_er,
        .MII_rxd,
        .MII_tx_clk,
        .MII_tx_en,
        .MII_txd,
        // LCD
        .LCD_data_tri_i,
        .LCD_data_tri_o,
        .LCD_data_tri_t,
        .LCD_nrst,
        .LCD_csel,
        .LCD_rd,
        .LCD_rs,
        .LCD_wr,
        .LCD_lighton
        // EJTAG
        // .EJTAG_trst,
        // .EJTAG_tck,
        // .EJTAG_tdi,
        // .EJTAG_tms,
        // .EJTAG_tdo
    );

endmodule
