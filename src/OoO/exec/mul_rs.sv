`include "cpu_defs.svh"

module mul_rs(
	input  logic             clk,
	input  logic             rst,
	input  logic             flush,

	input  logic             [1:0] rs_taken,
	input  reserve_station_t [1:0] rs_i,

	// result
	output uint32_t          result,
	output logic             data_ready,
	output rob_index_t       data_reorder,
	input  logic             data_ack,

	// HILO result
	output logic             hilo_valid,
	output uint64_t          hilo_result,
	input  uint64_t          hilo_data,

	// CDB
	input  cdb_packet_t      cdb
);

// *_q:  current status
// *_n:  next status
// *_ro: after reading operands
reserve_station_t rs_n, rs_ro, rs_q;
uint32_t mult_word;
logic multiplier_busy;

assign data_reorder  = rs_q.reorder;
assign data_ready    = ~multiplier_busy & &rs_q.operand_ready & rs_q.busy;
assign hilo_valid    = data_ack
	&& rs_q.decoded.op != OP_MFHI 
	&& rs_q.decoded.op != OP_MFLO
	&& rs_q.decoded.op != OP_MUL;

// update RS
always_comb begin
	rs_n = rs_ro;
	if(data_ack) rs_n = '0;
	if(rs_taken[0]) rs_n = rs_i[0];
	if(rs_taken[1]) rs_n = rs_i[1];
end

// read operands
read_operands read_ops_inst(
	.cdb_packet ( cdb   ),
	.rs_i       ( rs_q  ),
	.rs_o       ( rs_ro )
);

uint64_t multicyc_ret;
multiplier multiplier_inst(
	.clk,
	.rst,
	.flush ( flush | ~&rs_q.operand_ready ),
	.op    ( rs_q.decoded.op ),
	.reg1  ( rs_q.operand[0] ),
	.reg2  ( rs_q.operand[1] ),
	.hilo  ( hilo_data       ),
	.ret   ( multicyc_ret    ),
	.mult_word,
	.is_busy ( multiplier_busy )
);

always_comb begin
	unique case(rs_q.decoded.op)
		OP_MTHI: hilo_result = { rs_q.operand[0], hilo_data[31:0]  };
		OP_MTLO: hilo_result = { hilo_data[63:32], rs_q.operand[0] };
		default: hilo_result = multicyc_ret;
	endcase
end

always_comb begin
	unique case(rs_q.decoded.op)
		OP_MFHI: result = hilo_data[63:32];
		OP_MFLO: result = hilo_data[31:0];
		default: result = mult_word;
	endcase
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		rs_q <= '0;
	end else begin
		rs_q <= rs_n;
	end
end

endmodule
