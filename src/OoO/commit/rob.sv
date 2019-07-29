`include "cpu_defs.svh"

module rob(
	input  logic  clk,
	input  logic  rst,
	input  logic  flush,

	// ROB control
	input  logic  push,
	input  logic  pop,

	// ROB data
	input  rob_packet_t data_i,
	output rob_packet_t data_o,

	// ROB status
	output logic  full,
	output logic  empty,

	// allocated reorder
	output rob_index_t [1:0] reorder,

	// commit reorder
	output rob_index_t [1:0] reorder_commit,

	input  cdb_packet_t cdb
);

logic [1:0][$clog2(`ROB_SIZE / 2) - 1:0] rob_write_pointer, rob_read_pointer;
rob_packet_t packet;
logic [1:0] ch_full, ch_empty;

assign data_o = packet;
assign full   = ch_full[0];
assign empty  = ch_empty[0];

for(genvar i = 0; i < 2; ++i) begin : gen_rob_channel
	rob_channel #(
		.ID(i),
		.ID_WIDTH(1),
		.DEPTH(`ROB_SIZE / 2)
	) rob_channel_inst (
		.clk,
		.rst,
		.flush,
		.push,
		.pop,
		.data_i ( data_i[i]   ),
		.data_o ( packet[i]   ),
		.full   ( ch_full[i]  ),
		.empty  ( ch_empty[i] ),
		.write_pointer   ( rob_write_pointer[i]      ),
		.read_pointer    ( rob_read_pointer[i]       ),
		.cdb
	);

	assign reorder[i]        = { rob_write_pointer[i], i[0] };
	assign reorder_commit[i] = { rob_read_pointer[i], i[0]  };
end

endmodule
