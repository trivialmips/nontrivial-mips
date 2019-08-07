`include "cpu_defs.svh"

module instr_exec (
	input  logic             delayslot,
	input  logic             llbit_value,
	input  uint64_t          multicyc_hilo,
	input  uint64_t          hilo_i,
	input  uint32_t          multicyc_reg,
	input  pipeline_decode_t data,
	output pipeline_exec_t   result,
	output branch_resolved_t resolved_branch,

	output reg_addr_t        reg_raddr,
	input  uint32_t          reg_rdata,
	input  pipeline_exec_t   [1:0][1:0] pipeline_dcache,
	input  pipeline_memwb_t  [1:0] pipeline_mem,
	input  pipeline_memwb_t  [1:0] pipeline_wb,

	input  logic        is_usermode,
	input  uint32_t     cp0_rdata,

	output virt_t       mmu_vaddr,
	input  mmu_result_t mmu_result
);

oper_t op;
exception_t ex;
uint32_t exec_ret, reg1, reg2, instr;
assign reg1 = data.reg1;
assign reg2 = data.reg2;
assign instr = data.fetch.instr;
assign op = data.decoded.op;

assign result.instr  = instr;
assign result.valid  = data.valid;
assign result.ex     = ex;
assign result.result = exec_ret;
assign result.pc     = data.fetch.vaddr;
assign result.eret   = (op == OP_ERET) & ~(|data.fetch.iaddr_ex);
assign result.delayed_reg[0] = reg1;
assign result.delayed_reg[1] = reg2;
assign result.branch_predict = data.fetch.branch_predict;
assign result.delayslot      = delayslot;
assign result.tlbreq.probe   = (op == OP_TLBP);
assign result.tlbreq.read    = (op == OP_TLBR);
assign result.tlbreq.tlbwr   = (op == OP_TLBWR);
assign result.tlbreq.tlbwi   = (op == OP_TLBWI);

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
generate if(`COMPILE_FULL) begin: generate_cloclz
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
end else begin: generate_disable_cloclz
	assign clo_cnt = '0;
	assign clz_cnt = '0;
end endgenerate

// conditional move
`ifdef COMPILE_FULL_M
always_comb begin
	result.decoded = data.decoded;
	if(op == OP_MOVZ && reg2 != '0
		|| op == OP_MOVN && reg2 == '0)
		result.decoded.rd = '0;
end
`else
assign result.decoded = data.decoded;
`endif

// setup hilo request
assign result.hiloreq.we    = (
	op == OP_MADD || op == OP_MADDU || op == OP_MSUB || op == OP_MSUBU
	|| op == OP_MULT || op == OP_MULTU || op == OP_DIV || op == OP_DIVU
	|| op == OP_MTHI || op == OP_MTLO);
assign result.hiloreq.wdata = multicyc_hilo;

// CP0 operation
assign result.cp0_req.we    = (op == OP_MTC0);
assign result.cp0_req.wdata = reg1;
assign result.cp0_req.waddr = instr[15:11];
assign result.cp0_req.wsel  = instr[2:0];

// setup execution result
always_comb begin
	exec_ret = '0;
	unique case(op)
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
		OP_MFHI: exec_ret = hilo_i[63:32];
		OP_MFLO: exec_ret = hilo_i[31:0];

		/* multi-cycle */
		OP_MUL: exec_ret = multicyc_reg;

		/* jump instructions */
		OP_JAL, OP_BLTZAL, OP_BGEZAL, OP_JALR:
			exec_ret = result.pc + 32'd8;

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

`ifdef COMPILE_FULL_M
		/* conditional store */
		OP_SC:   exec_ret = llbit_value;
`endif

		/* read coprocessers */
		OP_MFC0: exec_ret = cp0_rdata;
		default: exec_ret = '0;
	endcase
end

/* cache operation */
logic dcache_invalidate;
logic icache_invalidate;
always_comb begin
	dcache_invalidate = 1'b0;
	icache_invalidate = 1'b0;
`ifdef COMPILE_FULL_M
	if(op == OP_CACHE) begin
		case(instr[20:16])
			5'b00000, 5'b10000:
				icache_invalidate = 1'b1;
			5'b00001, 5'b10101:
				dcache_invalidate = 1'b1;
		endcase
	end
`endif
end

/* memory operation */
uint32_t extended_imm, mem_wrdata;
logic [3:0] mem_sel;
assign extended_imm = { {16{instr[15]}}, instr[15:0] };
assign mmu_vaddr = reg1 + extended_imm;

always_comb begin
	result.memreq.invalidate_icache = icache_invalidate;
	result.memreq.invalidate = dcache_invalidate;
	result.memreq.read       = data.decoded.is_load;
`ifdef COMPILE_FULL_M
	result.memreq.write      = data.decoded.is_store & (op != OP_CACHE)
							   & (llbit_value || (op != OP_SC));
`else
	result.memreq.write      = data.decoded.is_store;
`endif
	result.memreq.uncached   = mmu_result.uncached;
	result.memreq.vaddr      = mmu_vaddr;
	result.memreq.paddr      = mmu_result.phy_addr;
	result.memreq.wrdata     = mem_wrdata;
	result.memreq.byteenable = mem_sel;
`ifndef XILINX_SIMULATOR
	if(~mmu_vaddr == `SIMU_ONLY_ADDR)
		result.memreq = '0;
`endif
end

uint32_t sw_reg2;
assign reg_raddr = data.decoded.rs2;
always_comb begin
	sw_reg2 = reg_rdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_wb[j].rd == data.decoded.rs2)
			sw_reg2 = pipeline_wb[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_mem[j].rd == data.decoded.rs2)
			sw_reg2 = pipeline_mem[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_dcache[1][j].decoded.rd == data.decoded.rs2)
			sw_reg2 = pipeline_dcache[1][j].result;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_dcache[0][j].decoded.rd == data.decoded.rs2)
			sw_reg2 = pipeline_dcache[0][j].result;
	if(data.decoded.rs2 == '0)
		sw_reg2 = '0;
end

always_comb begin
	unique case(op)
		OP_LW, OP_LL, OP_SW, OP_SC: begin
			mem_wrdata = sw_reg2;
			mem_sel = 4'b1111;
		end
		OP_LB, OP_LBU, OP_SB: begin
			mem_wrdata = sw_reg2 << (mmu_vaddr[1:0] * 8);
			mem_sel = 4'b0001 << mmu_vaddr[1:0];
		end
		OP_LH, OP_LHU, OP_SH: begin
			mem_wrdata = mmu_vaddr[1] ? (sw_reg2 << 16) : sw_reg2;
			mem_sel = mmu_vaddr[1] ? 4'b1100 : 4'b0011;
		end
`ifdef COMPILE_FULL_M
		OP_LWL: begin
			mem_wrdata = sw_reg2;
			unique case(mmu_vaddr[1:0])
				2'd0: mem_sel = 4'b1000;
				2'd1: mem_sel = 4'b1100;
				2'd2: mem_sel = 4'b1110;
				2'd3: mem_sel = 4'b1111;
			endcase
		end
		OP_LWR: begin
			mem_wrdata = sw_reg2;
			unique case(mmu_vaddr[1:0])
				2'd0: mem_sel = 4'b1111;
				2'd1: mem_sel = 4'b0111;
				2'd2: mem_sel = 4'b0011;
				2'd3: mem_sel = 4'b0001;
			endcase
		end
		OP_SWL:
		begin
			mem_wrdata = sw_reg2 >> ((3 - mmu_vaddr[1:0]) * 8);
			unique case(mmu_vaddr[1:0])
				2'd0: mem_sel = 4'b0001;
				2'd1: mem_sel = 4'b0011;
				2'd2: mem_sel = 4'b0111;
				2'd3: mem_sel = 4'b1111;
			endcase
		end
		OP_SWR:
		begin
			mem_wrdata = sw_reg2 << (mmu_vaddr[1:0] * 8);
			unique case(mmu_vaddr[1:0])
				2'd0: mem_sel = 4'b1111;
				2'd1: mem_sel = 4'b1110;
				2'd2: mem_sel = 4'b1100;
				2'd3: mem_sel = 4'b1000;
			endcase
		end
`endif
		default: begin
			mem_sel    = '0;
			mem_wrdata = '0;
		end
	endcase
end

/* exception */
logic trap_valid, daddr_unaligned, invalid_instr;
always_comb begin
`ifdef COMPILE_FULL_M
	unique case(op)
		OP_TEQ:  trap_valid = (reg1 == reg2);
		OP_TNE:  trap_valid = (reg1 != reg2);
		OP_TGE:  trap_valid = ~signed_lt;
		OP_TLT:  trap_valid = signed_lt;
		OP_TGEU: trap_valid = ~unsigned_lt;
		OP_TLTU: trap_valid = unsigned_lt;
		default: trap_valid = 1'b0;
	endcase
`else
	trap_valid = '0;
`endif
	unique case(op)
		OP_LW, OP_LL, OP_SW, OP_SC:
			daddr_unaligned = mmu_vaddr[0] | mmu_vaddr[1];
		OP_LH, OP_LHU, OP_SH:
			daddr_unaligned = mmu_vaddr[0];
		default: daddr_unaligned = 1'b0;
	endcase
end


// ( illegal | unaligned, miss | invalid )
logic [1:0] ex_if;  // exception in IF
assign ex_if = {
	data.fetch.iaddr_ex.illegal | |data.fetch.vaddr[1:0],
	data.fetch.iaddr_ex.miss | data.fetch.iaddr_ex.invalid
};

// ( trap, break, syscall, overflow, privilege )
logic [4:0] ex_ex;  // exception in EX
assign ex_ex = {
	trap_valid,
	op == OP_BREAK,
	op == OP_SYSCALL,
	((op == OP_ADD) & ov_add) | ((op == OP_SUB) & ov_sub),
	data.decoded.is_priv & is_usermode
};

assign invalid_instr = (op == OP_INVALID);

logic mem_tlbex, mem_addrex;
`ifdef COMPILE_FULL_M
assign mem_tlbex  = (mmu_result.miss | mmu_result.invalid) & ~mem_addrex;
`else
assign mem_tlbex = 1'b0;
`endif
assign mem_addrex = mmu_result.illegal | daddr_unaligned;
// ( addrex_r, addrex_w, tlbex_r, tlbex_w, readonly )
logic [4:0] ex_mm;  // exception in MEM
assign ex_mm = {
	mem_addrex & result.memreq.read,
	mem_addrex & result.memreq.write,
	mem_tlbex & result.memreq.read,
	mem_tlbex & result.memreq.write,
	~mmu_result.dirty & result.memreq.write
};

always_comb begin
	ex = '0;
	ex.valid = ((|ex_if) | invalid_instr | (|ex_ex) | (|ex_mm)) & data.valid;
	ex.tlb_refill = mmu_result.miss & ~mem_addrex;
	if(|ex_if) begin
		ex.extra = data.fetch.vaddr;
		unique casez(ex_if)
			2'b1?: ex.exc_code = `EXCCODE_ADEL;
			2'b01: begin
				ex.tlb_refill = data.fetch.iaddr_ex.miss;
				ex.exc_code   = `EXCCODE_TLBL;
			end
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
		ex.extra = mmu_vaddr;
		unique casez(ex_mm)
			5'b1????: ex.exc_code = `EXCCODE_ADEL;
			5'b01???: ex.exc_code = `EXCCODE_ADES;
			5'b001??: begin
				ex.tlb_refill = mmu_result.miss;
				ex.exc_code   = `EXCCODE_TLBL;
			end
			5'b0001?: begin
				ex.tlb_refill = mmu_result.miss;
				ex.exc_code   = `EXCCODE_TLBS;
			end
			5'b00001: ex.exc_code = `EXCCODE_MOD;
			default:;
		endcase
	end
end

/* resolve branch */
branch_resolver branch_resolver_inst(
	.en   ( ~data.decoded.delayed_exec ),
	.reg1,
	.reg2,
	.data,
	.resolved_branch
);

endmodule
