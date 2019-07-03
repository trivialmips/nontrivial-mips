`include "cpu_defs.svh"

module multi_queue #(
	parameter int unsigned DATA_WIDTH   = 32,   // default data width if the fifo is of type logic
	parameter int unsigned DEPTH        = 8,    // depth per channel, must be the power of 2
	parameter int unsigned CHANNEL      = 4,    // channel number, must be the power of 2
	parameter type dtype                = logic [DATA_WIDTH-1:0]
)(
	input  logic  clk,
	input  logic  rst_n,
	input  logic  flush,
	output logic  full,   // 1 if any channel is full
	output logic  empty,  // 1 if all channels are empty

	input  dtype  [CHANNEL-1:0] data_push,
	input  logic  [$clog2(CHANNEL+1)-1:0] push_num,

	output dtype  [CHANNEL-1:0] data_pop,
	output logic  [CHANNEL-1:0] pop_valid,
	input  logic  [$clog2(CHANNEL+1)-1:0] pop_num
);

typedef logic[$clog2(CHANNEL)-1:0] index_t;

// queues info
logic [CHANNEL-1:0] queue_push, queue_pop;
logic [CHANNEL-1:0] queue_full, queue_empty;
dtype [CHANNEL-1:0] data_in, data_out;

assign full  = |queue_full;
assign empty = &queue_empty;

// index
index_t [CHANNEL-1:0] shifted_read_idx, shifted_write_idx;
index_t read_ptr_now, write_ptr_now;

for(genvar i = 0; i < CHANNEL; ++i) begin : gen_shifted_rw_index
	assign shifted_read_idx[i]  = read_ptr_now + i;
	assign shifted_write_idx[i] = write_ptr_now + i;
end

// queue logic
for(genvar i = 0; i < CHANNEL; ++i) begin : gen_read_queue
	assign data_pop[i]  = data_out[shifted_read_idx[i]];
	assign pop_valid[i] = queue_empty[shifted_read_idx[i]];
end

// write queue logic
for(genvar i = 0; i < CHANNEL; ++i) begin : gen_rw_req
	assign data_in[shifted_write_idx[i]]    = data_push[i];
	assign queue_pop[shifted_read_idx[i]]   = (i < pop_num);
	assign queue_push[shifted_write_idx[i]] = (i < push_num);
end

// update index
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n || flush) begin
		read_ptr_now  <= '0;
		write_ptr_now <= '0;
	end else begin
		read_ptr_now  <= read_ptr_now + pop_num;
		write_ptr_now <= write_ptr_now + push_num;
	end
end

// FIFOs
for(genvar i = 0; i < CHANNEL; ++i) begin : gen_instr_fifo
	fifo_v3 #(
		.DEPTH       ( DEPTH      ),
		.DATA_WIDTH  ( DATA_WIDTH ),
		.dtype       ( dtype      )
	) instr_fifo (
		.clk_i       ( clk   ),
		.rst_ni      ( rst_n ),
		.flush_i     ( flush ),
		.testmode_i  ( 1'b0  ),
		.full_o      ( queue_full[i]  ),
		.empty_o     ( queue_empty[i] ),
		.usage_o     ( /* empty */    ),
		.data_i      ( data_in[i]     ),
		.data_o      ( data_out[i]    ),
		.push_i      ( queue_push[i]  ),
		.pop_i       ( queue_pop[i]   )
	);
end

endmodule
