`include "cpu_defs.svh"

module branch_predictor #(
	parameter int BTB_SIZE = 8,
	parameter int BHT_SIZE = 1024,
	parameter int RAS_SIZE = 8
)(
	input  logic   clk,
	input  logic   rst_n,
	input  logic   flush,
	input  logic   stall_s1,
	input  logic   stall_s2,

	input  virt_t            pc,   // 8-bytes aligned
	input  branch_resolved_t resolved_branch,
	input  uint32_t          [`FETCH_NUM-1:0] instr,
	input  logic             [`FETCH_NUM-1:0] instr_valid,

	output logic             valid,
	output virt_t            predict_vaddr,
	output logic             [`FETCH_NUM-1:0] maybe_jump,
	output controlflow_t     [`FETCH_NUM-1:0] cf
);

// BHT information
bht_update_t  bht_update;
bht_predict_t [`FETCH_NUM-1:0] bht_predict;

// BTB information
btb_update_t  btb_update;
btb_predict_t [`FETCH_NUM-1:0] btb_predict;

// RAS information
logic ras_pop, ras_push;
virt_t ras_update;
ras_t ras_predict;

// branch information
uint32_t [`FETCH_NUM-1:0] imm_branch, imm_jump;
logic    [`FETCH_NUM-1:0] is_branch;
logic    [`FETCH_NUM-1:0] is_return, is_call;
logic    [`FETCH_NUM-1:0] is_jump_r, is_jump_i;

// generate branch results
logic [`FETCH_NUM-1:0] taken;
always_comb begin
	ras_pop       = 1'b0;
	ras_push      = 1'b0;
	ras_update    = '0;
	predict_vaddr = '0;
	taken         = '0;
	for(int i = 0; i < `FETCH_NUM; ++i) begin
		cf[i] = ControlFlow_None;
	end

	for(int i = `FETCH_NUM - 1; i >= 0; --i) begin
		unique case( {
			is_branch[i],
			is_return[i],
			is_jump_i[i],
			is_jump_r[i] }
		)
		4'b0000:;       // do nothing, no control flow change
		4'b0001: begin  // unconditional jump via register, use BTB
			ras_pop  = 1'b0;
			ras_push = 1'b0;
			if(btb_predict[i].valid) begin
				cf[i] = ControlFlow_JumpReg;
				predict_vaddr = btb_predict[i].target;
			end
		end
		4'b0010: begin  // unconditional jump via immediate
			ras_pop  = 1'b0;
			ras_push = 1'b0;
			cf[i] = ControlFlow_JumpImm;
			predict_vaddr = { pc[31:28], imm_jump[i][27:0] };
		end
		4'b0100: begin // return, use RAS
			ras_pop  = ras_predict.valid;
			ras_push = 1'b0;
			cf[i] = ControlFlow_Return;
			predict_vaddr = ras_predict.data;
		end
		4'b1000: begin // conditional jump, use BHT
			ras_pop  = 1'b0;
			ras_push = 1'b0;
			if(bht_predict[i].valid) begin
				// use BHT result
				taken[i] = bht_predict[i].taken;
			end else begin
				// static branch prediction
				taken[i] = imm_branch[i][31];
			end

			if(taken[i]) begin
				cf[i] = ControlFlow_Branch;
				predict_vaddr = (pc | (i << 2)) + imm_branch[i];
			end
		end
		default:; // error
		endcase

		if(is_call[i]) begin
			ras_push   = 1'b1;
			ras_update = pc + 4 * i + 8;
		end
	end

	valid = 1'b0;
	for(int i = 0; i < `FETCH_NUM; ++i) begin
		valid = valid | (cf[i] != ControlFlow_None);
	end
end

// update BTB/BHT
assign btb_update.valid  = ~stall_s2
       & resolved_branch.valid
       & resolved_branch.mispredict
       & (resolved_branch.cf == ControlFlow_JumpReg);
assign btb_update.pc     = resolved_branch.pc;
assign btb_update.target = resolved_branch.target;

assign bht_update.valid  = ~stall_s2
       & resolved_branch.valid 
       & (resolved_branch.cf == ControlFlow_Branch);
assign bht_update.pc     = resolved_branch.pc;
assign bht_update.taken  = resolved_branch.taken;

// decode branch information
logic [`FETCH_NUM-1:0] b_branch;
logic [`FETCH_NUM-1:0] b_return, b_call;
logic [`FETCH_NUM-1:0] b_jump_r, b_jump_i;

for(genvar i = 0; i < `FETCH_NUM; ++i) begin : gen_branch_decoder
	decode_branch b_decoder(
		.instr      ( instr[i]       ),
		.imm_branch ( imm_branch[i]  ),
		.imm_jump   ( imm_jump[i]    ),
		.is_branch  ( b_branch[i]    ),
		.is_return  ( b_return[i]    ),
		.is_call    ( b_call[i]      ),
		.is_jump_i  ( b_jump_i[i]    ),
		.is_jump_r  ( b_jump_r[i]    )
	);

	assign is_branch[i] = instr_valid[i] & b_branch[i];
	assign is_return[i] = instr_valid[i] & b_return[i];
	assign is_call[i]   = instr_valid[i] & b_call[i];
	assign is_jump_i[i] = instr_valid[i] & b_jump_i[i];
	assign is_jump_r[i] = instr_valid[i] 
	                      & b_jump_r[i] & ~b_call[i] & ~b_return[i];
	assign maybe_jump[i] = instr_valid[i] & (
		  b_branch[i] | b_return[i] | b_call[i]
		| b_jump_i[i] | b_jump_r[i]
	);

end

bht #(
	.ENTRIES_NUM ( BHT_SIZE )
) bht_inst (
	.clk,
	.rst_n,
	.flush,
	.pc,
	.update  ( bht_update  ),
	.predict ( bht_predict )
);

btb #(
	.ENTRIES_NUM ( BTB_SIZE )
) btb_inst (
	.clk,
	.rst_n,
	.flush,
	.pc,
	.update  ( btb_update  ),
	.predict ( btb_predict )
);

ras #(
	.ENTRIES_NUM ( RAS_SIZE )
) ras_inst (
	.clk,
	.rst_n,
	.flush,
	.push_req   ( ~stall_s1 & ras_push ),
	.pop_req    ( ~stall_s1 & ras_pop  ),
	.push_data  ( ras_update  ),
	.ras_top    ( ras_predict )
);

endmodule
