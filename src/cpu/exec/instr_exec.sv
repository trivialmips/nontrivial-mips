`include "cpu_defs.svh"

module instr_exec (
	input  logic    clk,
	input  logic    rst_n,
	input  logic    flush,

	input  pipeline_decode_t data,
	output pipeline_exec_t   result,
	output logic             stall_req
);

uint32_t exec_ret, reg1, reg2;
assign reg1 = data.reg1;
assign reg2 = data.reg2;

assign result.result = exec_ret;

// unsigned register arithmetic
uint32_t add_u, sub_u;
assign add_u = reg1 + reg2;
assign sub_u = reg1 - reg2;

// comparsion
logic signed_lt, unsigned_lt;
assign signed_lt = (reg1[31] != reg2[31]) ? reg1[31] : sub_u[31];
assign unsigned_lt = (reg1 < reg2);

// count leading bits
uint32_t clz_cnt, clo_cnt;
count_bit count_clz(
	.bit_val(1'b0),
	.val(reg1),
	.count(clz_cnt)
);

count_bit count_clo(
	.bit_val(1'b1),
	.val(reg1),
	.count(clo_cnt)
);

always_comb begin
	result.rd = data.decoded.rd;
	if(data.decoded.op == OP_MOVZ && reg2 != '0
		|| data.decoded.op == OP_MOVN && reg2 == '0)
		result.rd = '0;
end

always_comb begin
	exec_ret = '0;
	unique case(data.decoded.op)
		/* logical instructions */
		OP_LUI: exec_ret = { data.instr[15:0], 16'b0 };
		OP_AND: exec_ret = reg1 & reg2;
		OP_OR:  exec_ret = reg1 | reg2;
		OP_XOR: exec_ret = reg1 ^ reg2;
		OP_NOR: exec_ret = ~(reg1 | reg2);

		/* add and subtract */
		OP_ADD, OP_ADDU: exec_ret = add_u;
		OP_SUB, OP_SUBU: exec_ret = sub_u;

		/* bits counting */
		OP_CLZ: exec_ret = clz_cnt;
		OP_CLO: exec_ret = clo_cnt;

		/* move instructions */
		OP_MOVZ, OP_MOVN: exec_ret = reg1;

		/* jump instructions */
		OP_JAL, OP_BLTZAL, OP_BGEZAL, OP_JALR:
			exec_ret = data.pc + 32'd8;

		/* shift instructions */
		OP_SLL:  exec_ret = reg2 << data.instr[10:6];
		OP_SLLV: exec_ret = reg2 << reg1[4:0];
		OP_SRL:  exec_ret = reg2 >> data.instr[10:6];
		OP_SRLV: exec_ret = reg2 >> reg1[4:0];
		OP_SRA:  exec_ret = $signed(reg2) >>> data.instr[10:6];
		OP_SRAV: exec_ret = $signed(reg2) >>> reg1[4:0];

		/* compare and set */
		OP_SLTU: exec_ret = { 30'b0, unsigned_lt };
		OP_SLT:  exec_ret = { 30'b0, signed_lt   };
		default: exec_ret = '0;
	endcase
end

endmodule
