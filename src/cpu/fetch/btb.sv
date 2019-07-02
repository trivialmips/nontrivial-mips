`include "cpu_defs.svh"

module btb #(
	parameter int ENTRIES_NUM = 128
)(
	input  logic         clk,
	input  logic         rst_n,
	input  logic         flush,

	input  virt_t        pc,
	input  btb_update_t  update,
	output btb_predict_t [`FETCH_NUM-1:0] predict
);

endmodule
