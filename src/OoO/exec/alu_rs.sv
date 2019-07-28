`include "cpu_defs.svh"

module alu_rs(
	input  logic             clk,
	input  logic             rst,
	input  logic             flush,

	input  logic             [1:0] rs_taken,
	output logic             [1:0] rs_ready,
	output rs_index_t        [1:0] rs_index,
	input  reserve_station_t [1:0] rs_i,

	// result
	output exception_t [`ALU_RS_SIZE-1:0] ex,
	output uint32_t    [`ALU_RS_SIZE-1:0] data,
	output logic       [`ALU_RS_SIZE-1:0] data_ready,
	output rob_index_t [`ALU_RS_SIZE-1:0] data_reorder,
	input  logic       [`ALU_RS_SIZE-1:0] data_ack,

	// CDB
	input  cdb_packet_t      cdb
);

// *_q:  current status
// *_n:  next status
// *_ro: after reading operands
reserve_station_t [`ALU_RS_SIZE-1:0] rs_n, rs_ro, rs_q;
logic      [1:0] rs_ready_n, rs_ready_q;
rs_index_t [1:0] rs_index_n, rs_index_q;
assign rs_index = rs_index_q;
assign rs_ready = rs_ready_q;

for(genvar i = 0; i < `ALU_RS_SIZE; ++i) begin: gen_data_valid
	assign data_ready[i]   = rs_q[i].busy & &rs_q[i].operand_ready;
	assign data_reorder[i] = rs_q[i].reorder;
end

// allocate ready RS
always_comb begin
	rs_ready_n = '0;
	rs_index_n = '0;
	for(int i = 0; i < `ALU_RS_SIZE; ++i) begin
		if(~rs_n[i].busy) begin
			rs_ready_n[0] = 1'b1;
			rs_index_n[0] = i;
		end
	end

	for(int i = 0; i < `ALU_RS_SIZE; ++i) begin
		if(~rs_n[i].busy && rs_index_n[0] != i) begin
			rs_ready_n[1] = 1'b1;
			rs_index_n[1] = i;
		end
	end
end

// update RS
always_comb begin
	rs_n = rs_ro;

	// pop RS
	for(int i = 0; i < `ALU_RS_SIZE; ++i)
		if(data_ack[i]) rs_n[i] = '0;

	// push RS
	if(rs_taken[0]) rs_n[rs_i[0].index] = rs_i[0];
	if(rs_taken[1]) rs_n[rs_i[1].index] = rs_i[1];
end

// read operands
for(genvar i = 0; i < `ALU_RS_SIZE; ++i) begin: gen_rs
	read_operands read_ops_inst(
		.cdb_packet ( cdb      ),
		.rs_i       ( rs_q[i]  ),
		.rs_o       ( rs_ro[i] )
	);
end

// ALU
for(genvar i = 0; i < `ALU_RS_SIZE; ++i) begin: gen_alu
	alu alu_inst(
		.op     ( rs_q[i].decoded.op  ),
		.pc     ( rs_q[i].fetch.vaddr ),
		.instr  ( rs_q[i].instr       ),
		.reg1   ( rs_q[i].operand[0]  ),
		.reg2   ( rs_q[i].operand[1]  ),
		.result ( data[i]             ),
		.ex     ( ex[i]               )
	);
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		rs_q       <= '0;
		rs_ready_q <= 2'b11;
		rs_index_q[0] <= 0;
		rs_index_q[1] <= 1;
	end else begin
		rs_q       <= rs_n;
		rs_ready_q <= rs_ready_n;
		rs_index_q <= rs_index_n;
	end
end

endmodule
