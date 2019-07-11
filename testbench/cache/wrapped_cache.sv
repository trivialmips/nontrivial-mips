module wrapped_cache (
    input  wire clk,
	input  wire rst,

    output axi_req_t axi_req,
    input axi_resp_t axi_resp,

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

    .ibus (ibus),
    .dbus (dbus)
);

endmodule
