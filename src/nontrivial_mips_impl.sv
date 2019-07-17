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
	output wire [BUS_WIDTH - 1 :0] icache_arid   ,
	output wire [31:0]             icache_araddr ,
	output wire [3 :0]             icache_arlen  ,
	output wire [2 :0]             icache_arsize ,
	output wire [1 :0]             icache_arburst,
	output wire [1 :0]             icache_arlock ,
	output wire [3 :0]             icache_arcache,
	output wire [2 :0]             icache_arprot ,
	output wire                    icache_arvalid,
	input  wire                    icache_arready,
	// AXI R signals
	input  wire [BUS_WIDTH - 1 :0] icache_rid    ,
	input  wire [31:0]             icache_rdata  ,
	input  wire [1 :0]             icache_rresp  ,
	input  wire                    icache_rlast  ,
	input  wire                    icache_rvalid ,
	output wire                    icache_rready ,
	// AXI AW signals
	output wire [BUS_WIDTH - 1 :0] icache_awid   ,
	output wire [31:0]             icache_awaddr ,
	output wire [3 :0]             icache_awlen  ,
	output wire [2 :0]             icache_awsize ,
	output wire [1 :0]             icache_awburst,
	output wire [1 :0]             icache_awlock ,
	output wire [3 :0]             icache_awcache,
	output wire [2 :0]             icache_awprot ,
	output wire                    icache_awvalid,
	input  wire                    icache_awready,
	// AXI W signals
	output wire [BUS_WIDTH - 1 :0] icache_wid    ,
	output wire [31:0]             icache_wdata  ,
	output wire [3 :0]             icache_wstrb  ,
	output wire                    icache_wlast  ,
	output wire                    icache_wvalid ,
	input  wire                    icache_wready ,
	// AXI B signals
	input  wire [BUS_WIDTH - 1 :0] icache_bid    ,
	input  wire [1 :0]             icache_bresp  ,
	input  wire                    icache_bvalid ,
	output wire                    icache_bready ,

    // dcache
	// AXI AR signals
	output wire [BUS_WIDTH - 1 :0] dcache_arid   ,
	output wire [31:0]             dcache_araddr ,
	output wire [3 :0]             dcache_arlen  ,
	output wire [2 :0]             dcache_arsize ,
	output wire [1 :0]             dcache_arburst,
	output wire [1 :0]             dcache_arlock ,
	output wire [3 :0]             dcache_arcache,
	output wire [2 :0]             dcache_arprot ,
	output wire                    dcache_arvalid,
	input  wire                    dcache_arready,
	// AXI R signals
	input  wire [BUS_WIDTH - 1 :0] dcache_rid    ,
	input  wire [31:0]             dcache_rdata  ,
	input  wire [1 :0]             dcache_rresp  ,
	input  wire                    dcache_rlast  ,
	input  wire                    dcache_rvalid ,
	output wire                    dcache_rready ,
	// AXI AW signals
	output wire [BUS_WIDTH - 1 :0] dcache_awid   ,
	output wire [31:0]             dcache_awaddr ,
	output wire [3 :0]             dcache_awlen  ,
	output wire [2 :0]             dcache_awsize ,
	output wire [1 :0]             dcache_awburst,
	output wire [1 :0]             dcache_awlock ,
	output wire [3 :0]             dcache_awcache,
	output wire [2 :0]             dcache_awprot ,
	output wire                    dcache_awvalid,
	input  wire                    dcache_awready,
	// AXI W signals
	output wire [BUS_WIDTH - 1 :0] dcache_wid    ,
	output wire [31:0]             dcache_wdata  ,
	output wire [3 :0]             dcache_wstrb  ,
	output wire                    dcache_wlast  ,
	output wire                    dcache_wvalid ,
	input  wire                    dcache_wready ,
	// AXI B signals
	input  wire [BUS_WIDTH - 1 :0] dcache_bid    ,
	input  wire [1 :0]             dcache_bresp  ,
	input  wire                    dcache_bvalid ,
	output wire                    dcache_bready ,

	// uncached
	// AXI AR signals
	output wire [BUS_WIDTH - 1 :0] uncached_arid   ,
	output wire [31:0]             uncached_araddr ,
	output wire [3 :0]             uncached_arlen  ,
	output wire [2 :0]             uncached_arsize ,
	output wire [1 :0]             uncached_arburst,
	output wire [1 :0]             uncached_arlock ,
	output wire [3 :0]             uncached_arcache,
	output wire [2 :0]             uncached_arprot ,
	output wire                    uncached_arvalid,
	input  wire                    uncached_arready,
	// AXI R signals
	input  wire [BUS_WIDTH - 1 :0] uncached_rid    ,
	input  wire [31:0]             uncached_rdata  ,
	input  wire [1 :0]             uncached_rresp  ,
	input  wire                    uncached_rlast  ,
	input  wire                    uncached_rvalid ,
	output wire                    uncached_rready ,
	// AXI AW signals
	output wire [BUS_WIDTH - 1 :0] uncached_awid   ,
	output wire [31:0]             uncached_awaddr ,
	output wire [3 :0]             uncached_awlen  ,
	output wire [2 :0]             uncached_awsize ,
	output wire [1 :0]             uncached_awburst,
	output wire [1 :0]             uncached_awlock ,
	output wire [3 :0]             uncached_awcache,
	output wire [2 :0]             uncached_awprot ,
	output wire                    uncached_awvalid,
	input  wire                    uncached_awready,
	// AXI W signals
	output wire [BUS_WIDTH - 1 :0] uncached_wid    ,
	output wire [31:0]             uncached_wdata  ,
	output wire [3 :0]             uncached_wstrb  ,
	output wire                    uncached_wlast  ,
	output wire                    uncached_wvalid ,
	input  wire                    uncached_wready ,
	// AXI B signals
	input  wire [BUS_WIDTH - 1 :0] uncached_bid    ,
	input  wire [1 :0]             uncached_bresp  ,
	input  wire                    uncached_bvalid ,
	output wire                    uncached_bready
);

    // initialization of bus interfaces
    cpu_ibus_if ibus_if();
	cpu_dbus_if dbus_if();
	cpu_dbus_if dbus_uncached_if();

    wire clk = aclk;


	// synchronize reset
	logic [1:0] sync_rst;
	always_ff @(posedge clk) begin
		sync_rst <= { sync_rst[0], ~reset_n };
	end

	wire rst = sync_rst[1];


    // pack AXI signals
    axi_req_t icache_axi_req, dcache_axi_req, uncached_axi_req;
    axi_resp_t icache_axi_resp, dcache_axi_resp, uncached_axi_resp;

    assign icache_araddr  = icache_axi_req.araddr;
    assign icache_arlen   = icache_axi_req.arlen;
    assign icache_arsize  = icache_axi_req.arsize;
    assign icache_arburst = icache_axi_req.arburst;
    assign icache_arlock  = icache_axi_req.arlock;
    assign icache_arcache = icache_axi_req.arcache;
    assign icache_arprot  = icache_axi_req.arprot;
    assign icache_arvalid = icache_axi_req.arvalid;
    assign icache_rready  = icache_axi_req.rready;
    assign icache_awaddr  = icache_axi_req.awaddr;
    assign icache_awlen   = icache_axi_req.awlen;
    assign icache_awsize  = icache_axi_req.awsize;
    assign icache_awburst = icache_axi_req.awburst;
    assign icache_awlock  = icache_axi_req.awlock;
    assign icache_awcache = icache_axi_req.awcache;
    assign icache_awprot  = icache_axi_req.awprot;
    assign icache_awvalid = icache_axi_req.awvalid;
    assign icache_wdata   = icache_axi_req.wdata;
    assign icache_wstrb   = icache_axi_req.wstrb;
    assign icache_wlast   = icache_axi_req.wlast;
    assign icache_wvalid  = icache_axi_req.wvalid;
    assign icache_bready  = icache_axi_req.bready;
    assign icache_axi_resp.arready = icache_arready;
    assign icache_axi_resp.rdata   = icache_rdata;
    assign icache_axi_resp.rresp   = icache_rresp;
    assign icache_axi_resp.rlast   = icache_rlast;
    assign icache_axi_resp.rvalid  = icache_rvalid;
    assign icache_axi_resp.awready = icache_awready;
    assign icache_axi_resp.wready  = icache_wready;
    assign icache_axi_resp.bresp   = icache_bresp;
    assign icache_axi_resp.bvalid  = icache_bvalid;


    assign dcache_araddr  = dcache_axi_req.araddr;
    assign dcache_arlen   = dcache_axi_req.arlen;
    assign dcache_arsize  = dcache_axi_req.arsize;
    assign dcache_arburst = dcache_axi_req.arburst;
    assign dcache_arlock  = dcache_axi_req.arlock;
    assign dcache_arcache = dcache_axi_req.arcache;
    assign dcache_arprot  = dcache_axi_req.arprot;
    assign dcache_arvalid = dcache_axi_req.arvalid;
    assign dcache_rready  = dcache_axi_req.rready;
    assign dcache_awaddr  = dcache_axi_req.awaddr;
    assign dcache_awlen   = dcache_axi_req.awlen;
    assign dcache_awsize  = dcache_axi_req.awsize;
    assign dcache_awburst = dcache_axi_req.awburst;
    assign dcache_awlock  = dcache_axi_req.awlock;
    assign dcache_awcache = dcache_axi_req.awcache;
    assign dcache_awprot  = dcache_axi_req.awprot;
    assign dcache_awvalid = dcache_axi_req.awvalid;
    assign dcache_wdata   = dcache_axi_req.wdata;
    assign dcache_wstrb   = dcache_axi_req.wstrb;
    assign dcache_wlast   = dcache_axi_req.wlast;
    assign dcache_wvalid  = dcache_axi_req.wvalid;
    assign dcache_bready  = dcache_axi_req.bready;
    assign dcache_axi_resp.arready = dcache_arready;
    assign dcache_axi_resp.rdata   = dcache_rdata;
    assign dcache_axi_resp.rresp   = dcache_rresp;
    assign dcache_axi_resp.rlast   = dcache_rlast;
    assign dcache_axi_resp.rvalid  = dcache_rvalid;
    assign dcache_axi_resp.awready = dcache_awready;
    assign dcache_axi_resp.wready  = dcache_wready;
    assign dcache_axi_resp.bresp   = dcache_bresp;
	assign dcache_axi_resp.bvalid  = dcache_bvalid;
	

    assign uncached_araddr  = uncached_axi_req.araddr;
    assign uncached_arlen   = uncached_axi_req.arlen;
    assign uncached_arsize  = uncached_axi_req.arsize;
    assign uncached_arburst = uncached_axi_req.arburst;
    assign uncached_arlock  = uncached_axi_req.arlock;
    assign uncached_arcache = uncached_axi_req.arcache;
    assign uncached_arprot  = uncached_axi_req.arprot;
    assign uncached_arvalid = uncached_axi_req.arvalid;
    assign uncached_rready  = uncached_axi_req.rready;
    assign uncached_awaddr  = uncached_axi_req.awaddr;
    assign uncached_awlen   = uncached_axi_req.awlen;
    assign uncached_awsize  = uncached_axi_req.awsize;
    assign uncached_awburst = uncached_axi_req.awburst;
    assign uncached_awlock  = uncached_axi_req.awlock;
    assign uncached_awcache = uncached_axi_req.awcache;
    assign uncached_awprot  = uncached_axi_req.awprot;
    assign uncached_awvalid = uncached_axi_req.awvalid;
    assign uncached_wdata   = uncached_axi_req.wdata;
    assign uncached_wstrb   = uncached_axi_req.wstrb;
    assign uncached_wlast   = uncached_axi_req.wlast;
    assign uncached_wvalid  = uncached_axi_req.wvalid;
    assign uncached_bready  = uncached_axi_req.bready;
    assign uncached_axi_resp.arready = uncached_arready;
    assign uncached_axi_resp.rdata   = uncached_rdata;
    assign uncached_axi_resp.rresp   = uncached_rresp;
    assign uncached_axi_resp.rlast   = uncached_rlast;
    assign uncached_axi_resp.rvalid  = uncached_rvalid;
    assign uncached_axi_resp.awready = uncached_awready;
    assign uncached_axi_resp.wready  = uncached_wready;
    assign uncached_axi_resp.bresp   = uncached_bresp;
    assign uncached_axi_resp.bvalid  = uncached_bvalid;


	// initialization of caches
	cache_controller #(
		.BUS_WIDTH(BUS_WIDTH)
	) cache_controller_inst (
		.*, // all axi signals
		.clk,
		.rst,
		.ibus(ibus_if.slave),
		.dbus(dbus_if.slave),
		.dbus_uncached(dbus_uncached_if.slave)
	);


    // initialization of CPU
    cpu_core cpu_core_inst(
        .clk,
        .rst,
        .intr,
        .ibus(ibus_if.master),
		.dbus(dbus_if.master),
		.dbus_uncached(dbus_uncached_if.master)
    );


endmodule
