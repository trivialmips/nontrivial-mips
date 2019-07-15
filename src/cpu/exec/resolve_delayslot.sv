`include "cpu_defs.svh"

module resolve_delayslot (
	input  logic  clk,
	input  logic  rst,
	input  logic  flush,
	input  logic  stall,

	input  pipeline_decode_t [`ISSUE_NUM-1:0] data,
	output [`ISSUE_NUM-1:0] resolved_delayslot
);

logic wait_delayslot, wait_delayslot_nxt;
logic [`ISSUE_NUM-1:0] is_controlflow;

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_cf
	assign is_controlflow[i] = data[i].valid & data[i].decoded.is_controlflow;
end

assign resolved_delayslot[0] = wait_delayslot & data[0].valid;
for(genvar i = 1; i < `ISSUE_NUM; ++i) begin : gen_rd
	assign resolved_delayslot[i] = is_controlflow[i - 1] & data[i].valid;
end

always_comb begin
	wait_delayslot_nxt = is_controlflow[`ISSUE_NUM - 1];
	for(int i = 0; i < `ISSUE_NUM - 1; ++i)
		wait_delayslot_nxt |= is_controlflow[i] & ~data[i + 1].valid;
end

always_ff @(posedge clk) begin
	if(rst || flush)
		wait_delayslot <= 1'b0;
	else if(~stall)
		wait_delayslot <= wait_delayslot_nxt;
end

endmodule
