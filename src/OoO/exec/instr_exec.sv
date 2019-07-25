`include "cpu_defs.svh"

module instr_exec(
	input  logic             clk,
	input  logic             rst,
	input  logic             flush,

	input  logic             [1:0] alu_taken,
	output logic             [1:0] alu_ready,
	output rs_index_t        [1:0] alu_index,

	// reserve station
	output reserve_station_t [1:0] rs_i,

	// CDB
	output cdb_packet_t      cdb_o
);

// CDB
cdb_packet_t cdb;

// ALU information
uint32_t  [`ALU_RS_SIZE-1:0] alu_data;
logic     [`ALU_RS_SIZE-1:0] alu_data_ready;
logic     [`ALU_FU_SIZE-1:0] alu_data_ack;

alu_rs alu_rs_inst(
	.clk,
	.rst,
	.flush,
	.rs_taken ( alu_taken ),
	.rs_ready ( alu_ready ),
	.rs_index ( alu_index ),
	.rs_i,
	.data       ( alu_data       ),
	.data_ready ( alu_data_ready ),
	.data_ack   ( alu_data_ack   ),
	.cdb
);


endmodule
