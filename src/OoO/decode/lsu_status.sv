`include "cpu_defs.svh"

module lsu_status(
	input  logic    clk,
	input  logic    rst,
	input  logic    flush,
	input  logic    lsu_store_empty,

	input  reserve_station_t   [1:0] rs,
	input  logic               commit_store,
	
	// LSU status
	output logic     locked
);

logic [$clog2(`ROB_SIZE):0] issued_store;
assign locked = |issued_store | ~lsu_store_empty;

always_ff @(posedge clk) begin
	if(rst || flush) begin
		issued_store <= '0;
	end else begin
		issued_store <= issued_store
			+ (rs[0].busy && rs[0].decoded.fu == FU_STORE)
			+ (rs[1].busy && rs[1].decoded.fu == FU_STORE)
			- commit_store;
	end
end

endmodule
