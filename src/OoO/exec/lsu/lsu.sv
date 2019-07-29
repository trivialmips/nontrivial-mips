`include "cpu_defs.svh"

module lsu(
	input  logic             clk,
	input  logic             rst,
	input  logic             flush,

	// reserve statsion
	input  reserve_station_t rs,
	output logic             fu_busy,

	// dbus request
	output data_memreq_t     dbus_req,
	input  data_memres_t     dbus_res,
	output logic             dbus_request,
	input  logic             dbus_ready,

	// MMU request
	output virt_t            mmu_vaddr,
	output logic             mmu_request,
	input  mmu_result_t      mmu_result,
	input  logic             mmu_ready,

	// result
	output exception_t       ex,
	output data_memreq_t     req,
	output uint32_t          data,
	output logic             data_ready
);

enum logic [2:0] {
	IDLE,
	WAIT_MMU,
	WAIT_OP,
	WAIT_DBUS,
	WAIT_DATA,
	WRITE,
	EXCEPTION
} state, state_d;

// MMU request
uint32_t extended_imm;
assign extended_imm = { {16{rs.fetch.instr[15]}}, rs.fetch.instr[15:0] };
assign mmu_vaddr    = rs.operand[0] + extended_imm;
assign mmu_request  = (state == WAIT_MMU);

// memory request
uint32_t mem_wrdata;
logic [3:0] mem_sel;
data_memreq_t memreq, pipe_memreq;

assign req             = pipe_memreq;
assign dbus_request    = (state == WAIT_DBUS);
assign dbus_req.read       = pipe_memreq.read;
assign dbus_req.write      = 1'b0;
assign dbus_req.uncached   = pipe_memreq.uncached;
assign dbus_req.wrdata     = '0;
assign dbus_req.paddr      = pipe_memreq.paddr;
assign dbus_req.byteenable = pipe_memreq.byteenable;
assign dbus_req.invalidate = 1'b0;
assign dbus_req.invalidate_icache = 1'b0;

always_comb begin
	memreq.invalidate_icache = '0;
	memreq.invalidate = '0;
	memreq.read       = rs.decoded.fu == FU_LOAD;
	memreq.write      = rs.decoded.fu == FU_STORE;
	memreq.uncached   = mmu_result.uncached;
	memreq.vaddr      = mmu_vaddr;
	memreq.paddr      = mmu_result.phy_addr;
	memreq.wrdata     = mem_wrdata;
	memreq.byteenable = mem_sel;
`ifndef XILINX_SIMULATOR
	if(~mmu_vaddr == `SIMU_ONLY_ADDR)
		memreq = '0;
`endif
end

always_comb begin
	unique case(rs.decoded.op)
		OP_LW, OP_LL, OP_SW, OP_SC: begin
			mem_wrdata = rs.operand[1];
			mem_sel = 4'b1111;
		end
		OP_LB, OP_LBU, OP_SB: begin
			mem_wrdata = rs.operand[1] << (mmu_vaddr[1:0] * 8);
			mem_sel = 4'b0001 << mmu_vaddr[1:0];
		end
		OP_LH, OP_LHU, OP_SH: begin
			mem_wrdata = mmu_vaddr[1] ? (rs.operand[1] << 16) : rs.operand[1];
			mem_sel = mmu_vaddr[1] ? 4'b1100 : 4'b0011;
		end
		OP_LWL: begin
			mem_wrdata = rs.operand[1];
			unique case(mmu_vaddr[1:0])
				2'd0: mem_sel = 4'b1000;
				2'd1: mem_sel = 4'b1100;
				2'd2: mem_sel = 4'b1110;
				2'd3: mem_sel = 4'b1111;
			endcase
		end
		OP_LWR: begin
			mem_wrdata = rs.operand[1];
			unique case(mmu_vaddr[1:0])
				2'd0: mem_sel = 4'b1111;
				2'd1: mem_sel = 4'b0111;
				2'd2: mem_sel = 4'b0011;
				2'd3: mem_sel = 4'b0001;
			endcase
		end
		OP_SWL:
		begin
			mem_wrdata = rs.operand[1] >> ((3 - mmu_vaddr[1:0]) * 8);
			unique case(mmu_vaddr[1:0])
				2'd0: mem_sel = 4'b0001;
				2'd1: mem_sel = 4'b0011;
				2'd2: mem_sel = 4'b0111;
				2'd3: mem_sel = 4'b1111;
			endcase
		end
		OP_SWR:
		begin
			mem_wrdata = rs.operand[1] << (mmu_vaddr[1:0] * 8);
			unique case(mmu_vaddr[1:0])
				2'd0: mem_sel = 4'b1111;
				2'd1: mem_sel = 4'b1110;
				2'd2: mem_sel = 4'b1100;
				2'd3: mem_sel = 4'b1000;
			endcase
		end
		default: begin
			mem_sel    = '0;
			mem_wrdata = '0;
		end
	endcase
end

// exception
logic daddr_unaligned;
always_comb begin
	unique case(rs.decoded.op)
		OP_LW, OP_LL, OP_SW, OP_SC:
			daddr_unaligned = mmu_vaddr[0] | mmu_vaddr[1];
		OP_LH, OP_LHU, OP_SH:
			daddr_unaligned = mmu_vaddr[0];
		default: daddr_unaligned = 1'b0;
	endcase
end

logic mem_tlbex, mem_addrex;
assign mem_tlbex  = (mmu_result.miss | mmu_result.invalid) & ~mem_addrex;
assign mem_addrex = mmu_result.illegal | daddr_unaligned;
// ( addrex_r, addrex_w, tlbex_r, tlbex_w, readonly )
logic [4:0] ex_mm, pipe_ex_mm;
assign ex_mm = {
	mem_addrex & memreq.read,
	mem_addrex & memreq.write,
	mem_tlbex  & memreq.read,
	mem_tlbex  & memreq.write,
	~mmu_result.dirty & memreq.write
};

always_comb begin
	ex = '0;
	ex.valid = |pipe_ex_mm;
	ex.extra = pipe_memreq.vaddr;
	unique casez(pipe_ex_mm)
		5'b1????: ex.exc_code = `EXCCODE_ADEL;
		5'b01???: ex.exc_code = `EXCCODE_ADES;
		5'b001??: ex.exc_code = `EXCCODE_TLBL;
		5'b0001?: ex.exc_code = `EXCCODE_TLBS;
		5'b00001: ex.exc_code = `EXCCODE_MOD;
		default:;
	endcase
end

// data
uint32_t data_rd;
assign data_ready = rs.busy & (state_d == IDLE);
assign fu_busy    = (state_d != IDLE);
assign data_rd    = dbus_res.rddata;

logic [1:0] addr_offset;
uint32_t aligned_data_rd, unaligned_data_rd, ext_sel;
uint32_t signed_ext_byte, signed_ext_half_word;
uint32_t zero_ext_byte, zero_ext_half_word;
uint32_t unaligned_word;
assign aligned_data_rd = data_rd >> (addr_offset * 8);
assign ext_sel = {
	{8{pipe_memreq.byteenable[3]}},
	{8{pipe_memreq.byteenable[2]}},
	{8{pipe_memreq.byteenable[1]}},
	{8{pipe_memreq.byteenable[0]}}
};
assign addr_offset          = pipe_memreq.paddr[1:0];
assign signed_ext_byte      = { {24{aligned_data_rd[7]}}, aligned_data_rd[7:0] };
assign signed_ext_half_word = { {16{aligned_data_rd[15]}}, aligned_data_rd[15:0] };
assign zero_ext_byte      = { 24'b0, aligned_data_rd[7:0] };
assign zero_ext_half_word = { 16'b0, aligned_data_rd[15:0] };
// for LWL/LWR, memreq.wdata = reg2
assign unaligned_word = (pipe_memreq.wrdata & ~ext_sel) | (unaligned_data_rd & ext_sel);
always_comb
begin
	if(rs.decoded.op == OP_LWL) begin
		unaligned_data_rd = data_rd << ((3 - addr_offset) * 8);
	end else begin
		unaligned_data_rd = data_rd >> (addr_offset * 8);
	end
end

always_comb begin
	data = '0;
	unique case(rs.decoded.op)
		OP_LB:  data = signed_ext_byte;
		OP_LH:  data = signed_ext_half_word;
		OP_LBU: data = zero_ext_byte;
		OP_LHU: data = zero_ext_half_word;
		OP_LWL, OP_LWR: data = unaligned_word;
		default: data = aligned_data_rd;
	endcase
end

// dbus counter
logic [`DCACHE_PIPE_DEPTH-2:0] counter_n, counter_q;
always_comb begin
	counter_n = counter_q;

	if(~dbus_res.stall) counter_n >>= 1;

	if(state == WAIT_DBUS) begin
		counter_n = '0;
		counter_n[`DCACHE_PIPE_DEPTH-2] = 1'b1;
	end
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		counter_q <= '0;
		state     <= IDLE;
	end else begin
		counter_q <= counter_n;
		state     <= state_d;
	end
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		pipe_ex_mm  <= '0;
		pipe_memreq <= '0;
	end else if(mmu_ready) begin
		pipe_ex_mm  <= ex_mm;
		pipe_memreq <= memreq;
	end
end

always_comb begin
	state_d = state;
	case(state)
		IDLE, WAIT_OP: if(rs.busy)
			state_d = (&rs.operand_ready) ? WAIT_MMU : WAIT_OP;
		WAIT_MMU: if(mmu_ready) begin
			if(|pipe_ex_mm)
				state_d = EXCEPTION;
			else state_d = rs.decoded.fu == FU_LOAD ? WAIT_DBUS : WRITE;
		end
		WAIT_DBUS: if(dbus_ready)
			state_d = WAIT_DATA;
		WAIT_DATA: if(counter_q[0] && ~dbus_res.stall)
			state_d = IDLE;
		EXCEPTION, WRITE:
			state_d = IDLE;
	endcase
end


endmodule
