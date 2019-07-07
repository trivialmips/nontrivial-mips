`include "cpu_defs.svh"

module instr_fetch #(
	parameter int unsigned RESET_BASE = `BOOT_VEC,
	parameter int BTB_SIZE = 8,
	parameter int BHT_SIZE = 1024,
	parameter int RAS_SIZE = 8,
	parameter int INSTR_FIFO_DEPTH = 4
)(
	input  logic    clk,
	input  logic    rst,
	input  logic    flush_pc,
	input  logic    flush_bp,

	// stall popping instructions
	input  logic    stall_s2,
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

// When hold_resolved_branch_d is true, resolved_branch is used last
// cycle and do not change due to stall signals from EX/MM.
logic hold_resolved_branch_d;
branch_resolved_t resolved_branch;
always_comb begin
	resolved_branch = resolved_branch_i;
	resolved_branch.valid &= ~hold_resolved_branch_d;
end

always_ff @(posedge clk or posedge rst) begin
	if(rst || flush_pc) begin
		hold_resolved_branch_d <= 1'b0;
	end else begin
		hold_resolved_branch_d <= hold_resolved_branch;
	end
end

// program counter (stage 1)
logic    hold_pc;
virt_t   pc, fetch_vaddr;

// pipeline registers
logic    predict_valid_d;
virt_t   fetch_vaddr_d, predict_vaddr_d;
logic    [`FETCH_NUM-1:0] maybe_jump_d;

// fetched instructions (stage 2)
logic    invalid_push;
logic    [`FETCH_NUM-1:0] instr_valid;
virt_t   [`FETCH_NUM-1:0] instr_vaddr;
uint32_t [`FETCH_NUM-1:0] instr;

// instruction queue (stage 2)
logic    queue_full, queue_empty, flush_que;
logic    [$clog2(`FETCH_NUM+1)-1:0] valid_instr_num;

// branch prediction (stage 2)
logic    predict_valid, predict_delayed;
virt_t   predict_vaddr;
controlflow_t    [`FETCH_NUM-1:0] cf;
branch_predict_t [`FETCH_NUM-1:0] branch_predict;
logic            [`FETCH_NUM-1:0] maybe_jump;

/* ==== stage 1 ====
 * send I$ request
 * compute next PC */

// I$ request
assign icache_req.read  = 1'b1;
assign icache_req.vaddr = aligned_address(fetch_vaddr);

// set fetch address
logic delayslot;
assign delayslot = maybe_jump[`FETCH_NUM - 1];
assign predict_delayed = predict_valid & delayslot;
always_comb begin
	if(hold_pc) begin
		fetch_vaddr = fetch_vaddr_d;
	end else if(predict_valid) begin
		// when the last instruction is a branch
		// delayslot must be fetched next cycle
		fetch_vaddr = delayslot ? pc : predict_vaddr;
	end else begin 
		fetch_vaddr = pc;
	end
end

assign hold_pc = (icache_res.stall | queue_full) & ~flush_pc;

pc_generator #(
	.RESET_BASE ( RESET_BASE )
) pc_gen_inst (
	.clk,
	.rst,
	.hold_pc,
	.except_valid,
	.except_vec,
	.predict_valid,
	.predict_vaddr,
	.predict_delayed,
	.resolved_branch,
	.pc
);

/* ==== pipline stage 1 and 2 ==== */
always_ff @(posedge clk or posedge rst) begin
	if(rst || flush_pc) begin
		fetch_vaddr_d   <= '0;
		predict_vaddr_d <= '0;
		predict_valid_d <= '0;
		maybe_jump_d    <= '0;
	end else if(~hold_pc) begin
		predict_valid_d <= predict_valid;
		predict_vaddr_d <= predict_vaddr;
		fetch_vaddr_d   <= fetch_vaddr;
		maybe_jump_d    <= maybe_jump;
	end
end

always_ff @(posedge clk or posedge rst) begin
	invalid_push <= rst | flush_que;
end

/* ==== stage 2 ====
 * predict branch
 * push instructions */

// pack branch prediction
for(genvar i = 0; i < `FETCH_NUM; ++i) begin : gen_pack_bp
	assign branch_predict[i].cf = cf[i];
	assign branch_predict[i].predict_vaddr = predict_vaddr;
end

// unpack instructions
logic [FETCH_WIDTH-1:0] fetch_offset;
virt_t aligned_fetch_vaddr_d;

assign fetch_offset = fetch_vaddr_d[ADDR_ALIGN_WIDTH-1 -: FETCH_WIDTH];
assign aligned_fetch_vaddr_d = aligned_address(fetch_vaddr_d);

for(genvar i = 0; i < `FETCH_NUM; ++i) begin : gen_unpacked_instr
	assign instr[i] = icache_res.data[i * 32 +: 32];
end

logic delayslot_d;
assign delayslot_d = maybe_jump_d[`FETCH_NUM - 1];
always_comb begin
	for(int i = 0; i < `FETCH_NUM; ++i) begin
		instr_vaddr[i] = aligned_fetch_vaddr_d + i * 4;
		instr_valid[i] = (i >= fetch_offset);
	end

	valid_instr_num = `FETCH_NUM - fetch_offset;

	if(predict_valid_d & delayslot_d) begin
		instr_valid = '0;
		instr_valid[fetch_offset] = 1'b1;
		valid_instr_num = 1;
	end

	if(invalid_push) begin
		instr_valid = '0;
		valid_instr_num = 0;
	end
end

// commit flush request
assign icache_req.flush_s2 = flush_pc
      | (resolved_branch.valid & resolved_branch.mispredict);
assign icache_req.flush_s1 = icache_req.flush_s2; // | predict_valid;
assign flush_que = icache_req.flush_s2;

branch_predictor #(
	.BTB_SIZE ( BTB_SIZE ),
	.BHT_SIZE ( BHT_SIZE ),
	.RAS_SIZE ( RAS_SIZE )
) bp_inst (
	.clk,
	.rst,
	.flush           ( flush_bp              ),
	.stall_s1        ( hold_pc               ),
	.pc              ( aligned_fetch_vaddr_d ),
	.resolved_branch ( resolved_branch       ),
	.instr,
	.instr_valid,
	.valid           ( predict_valid         ),
	.maybe_jump,
	.predict_vaddr,
	.cf
);

instr_queue #(
	.FIFO_DEPTH ( INSTR_FIFO_DEPTH )
) ique_inst (
	.clk,
	.rst,
	.flush      ( flush_que   ),
	.stall_push ( hold_pc     ),
	.stall_pop  ( stall_s2    ),
	.full       ( queue_full  ),
	.empty      ( queue_empty ),
	.instr      ( instr       ),
	.vaddr      ( instr_vaddr ),
	.branch_predict,
	.valid_num  ( valid_instr_num     ),
	.offset     ( fetch_offset        ),
	.iaddr_ex   ( icache_res.iaddr_ex ),
	.fetch_ack,
	.fetch_entry
);

endmodule
