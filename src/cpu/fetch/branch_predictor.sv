`include "cpu_defs.svh"

module branch_predictor #(
	parameter int SIZE,
	parameter int ICACHE_LINE_WIDTH
)(
	input  logic   clk,
	input  logic   rst,
	input  logic   flush,

	// current program counter, aligned in 4-bytes
	input  virt_t  pc_cur,

	// previous program counter, aligned in 4-bytes
	input  virt_t  pc_prev,

	// resolved branch information
	input  branch_resolved_t resolved_branch,

	// prediction comes out next cycle
	output branch_predict_t  prediction,
	output logic [1:0]       prediction_sel
);

localparam int ICACHE_ADDR_WIDTH = $clog2(ICACHE_LINE_WIDTH);

// BHT information
bht_update_t  bht_update;
bht_predict_t [1:0] bht_predict;

// BTB information
btb_update_t  btb_update;
btb_predict_t [1:0] btb_predict;

// evaluate prediction results
logic bt_index;
btb_predict_t btb_selected;
bht_predict_t bht_selected;
assign btb_selected = btb_predict[bt_index];
assign bht_selected = bht_predict[bt_index];

logic pipe_flush;
always_ff @(posedge clk) begin
	if(rst) pipe_flush <= 1'b0;
	else    pipe_flush <= flush;
end

always_comb begin
	if(pc_prev[2]) begin
		// not aligned in 8-bytes
		bt_index = 1;
	end else begin
		// two predictions are both available
		bt_index = btb_predict[0].cf != ControlFlow_None ? 0 : 1;
	end

	prediction_sel = '0;
	prediction_sel[bt_index] = 1'b1;

	// set prediction result
	prediction.valid   = btb_selected.cf != ControlFlow_None;
	prediction.target  = btb_selected.target;
	prediction.cf      = btb_selected.cf;
	prediction.counter = bht_selected;
	if(btb_selected.cf == ControlFlow_Branch)
		prediction.taken = bht_selected[1];
	else prediction.taken = 1'b1;

	// the last data in a cache line, no delayslot available
	if(&pc_prev[ICACHE_ADDR_WIDTH - 1 : 2] || pipe_flush)
		prediction.valid = 1'b0;
end

// update BTB whenever we recognize the instruction as controlflow
assign btb_update.valid   = resolved_branch.valid;
assign btb_update.pc      = resolved_branch.pc;
assign btb_update.target  = resolved_branch.target;
assign btb_update.cf      = resolved_branch.cf;

// update BHT when ControlFlow_Branch is resolved
assign bht_update.valid   = resolved_branch.valid
       & resolved_branch.cf == ControlFlow_Branch;
assign bht_update.pc      = resolved_branch.pc;
assign bht_update.taken   = resolved_branch.taken;
assign bht_update.counter = resolved_branch.counter;

bht #(
	.SIZE ( SIZE )
) bht_inst (
	.clk,
	.rst,
	.vaddr   ( pc_cur      ),
	.update  ( bht_update  ),
	.predict ( bht_predict )
);

btb #(
	.SIZE ( SIZE )
) btb_inst (
	.clk,
	.rst,
	.vaddr   ( pc_cur      ),
	.update  ( btb_update  ),
	.predict ( btb_predict )
);

endmodule
