`include "cpu_defs.svh"

module delayed_exec #(
	parameter int HAS_DIV = 1
) (
	input  logic             stall,
	input  pipeline_exec_t   data,
	output pipeline_exec_t   result,
	input  branch_early_resolved_t early_resolved,
	output branch_resolved_t resolved_branch
);

oper_t op;
uint32_t exec_ret, reg1, reg2, instr;
assign instr = data.instr;
assign reg1 = data.delayed_reg[0];
assign reg2 = data.delayed_reg[1];
assign op   = data.decoded.op;

always_comb begin
	result = data;
	result.result = exec_ret;
end

// unsigned register arithmetic
uint32_t add_u, sub_u;
assign add_u = reg1 + reg2;
assign sub_u = reg1 - reg2;

// comparsion
logic signed_lt, unsigned_lt;
assign signed_lt = (reg1[31] != reg2[31]) ? reg1[31] : sub_u[31];
assign unsigned_lt = (reg1 < reg2);

// setup execution result
always_comb begin
	unique case(op)
		/* logical instructions */
		OP_AND: exec_ret = reg1 & reg2;
		OP_OR:  exec_ret = reg1 | reg2;
		OP_XOR: exec_ret = reg1 ^ reg2;
		OP_NOR: exec_ret = ~(reg1 | reg2);

		/* add and subtract */
		OP_ADDU: exec_ret = add_u;
		OP_SUBU: exec_ret = sub_u;

		/* shift instructions */
		OP_SLL:  exec_ret = reg2 << instr[10:6];
		OP_SLLV: exec_ret = reg2 << reg1[4:0];
		OP_SRL:  exec_ret = reg2 >> instr[10:6];
		OP_SRLV: exec_ret = reg2 >> reg1[4:0];
		OP_SRA:  exec_ret = $signed(reg2) >>> instr[10:6];
		OP_SRAV: exec_ret = $signed(reg2) >>> reg1[4:0];

		/* compare and set */
		OP_SLTU: exec_ret = { 30'b0, unsigned_lt };
		OP_SLT:  exec_ret = { 30'b0, signed_lt   };
		default: exec_ret = data.result;
	endcase
end

branch_predict_t branch_sbt;
assign branch_sbt              = data.branch_predict;
assign resolved_branch.valid   = data.valid & data.decoded.is_controlflow & data.decoded.delayed_exec & ~stall;
assign resolved_branch.counter = branch_sbt.counter;
assign resolved_branch.pc      = data.pc;
assign resolved_branch.cf      = data.decoded.cf;
assign resolved_branch.target  = early_resolved.target;
assign resolved_branch.taken   = early_resolved.negate 
	^ (early_resolved.mask_sign & early_resolved.cond_sign
	| early_resolved.mask_equal & early_resolved.cond_equal);
always_comb begin
	unique case(data.decoded.op)
		OP_BLTZ, OP_BLTZAL, OP_BGEZ, OP_BGEZAL,
		OP_BEQ,  OP_BNE,    OP_BLEZ, OP_BGTZ: begin
			resolved_branch.mispredict = branch_sbt.valid
				& (branch_sbt.taken ^ resolved_branch.taken);
			if(resolved_branch.taken)
				resolved_branch.mispredict |= (branch_sbt.target != resolved_branch.target) | ~branch_sbt.valid;
		end
		default: resolved_branch.mispredict = 1'b1;
	endcase
end

endmodule
