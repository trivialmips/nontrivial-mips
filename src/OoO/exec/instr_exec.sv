`include "cpu_defs.svh"

module instr_exec(
	input  logic             clk,
	input  logic             rst,

	input  logic             [1:0] alu_taken,
	output logic             [1:0] alu_ready,
	output rs_index_t        [1:0] alu_index,

	// reserve station
	output reserve_station_t [1:0] rs_i,

	// CDB
	input  cdb_packet_t      cdb_i
);

endmodule
