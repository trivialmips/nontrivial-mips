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
logic [0:15] ans_valid, ans_record;
assign address[0] = 'h000000D0;
assign address[1] = 'h000000E0;
assign address[2] = 'h000000E8;
assign address[3] = 'h000000F0;
assign address[4] = 'h000000F8;
assign address[5] = 'h00000000;  // killed in IDLE
assign address[6] = 'h00000020;  // discard
assign address[7] = 'h000000D0;
assign address[8] = 'h00000000;  // killed in WAIT_AXI_READY
assign address[9] = 'h00000020;  // discard
assign address[10] = 'h000000D8; // hit
assign address[11] = 'h000000E0; // hit
assign address[12] = 'h00000000; // killed in RECEIVING
assign address[13] = 'h00000020; // discard
assign address[14] = 'h00000040; // miss
assign address[15] = 'h00000048;
assign ans_valid = 16'b1111_1001_0011_0011;

assign ibus.read = 1'b1;
assign ibus.address = address[pc];

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		pc <= '0;
	end else if(~ibus.stall) begin
		pc <= pc + 1;
	end
end

always_ff @(negedge clk) begin
	if(rst) ans_record = '0;
	if(~rst && ibus.valid) begin
		$display("pc = %0d, data = %016x", pc - 1, ibus.rddata);
		if(ibus.rddata[63:32] != address[pc - 1] + 4 || ibus.rddata[31:0] != address[pc - 1] || ~ans_valid[pc - 1]) begin
			$display("[Error] expected = %08x%08x, ans_valid = %d", address[pc - 1] + 4, address[pc - 1], ans_valid[pc - 1]);
			$stop;
		end
		ans_record[pc - 1] = 1'b1;
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
	wait(pc == 5);
	#15
	ibus.flush_1 = 1'b1;
	ibus.flush_2 = 1'b1;
	#10
	ibus.flush_1 = 1'b0;
	ibus.flush_2 = 1'b0;

	wait(pc == 8);
	#25
	ibus.flush_1 = 1'b1;
	ibus.flush_2 = 1'b1;
	#10
	ibus.flush_1 = 1'b0;
	ibus.flush_2 = 1'b0;

	wait(pc == 12);
	#45
	ibus.flush_1 = 1'b1;
	ibus.flush_2 = 1'b1;
	#10
	ibus.flush_1 = 1'b0;
	ibus.flush_2 = 1'b0;

	wait(pc == 17);
	if(ans_record != ans_valid) $display("[Error]");
	else $display("[Pass]");
	$finish;
end

endmodule
