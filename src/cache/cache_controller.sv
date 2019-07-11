`include "common_defs.svh"
`include "cache_defs.sv"

// DATA_WIDTH should be multiples of 32
module cache_controller #(
	parameter DATA_WIDTH = 64, // 2 * 32-bit instruction
	parameter LINE_WIDTH = 256, // max burst size is 16, so LINE_WIDTH should <= 8*32 = 256

	parameter ADDR_LEN = 32,
	parameter INDEX_LEN = 16
) (
	// external logics
	input  wire        clk    ,
	input  wire        rst    ,
	// AXI AR signals
	output wire [3 :0] arid   ,
	output wire [31:0] araddr ,
	output wire [3 :0] arlen  ,
	output wire [2 :0] arsize ,
	output wire [1 :0] arburst,
	output wire [1 :0] arlock ,
	output wire [3 :0] arcache,
	output wire [2 :0] arprot ,
	output wire        arvalid,
	input  wire        arready,
	// AXI R signals
	input  wire [3 :0] rid    ,
	input  wire [31:0] rdata  ,
	input  wire [1 :0] rresp  ,
	input  wire        rlast  ,
	input  wire        rvalid ,
	output wire        rready ,
	// AXI AW signals
	output wire [3 :0] awid   ,
	output wire [31:0] awaddr ,
	output wire [3 :0] awlen  ,
	output wire [2 :0] awsize ,
	output wire [1 :0] awburst,
	output wire [1 :0] awlock ,
	output wire [3 :0] awcache,
	output wire [2 :0] awprot ,
	output wire        awvalid,
	input  wire        awready,
	// AXI W signals
	output wire [3 :0] wid    ,
	output wire [31:0] wdata  ,
	output wire [3 :0] wstrb  ,
	output wire        wlast  ,
	output wire        wvalid ,
	input  wire        wready ,
	// AXI B signals
	input  wire [3 :0] bid    ,
	input  wire [1 :0] bresp  ,
	input  wire        bvalid ,
	output wire        bready ,
	// CPU signals
	cpu_ibus_if.slave  ibus   ,
	cpu_dbus_if.slave  dbus
);

axi_req_t axi_req;
axi_resp_t axi_resp;
assign arid    = axi_req.arid;
assign araddr  = axi_req.araddr;
assign arlen   = axi_req.arlen;
assign arsize  = axi_req.arsize;
assign arburst = axi_req.arburst;
assign arlock  = axi_req.arlock;
assign arcache = axi_req.arcache;
assign arprot  = axi_req.arprot;
assign arvalid = axi_req.arvalid;
assign rready  = axi_req.rready;
assign awid    = axi_req.awid;
assign awaddr  = axi_req.awaddr;
assign awlen   = axi_req.awlen;
assign awsize  = axi_req.awsize;
assign awburst = axi_req.awburst;
assign awlock  = axi_req.awlock;
assign awcache = axi_req.awcache;
assign awprot  = axi_req.awprot;
assign awvalid = axi_req.awvalid;
assign wid     = axi_req.wid;
assign wdata   = axi_req.wdata;
assign wstrb   = axi_req.wstrb;
assign wlast   = axi_req.wlast;
assign wvalid  = axi_req.wvalid;
assign bready  = axi_req.bready;
assign axi_resp.arready = arready;
assign axi_resp.rid     = rid;
assign axi_resp.rdata   = rdata;
assign axi_resp.rresp   = rresp;
assign axi_resp.rlast   = rlast;
assign axi_resp.rvalid  = rvalid;
assign axi_resp.awready = awready;
assign axi_resp.wready  = wready;
assign axi_resp.bid     = bid;
assign axi_resp.bresp   = bresp;
assign axi_resp.bvalid  = bvalid;

icache icache_inst(
	.clk,
	.rst,
	.ibus,
	.axi_req,
	.axi_resp
);

endmodule
