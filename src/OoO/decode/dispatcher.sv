`include "cpu_defs.svh"

module dispatcher(
	input  logic             stall,

	input  logic             delayslot,

	// instruction valid
	input  logic             valid,

	// fetch entry
	input  fetch_entry_t     fetch,

	// decoded instruction
	input  decoded_instr_t   decoded,

	// ROB reorder
	input  rob_index_t       reorder,

	// register status
	input  uint32_t          [1:0] reg_rdata,
	input  register_status_t [1:0] reg_status,

	// function unit status
	input  logic             alu_ready,
	input  rs_index_t        alu_index,
	output logic             alu_taken,

	input  logic             lsu_ready,
	input  rs_index_t        lsu_index,
	output logic             lsu_taken,

	input  logic             branch_ready,
	input  rs_index_t        branch_index,
	output logic             branch_taken,

	input  logic             mul_ready,
	output logic             mul_taken,

	input  logic             cp0_ready,
	output logic             cp0_taken,

	// reserve station
	output reserve_station_t rs,
	
	// ROB
	output rob_entry_t       rob
);

exception_t ex;
uint32_t imm;
assign imm = { {16{fetch.instr[15] & decoded.imm_signed}}, fetch.instr[15:0] };
assign rs.reorder = reorder;

always_comb begin
	for(int i = 0; i < 2; ++i) begin
		rs.operand[i]       = reg_status[i].busy ? reg_status[i].data : reg_rdata[i];
		rs.operand_ready[i] = ~reg_status[i].busy | reg_status[i].data_valid;
		rs.operand_addr[i]  = reg_status[i].reorder;
	end

	if(decoded.use_imm) begin
		rs.operand[1]       = imm;
		rs.operand_ready[1] = 1'b1;
	end
end

always_comb begin
	rs.busy    = 1'b0;
	rs.decoded = decoded;
	rs.fetch   = fetch;
	rs.instr   = fetch.instr;
	rs.index   = '0;
	alu_taken    = 1'b0;
	branch_taken = 1'b0;
	cp0_taken    = 1'b0;
	lsu_taken    = 1'b0;
	mul_taken    = 1'b0;
	if(~ex.valid) begin
		unique case(decoded.fu)
			FU_ALU: begin
				alu_taken = alu_ready & valid & ~stall;
				rs.busy   = alu_ready & valid;
				rs.index  = alu_index;
			end
			FU_BRANCH: begin
				branch_taken = branch_ready & valid & ~stall;
				rs.busy      = branch_ready & valid;
				rs.index     = branch_index;
			end
			FU_LOAD, FU_STORE: begin
				lsu_taken = lsu_ready & valid & ~stall;
				rs.busy   = lsu_ready & valid;
				rs.index  = lsu_index;
			end
			FU_MUL: begin
				mul_taken    = mul_ready & valid & ~stall;
				rs.busy      = mul_ready & valid;
				rs.index     = '0;
			end
			FU_CP0: begin
				cp0_taken    = cp0_ready & valid & ~stall;
				rs.busy      = cp0_ready & valid;
				rs.index     = '0;
			end
			default:;
		endcase
	end
end

// ( illegal | unaligned, miss | invalid )
logic [1:0] ex_if;  // exception in IF
assign ex_if = {
	fetch.iaddr_ex.illegal | |fetch.vaddr[1:0],
	fetch.iaddr_ex.miss | fetch.iaddr_ex.invalid
};

logic invalid_instr;
assign invalid_instr = (decoded.op == OP_INVALID);

always_comb begin
	ex = '0;
	ex.valid = ((|ex_if) | invalid_instr) & valid;
	if(|ex_if) begin
		ex.extra = fetch.vaddr;
		unique casez(ex_if)
			2'b1?: ex.exc_code = `EXCCODE_ADEL;
			2'b01: ex.exc_code = `EXCCODE_TLBL;
			default:;
		endcase
	end else if(invalid_instr) begin
		ex.exc_code = `EXCCODE_RI;
	end
end

always_comb begin
	rob           = '0;
	rob.delayslot = delayslot;
	rob.valid     = rs.busy | ex.valid;
	rob.busy      = rs.busy;
	rob.pc        = fetch.vaddr;
	rob.dest      = decoded.rd;
	rob.fu        = decoded.fu;
	rob.ex        = ex;
end

endmodule
