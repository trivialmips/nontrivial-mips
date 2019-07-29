`include "cpu_defs.svh"

module cdb_arbitrator(
	input  exception_t       [`ALU_RS_SIZE-1:0] alu_ex,
	input  uint32_t          [`ALU_RS_SIZE-1:0] alu_data,
	input  rob_index_t       [`ALU_RS_SIZE-1:0] alu_data_reorder,
	input  logic             [`ALU_RS_SIZE-1:0] alu_data_ready,
	output logic             [`ALU_RS_SIZE-1:0] alu_data_ack,

	input  uint32_t          [`BRANCH_RS_SIZE-1:0] branch_data,
	input  branch_resolved_t [`BRANCH_RS_SIZE-1:0] branch_resolved,
	input  rob_index_t       [`BRANCH_RS_SIZE-1:0] branch_data_reorder,
	input  logic             [`BRANCH_RS_SIZE-1:0] branch_data_ready,
	output logic             [`BRANCH_RS_SIZE-1:0] branch_data_ack,

	input  exception_t       [`LSU_RS_SIZE-1:0] lsu_ex,
	input  data_memreq_t     [`LSU_RS_SIZE-1:0] lsu_memreq,
	input  uint32_t          [`LSU_RS_SIZE-1:0] lsu_data,
	input  logic             [`LSU_RS_SIZE-1:0] lsu_data_ready,
	input  rob_index_t       [`LSU_RS_SIZE-1:0] lsu_data_reorder,
	output logic             [`LSU_RS_SIZE-1:0] lsu_data_ack,

	input  uint32_t          mul_data,
	input  logic             mul_data_ready,
	input  rob_index_t       mul_data_reorder,
	output logic             mul_data_ack,

	input  exception_t       cp0_ex,
	input  uint32_t          cp0_data,
	input  logic             cp0_data_ready,
	input  rob_index_t       cp0_data_reorder,
	output logic             cp0_data_ack,

	output cdb_packet_t cdb
);

localparam int CP0_CDB = `BRANCH_RS_SIZE + 0;
localparam int MUL_CDB = `BRANCH_RS_SIZE + 1;

always_comb begin
	cdb = '0;
	alu_data_ack    = '0;
	branch_data_ack = '0;
	cp0_data_ack    = '0;
	mul_data_ack    = '0;
	lsu_data_ack    = '0;
	for(int i = 0; i < `ALU_RS_SIZE; ++i) begin
		alu_data_ack[i] = alu_data_ready[i];

		cdb[i].ex       = alu_ex[i];
		cdb[i].valid    = alu_data_ready[i];
		cdb[i].reorder  = alu_data_reorder[i];
		cdb[i].value    = alu_data[i];
	end

	for(int i = 0; i < `BRANCH_RS_SIZE; ++i) begin
		if(branch_data_ready[i]) begin
			branch_data_ack[i] = 1'b1;
			alu_data_ack[i]    = 1'b0;

			cdb[i]             = '0;
			cdb[i].valid       = 1'b1;
			cdb[i].reorder     = branch_data_reorder[i];
			cdb[i].value       = branch_data[i];
			cdb[i].data.resolved_branch = branch_resolved[i];
		end
	end

	if(cp0_data_ready) begin
		cp0_data_ack          = 1'b1;
		alu_data_ack[CP0_CDB] = 1'b0;
		cdb[CP0_CDB]          = '0;
		cdb[CP0_CDB].ex       = cp0_ex;
		cdb[CP0_CDB].valid    = 1'b1;
		cdb[CP0_CDB].reorder  = cp0_data_reorder;
		cdb[CP0_CDB].value    = cp0_data;
	end

	if(mul_data_ready) begin
		mul_data_ack          = 1'b1;
		alu_data_ack[MUL_CDB] = 1'b0;
		cdb[MUL_CDB]          = '0;
		cdb[MUL_CDB].valid    = 1'b1;
		cdb[MUL_CDB].reorder  = mul_data_reorder;
		cdb[MUL_CDB].value    = mul_data;
	end

	for(int i = 0; i < `ALU_RS_SIZE; ++i) begin
		if(lsu_data_ready[i]) begin
			if(i < `ALU_RS_SIZE)    alu_data_ack[i] = 1'b0;
			if(i < `BRANCH_RS_SIZE) branch_data_ack[i] = 1'b0;
			if(i == CP0_CDB)        cp0_data_ack = 1'b0;
			if(i == MUL_CDB)        mul_data_ack = 1'b0;
			lsu_data_ack[i] = 1'b1;

			cdb[i]          = '0;
			cdb[i].ex       = lsu_ex[i];
			cdb[i].valid    = lsu_data_ready[i];
			cdb[i].reorder  = lsu_data_reorder[i];
			cdb[i].value    = lsu_data[i];
			cdb[i].data.memreq = lsu_memreq[i];
		end
	end
end

endmodule
