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

cpu_ibus_if ibus();

icache cache (
	.clk (clk),
	.rst (rst),
	.axi_req (axi_req),
	.axi_resp (axi_resp),

	.ibus (ibus)
);

logic [4:0] pc;
logic [23:0][31:0] address;
logic [0:23] ans_valid, ans_record;
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
assign address[16] = 'h00000000;
assign address[17] = 'h00001000;
assign address[18] = 'h00002000;
assign address[19] = 'h00003000;
assign address[20] = 'h00004000;
assign address[21] = 'h00005000;
assign address[22] = 'h00006000;
assign address[23] = 'h00007000;
assign ans_valid = 24'b1111_1001_0011_0011_1111_1111;

assign ibus.read = 1'b1;
assign ibus.address = address[pc];

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		pc <= '0;
	end else if(~ibus.stall) begin
		pc <= pc + 1;
	end
end

integer cycle;
always_ff @(negedge clk) begin
	cycle <= rst ? '0 : cycle + 1;
	if(rst) begin
		ans_record <= '0;
	end else if(~rst && ibus.valid) begin
		$display("[%0d] pc = %0d, data = %016x", cycle, pc - 1, ibus.rddata);
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

	wait(pc == 25);
	if(ans_record != ans_valid) $display("[Error]");
	else $display("[Pass]");
	$finish;
end

endmodule
