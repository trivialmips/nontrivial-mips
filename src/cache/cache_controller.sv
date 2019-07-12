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

    // dcache
	// AXI AR signals
	output wire [3 :0] arid_dcache    ,
	output wire [31:0] araddr_dcache  ,
	output wire [3 :0] arlen_dcache   ,
	output wire [2 :0] arsize_dcache  ,
	output wire [1 :0] arburst_dcache ,
	output wire [1 :0] arlock_dcache  ,
	output wire [3 :0] arcache_dcache ,
	output wire [2 :0] arprot_dcache  ,
	output wire        arvalid_dcache ,
	input  wire        arready_dcache ,
	// AXI R signals
	input  wire [3 :0] rid_dcache     ,
	input  wire [31:0] rdata_dcache   ,
	input  wire [1 :0] rresp_dcache   ,
	input  wire        rlast_dcache   ,
	input  wire        rvalid_dcache  ,
	output wire        rready_dcache  ,
	// AXI AW signals
	output wire [3 :0] awid_dcache    ,
	output wire [31:0] awaddr_dcache  ,
	output wire [3 :0] awlen_dcache   ,
	output wire [2 :0] awsize_dcache  ,
	output wire [1 :0] awburst_dcache ,
	output wire [1 :0] awlock_dcache  ,
	output wire [3 :0] awcache_dcache ,
	output wire [2 :0] awprot_dcache  ,
	output wire        awvalid_dcache ,
	input  wire        awready_dcache ,
	// AXI W signals
	output wire [3 :0] wid_dcache     ,
	output wire [31:0] wdata_dcache   ,
	output wire [3 :0] wstrb_dcache   ,
	output wire        wlast_dcache   ,
	output wire        wvalid_dcache  ,
	input  wire        wready_dcache  ,
	// AXI B signals
	input  wire [3 :0] bid_dcache     ,
	input  wire [1 :0] bresp_dcache   ,
	input  wire        bvalid_dcache  ,
	output wire        bready_dcache  ,

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

axi_req_t axi_dcache_req;
axi_resp_t axi_dcache_resp;
assign arid_dcache    = axi_dcache_req.arid;
assign araddr_dcache  = axi_dcache_req.araddr;
assign arlen_dcache   = axi_dcache_req.arlen;
assign arsize_dcache  = axi_dcache_req.arsize;
assign arburst_dcache = axi_dcache_req.arburst;
assign arlock_dcache  = axi_dcache_req.arlock;
assign arcache_dcache = axi_dcache_req.arcache;
assign arprot_dcache  = axi_dcache_req.arprot;
assign arvalid_dcache = axi_dcache_req.arvalid;
assign rready_dcache  = axi_dcache_req.rready;
assign awid_dcache    = axi_dcache_req.awid;
assign awaddr_dcache  = axi_dcache_req.awaddr;
assign awlen_dcache   = axi_dcache_req.awlen;
assign awsize_dcache  = axi_dcache_req.awsize;
assign awburst_dcache = axi_dcache_req.awburst;
assign awlock_dcache  = axi_dcache_req.awlock;
assign awcache_dcache = axi_dcache_req.awcache;
assign awprot_dcache  = axi_dcache_req.awprot;
assign awvalid_dcache = axi_dcache_req.awvalid;
assign wid_dcache     = axi_dcache_req.wid;
assign wdata_dcache   = axi_dcache_req.wdata;
assign wstrb_dcache   = axi_dcache_req.wstrb;
assign wlast_dcache   = axi_dcache_req.wlast;
assign wvalid_dcache  = axi_dcache_req.wvalid;
assign bready_dcache  = axi_dcache_req.bready;
assign axi_dcache_resp.arready = arready_dcache;
assign axi_dcache_resp.rid     = rid_dcache;
assign axi_dcache_resp.rdata   = rdata_dcache;
assign axi_dcache_resp.rresp   = rresp_dcache;
assign axi_dcache_resp.rlast   = rlast_dcache;
assign axi_dcache_resp.rvalid  = rvalid_dcache;
assign axi_dcache_resp.awready = awready_dcache;
assign axi_dcache_resp.wready  = wready_dcache;
assign axi_dcache_resp.bid     = bid_dcache;
assign axi_dcache_resp.bresp   = bresp_dcache;
assign axi_dcache_resp.bvalid  = bvalid_dcache;

icache icache_inst(
	.clk,
	.rst,
	.ibus,
	.axi_req,
	.axi_resp
);

dcache dcache_inst(
	.clk,
	.rst,
	.dbus,
	.axi_req (axi_dcache_req),
	.axi_resp (axi_dcache_resp)
);

endmodule
