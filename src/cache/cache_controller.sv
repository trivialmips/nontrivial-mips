`include "common_defs.svh"

module cache_controller #(
	parameter BUS_WIDTH = 4
) (
	// external logics
	input  logic        clk,
    input  logic        rst,
    // CPU signals
    cpu_ibus_if.slave   ibus,
    cpu_dbus_if.slave   dbus,
    cpu_dbus_if.slave   dbus_uncached,
    // icache
    // AXI request
    output axi_req_t                icache_axi_req,
    output logic [BUS_WIDTH - 1 :0] icache_arid,
    output logic [BUS_WIDTH - 1 :0] icache_awid,
    output logic [BUS_WIDTH - 1 :0] icache_wid,
	// AXI response
    input  axi_resp_t               icache_axi_resp,
    input  logic [BUS_WIDTH - 1 :0] icache_rid,
    input  logic [BUS_WIDTH - 1 :0] icache_bid,

    // dcache
    // AXI request
    output axi_req_t                dcache_axi_req,
    output logic [BUS_WIDTH - 1 :0] dcache_arid,
    output logic [BUS_WIDTH - 1 :0] dcache_awid,
    output logic [BUS_WIDTH - 1 :0] dcache_wid,
	// AXI response
    input  axi_resp_t               dcache_axi_resp,
    input  logic [BUS_WIDTH - 1 :0] dcache_rid,
    input  logic [BUS_WIDTH - 1 :0] dcache_bid,

    // uncached
    // AXI request
    output axi_req_t                uncached_axi_req,
    output logic [BUS_WIDTH - 1 :0] uncached_arid,
    output logic [BUS_WIDTH - 1 :0] uncached_awid,
    output logic [BUS_WIDTH - 1 :0] uncached_wid,
	// AXI response
    input  axi_resp_t               uncached_axi_resp,
    input  logic [BUS_WIDTH - 1 :0] uncached_rid,
    input  logic [BUS_WIDTH - 1 :0] uncached_bid
);

    icache #(
        .BUS_WIDTH (BUS_WIDTH),
        .DATA_WIDTH(64),  // 2 * 32-bit instruction
        .LINE_WIDTH(`ICACHE_LINE_WIDTH), // max burst size is 16, so LINE_WIDTH should <= 8*32 = 256
        .SET_ASSOC (`ICACHE_SET_ASSOC),
        .CACHE_SIZE(`ICACHE_SIZE)  // in bit
    ) icache_inst(
        .clk,
        .rst,
        .ibus(ibus),
		.invalidate_icache(`ICACHE_NO_INCALIDATE ? 1'b0 : dbus.invalidate_icache),
		.invalidate_addr(dbus.address),
        .axi_req(icache_axi_req),
        .axi_req_arid(icache_arid),
        .axi_req_awid(icache_awid),
        .axi_req_wid(icache_wid),
        .axi_resp(icache_axi_resp),
        .axi_resp_rid(icache_rid),
        .axi_resp_bid(icache_bid)
    );

    dcache #(
        .BUS_WIDTH (BUS_WIDTH),
        .DATA_WIDTH(32),
        .LINE_WIDTH(`DCACHE_LINE_WIDTH), // max burst size is 16, so LINE_WIDTH should <= 8*32 = 256
        .SET_ASSOC (`DCACHE_SET_ASSOC),
        .CACHE_SIZE(`DCACHE_SIZE),  // in bit
        .WB_FIFO_DEPTH(`DCACHE_WB_FIFO_DEPTH)
    ) dcache_inst(
        .clk,
        .rst,
        .dbus,
        .axi_req(dcache_axi_req),
        .axi_req_arid(dcache_arid),
        .axi_req_awid(dcache_awid),
        .axi_req_wid(dcache_wid),
        .axi_resp(dcache_axi_resp),
        .axi_resp_rid(dcache_rid),
        .axi_resp_bid(dcache_bid)
    );

    dcache_pass #(
        .BUS_WIDTH (BUS_WIDTH)
    ) uncached_inst(
        .clk,
        .rst,
        .dbus(dbus_uncached),
        .axi_req(uncached_axi_req),
        .axi_req_arid(uncached_arid),
        .axi_req_awid(uncached_awid),
        .axi_req_wid(uncached_wid),
        .axi_resp(uncached_axi_resp),
        .axi_resp_rid(uncached_rid),
        .axi_resp_bid(uncached_bid)
    );

endmodule
