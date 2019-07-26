`include "cpu_defs.svh"

module rob(
	input  logic  clk,
	input  logic  rst,
	input  logic  flush,

	input  logic  push,
	input  logic  pop,

	input  rob_packet_t data_i,
	output rob_packet_t data_o,

	output logic  full,
	output logic  empty,

	output rob_index_t [1:0] reorder,

	input  rob_index_t [3:0] rob_raddr,
	output logic       [3:0] rob_rdata_valid,
	output uint32_t    [3:0] rob_rdata,

	input  cdb_packet_t cdb
);

logic [$clog2(`ROB_SIZE / 2) - 1:0] rob_write_pointer;
rob_packet_t packet;
assign data_o = packet;

logic    [1:0][3:0] rob_channel_data_valid,
uint32_t [1:0][3:0] rob_channel_data,

for(genvar i = 0; i < 4; ++i) begin: gen_rob_read
	assign rob_rdata[i]       = rob_channel_data[rob_raddr[i][0]][i];
	assign rob_rdata_valid[i] = rob_channel_data_valid[rob_raddr[i][0]][i];
end

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
		.rob_raddr       ( rob_raddr[$clog2(`ROB_SIZE)-1:1] ),
		.rob_rdata_valid ( rob_channel_data_valid[i]        ),
		.rob_rdata       ( rob_channel_data[i]              ),
		.write_pointer   ( rob_write_pointer[i]             ),
		.cdb
	);

	assign reorder[i] = { rob_write_pointer[i], i[0] };
end

endmodule
