`include "cpu_defs.svh"

module instr_fetch #(
	parameter int BPU_SIZE = 4096,
	parameter int INSTR_FIFO_DEPTH = 4,
	parameter int ICACHE_LINE_WIDTH = `ICACHE_LINE_WIDTH
)(
	input  logic    clk,
	input  logic    rst,
	input  logic    flush_pc,

	// stall popping instructions
	input  logic    stall_pop,
	// stall from EX/MM, resolved_branch does not change
	input  logic    hold_resolved_branch,

	// exception
	input  logic    except_valid,
	input  virt_t   except_vec,

	// mispredict
	input  branch_resolved_t    resolved_branch_i,

	// memory request
	input  instr_fetch_memres_t icache_res,
	output instr_fetch_memreq_t icache_req,

	// fetch
	input  fetch_ack_t                    fetch_ack,
	output fetch_entry_t [`FETCH_NUM-1:0] fetch_entry
);

localparam int FETCH_WIDTH      = $clog2(`FETCH_NUM);
localparam int ADDR_ALIGN_WIDTH = FETCH_WIDTH + 2;

function virt_t aligned_address( input virt_t addr );
	return { addr[31:ADDR_ALIGN_WIDTH], {ADDR_ALIGN_WIDTH{1'b0}} };
endfunction

// process resolved_branch
branch_resolved_t resolved_branch;
always_comb begin
	resolved_branch = resolved_branch_i;
	resolved_branch.valid &= ~hold_resolved_branch;
end

struct packed {
	logic valid;
	virt_t pc;
} pipe_s1;

struct packed {
	logic valid;
	logic delayslot;
	virt_t pc;
	branch_predict_t bp;
	address_exception_t iaddr_ex;
	logic [1:0] prediction_sel;
} pipe_s2;

// replay (queue full)
logic replay_valid;
uint32_t replay_vaddr;

// presolved branch ( for non-controlflow )
presolved_branch_t presolved_branch;

// fetch entries
fetch_entry_t [2:0] entry_s2, entry_s2_d, entry_s3;

// fetch delayslot next cycle
logic predict_delayed, delayslot_s3;

// instruction queue
logic queue_full, queue_empty;
logic [3:0] queue_valid;

// control signals
logic ready, bpu_ready;
logic stall_s1, stall_s2;
logic flush_s1, flush_s2, flush_s3;
assign stall_s2 = icache_res.stall & ~flush_s2;
assign stall_s1 = stall_s2;
assign flush_s3 = flush_pc | (resolved_branch.valid & resolved_branch.mispredict);
assign flush_s2 = flush_s3 | presolved_branch.mispredict | replay_valid;
assign flush_s1 = flush_s2;
assign icache_req.flush_s1 = flush_s1;
assign icache_req.flush_s2 = flush_s2;
assign predict_delayed = pipe_s2.bp.valid
	& pipe_s2.bp.taken & pipe_s2.bp.wait_delayslot;
assign ready = icache_res.icache_ready & bpu_ready;

/* ====== stage 1 (PCGen) ====== */
pc_generator pc_gen(
	.clk,
	.rst,
	.ready,
	.hold_pc ( stall_s1 ),
	.except_valid,
	.except_vec,
	.replay_valid,
	.replay_vaddr,
	.predict_delayed,
	.predict_valid ( pipe_s2.bp.valid & pipe_s2.bp.taken ),
	.predict_vaddr ( pipe_s2.bp.target ),
	.resolved_branch,
	.presolved_branch,
	.pc    ( pipe_s1.pc    ),
	.pc_en ( pipe_s1.valid )
);

branch_predictor #(
	.SIZE(BPU_SIZE),
	.ICACHE_LINE_WIDTH(ICACHE_LINE_WIDTH)
) bpu_inst (
	.clk,
	.rst,
	.ready,
	.stall          ( stall_s1   ),
	.flush          ( flush_s1   ),
	.pc_cur         ( pipe_s1.pc ),
	.pc_prev        ( pipe_s2.pc ),
	.skip           ( pipe_s2.delayslot ),
	.bpu_ready,
	.resolved_branch,
	.presolved_branch,
	.prediction     ( pipe_s2.bp ),
	.prediction_sel ( pipe_s2.prediction_sel )
);

// I$ request
assign icache_req.read  = pipe_s1.valid;
assign icache_req.vaddr = aligned_address(pipe_s1.pc);

/* pipeline between PCGen and I$ read */
always_ff @(posedge clk) begin
	if(rst || flush_s1 || stall_s1 & ~stall_s2) begin
		pipe_s2.pc        <= '0;
		pipe_s2.valid     <= 1'b0;
		pipe_s2.iaddr_ex  <= '0;
		pipe_s2.delayslot <= 1'b0;
	end else if(~stall_s1) begin
		// pipe_s2.bp comes from RAM
		pipe_s2.pc        <= pipe_s1.pc;
		pipe_s2.valid     <= pipe_s1.valid;
		pipe_s2.iaddr_ex  <= icache_res.iaddr_ex;
		pipe_s2.delayslot <= predict_delayed;
	end
end

/* ====== stage 2 (I$ read) ====== */
logic [1:0] avail_instr_s2, avail_instr_s2_d, avail_instr_s3;
always_comb begin
	entry_s2 = '0;
	for(int i = 0; i < 3; ++i) begin
		entry_s2[i].vaddr = { pipe_s2.pc[31:3], 1'b0, pipe_s2.pc[1:0] } + 4 * i;
		entry_s2[i].iaddr_ex = pipe_s2.iaddr_ex;
		entry_s2[i].branch_predict = pipe_s2.bp;
	end

	entry_s2[0].branch_predict.valid = pipe_s2.bp.valid & pipe_s2.prediction_sel[0];
	entry_s2[1].branch_predict.valid = pipe_s2.bp.valid & pipe_s2.prediction_sel[1];
	entry_s2[2].branch_predict.valid = 1'b0;

	entry_s2[0].valid = (pipe_s2.pc[2] == 0);
	entry_s2[1].valid = 1'b1;
	entry_s2[2].valid = ~predict_delayed
		& entry_s2[1].branch_predict.valid
		& entry_s2[1].branch_predict.taken;

	// branch taken, but delayslot not fetched
	if(pipe_s2.delayslot) begin
		entry_s2[0].valid = ~pipe_s2.pc[2];
		entry_s2[1].valid = pipe_s2.pc[2];
	end

	avail_instr_s2  = entry_s2[0].valid + entry_s2[1].valid + entry_s2[2].valid;

	if(~pipe_s2.valid) begin
		entry_s2 = '0;
		avail_instr_s2 = '0;
	end
end

/* pipeline between I$ and FIFO read */
always_ff @(posedge clk) begin
	if(rst || flush_s2 || stall_s2) begin
		entry_s2_d        <= '0;
		avail_instr_s2_d  <= '0;
		replay_vaddr      <= '0;
		delayslot_s3      <= '0;
	end else begin
		replay_vaddr      <= pipe_s2.pc;
		entry_s2_d        <= entry_s2;
		avail_instr_s2_d  <= avail_instr_s2;
		delayslot_s3      <= pipe_s2.delayslot;
	end
end

// resolve non-controlflow
logic  [1:0] is_branch, is_jump_i, is_jump_r, is_call, is_return;
logic  [1:0] is_cf, is_nocf_mispredict;
virt_t [1:0] imm_branch, imm_jump;
for(genvar i = 0; i < 2; ++i) begin: gen_branch_decoder
	decode_branch branch_decoder_inst(
		.instr ( icache_res.data[31 + 32 * i -: 32] ),
		.is_branch  ( is_branch[i]  ),
		.is_jump_i  ( is_jump_i[i]  ),
		.is_jump_r  ( is_jump_r[i]  ),
		.is_call    ( is_call[i]    ),
		.is_return  ( is_return[i]  ),
		.imm_branch ( imm_branch[i] ),
		.imm_jump   ( imm_jump[i]   )
	);

	assign is_cf[i] = is_branch[i] | is_jump_i[i]
		| is_jump_r[i] | is_call[i] | is_return[i];
	assign is_nocf_mispredict[i] = ~is_cf[i] && entry_s2_d[i].valid
		&& entry_s2_d[i].branch_predict.valid
		&& entry_s2_d[i].branch_predict.cf != ControlFlow_None;
end

assign presolved_branch.mispredict = |is_nocf_mispredict;
assign presolved_branch.pc = is_nocf_mispredict[0] ?
	entry_s2_d[0].vaddr : entry_s2_d[1].vaddr;
assign presolved_branch.target = { entry_s2_d[0].vaddr[31:3] + 1, 1'b0, entry_s2_d[0].vaddr[1:0] };

// Since queue_full if one of channels is full and CHANNEL > PUSH_CHANNEL,
// so after branch is pushed into FIFO, there exists at least one 
// free channel for possible delayslot. We do not replay it.
assign replay_valid = queue_full && (avail_instr_s2_d != '0) && ~delayslot_s3;

// setup fetch entries
always_comb begin
	entry_s3 = entry_s2_d;
	avail_instr_s3 = avail_instr_s2_d;
	entry_s3[0].instr = icache_res.data[31:0];
	entry_s3[1].instr = icache_res.data[63:32];
	entry_s3[2].instr = icache_res.data_extra[31:0];

	entry_s3[1].branch_predict.valid &= ~presolved_branch.mispredict;
	entry_s3[0].branch_predict.valid &= ~presolved_branch.mispredict;

	if(entry_s3[2].valid & presolved_branch.mispredict) begin
		entry_s3[2] = '0;
		avail_instr_s3 -= 1;
	end

	if(~entry_s3[0].valid) begin
		entry_s3[0] = entry_s3[1];
		entry_s3[1] = entry_s3[2];
		entry_s3[2].valid = 1'b0;
	end
end

fetch_entry_t [1:0] fetch_entry_pop;
logic [1:0] fetch_entry_valid;
multi_queue #(
	// REQUIREMENT: CHANNEL >= PUSH_CHANNEL + 1
	// for delayslot
	.CHANNEL      ( 4 ),
	.PUSH_CHANNEL ( 3 ),
	.POP_CHANNEL  ( 2 ),
	.DEPTH   ( INSTR_FIFO_DEPTH ),
	.dtype   ( fetch_entry_t    )
) ique_inst (
	.clk,
	.rst,
	.flush      ( flush_s3     ),
	.stall_push ( replay_valid ),
	.stall_pop  ( stall_pop    ),
	.full       ( queue_full   ),
	.empty      ( queue_empty  ),
	.data_push  ( entry_s3     ),
	.push_num   ( avail_instr_s3  ),
	.data_pop   ( fetch_entry_pop ),
	.pop_valid  ( fetch_entry_valid ),
	.pop_num    ( fetch_ack       )
);

always_comb begin
	fetch_entry = fetch_entry_pop;
	for(int i = 0; i < 2; ++i)
		fetch_entry[i].valid &= fetch_entry_valid[i];
end

endmodule
