`include "cpu_defs.svh"

module instr_issue(
	// fetched instructions
	input  fetch_entry_t       [1:0] fetch_entry,
	output fetch_ack_t         fetch_ack,

	// ROB packet
	input  logic               rob_full,
	input  rob_index_t         [1:0] rob_reorder,
	output logic               rob_packet_valid,
	output rob_packet_t        rob_packet,

	// dispatcher
	input  logic               [1:0] alu_ready,
	input  rs_index_t          [1:0] alu_index,
	output logic               [1:0] alu_taken,

	input  logic               lsu_locked,
	input  logic               [1:0] lsu_ready,
	input  rs_index_t          [1:0] lsu_index,
	output logic               [1:0] lsu_taken,

	input  logic               [1:0] branch_ready,
	input  rs_index_t          [1:0] branch_index,
	output logic               [1:0] branch_taken,

	input  logic               mul_ready,
	output logic               [1:0] mul_taken,

	input  logic               cp0_ready,
	output logic               [1:0] cp0_taken,

	// reserve station
	output reserve_station_t   [1:0] rs_o,
	
	// registers
	output reg_addr_t          [3:0] reg_raddr,
	input  uint32_t            [3:0] reg_rdata,
	input  register_status_t   [3:0] reg_status,

	// register status
	output logic               [1:0] reg_status_we,
	output reg_addr_t          [1:0] reg_status_waddr,
	output register_status_t   [1:0] reg_status_wdata
);

logic [1:0] instr_valid;
decoded_instr_t [1:0] decoded;
reserve_station_t [1:0] rs;

logic stall;
assign stall = rob_full
	| decoded[0].is_controlflow & ~rs[1].busy & ~(fetch_entry[1].valid & rob_packet[1].ex.valid);

always_comb begin
	if(rob_packet[0].ex.valid) begin
		fetch_ack        = 1;
		rob_packet_valid = 1'b1;
	end else begin
		fetch_ack        = rs_o[0].busy + rs_o[1].busy;
		rob_packet_valid = rs_o[0].busy;
	end
end

assign instr_valid[0] = fetch_entry[0].valid
	&& ~(decoded[0].fu == FU_LOAD && lsu_locked);
assign instr_valid[1] = fetch_entry[1].valid
	&& rs[0].busy
	&& ~decoded[1].is_controlflow
	&& decoded[0].fu != FU_CP0 && decoded[1].fu != FU_CP0
	&& decoded[0].fu != FU_MUL && decoded[1].fu != FU_MUL
	&& ~(decoded[1].fu == FU_LOAD && lsu_locked)
	&& ~(decoded[0].fu == FU_STORE && decoded[1].fu == FU_STORE)
	&& ~(decoded[0].fu == FU_STORE && decoded[1].fu == FU_LOAD)
	|| rs[0].busy && decoded[0].is_controlflow && fetch_entry[1].valid;

// dispatch the first instruction
dispatcher dispatcher_instr_1(
	.stall,
	.delayslot       ( 1'b0                 ),
	.valid           ( instr_valid[0]       ),
	.fetch           ( fetch_entry[0]       ),
	.decoded         ( decoded[0]           ),
	.reorder         ( rob_reorder[0]       ),
	.reg_rdata       ( reg_rdata[1:0]       ),
	.reg_status      ( reg_status[1:0]      ),
	.alu_ready       ( alu_ready[0]         ),
	.alu_taken       ( alu_taken[0]         ),
	.alu_index       ( alu_index[0]         ),
	.lsu_ready       ( lsu_ready[0]         ),
	.lsu_taken       ( lsu_taken[0]         ),
	.lsu_index       ( lsu_index[0]         ),
	.branch_ready    ( branch_ready[0]      ),
	.branch_taken    ( branch_taken[0]      ),
	.branch_index    ( branch_index[0]      ),
	.cp0_ready       ( cp0_ready            ),
	.cp0_taken       ( cp0_taken[0]         ),
	.mul_ready       ( mul_ready            ),
	.mul_taken       ( mul_taken[0]         ),
	.rs              ( rs[0]                ),
	.rob             ( rob_packet[0]        )
);

// resolve data-related in a issue packet
logic alu_ready_2, lsu_ready_2;
rs_index_t alu_index_2, lsu_index_2;
rob_index_t rob_reorder_2;

assign alu_ready_2   = alu_ready[1] | (alu_ready[0] & ~alu_taken[0]);
assign alu_index_2   = alu_ready[1] ? alu_index[1] : alu_index[0];
assign lsu_ready_2   = lsu_ready[1] | (lsu_ready[0] & ~lsu_taken[0]);
assign lsu_index_2   = lsu_ready[1] ? lsu_index[1] : lsu_index[0];
assign rob_reorder_2 = rs[0].busy ? rob_reorder[1] : rob_reorder[0];

// dispatch the second instruction
dispatcher dispatcher_instr_2(
	.stall,
	.delayslot       ( decoded[0].is_controlflow ),
	.valid           ( instr_valid[1]       ),
	.fetch           ( fetch_entry[1]       ),
	.decoded         ( decoded[1]           ),
	.reorder         ( rob_reorder_2        ),
	.reg_rdata       ( reg_rdata[3:2]       ),
	.reg_status      ( reg_status[3:2]      ),
	.alu_ready       ( alu_ready_2          ),
	.alu_index       ( alu_index_2          ),
	.alu_taken       ( alu_taken[1]         ),
	.lsu_ready       ( lsu_ready_2          ),
	.lsu_index       ( lsu_index_2          ),
	.lsu_taken       ( lsu_taken[1]         ),
	.branch_ready    ( 1'b0                 ),
	.branch_taken    ( /* empty */          ),
	.branch_index    ( '0                   ),
	.cp0_ready       ( cp0_ready            ),
	.cp0_taken       ( cp0_taken[1]         ),
	.mul_ready       ( mul_ready            ),
	.mul_taken       ( mul_taken[1]         ),
	.rs              ( rs[1]                ),
	.rob             ( rob_packet[1]        )
);

assign branch_taken[1] = 1'b0;

always_comb begin
	rs_o = rs;
	if(decoded[0].rd != '0 && decoded[0].rd == decoded[1].rs1) begin
		rs_o[1].operand_ready[0] = 1'b0;
		rs_o[1].operand_addr[0]  = rs[0].reorder;
	end

	if(decoded[0].rd != '0 && decoded[0].rd == decoded[1].rs2) begin
		rs_o[1].operand_ready[1] = 1'b0;
		rs_o[1].operand_addr[1]  = rs[0].reorder;
	end
	rs_o[0].busy &= ~stall;
	rs_o[1].busy &= ~stall;
end

// generate decoders and read the register file
for(genvar i = 0; i < 2; ++i) begin: gen_decoder
	decoder decoder_inst(
		.instr         ( fetch_entry[i].instr ),
		.decoded_instr ( decoded[i]           )
	);

	assign reg_raddr[i * 2]     = decoded[i].rs1;
	assign reg_raddr[i * 2 + 1] = decoded[i].rs2;
end

// write register status
for(genvar i = 0; i < 2; ++i) begin: gen_write_reg_status
	assign reg_status_we[i]    = rs[i].busy & ~stall;
	assign reg_status_waddr[i] = decoded[i].rd;
	assign reg_status_wdata[i].busy    = 1'b1;
	assign reg_status_wdata[i].data    = '0;
	assign reg_status_wdata[i].reorder = rs[i].reorder;
	assign reg_status_wdata[i].data_valid = 1'b0;
end

endmodule
