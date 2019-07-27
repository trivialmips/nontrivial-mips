`include "cpu_defs.svh"

module alu(
	input  oper_t      op,
	input  virt_t      pc,
	input  uint32_t    instr,
	input  uint32_t    reg1,
	input  uint32_t    reg2,
	output uint32_t    result,
	output exception_t ex
);

// unsigned register arithmetic
uint32_t add_u, sub_u;
assign add_u = reg1 + reg2;
assign sub_u = reg1 - reg2;

// overflow checking
logic ov_add, ov_sub;
assign ov_add = (reg1[31] == reg2[31]) & (reg1[31] ^ add_u[31]);
assign ov_sub = (reg1[31] ^ reg2[31]) & (reg1[31] ^ sub_u[31]);

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

// execution result
always_comb begin
	unique case(op)
		/* logical instructions */
		OP_LUI: result = { instr[15:0], 16'b0 };
		OP_AND: result = reg1 & reg2;
		OP_OR:  result = reg1 | reg2;
		OP_XOR: result = reg1 ^ reg2;
		OP_NOR: result = ~(reg1 | reg2);

		/* add and subtract */
		OP_ADD, OP_ADDU: result = add_u;
		OP_SUB, OP_SUBU: result = sub_u;

		/* bits counting */
		OP_CLZ: result = clz_cnt;
		OP_CLO: result = clo_cnt;

		/* shift instructions */
		OP_SLL:  result = reg2 << instr[10:6];
		OP_SLLV: result = reg2 << reg1[4:0];
		OP_SRL:  result = reg2 >> instr[10:6];
		OP_SRLV: result = reg2 >> reg1[4:0];
		OP_SRA:  result = $signed(reg2) >>> instr[10:6];
		OP_SRAV: result = $signed(reg2) >>> reg1[4:0];

		/* compare and set */
		OP_SLTU: result = { 30'b0, unsigned_lt };
		OP_SLT:  result = { 30'b0, signed_lt   };
		default: result = '0;
	endcase
end

// exception
logic trap_valid;
always_comb begin
	unique case(op)
		OP_TEQ:  trap_valid = (reg1 == reg2);
		OP_TNE:  trap_valid = (reg1 != reg2);
		OP_TGE:  trap_valid = ~signed_lt;
		OP_TLT:  trap_valid = signed_lt;
		OP_TGEU: trap_valid = ~unsigned_lt;
		OP_TLTU: trap_valid = unsigned_lt;
		default: trap_valid = 1'b0;
	endcase
end

// ( trap, break, syscall, overflow, privilege )
logic [3:0] ex_ex;
assign ex_ex = {
	trap_valid,
	op == OP_BREAK,
	op == OP_SYSCALL,
	((op == OP_ADD) & ov_add) | ((op == OP_SUB) & ov_sub)
};

always_comb begin
	ex = '0;
	ex.valid = |ex_ex;
	unique case(ex_ex)
		4'b1000: ex.exc_code = `EXCCODE_TR;
		4'b0100: ex.exc_code = `EXCCODE_BP;
		4'b0010: ex.exc_code = `EXCCODE_SYS;
		4'b0001: ex.exc_code = `EXCCODE_OV;
		default: ex.exc_code = '0;
	endcase
end

endmodule
