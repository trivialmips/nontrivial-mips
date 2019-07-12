`include "cache_defs.sv"

module dcache_tb();

logic rst, clk;
axi_req_t axi_req;
axi_resp_t axi_resp;

always #5 clk = ~clk;

identity_device id (
	.clk (clk),
	.rst (rst),
	.axi_req (axi_req),
	.axi_resp (axi_resp)
);

cpu_dbus_if dbus();
cpu_ibus_if ibus();

wrapped_cache cache (
	.clk (clk),
	.rst (rst),
	.axi_dcache_req (axi_req),
	.axi_dcache_resp (axi_resp),

	.ibus (ibus),
	.dbus (dbus)
);

localparam int unsigned REQ_COUNT = 4;
logic [$clog2(REQ_COUNT+2):0] req;
logic [$clog2(REQ_COUNT+2):0][31:0] address;
logic [$clog2(REQ_COUNT+2):0][31:0] wdata;
typedef enum logic [1:0] {
    READ, WRITE, UNCACHED_READ, UNCACHED_WRITE
} req_type_t;
req_type_t req_type [$clog2(REQ_COUNT+2):0];
req_type_t current_type;

assign address[0] = 'h80000000;
assign req_type[0] = UNCACHED_READ;

assign address[1] = 'h80000004;
assign req_type[1] = UNCACHED_WRITE;
assign wdata[1] = 'h13579BDF;

assign address[2] = 'h80000040;
assign req_type[2] = UNCACHED_WRITE;
assign wdata[2] = 'h13579BDF;

assign address[3] = 'h80000080;
assign req_type[3] = UNCACHED_WRITE;
assign wdata[3] = 'h13579BDF;

assign dbus.address = address[req];
assign dbus.wrdata = wdata[req];
assign current_type = req_type[req];
assign dbus.read           = current_type == READ;
assign dbus.write          = current_type == WRITE;
assign dbus.uncached_read  = current_type == UNCACHED_READ;
assign dbus.uncached_write = current_type == UNCACHED_WRITE;

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
        if(req_type[req-1] == UNCACHED_WRITE) begin
            if(dbus.rddata != wdata[req-1]) begin
                $display("[Error] expected = %08x", wdata[req-1]);
                $stop;
            end
        end else if(dbus.rddata != address[req-1]) begin
			$display("[Error] expected = %08x", address[req-1]);
			$stop;
		end
	end
end

initial begin
    rst = 1'b1;
	clk = 1'b1;
    ibus.read = 1'b0;

    #51 rst = 1'b0;
    wait(req == REQ_COUNT + 1);
    $display("[pass]");
	$finish;
end

endmodule
