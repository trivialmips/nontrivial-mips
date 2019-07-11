module icache_tb();

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
    .axi_req (axi_req),
    .axi_resp (axi_resp),

    .ibus (ibus),
    .dbus (dbus)
);

logic [4:0] pc;
logic [15:0][31:0] address;
assign address[0] = 'h000000D0;
assign address[1] = 'h000000E0;
assign address[2] = 'h000000E8;
assign address[3] = 'h000000F0;
assign address[4] = 'h000000F8;
assign address[5] = 'h000000D8;
assign address[6] = 'h000000D8;
assign address[7] = 'h000000D8;
assign address[8] = 'h000000D8;
assign address[9] = 'h000000D8;
assign address[10] = 'h000000D8;
assign address[11] = 'h000000D8;
assign address[12] = 'h000000D8;
assign address[13] = 'h000000D8;
assign address[14] = 'h000000D8;
assign address[15] = 'h000000D8;

assign ibus.read = 1'b1;
assign ibus.address = address[pc];

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		pc <= '0;
	end else if(~ibus.stall) begin
		pc <= pc + 1;
	end
end


initial
begin
    clk = 1'b1;
    rst = 1'b1;
    dbus.read = 1'b0;
    dbus.write = 1'b0;
    dbus.uncached_read = 1'b0;
    dbus.uncached_write = 1'b0;

	ibus.flush_1 = 1'b0;
	ibus.flush_2 = 1'b0;

    #51 rst = 1'b0;

	wait(pc == 15);
	$stop;
end

endmodule
