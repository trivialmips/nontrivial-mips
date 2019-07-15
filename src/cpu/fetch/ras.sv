`include "cpu_defs.svh"

module ras #(
	parameter int ENTRIES_NUM = 4
)(
	input  logic   clk,
	input  logic   rst,
	input  logic   flush,
	input  logic   push_req,
	input  logic   pop_req,
	input  virt_t  push_data,
	output ras_t   ras_top
);

ras_t [ENTRIES_NUM-1:0] ras_now, ras_nxt;

assign ras_top = ras_now[0];

always_comb begin
	ras_nxt = ras_now;

	if(push_req) begin
		ras_nxt[0].data  = push_data;
		ras_nxt[0].valid = 1'b1;
		ras_nxt[ENTRIES_NUM-1:1] = ras_now[ENTRIES_NUM-2:0];
	end

	if(pop_req) begin
		ras_nxt[ENTRIES_NUM-1].data  = '0;
		ras_nxt[ENTRIES_NUM-1].valid = 1'b0;
		ras_nxt[ENTRIES_NUM-2:0] = ras_now[ENTRIES_NUM-1:1];
	end

	if(push_req && pop_req) begin
		ras_nxt = ras_now;
		ras_nxt[0].data  = push_data;
		ras_nxt[0].valid = 1'b1;
	end
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		ras_now <= '0;
	end else begin
		ras_now <= ras_nxt;
	end
end

endmodule
