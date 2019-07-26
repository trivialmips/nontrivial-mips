`include "cpu_defs.svh"

module dispatcher(
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

	// reserve station
	output reserve_station_t rs,
	
	// ROB
	output rob_entry_t       rob
);

uint32_t imm;
assign imm = { {16{fetch.instr[15] & decoded.imm_signed}}, fetch.instr[15:0] };
assign rs.reorder = reorder;

always_comb begin
	for(int i = 0; i < 2; ++i) begin
		rs.operand[i]       = reg_rdata[i];
		rs.operand_ready[i] = ~reg_status[i].busy;
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
	alu_taken  = 1'b0;
	unique case(decoded.fu)
		FU_ALU: begin
			alu_taken = alu_ready & valid;
			rs.busy   = alu_ready & valid;
			rs.index  = alu_index;
		end
		default:;
	endcase
end

always_comb begin
	rob       = '0;
	rob.valid = rs.busy;
	rob.busy  = rs.busy;
	rob.pc    = fetch.vaddr;
	rob.dest  = decoded.rd;
	rob.fu    = decoded.fu;
end

endmodule
