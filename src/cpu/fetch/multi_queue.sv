`include "cpu_defs.svh"

module multi_queue #(
	parameter int unsigned DATA_WIDTH   = 32,   // default data width if the fifo is of type logic
	parameter int unsigned DEPTH        = 8,    // depth per channel, must be the power of 2
	parameter int unsigned CHANNEL      = 4,    // channel number, must be the power of 2
	parameter int unsigned PUSH_CHANNEL = 3,
	parameter int unsigned POP_CHANNEL  = 3,
	parameter type dtype                = logic [DATA_WIDTH-1:0]
)(
	input  logic  clk,
	input  logic  rst,
	input  logic  flush,
	input  logic  stall_push,
	input  logic  stall_pop,
	output logic  full,   // 1 if any channel is full
	output logic  empty,  // 1 if all channels are empty

	input  dtype  [PUSH_CHANNEL-1:0] data_push,
	input  logic  [$clog2(PUSH_CHANNEL+1)-1:0] push_num,

	output dtype  [POP_CHANNEL-1:0] data_pop,
	output logic  [POP_CHANNEL-1:0] pop_valid,
	input  logic  [$clog2(POP_CHANNEL+1)-1:0] pop_num
);

typedef logic[$clog2(CHANNEL)-1:0] index_t;

// queues info
logic [CHANNEL-1:0] queue_push, queue_pop;
logic [CHANNEL-1:0] queue_full, queue_empty;
dtype [CHANNEL-1:0] data_in, data_out;
logic [$clog2(CHANNEL+1)-1:0] full_cnt;

assign full  = full_cnt > CHANNEL - PUSH_CHANNEL;
assign empty = &queue_empty;

// index
index_t [CHANNEL-1:0] shifted_read_idx, shifted_write_idx;
index_t [CHANNEL-1:0] rshifted_read_idx, rshifted_write_idx;
index_t read_ptr_now, write_ptr_now;

always_comb begin
	full_cnt = '0;
	for(int i = 0; i < CHANNEL; ++i)
		full_cnt += queue_full[i];
end

for(genvar i = 0; i < CHANNEL; ++i) begin : gen_shifted_rw_index
	assign shifted_read_idx[i]   = read_ptr_now + i;
	assign shifted_write_idx[i]  = write_ptr_now + i;
	assign rshifted_read_idx[i]  = i - read_ptr_now;
	assign rshifted_write_idx[i] = i - write_ptr_now;
end

// queue logic
for(genvar i = 0; i < POP_CHANNEL; ++i) begin : gen_read_queue
	assign data_pop[i]  = data_out[shifted_read_idx[i]];
	assign pop_valid[i] = ~queue_empty[shifted_read_idx[i]];
end

// write queue logic
for(genvar i = 0; i < CHANNEL; ++i) begin : gen_rw_req
	assign data_in[i]    = data_push[rshifted_write_idx[i]];
	assign queue_pop[i]  = (rshifted_read_idx[i] < pop_num);
	assign queue_push[i] = (rshifted_write_idx[i] < push_num);
end

// update index
always_ff @(posedge clk) begin
	if(rst || flush) begin
		read_ptr_now  <= '0;
		write_ptr_now <= '0;
	end else begin
		if(~stall_pop)  read_ptr_now  <= read_ptr_now + pop_num;
		if(~stall_push) write_ptr_now <= write_ptr_now + push_num;
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
		.rst_i       ( rst   ),
		.flush_i     ( flush ),
		.testmode_i  ( 1'b0  ),
		.full_o      ( queue_full[i]  ),
		.empty_o     ( queue_empty[i] ),
		.usage_o     ( /* empty */    ),
		.data_i      ( data_in[i]     ),
		.data_o      ( data_out[i]    ),
		.push_i      ( ~stall_push & queue_push[i] ),
		.pop_i       ( ~stall_pop  & queue_pop[i]  )
	);
end

endmodule
