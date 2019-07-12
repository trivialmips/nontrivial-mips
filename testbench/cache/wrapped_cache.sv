module wrapped_cache (
    input  wire clk,
	input  wire rst,

    output axi_req_t axi_req,
    input axi_resp_t axi_resp,

    output axi_req_t axi_dcache_req,
    input axi_resp_t axi_dcache_resp,

    cpu_ibus_if.slave  ibus,
    cpu_dbus_if.slave  dbus
);

cache_controller ctrl (
    .clk (clk),
    .rst (rst),
    
    .arid (axi_req.arid),
    .araddr (axi_req.araddr),
    .arlen (axi_req.arlen),
    .arsize (axi_req.arsize),
    .arburst (axi_req.arburst),
    .arlock (axi_req.arlock),
    .arcache (axi_req.arcache),
    .arprot (axi_req.arprot),
    .arvalid (axi_req.arvalid),
    .arready (axi_resp.arready),

    .rid (axi_resp.rid),
    .rdata (axi_resp.rdata),
    .rresp (axi_resp.rresp),
    .rlast (axi_resp.rlast),
    .rvalid (axi_resp.rvalid),
    .rready (axi_req.rready),

    .awid (axi_req.awid),
    .awaddr (axi_req.awaddr),
    .awlen (axi_req.awlen),
    .awsize (axi_req.awsize),
    .awburst (axi_req.awburst),
    .awlock (axi_req.awlock),
    .awcache (axi_req.awcache),
    .awprot (axi_req.awprot),
    .awvalid (axi_req.awvalid),
    .awready (axi_resp.awready),

    .wid (axi_req.wid),
    .wdata (axi_req.wdata),
    .wstrb (axi_req.wstrb),
    .wlast (axi_req.wlast),
    .wvalid (axi_req.wvalid),
    .wready (axi_resp.wready),

    .bid (axi_resp.bid),
    .bresp (axi_resp.bresp),
    .bvalid (axi_resp.bvalid),
    .bready (axi_req.bready),

    .arid_dcache (axi_dcache_req.arid),
    .araddr_dcache (axi_dcache_req.araddr),
    .arlen_dcache (axi_dcache_req.arlen),
    .arsize_dcache (axi_dcache_req.arsize),
    .arburst_dcache (axi_dcache_req.arburst),
    .arlock_dcache (axi_dcache_req.arlock),
    .arcache_dcache (axi_dcache_req.arcache),
    .arprot_dcache (axi_dcache_req.arprot),
    .arvalid_dcache (axi_dcache_req.arvalid),
    .arready_dcache (axi_dcache_resp.arready),

    .rid_dcache (axi_dcache_resp.rid),
    .rdata_dcache (axi_dcache_resp.rdata),
    .rresp_dcache (axi_dcache_resp.rresp),
    .rlast_dcache (axi_dcache_resp.rlast),
    .rvalid_dcache (axi_dcache_resp.rvalid),
    .rready_dcache (axi_dcache_req.rready),

    .awid_dcache (axi_dcache_req.awid),
    .awaddr_dcache (axi_dcache_req.awaddr),
    .awlen_dcache (axi_dcache_req.awlen),
    .awsize_dcache (axi_dcache_req.awsize),
    .awburst_dcache (axi_dcache_req.awburst),
    .awlock_dcache (axi_dcache_req.awlock),
    .awcache_dcache (axi_dcache_req.awcache),
    .awprot_dcache (axi_dcache_req.awprot),
    .awvalid_dcache (axi_dcache_req.awvalid),
    .awready_dcache (axi_dcache_resp.awready),

    .wid_dcache (axi_dcache_req.wid),
    .wdata_dcache (axi_dcache_req.wdata),
    .wstrb_dcache (axi_dcache_req.wstrb),
    .wlast_dcache (axi_dcache_req.wlast),
    .wvalid_dcache (axi_dcache_req.wvalid),
    .wready_dcache (axi_dcache_resp.wready),

    .bid_dcache (axi_dcache_resp.bid),
    .bresp_dcache (axi_dcache_resp.bresp),
    .bvalid_dcache (axi_dcache_resp.bvalid),
    .bready_dcache (axi_dcache_req.bready),

    .ibus (ibus),
    .dbus (dbus)
);

endmodule
