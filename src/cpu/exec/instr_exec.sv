`include "cpu_defs.svh"

module instr_exec (
	input  logic    clk,
	input  logic    rst_n,
	input  logic    flush,

	input  pipeline_decode_t data,
	output pipeline_exec_t   result,
	output logic             stall_req

	output virt_t       mmu_vaddr,
	input  mmu_result_t mmu_result
);

exception_t ex;
uint32_t exec_ret, reg1, reg2, instr;
assign reg1 = data.reg1;
assign reg2 = data.reg2;
assign instr = data.fetch.instr;

assign result.ex     = ex;
assign result.result = exec_ret;
assign result.pc     = data.fetch.vaddr;
assign result.eret   = (data.decoded.op == OP_ERET);

// unsigned register arithmetic
uint32_t add_u, sub_u;
assign add_u = reg1 + reg2;
assign sub_u = reg1 - reg2;

// overflow checking
Bit_t ov_add, ov_sub;
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

always_comb begin
	result.decoded = data.decoded;
	if(data.decoded.op == OP_MOVZ && reg2 != '0
		|| data.decoded.op == OP_MOVN && reg2 == '0)
		result.rd = '0;
end

always_comb begin
	exec_ret = '0;
	unique case(data.decoded.op)
		/* logical instructions */
		OP_LUI: exec_ret = { instr[15:0], 16'b0 };
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
		OP_SLL:  exec_ret = reg2 << instr[10:6];
		OP_SLLV: exec_ret = reg2 << reg1[4:0];
		OP_SRL:  exec_ret = reg2 >> instr[10:6];
		OP_SRLV: exec_ret = reg2 >> reg1[4:0];
		OP_SRA:  exec_ret = $signed(reg2) >>> instr[10:6];
		OP_SRAV: exec_ret = $signed(reg2) >>> reg1[4:0];

		/* compare and set */
		OP_SLTU: exec_ret = { 30'b0, unsigned_lt };
		OP_SLT:  exec_ret = { 30'b0, signed_lt   };
		default: exec_ret = '0;
	endcase
end

/* memory operation */
uint32_t extended_imm, mem_wrdata;
logic [3:0] mem_sel;
assign extended_imm = { {16{instr[15]}, instr[15:0] };
assign mmu_vaddr = reg1 + extended_imm;

// TODO: LL/SC
assign result.memreq.read  = data.decoded.is_load;
assign result.memreq.write = data.decoded.is_store;
assign result.memreq.vaddr = mmu_vaddr;
assign result.memreq.paddr = mmu_result.phy_addr;
assign result.memreq.wrdata = mem_wrdata;
assign result.memreq.byteenable = mem_sel;

always_comb begin
	unique case(data.decoded.op)
		OP_LW, OP_LL, OP_SW, OP_SC: begin
			mem_wrdata = reg2;
			mem_sel = 4'b1111;
		end
		OP_LB, OP_LBU, OP_SB: begin
			mem_wrdata = reg2 << (mem_vaddr[1:0] * 8);
			mem_sel = 4'b0001 << mem_vaddr[1:0];
		end
		OP_LH, OP_LHU, OP_SH: begin
			mem_wrdata = mem_vaddr[1] ? (reg2 << 16) : reg2;
			mem_sel = mem_vaddr[1] ? 4'b1100 : 4'b0011;
		end
		OP_LWL: begin
			mem_wrdata = reg2;
			unique case(mem_vaddr[1:0])
				2'd0: mem_sel = 4'b1000;
				2'd1: mem_sel = 4'b1100;
				2'd2: mem_sel = 4'b1110;
				2'd3: mem_sel = 4'b1111;
			endcase
		end
		OP_LWR: begin
			mem_wrdata = reg2;
			unique case(mem_vaddr[1:0])
				2'd0: mem_sel = 4'b1111;
				2'd1: mem_sel = 4'b0111;
				2'd2: mem_sel = 4'b0011;
				2'd3: mem_sel = 4'b0001;
			endcase
		end
		OP_SWL:
		begin
			mem_wrdata = reg2 >> ((3 - mem_vaddr[1:0]) * 8);
			unique case(mem_vaddr[1:0])
				2'd0: mem_sel = 4'b0001;
				2'd1: mem_sel = 4'b0011;
				2'd2: mem_sel = 4'b0111;
				2'd3: mem_sel = 4'b1111;
			endcase
		end
		OP_SWR:
		begin
			mem_wrdata = reg2 << (mem_vaddr[1:0] * 8);
			unique case(mem_vaddr[1:0])
				2'd0: mem_sel = 4'b1111;
				2'd1: mem_sel = 4'b1110;
				2'd2: mem_sel = 4'b1100;
				2'd3: mem_sel = 4'b1000;
			endcase
		end
	endcase
end

/* exception */
logic trap_valid, daddr_unaligned, invalid_instr;
always_comb begin
	unique case(data.decoded.op)
		OP_TEQ:  trap_valid = (reg1 == reg2);
		OP_TNE:  trap_valid = (reg1 != reg2);
		OP_TGE:  trap_valid = ~signed_lt;
		OP_TLT:  trap_valid = signed_lt;
		OP_TGEU: trap_valid = ~unsigned_lt;
		OP_TLTU: trap_valid = unsigned_lt;
		default: trap_valid = 1'b0;
	endcase
	unique case(op)
		OP_LW, OP_LL, OP_SW, OP_SC:
			daddr_unaligned = mem_addr[0] | mem_addr[1];
		OP_LH, OP_LHU, OP_SH:
			daddr_unaligned = mem_addr[0];
		default: daddr_unaligned = 1'b0;
	endcase
end

// ( miss | invalid, illegal | unaligned )
logic [1:0] ex_if;  // exception in IF
// ( trap, break, syscall, overflow, privilege )
logic [4:0] ex_ex;  // exception in EX
// ( miss | invalid, illegal | unaligned, readonly )
logic [2:0] ex_mm;  // exception in MEM

assign ex_if = {
	data.fetch.iaddr_ex.miss | data.fetch.iaddr_ex.invalid,
	data.fetch.iaddr_ex.illegal
};

assign ex_ex = {
	trap_valid,
	data.decoded.op == OP_BREAK,
	data.decoded.op == OP_SYSCALL,
	((op == OP_ADD) & ov_add) | ((op == OP_SUB) & ov_sub),
	data.decoded.is_priv
};

assign invalid_instr = (data.decoded.op == OP_INVALID);
assign ex_mm = {
	(mmu_result.miss | mmu_result.invalid) & result.memreq.read,
	(mmu_result.illegal | daddr_unaligned) & result.memreq.read,
	~mmu_result.dirty & result.memreq.write
};

always_comb begin
	ex = '0;
	ex.valid = (|ex_if) | invalid_instr | (|ex_ex) | (|ex_mm);
	if(|ex_if) begin
		ex.extra = data.fetch.vaddr;
		unique case(ex_if)
			2'b10: ex.exc_code = `EXCCODE_TLBL;
			2'b01: ex.exc_code = `EXCCODE_ADEL;
			default:;
		endcase
	end else if(invalid_instr) begin
		ex.exc_code = `EXCCODE_RI;
	end else if(|ex_ex) begin
		unique case(ex_ex)
			5'b10000: ex.exc_code = `EXCCODE_TR;
			5'b01000: ex.exc_code = `EXCCODE_BP;
			5'b00100: ex.exc_code = `EXCCODE_SYS;
			5'b00010: ex.exc_code = `EXCCODE_OV;
			5'b00001: ex.exc_code = `EXCCODE_CpU;
			default:;
		endcase
	end else if(|ex_mm) begin
		ex.extra = mem_vaddr;
		unique case(ex_mm)
			3'b100: ex.exc_code = `EXCCODE_TLBS;
			3'b010: ex.exc_code = `EXCCODE_ADES;
			3'b001: ex.exc_code = `EXCCODE_MOD;
			default:;
		endcase
	end
end

endmodule
