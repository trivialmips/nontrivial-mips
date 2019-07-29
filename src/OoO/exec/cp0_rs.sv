`include "cpu_defs.svh"

module cp0_rs(
	input  logic             clk,
	input  logic             rst,
	input  logic             flush,

	input  logic             [1:0] rs_taken,
	input  reserve_station_t [1:0] rs_i,

	// result
	output logic             data_ready,
	output rob_index_t       data_reorder,
	input  logic             data_ack,

	output cp0_req_t         cp0_req,
	output tlb_request_t     cp0_tlbreq,

	input  uint32_t          cp0_rdata,
	output reg_addr_t        cp0_raddr,
	output logic [2:0]       cp0_rsel,
	output exception_t       cp0_ex,

	// CDB
	input  cdb_packet_t      cdb
);

// *_q:  current status
// *_n:  next status
// *_ro: after reading operands
reserve_station_t rs_n, rs_ro, rs_q;
assign data_ready    = rs_q.busy & &rs_q.operand_ready;
assign data_reorder  = rs_q.reorder;
assign cp0_raddr     = rs_q.fetch.instr[15:11];
assign cp0_rsel      = rs_q.fetch.instr[2:0];

assign cp0_req.we    = data_ack & (rs_q.decoded.op == OP_MTC0);
assign cp0_req.wdata = rs_q.operand[0];
assign cp0_req.waddr = rs_q.fetch.instr[15:11];
assign cp0_req.wsel  = rs_q.fetch.instr[2:0];
// TODO: TLB
assign cp0_tlbreq    = '0;

always_comb begin
	cp0_ex = '0;
	if(rs_q.decoded.op == OP_ERET) begin
		cp0_ex.valid = 1'b1;
		cp0_ex.eret  = 1'b1;
	end
end

uint32_t cp0_wmask;
cp0_write_mask cp0_write_mask_inst(
	.rst,
	.sel  ( cp0_rsel  ),
	.addr ( cp0_raddr ),
	.mask ( cp0_wmask )
);

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

always_ff @(posedge clk) begin
	if(rst || flush) begin
		rs_q <= '0;
	end else begin
		rs_q <= rs_n;
	end
end

endmodule
