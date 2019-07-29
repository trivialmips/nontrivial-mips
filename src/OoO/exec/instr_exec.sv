`include "cpu_defs.svh"

module instr_exec(
	input  logic             clk,
	input  logic             rst,
	input  logic             flush,

	// ALUs
	input  logic             [1:0] alu_taken,
	output logic             [1:0] alu_ready,
	output rs_index_t        [1:0] alu_index,

	// LSUs
	input  logic             [1:0] lsu_taken,
	output logic             [1:0] lsu_ready,
	output rs_index_t        [1:0] lsu_index,

	// branch
	input  logic             [1:0] branch_taken,
	output logic             [1:0] branch_ready,
	output rs_index_t        [1:0] branch_index,

	// multiplier
	input  logic             [1:0] mul_taken,
	output logic             mul_valid,
	output uint64_t          hilo_result,
	input  uint64_t          hilo_data,

	// CP0
	input  logic             [1:0] cp0_taken,
	output cp0_req_t         cp0_req,
	output tlb_request_t     cp0_tlbreq,
	input  uint32_t          cp0_rdata,
	output reg_addr_t        cp0_raddr,
	output logic [2:0]       cp0_rsel,

	// LSU store
	input  data_memreq_t     lsu_store_memreq,
	input  logic             lsu_store_push,
	output logic             lsu_store_full,
	output logic             lsu_store_empty,

	// reserve station
	input  reserve_station_t [1:0] rs_i,

	// MMU
	input  mmu_result_t      mmu_result,
	output virt_t            mmu_vaddr,

	// ROB
	input  rob_packet_t      rob_packet,
	input  rob_index_t       [1:0] rob_reorder,

	// DBus
	cpu_dbus_if.master       dbus,
	cpu_dbus_if.master       dbus_uncached,

	// CDB
	output cdb_packet_t      cdb_o
);

cdb_packet_t cdb;
reserve_station_t [1:0] rs_ro;
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

// LSU information
uint32_t      [`LSU_RS_SIZE-1:0] lsu_data;
logic         [`LSU_RS_SIZE-1:0] lsu_data_ready;
logic         [`LSU_RS_SIZE-1:0] lsu_data_ack;
rob_index_t   [`LSU_RS_SIZE-1:0] lsu_data_reorder;
data_memreq_t [`LSU_RS_SIZE-1:0] lsu_memreq;
exception_t   [`LSU_RS_SIZE-1:0] lsu_ex;

// multiplier information
uint32_t    mul_data;
logic       mul_data_ready;
logic       mul_data_ack;
rob_index_t mul_data_reorder;

// CP0 information
uint32_t    cp0_data;
logic       cp0_data_ready;
logic       cp0_data_ack;
rob_index_t cp0_data_reorder;
exception_t cp0_ex;
assign cp0_data = cp0_rdata;

// read CDB
for(genvar i = 0; i < 2; ++i) begin: gen_rs_rcdb
	read_operands read_ops_inst(
		.cdb_packet ( cdb      ),
		.rs_i       ( rs_i[i]  ),
		.rs_o       ( rs_ro[i] )
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

lsu_rs lsu_rs_inst(
	.clk,
	.rst,
	.flush,
	.rs_taken ( lsu_taken ),
	.rs_ready ( lsu_ready ),
	.rs_index ( lsu_index ),
	.rs_i     ( rs_ro     ),
	.ex           ( lsu_ex           ),
	.memreq       ( lsu_memreq       ),
	.data         ( lsu_data         ),
	.data_ready   ( lsu_data_ready   ),
	.data_reorder ( lsu_data_reorder ),
	.data_ack     ( lsu_data_ack     ),
	.store_push   ( lsu_store_push   ),
	.store_memreq ( lsu_store_memreq ),
	.store_full   ( lsu_store_full   ),
	.store_empty  ( lsu_store_empty  ),
	.mmu_vaddr,
	.mmu_result,
	.rob_packet,
	.rob_reorder,
	.dbus,
	.dbus_uncached,
	.cdb
);

mul_rs mul_rs_inst(
	.clk,
	.rst,
	.flush,
	.rs_taken     ( mul_taken        ),
	.rs_i         ( rs_ro            ),
	.result       ( mul_data         ),
	.data_ready   ( mul_data_ready   ),
	.data_reorder ( mul_data_reorder ),
	.data_ack     ( mul_data_ack     ),
	.hilo_valid   ( mul_valid        ),
	.hilo_result,
	.hilo_data,
	.cdb
);

cp0_rs cp0_rs_inst(
	.clk,
	.rst,
	.flush,
	.rs_taken     ( cp0_taken        ),
	.rs_i         ( rs_ro            ),
	.data_ready   ( cp0_data_ready   ),
	.data_reorder ( cp0_data_reorder ),
	.data_ack     ( cp0_data_ack     ),
	.cp0_ex,
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
