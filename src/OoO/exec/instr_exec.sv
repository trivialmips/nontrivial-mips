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

	// branch
	input  logic             [1:0] branch_taken,
	output logic             [1:0] branch_ready,
	output rs_index_t        [1:0] branch_index,

	// CP0
	input  logic             cp0_taken,
	output cp0_req_t         cp0_req,
	output tlb_request_t     cp0_tlbreq,
	input  uint32_t          cp0_rdata,
	output reg_addr_t        cp0_raddr,
	output logic [2:0]       cp0_rsel,

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
exception_t [`ALU_RS_SIZE-1:0] alu_ex;

// branch information
uint32_t    [`BRANCH_RS_SIZE-1:0] branch_data;
logic       [`BRANCH_RS_SIZE-1:0] branch_data_ready;
logic       [`BRANCH_RS_SIZE-1:0] branch_data_ack;
rob_index_t [`BRANCH_RS_SIZE-1:0] branch_data_reorder;
branch_resolved_t [`BRANCH_RS_SIZE-1:0] branch_resolved;

// CP0 information
uint32_t    cp0_data;
logic       cp0_data_ready;
logic       cp0_data_ack;
rob_index_t cp0_data_reorder;
assign cp0_data = cp0_rdata;

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
	.ex           ( alu_ex           ),
	.cdb
);

branch_rs branch_rs_inst(
	.clk,
	.rst,
	.flush,
	.rs_taken ( branch_taken ),
	.rs_ready ( branch_ready ),
	.rs_index ( branch_index ),
	.rs_i     ( rs_ro        ),
	.data         ( branch_data         ),
	.data_ready   ( branch_data_ready   ),
	.data_reorder ( branch_data_reorder ),
	.data_ack     ( branch_data_ack     ),
	.resolved     ( branch_resolved     ),
	.cdb
);

cp0_rs cp0_rs_inst(
	.clk,
	.rst,
	.flush,
	.rs_taken     ( cp0_taken        ),
	.rs_i         ( rs_ro[0]         ),
	.data_ready   ( cp0_data_ready   ),
	.data_reorder ( cp0_data_reorder ),
	.data_ack     ( cp0_data_ack     ),
	.cp0_req,
	.cp0_tlbreq,
	.cp0_rdata,
	.cp0_raddr,
	.cp0_rsel,
	.cdb
);

// CDB arbitrator
cdb_arbitrator cdb_arbitrator_inst(
	.*
);

endmodule
