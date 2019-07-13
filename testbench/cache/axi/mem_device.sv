module mem_device #(
	parameter ADDR_WIDTH = 16,
	parameter DATA_WIDTH = 32
) (
	input logic clk,
	input logic rst,
	input axi_req_t axi_req,
	output axi_resp_t axi_resp
);


axi_ram #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .ID_WIDTH (4)
) ram (
    .clk,
    .rst,

    .s_axi_awid (4'b0000),
    .s_axi_awaddr (axi_req.awaddr),
    .s_axi_awlen (axi_req.awlen),
    .s_axi_awsize (axi_req.awsize),
    .s_axi_awburst (axi_req.awburst),
    .s_axi_awlock (axi_req.awlock),
    .s_axi_awcache (axi_req.awcache),
    .s_axi_awprot (axi_req.awprot),
    .s_axi_awvalid (axi_req.awvalid),
    .s_axi_awready (axi_resp.awready),
    .s_axi_wdata (axi_req.wdata),
    .s_axi_wstrb (axi_req.wstrb),
    .s_axi_wlast (axi_req.wlast),
    .s_axi_wvalid (axi_req.wvalid),
    .s_axi_wready (axi_resp.wready),
    .s_axi_bid ( /* open */ ),
    .s_axi_bresp (axi_resp.bresp),
    .s_axi_bvalid (axi_resp.bvalid),
    .s_axi_bready (axi_req.bready),
    .s_axi_arid (4'b0000),
    .s_axi_araddr (axi_req.araddr),
    .s_axi_arlen (axi_req.arlen),
    .s_axi_arsize (axi_req.arsize),
    .s_axi_arburst (axi_req.arburst),
    .s_axi_arlock (axi_req.arlock),
    .s_axi_arcache (axi_req.arcache),
    .s_axi_arprot (axi_req.arprot),
    .s_axi_arvalid (axi_req.arvalid),
    .s_axi_arready (axi_resp.arready),
    .s_axi_rid ( /* open */ ),
    .s_axi_rdata (axi_resp.rdata),
    .s_axi_rresp (axi_resp.rresp),
    .s_axi_rlast (axi_resp.rlast),
    .s_axi_rvalid (axi_resp.rvalid),
    .s_axi_rready (axi_req.rready)
);

endmodule
