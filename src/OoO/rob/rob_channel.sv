`include "cpu_defs.svh"

module rob_channel #(
	parameter int ID       = 0,
	parameter int ID_WIDTH = 1,
	parameter int DEPTH    = 8
) (
	input  logic  clk,
	input  logic  rst,
	input  logic  flush,

	input  logic  push,
	input  logic  pop,
	input  rob_entry_t  data_i,
	output rob_entry_t  data_o,

	input  cdb_packet_t cdb_packet
);

localparam int ADDR_WIDTH = $clog2(DEPTH);
typedef logic [ADDR_WIDTH-1:0] addr_t;

addr_t read_pointer_n, read_pointer_q;
addr_t write_pointer_n, write_pointer_q;
rob_entry_t [DEPTH-1:0] mem_n, mem_q;

logic [`CDB_SIZE-1:0] cdb_hit;
logic [`CDB_SIZE-1:0][DEPTH-1:0] rob_hit;

// use CDB to update ROB
always_comb begin
	mem_n = mem_q;

	for(int i = 0; i < `CDB_SIZE; ++i) begin
		cdb_hit[i] = cdb_packet[i].valid
			&& cdb_packet[i].reorder[ID_WIDTH-1:0] == ID;
		for(int j = 0; j < DEPTH; ++j) begin
			rob_hit[i][j] = cdb_hit[i]
				&& (cdb_packet[i].reorder[$clog2(`ROB_SIZE)-1:ID_WIDTH] == j);
		end
	end

	for(int i = 0; i < `CDB_SIZE; ++i) begin
		for(int j = 0; j < DEPTH; ++j) begin
			mem_n[j].busy  &= ~cdb_hit[i][j];
			mem_n[j].value |= {32{cdb_hit[i][j]}} & cdb_packet[i].value;
		end
	end

	if(push) mem_n[write_pointer_q] = data_i;
end

// update FIFO pointer
always_comb begin
	read_pointer_n  = read_pointer_q;
	write_pointer_n = write_pointer_q;

	if(push) begin
		if(write_pointer_q == FIFO_DEPTH[ADDR_DEPTH-1:0] - 1)
			write_pointer_n = '0;
		else write_pointer_n = write_pointer_q + 1;
	end

	if(pop) begin
		if(read_pointer_q == FIFO_DEPTH[ADDR_DEPTH-1:0] - 1)
			read_pointer_n = '0;
		else read_pointer_n = read_pointer_q + 1;
	end
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		read_pointer_q  <= '0;
		write_pointer_q <= '0;
	end else begin
		read_pointer_q  <= read_pointer_n;
		write_pointer_q <= write_pointer_n;
	end
end

always_ff @(posedge clk) begin
	if(rst) mem_q <= '0;
	else    mem_q <= mem_n;
end

endmodule
