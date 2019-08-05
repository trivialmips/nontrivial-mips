`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2019 03:23:49 PM
// Design Name: 
// Module Name: usbh_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module usbh_top(
    // UTMI clock = AXI clock
    input aclk,
    input aresetn,
    output intr,

    input cfg_awvalid,
    input [31:0] cfg_awaddr,
    input cfg_wvalid,
    input [31:0] cfg_wdata,
    input [3:0] cfg_wstrb,
    input cfg_bready,
    input cfg_arvalid,
    input [31:0] cfg_araddr,
    input cfg_rready,

    output cfg_awready,
    output cfg_wready,
    output cfg_bvalid,
    output [1:0] cfg_bresp,
    output cfg_arready,
    output cfg_rvalid,
    output [31:0] cfg_rdata,
    output [1:0] cfg_rresp,

    //inout [7:0] utmi_data,
    input [7:0] utmi_data_in,
    output [7:0] utmi_data_out,
    output utmi_data_t,
    output utmi_reset,

    input utmi_txready,
    input utmi_rxvalid,
    input utmi_rxactive,
    input utmi_rxerror,
    input [1:0] utmi_linestate,
    
    output utmi_txvalid,
    output [1:0] utmi_opmode,
    output [1:0] utmi_xcvrsel,
    output utmi_termsel,
    output utmi_dppulldown,
    output utmi_dmpulldown,

    // 0
    output utmi_idpullup,
    output utmi_chrgvbus,
    output utmi_dischrgvbus,
    output utmi_suspend_n,

    // ignore
    input utmi_hostdisc,
    input utmi_iddig,
    input utmi_vbusvalid,
    input utmi_sessend
    );

    assign utmi_idpullup = 0;
    assign utmi_chrgvbus = 0;
    assign utmi_dischrgvbus = 0;
    assign utmi_suspend_n = 1;
    assign utmi_data_t = !utmi_txvalid;

    usbh_host usb_host_inst(
        .clk_i(aclk),
        .rst_i(!aresetn),

        .cfg_awvalid_i(cfg_awvalid),
        .cfg_awaddr_i(cfg_awaddr),
        .cfg_wvalid_i(cfg_wvalid),
        .cfg_wdata_i(cfg_wdata),
        .cfg_wstrb_i(cfg_wstrb),
        .cfg_bready_i(cfg_bready),
        .cfg_arvalid_i(cfg_arvalid),
        .cfg_araddr_i(cfg_araddr),
        .cfg_rready_i(cfg_rready),

        .cfg_awready_o(cfg_awready),
        .cfg_wready_o(cfg_wready),
        .cfg_bvalid_o(cfg_bvalid),
        .cfg_bresp_o(cfg_bresp),
        .cfg_arready_o(cfg_arready),
        .cfg_rvalid_o(cfg_rvalid),
        .cfg_rdata_o(cfg_rdata),
        .cfg_rresp_o(cfg_rresp),
        
        .intr_o(intr),

        .utmi_data_in_i(utmi_data_in),
        .utmi_txready_i(utmi_txready),
        .utmi_rxvalid_i(utmi_rxvalid),
        .utmi_rxactive_i(utmi_rxactive),
        .utmi_rxerror_i(utmi_rxerror),
        .utmi_linestate_i(utmi_linestate),

        .utmi_data_out_o(utmi_data_out),
        .utmi_txvalid_o(utmi_txvalid),
        .utmi_op_mode_o(utmi_opmode),
        .utmi_xcvrselect_o(utmi_xcvrsel),
        .utmi_termselect_o(utmi_termsel),
        .utmi_dppulldown_o(utmi_dppulldown),
        .utmi_dmpulldown_o(utmi_dmpulldown),
	.utmi_reset_o(utmi_reset)
    );

endmodule
