`include "common_defs.svh"

module dcache_tb();

logic rst, clk;
axi_req_t axi_req;
axi_resp_t axi_resp;

always #5 clk = ~clk;

mem_device id (
	.clk (clk),
	.rst (rst),
	.axi_req (axi_req),
	.axi_resp (axi_resp)
);

cpu_dbus_if dbus();

dcache #(
    .SET_ASSOC (1), // Testing write-back
    .CACHE_SIZE(2048)
) cache (
	.clk (clk),
	.rst (rst),
	.axi_req (axi_req),
	.axi_resp (axi_resp),

	.dbus (dbus),
	.axi_req_awid ( /* open */ ),
	.axi_req_arid ( /* open */ ),
	.axi_req_wid ( /* open */ ),
	.axi_resp_rid (4'b0000),
	.axi_resp_bid (4'b0000)
);

localparam int unsigned REQ_COUNT = 7;
logic [$clog2(REQ_COUNT+2):0] req;
logic [REQ_COUNT+2:0][31:0] address;
logic [REQ_COUNT+2:0][31:0] wdata;
logic [REQ_COUNT+2:0][31:0] rdata;
typedef enum logic [1:0] {
	READ, WRITE
} req_type_t;
req_type_t req_type [REQ_COUNT+2:0];
req_type_t current_type;

assign address[0] = 'h00008000;
assign req_type[0] = READ;
assign rdata[0] = 'h00000000;

assign address[1] = 'h00008004;
assign req_type[1] = WRITE;
assign wdata[1] = 'h00000001;

assign address[2] = 'h00008040;
assign req_type[2] = WRITE;
assign wdata[2] = 'h00000002;

assign address[3] = 'h00008080;
assign req_type[3] = WRITE;
assign wdata[3] = 'h00000003;

assign address[4] = 'h00008004;
assign req_type[4] = READ;
assign rdata[4] = 'h00000001;

// Write-back

assign address[5] = 'h00009000;
assign req_type[5] = READ;
assign rdata[5] = 'h00000000;

assign address[6] = 'h00008004;
assign req_type[6] = READ;
assign rdata[6] = 'h00000001;

assign dbus.address = address[req];
assign dbus.wrdata = wdata[req];
assign current_type = req_type[req];
assign dbus.read           = current_type == READ;
assign dbus.write          = current_type == WRITE;

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		req <= 0;
	end else if(~dbus.stall) begin
		req <= req + 1;
	end
end

integer cycle;
always_ff @(negedge clk) begin
	cycle <= rst ? '0 : cycle + 1;
	if(~rst && req > 0 && ~dbus.stall) begin
		$display("[%0d] req = %0d, data = %08x", cycle, req - 1, dbus.rddata);
		if(req_type[req-1] == WRITE) begin
			if(dbus.rddata != wdata[req-1]) begin
				$display("[Error] expected = %08x", wdata[req-1]);
				$stop;
			end
		end else if(dbus.rddata != rdata[req-1]) begin
			$display("[Error] expected = %08x", rdata[req-1]);
			$stop;
		end
	end
end

initial begin
	rst = 1'b1;
	clk = 1'b1;

	#51 rst = 1'b0;
	wait(req == REQ_COUNT + 1);
	$display("[pass]");
	$finish;
end

endmodule
