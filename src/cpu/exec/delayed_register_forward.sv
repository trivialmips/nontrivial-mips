`include "cpu_defs.svh"

module delayed_register_forward(
	input  pipeline_exec_t  data,
	output pipeline_exec_t  result,

	output branch_early_resolved_t early_resolved,
	output reg_addr_t        [1:0] reg_raddr,
	input  uint32_t          [1:0] reg_rdata,
	input  pipeline_exec_t   [`ISSUE_NUM-1:0] pipeline_dcache,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_mem,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_wb
);

assign reg_raddr[0] = data.decoded.rs1;
assign reg_raddr[1] = data.decoded.rs2;

uint32_t [1:0] regs;

always_comb begin
	regs = reg_rdata;

	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_wb[j].rd == data.decoded.rs1)
			regs[0] = pipeline_wb[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_mem[j].rd == data.decoded.rs1)
			regs[0] = pipeline_mem[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_dcache[j].decoded.rd == data.decoded.rs1)
			regs[0] = pipeline_dcache[j].result;
	if(data.decoded.rs1 == '0)
		regs[0] = '0;

	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_wb[j].rd == data.decoded.rs2)
			regs[1] = pipeline_wb[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_mem[j].rd == data.decoded.rs2)
			regs[1] = pipeline_mem[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_dcache[j].decoded.rd == data.decoded.rs2)
			regs[1] = pipeline_dcache[j].result;

	if(data.decoded.rs2 == '0)
		regs[1] = '0;
	if(data.decoded.use_imm)
		regs[1] = data.delayed_reg[1];
end

/* resolve branch */
oper_t op;
uint32_t instr;
virt_t pc_plus4;
virt_t default_jump_j, default_jump_i;
branch_predict_t branch_sbt;
assign op             = data.decoded.op;
assign instr          = data.instr;
assign pc_plus4       = data.pc + 32'd4;
assign default_jump_i = pc_plus4 + { {14{instr[15]}}, instr[15:0], 2'b0 };

assign early_resolved.cond_equal = (regs[0] == regs[1]);
assign early_resolved.cond_sign  = regs[0][31];
assign early_resolved.negate = 
	   op == OP_BGEZ || op == OP_BGEZAL
	|| op == OP_BNE  || op == OP_BGTZ;
assign early_resolved.mask_equal = 
	   op == OP_BEQ || op == OP_BNE
	|| op == OP_BLEZ  || op == OP_BGTZ;
assign early_resolved.mask_sign = 
	   op == OP_BLTZ || op == OP_BLTZAL
	|| op == OP_BGEZ || op == OP_BGEZAL
	|| op == OP_BLEZ || op == OP_BGTZ;

always_comb begin
	unique case(op)
		OP_BLTZ, OP_BLTZAL, OP_BGEZ, OP_BGEZAL,
		OP_BEQ,  OP_BNE,    OP_BLEZ, OP_BGTZ:
			early_resolved.target = default_jump_i;
		default: early_resolved.target = '0;
	endcase
end

always_comb begin
	result = data;
	result.delayed_reg = regs;
end

endmodule
