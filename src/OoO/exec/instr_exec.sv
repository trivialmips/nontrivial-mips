`include "cpu_defs.svh"

module instr_exec(
	input  logic             clk,
	input  logic             rst,
	input  logic             flush,

	// ROB data
	output rob_index_t       [3:0] rob_raddr,
	input  logic             [3:0] rob_rdata_valid,
	input  uint32_t          [3:0] rob_rdata,

	// ALUs
	input  logic             [1:0] alu_taken,
	output logic             [1:0] alu_ready,
	output rs_index_t        [1:0] alu_index,

	// reserve station
	input  reserve_station_t [1:0] rs_i,

	// CDB
	output cdb_packet_t      cdb_o
);

cdb_packet_t cdb;
reserve_station_t [1:0] rs_ucdb, rs_ro;
assign cdb_o = cdb;

// ALU information
uint32_t    [`ALU_RS_SIZE-1:0] alu_data;
logic       [`ALU_RS_SIZE-1:0] alu_data_ready;
logic       [`ALU_RS_SIZE-1:0] alu_data_ack;
rob_index_t [`ALU_RS_SIZE-1:0] alu_data_reorder;

// read ROB
for(genvar i = 0; i < 2; ++i) begin: gen_read_rob
	assign rob_raddr[i * 2]     = rs_i[i].operand_addr[0];
	assign rob_raddr[i * 2 + 1] = rs_i[i].operand_addr[1];
end

always_comb begin
	rs_ucdb = rs_i;
	for(int i = 0; i < 2; ++i) begin
		for(int j = 0; j < 2; ++j) begin
			if(~rs_ucdb[i].operand_ready[j] & rob_rdata_valid[i * 2 + j]) begin
				rs_ucdb[i].operand[j]       = rob_rdata[i * 2 + j];
				rs_ucdb[i].operand_ready[j] = 1'b1;
			end
		end
	end
end

// read CDB
for(genvar i = 0; i < 2; ++i) begin: gen_rs_rcdb
	read_operands read_ops_inst(
		.cdb_packet ( cdb        ),
		.rs_i       ( rs_ucdb[i] ),
		.rs_o       ( rs_ro[i]   )
	);
end

alu_rs alu_rs_inst(
	.clk,
	.rst,
	.flush,
	.rs_taken ( alu_taken ),
	.rs_ready ( alu_ready ),
	.rs_index ( alu_index ),
	.rs_i     ( rs_ro     ),
	.data         ( alu_data         ),
	.data_ready   ( alu_data_ready   ),
	.data_reorder ( alu_data_reorder ),
	.data_ack     ( alu_data_ack     ),
	.cdb
);

// CDB arbitrator
cdb_arbitrator cdb_arbitrator_inst(
	.*
);

endmodule
