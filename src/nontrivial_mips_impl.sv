`include "common_defs.svh"

module nontrivial_mips_impl #(
	parameter BUS_WIDTH = 4
) (
    // external signals
    input  wire        aclk   ,
    input  wire        reset_n,
    input  wire [4 :0] intr   ,

    // icache
	// AXI AR signals
	output wire [BUS_WIDTH - 1 :0] arid_icache   ,
	output wire [31:0]             araddr_icache ,
	output wire [3 :0]             arlen_icache  ,
	output wire [2 :0]             arsize_icache ,
	output wire [1 :0]             arburst_icache,
	output wire [1 :0]             arlock_icache ,
	output wire [3 :0]             arcache_icache,
	output wire [2 :0]             arprot_icache ,
	output wire                    arvalid_icache,
	input  wire                    arready_icache,
	// AXI R signals
	input  wire [BUS_WIDTH - 1 :0] rid_icache    ,
	input  wire [31:0]             rdata_icache  ,
	input  wire [1 :0]             rresp_icache  ,
	input  wire                    rlast_icache  ,
	input  wire                    rvalid_icache ,
	output wire                    rready_icache ,
	// AXI AW signals
	output wire [BUS_WIDTH - 1 :0] awid_icache   ,
	output wire [31:0]             awaddr_icache ,
	output wire [3 :0]             awlen_icache  ,
	output wire [2 :0]             awsize_icache ,
	output wire [1 :0]             awburst_icache,
	output wire [1 :0]             awlock_icache ,
	output wire [3 :0]             awcache_icache,
	output wire [2 :0]             awprot_icache ,
	output wire                    awvalid_icache,
	input  wire                    awready_icache,
	// AXI W signals
	output wire [BUS_WIDTH - 1 :0] wid_icache    ,
	output wire [31:0]             wdata_icache  ,
	output wire [3 :0]             wstrb_icache  ,
	output wire                    wlast_icache  ,
	output wire                    wvalid_icache ,
	input  wire                    wready_icache ,
	// AXI B signals
	input  wire [BUS_WIDTH - 1 :0] bid_icache    ,
	input  wire [1 :0]             bresp_icache  ,
	input  wire                    bvalid_icache ,
	output wire                    bready_icache ,

    // dcache
	// AXI AR signals
	output wire [BUS_WIDTH - 1 :0] arid_dcache   ,
	output wire [31:0]             araddr_dcache ,
	output wire [3 :0]             arlen_dcache  ,
	output wire [2 :0]             arsize_dcache ,
	output wire [1 :0]             arburst_dcache,
	output wire [1 :0]             arlock_dcache ,
	output wire [3 :0]             arcache_dcache,
	output wire [2 :0]             arprot_dcache ,
	output wire                    arvalid_dcache,
	input  wire                    arready_dcache,
	// AXI R signals
	input  wire [BUS_WIDTH - 1 :0] rid_dcache    ,
	input  wire [31:0]             rdata_dcache  ,
	input  wire [1 :0]             rresp_dcache  ,
	input  wire                    rlast_dcache  ,
	input  wire                    rvalid_dcache ,
	output wire                    rready_dcache ,
	// AXI AW signals
	output wire [BUS_WIDTH - 1 :0] awid_dcache   ,
	output wire [31:0]             awaddr_dcache ,
	output wire [3 :0]             awlen_dcache  ,
	output wire [2 :0]             awsize_dcache ,
	output wire [1 :0]             awburst_dcache,
	output wire [1 :0]             awlock_dcache ,
	output wire [3 :0]             awcache_dcache,
	output wire [2 :0]             awprot_dcache ,
	output wire                    awvalid_dcache,
	input  wire                    awready_dcache,
	// AXI W signals
	output wire [BUS_WIDTH - 1 :0] wid_dcache    ,
	output wire [31:0]             wdata_dcache  ,
	output wire [3 :0]             wstrb_dcache  ,
	output wire                    wlast_dcache  ,
	output wire                    wvalid_dcache ,
	input  wire                    wready_dcache ,
	// AXI B signals
	input  wire [BUS_WIDTH - 1 :0] bid_dcache    ,
	input  wire [1 :0]             bresp_dcache  ,
	input  wire                    bvalid_dcache ,
	output wire                    bready_dcache
);

    // initialization of bus interfaces
    cpu_ibus_if ibus_if();
    cpu_dbus_if dbus_if();

    wire clk = aclk;
    wire rst = ~reset_n;

    // pack AXI signals
    axi_req_t axi_req_icache;
    axi_resp_t axi_resp_icache;

    assign araddr_icache  = axi_req_icache.araddr;
    assign arlen_icache   = axi_req_icache.arlen;
    assign arsize_icache  = axi_req_icache.arsize;
    assign arburst_icache = axi_req_icache.arburst;
    assign arlock_icache  = axi_req_icache.arlock;
    assign arcache_icache = axi_req_icache.arcache;
    assign arprot_icache  = axi_req_icache.arprot;
    assign arvalid_icache = axi_req_icache.arvalid;
    assign rready_icache  = axi_req_icache.rready;
    assign awaddr_icache  = axi_req_icache.awaddr;
    assign awlen_icache   = axi_req_icache.awlen;
    assign awsize_icache  = axi_req_icache.awsize;
    assign awburst_icache = axi_req_icache.awburst;
    assign awlock_icache  = axi_req_icache.awlock;
    assign awcache_icache = axi_req_icache.awcache;
    assign awprot_icache  = axi_req_icache.awprot;
    assign awvalid_icache = axi_req_icache.awvalid;
    assign wdata_icache   = axi_req_icache.wdata;
    assign wstrb_icache   = axi_req_icache.wstrb;
    assign wlast_icache   = axi_req_icache.wlast;
    assign wvalid_icache  = axi_req_icache.wvalid;
    assign bready_icache  = axi_req_icache.bready;
    assign axi_resp_icache.arready = arready_icache;
    assign axi_resp_icache.rdata   = rdata_icache;
    assign axi_resp_icache.rresp   = rresp_icache;
    assign axi_resp_icache.rlast   = rlast_icache;
    assign axi_resp_icache.rvalid  = rvalid_icache;
    assign axi_resp_icache.awready = awready_icache;
    assign axi_resp_icache.wready  = wready_icache;
    assign axi_resp_icache.bresp   = bresp_icache;
    assign axi_resp_icache.bvalid  = bvalid_icache;

    axi_req_t axi_req_dcache;
    axi_resp_t axi_resp_dcache;

    assign araddr_dcache  = axi_req_dcache.araddr;
    assign arlen_dcache   = axi_req_dcache.arlen;
    assign arsize_dcache  = axi_req_dcache.arsize;
    assign arburst_dcache = axi_req_dcache.arburst;
    assign arlock_dcache  = axi_req_dcache.arlock;
    assign arcache_dcache = axi_req_dcache.arcache;
    assign arprot_dcache  = axi_req_dcache.arprot;
    assign arvalid_dcache = axi_req_dcache.arvalid;
    assign rready_dcache  = axi_req_dcache.rready;
    assign awaddr_dcache  = axi_req_dcache.awaddr;
    assign awlen_dcache   = axi_req_dcache.awlen;
    assign awsize_dcache  = axi_req_dcache.awsize;
    assign awburst_dcache = axi_req_dcache.awburst;
    assign awlock_dcache  = axi_req_dcache.awlock;
    assign awcache_dcache = axi_req_dcache.awcache;
    assign awprot_dcache  = axi_req_dcache.awprot;
    assign awvalid_dcache = axi_req_dcache.awvalid;
    assign wdata_dcache   = axi_req_dcache.wdata;
    assign wstrb_dcache   = axi_req_dcache.wstrb;
    assign wlast_dcache   = axi_req_dcache.wlast;
    assign wvalid_dcache  = axi_req_dcache.wvalid;
    assign bready_dcache  = axi_req_dcache.bready;
    assign axi_resp_dcache.arready = arready_dcache;
    assign axi_resp_dcache.rdata   = rdata_dcache;
    assign axi_resp_dcache.rresp   = rresp_dcache;
    assign axi_resp_dcache.rlast   = rlast_dcache;
    assign axi_resp_dcache.rvalid  = rvalid_dcache;
    assign axi_resp_dcache.awready = awready_dcache;
    assign axi_resp_dcache.wready  = wready_dcache;
    assign axi_resp_dcache.bresp   = bresp_dcache;
    assign axi_resp_dcache.bvalid  = bvalid_dcache;


    // initialization of caches
    icache #(
		.BUS_WIDTH (BUS_WIDTH),
		.DATA_WIDTH(64),  // 2 * 32-bit instruction
		.LINE_WIDTH(256), // max burst size is 16, so LINE_WIDTH should <= 8*32 = 256
		.SET_ASSOC (4),
		.CACHE_SIZE(16 * 1024 * 8)  // in bit
	) icache_inst(
		.clk,
		.rst,
		.ibus(ibus_if.slave),
		.axi_req(axi_req_icache),
		.axi_req_arid(arid_icache),
		.axi_req_awid(awid_icache),
		.axi_req_wid(wid_icache),
		.axi_resp(axi_resp_icache),
		.axi_resp_rid(rid_icache),
		.axi_resp_bid(bid_icache)
	);

	dcache #(
		.BUS_WIDTH (BUS_WIDTH),
		.DATA_WIDTH(64),  // 2 * 32-bit instruction
		.LINE_WIDTH(256)
	) dcache_inst(
		.clk,
		.rst,
		.dbus(dbus_if.slave),
		.axi_req(axi_req_dcache),
		.axi_req_arid(arid_dcache),
		.axi_req_awid(awid_dcache),
		.axi_req_wid(wid_dcache),
		.axi_resp(axi_resp_dcache),
		.axi_resp_rid(rid_dcache),
		.axi_resp_bid(bid_dcache)
	);


    // initialization of CPU
    cpu_core cpu_core_inst(
        .clk,
        .rst,
        .intr,
        .ibus(ibus_if.master),
        .dbus(dbus_if.master)
    );


endmodule
