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

assign rs.reorder = reorder;

for(genvar i = 0; i < 2; ++i) begin: gen_register_dispatcher
	assign rs.operand[i]       = reg_rdata[i];
	assign rs.operand_ready{i] = ~reg_status[i].busy;
	assign rs.operand_addr{i]  = reg_status[i].reorder;
end

always_comb begin
	rs.busy    = 1'b0;
	rs.decoded = decoded;
	rs.instr   = fetch.instr;
	rs.index   = '0;
	alu_taken  = 1'b0;
	unique case(decoded.fu)
		FU_ALU: begin
			alu_taken = alu_ready;
			rs.busy   = alu_ready;
			rs.index  = alu_index;
		end
		default: begin
			// we put invalid instructions to ALU
			alu_taken = alu_ready;
			rs.busy   = alu_ready;
			rs.index  = alu_index;
		end
	endcase

	if(~valid) rs.busy = 1'b0;
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
