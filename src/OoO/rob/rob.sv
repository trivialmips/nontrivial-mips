`include "cpu_defs.svh"

module rob_channel(
	input  logic  clk,
	input  logic  rst,
	input  logic  flush,

	input  logic  push,
	input  logic  pop,

	input  rob_packet_t data_i,
	output rob_packet_t data_o,

	output logic  full,
	output logic  empty,

	input  cdb_packet_t cdb_packet
);

rob_packet_t packet;
assign data_o = packet;

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
		.data_i ( data_i.entry[i]  ),
		.data_o ( packet.entry[i]  ),
		.cdb_packet
	);
end

fifo_v3 #(
	.DATA_WIDTH(32),
	.DEPTH(`ROB_SIZE / 2)
) pc_fifo_inst (
	.clk_i      ( clk       ),
	.rst_i      ( rst       ),
	.flush_i    ( flush     ),
	.testmode_i ( 1'b0      ),
	.full_o     ( full      ),
	.empty_o    ( empty     ),
	.data_i     ( data_i.pc ),
	.push_i     ( push      ),
	.data_o     ( packet.pc ),
	.pop_i      ( pop       )
);


endmodule
