`include "cpu_defs.svh"

module branch_resolver(
	input  logic             en,
	input  uint32_t          reg1,
	input  uint32_t          reg2,
	input  pipeline_decode_t data,
	`ifdef ENABLE_FPU
	input  logic             fcc_match,
	`endif
	output branch_resolved_t resolved_branch
);

/* resolve branch */
logic reg_equal;
uint32_t instr;
branch_predict_t branch_sbt;
assign instr      = data.fetch.instr;
assign branch_sbt = data.fetch.branch_predict;
assign reg_equal  = (reg1 == reg2);

assign resolved_branch.valid   = data.valid & data.decoded.is_controlflow & en;
assign resolved_branch.counter = branch_sbt.counter;
assign resolved_branch.pc      = data.fetch.vaddr;
assign resolved_branch.cf      = data.decoded.cf;

always_comb begin
	unique case(data.decoded.op)
		OP_BLTZ, OP_BLTZAL: resolved_branch.taken = reg1[31];
		OP_BGEZ, OP_BGEZAL: resolved_branch.taken = ~reg1[31];
		OP_BEQ:  resolved_branch.taken = reg_equal;
		OP_BNE:  resolved_branch.taken = ~reg_equal;
		OP_BLEZ: resolved_branch.taken = reg_equal | reg1[31];
		OP_BGTZ: resolved_branch.taken = ~reg_equal & ~reg1[31];
		OP_JAL, OP_JALR: resolved_branch.taken = 1'b1;
		`ifdef ENABLE_FPU
			OP_BC1: resolved_branch.taken = fcc_match;
		`endif
		default: resolved_branch.taken = 1'b0;
	endcase

	unique case(data.decoded.op)
	`ifdef ENABLE_FPU
		OP_BC1,
	`endif
		OP_BLTZ, OP_BLTZAL, OP_BGEZ, OP_BGEZAL,
		OP_BEQ,  OP_BNE,    OP_BLEZ, OP_BGTZ: begin
			resolved_branch.target = data.decoded.default_jump_i;
			resolved_branch.mispredict = branch_sbt.valid
				& (branch_sbt.taken ^ resolved_branch.taken);
			if(resolved_branch.taken)
				resolved_branch.mispredict |= (branch_sbt.target != resolved_branch.target) | ~branch_sbt.valid;
		end
		OP_JAL:  begin
			resolved_branch.target = data.decoded.default_jump_j;
			resolved_branch.mispredict = (branch_sbt.target != resolved_branch.target) | ~branch_sbt.valid | ~branch_sbt.taken;
		end
		OP_JALR: begin
			resolved_branch.target = reg1;
			resolved_branch.mispredict = (branch_sbt.target != resolved_branch.target) | ~branch_sbt.valid | ~branch_sbt.taken;
		end
		default: begin
			resolved_branch.target     = '0;
			resolved_branch.mispredict = 1'b1;
		end
	endcase
end

endmodule
