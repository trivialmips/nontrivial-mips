`include "cpu_defs.svh"

module branch(
	input  reserve_station_t  rs,
	output uint32_t           result,
	output branch_resolved_t  resolved
);

uint32_t reg1, reg2, instr;
logic reg_equal;
virt_t pc_plus4, pc_plus8;
virt_t default_jump_j, default_jump_i;
branch_predict_t branch_sbt;

assign reg1   = rs.operand[0];
assign reg2   = rs.operand[1];
assign instr  = rs.fetch.instr;
assign result = pc_plus8;

assign branch_sbt     = rs.fetch.branch_predict;
assign pc_plus4       = rs.fetch.vaddr + 32'd4;
assign pc_plus8       = rs.fetch.vaddr + 32'd8;
assign default_jump_i = pc_plus4 + { {14{instr[15]}}, instr[15:0], 2'b0 };
assign default_jump_j = { pc_plus4[31:28], instr[25:0], 2'b0 };
assign reg_equal = (reg1 == reg2);

assign resolved.valid   = rs.decoded.is_controlflow;
assign resolved.counter = branch_sbt.counter;
assign resolved.pc      = rs.fetch.vaddr;
assign resolved.cf      = rs.decoded.cf;

always_comb begin
	unique case(rs.decoded.op)
		OP_BLTZ, OP_BLTZAL: resolved.taken = reg1[31];
		OP_BGEZ, OP_BGEZAL: resolved.taken = ~reg1[31];
		OP_BEQ:  resolved.taken = reg_equal;
		OP_BNE:  resolved.taken = ~reg_equal;
		OP_BLEZ: resolved.taken = reg_equal | reg1[31];
		OP_BGTZ: resolved.taken = ~reg_equal & ~reg1[31];
		OP_JAL, OP_JALR: resolved.taken = 1'b1;
		default: resolved.taken = 1'b0;
	endcase

	unique case(rs.decoded.op)
		OP_BLTZ, OP_BLTZAL, OP_BGEZ, OP_BGEZAL,
		OP_BEQ,  OP_BNE,    OP_BLEZ, OP_BGTZ: begin
			resolved.target = default_jump_i;
			resolved.mispredict = branch_sbt.valid
				& (branch_sbt.taken ^ resolved.taken);
			if(resolved.taken)
				resolved.mispredict |= (branch_sbt.target != resolved.target) | ~branch_sbt.valid;
		end
		OP_JAL:  begin
			resolved.target = default_jump_j;
			resolved.mispredict = (branch_sbt.target != resolved.target) | ~branch_sbt.valid;
		end
		OP_JALR: begin
			resolved.target = reg1;
			resolved.mispredict = (branch_sbt.target != resolved.target) | ~branch_sbt.valid;
		end
		default: begin
			resolved.target     = '0;
			resolved.mispredict = 1'b1;
		end
	endcase
end


endmodule
