`include "cpu_defs.svh"

module instr_issue(
	// fetched instructions
	input  fetch_entry_t [1:0] fetch_entry,
	output fetch_ack_t         fetch_ack,

	// ROB packet
	input  logic               rob_full,
	input  rob_index_t [1:0]   rob_reorder,
	output logic               rob_packet_valid,
	output rob_packet_t        rob_packet,

	// dispatcher
	input  logic [1:0]         alu_ready,
	output logic [1:0]         alu_taken,

	// reserve station
	output reserve_station_t   [1:0] rs,
	
	// registers
	output reg_addr_t          [3:0] reg_raddr,
	input  uint32_t            [3:0] reg_rdata,
	input  register_status_t   [3:0] reg_status
);

// decoded instructions
decoded_instr_t decoded[1:0];

// instruction valid
logic [1:0] instr_valid;

always_comb begin
	instr_valid[0] = fetch_entry[0].valid;
	instr_valid[1] = fetch_entry[1].valid & rs[0].busy;

	if(rob_full) instr_valid = '0;
end

// fetch ack
assign fetch_ack        = rs[0].busy + rs[1].busy;
assign rob_packet_valid = rs[0].busy;

// dispatch the first instruction
dispatcher dispatcher_instr_1(
	.valid       ( instr_valid[0]  ),
	.fetch       ( fetch_entry[0]  ),
	.decoded     ( decoded[0]      ),
	.reorder     ( rob_reorder[0]  ),
	.reg_rdata   ( reg_rdata[1:0]  ),
	.reg_status  ( reg_status[1:0] ),
	.alu_ready   ( alu_ready[0]    ),
	.alu_taken   ( alu_taken[0]    ),
	.rs          ( rs[0]           ),
	.rob         ( rob_packet[0]   )
);

// resolve data-related in a issue packet
register_status_t [1:0] reg_status_2;
always_comb begin
	reg_status_2 = reg_status[3:2];
	if(decoded[0].rd != '0 && decoded[0].rd == decoded[1].rs1) begin
		reg_status_2[0].busy    = 1'b1;
		reg_status_2[0].reorder = rs[0].reorder;
	end

	if(decoded[0].rd != '0 && decoded[0].rd == decoded[1].rs2) begin
		reg_status_2[1].busy    = 1'b1;
		reg_status_2[1].reorder = rs[0].reorder;
	end
end

// dispatch the second instruction
dispatcher dispatcher_instr_2(
	.valid       ( instr_valid[1]  ),
	.fetch       ( fetch_entry[1]  ),
	.decoded     ( decoded[1]      ),
	.reorder     ( rob_reorder[1]  ),
	.reg_rdata   ( reg_rdata[3:2]  ),
	.reg_status  ( reg_status_2    ),
	.alu_ready   ( alu_ready[1] | (alu_ready[0] & ~alu_taken[0]) ),
	.alu_taken   ( alu_taken[1]    ),
	.rs          ( rs[1]           ),
	.rob         ( rob_packet[1]   )
);

// generate decoders and read the register file
for(genvar i = 0; i < 2; ++i) begin: gen_decoder
	decoder decoder_inst(
		.instr         ( fetch_entry[i].instr ),
		.decoded_instr ( decoded[i]           )
	);

	assign reg_raddr[i * 2]     = decoded[i].rs1;
	assign reg_raddr[i * 2 + 1] = decoded[i].rs2;
end

endmodule
