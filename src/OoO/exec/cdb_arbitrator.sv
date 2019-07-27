`include "cpu_defs.svh"

module cdb_arbitrator(
	input  uint32_t    [`ALU_RS_SIZE-1:0] alu_data,
	input  rob_index_t [`ALU_RS_SIZE-1:0] alu_data_reorder,
	input  logic       [`ALU_RS_SIZE-1:0] alu_data_ready,
	output logic       [`ALU_RS_SIZE-1:0] alu_data_ack,

	input  uint32_t          [`BRANCH_RS_SIZE-1:0] branch_data,
	input  branch_resolved_t [`BRANCH_RS_SIZE-1:0] branch_resolved,
	input  rob_index_t       [`BRANCH_RS_SIZE-1:0] branch_data_reorder,
	input  logic             [`BRANCH_RS_SIZE-1:0] branch_data_ready,
	output logic             [`BRANCH_RS_SIZE-1:0] branch_data_ack,

	output cdb_packet_t cdb
);

always_comb begin
	cdb = '0;
	alu_data_ack    = '0;
	branch_data_ack = '0;
	for(int i = 0; i < `ALU_RS_SIZE; ++i) begin
		cdb[i].valid    = alu_data_ready[i];
		cdb[i].reorder  = alu_data_reorder[i];
		cdb[i].value    = alu_data[i];
		alu_data_ack[i] = alu_data_ready[i];
	end

	for(int i = 0; i < `BRANCH_RS_SIZE; ++i) begin
		if(branch_data_ready[i]) begin
			branch_data_ack[i] = 1'b1;
			alu_data_ack[i]    = 1'b0;
			cdb[i].valid       = 1'b1;
			cdb[i].reorder     = branch_data_reorder[i];
			cdb[i].value       = branch_data[i];
			cdb[i].data.resolved_branch = branch_resolved[i];
		end
	end
end

endmodule
