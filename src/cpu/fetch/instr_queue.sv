`include "cpu_defs.svh"

module instr_queue #(
	parameter int FIFO_DEPTH = 4
)(
	input  logic    clk,
	input  logic    rst,
	input  logic    flush,
	input  logic    stall_push,
	input  logic    stall_pop,

	output logic    full,
	output logic    empty,

	input  uint32_t          [`FETCH_NUM-1:0] instr,
	input  virt_t            [`FETCH_NUM-1:0] vaddr,
	input  branch_predict_t  [`FETCH_NUM-1:0] branch_predict,
	input  logic   [$clog2(`FETCH_NUM+1)-1:0] valid_num,
	input  logic   [$clog2(`FETCH_NUM)-1:0]   offset,
	input  address_exception_t                iaddr_ex,

	input  fetch_ack_t                    fetch_ack,
	output fetch_entry_t [`FETCH_NUM-1:0] fetch_entry
);

typedef struct packed {
	virt_t              vaddr;
	uint32_t            instr;
	branch_predict_t    branch_predict;
	address_exception_t iaddr_ex;
} queue_data_t;

queue_data_t  [`FETCH_NUM-1:0]    data_push, data_pop;
logic  [`FETCH_NUM-1:0]           pop_valid;

for(genvar i = 0; i < `FETCH_NUM; ++i) begin : gen_fetch_entry
	assign fetch_entry[i].valid = pop_valid[i];
	assign fetch_entry[i].vaddr = data_pop[i].vaddr;
	assign fetch_entry[i].instr = data_pop[i].instr;
	assign fetch_entry[i].iaddr_ex = data_pop[i].iaddr_ex;
	assign fetch_entry[i].branch_predict = data_pop[i].branch_predict;
end

for(genvar i = 0; i < `FETCH_NUM; ++i) begin : gen_push_data
	assign data_push[i].vaddr = vaddr[i];
	assign data_push[i].instr = instr[i];
	assign data_push[i].iaddr_ex = iaddr_ex;
	assign data_push[i].branch_predict = branch_predict[i];
end

multi_queue #(
	.CHANNEL ( `FETCH_NUM   ),
	.DEPTH   ( FIFO_DEPTH   ),
	.dtype   ( queue_data_t )
) multi_queue_inst (
	.clk,
	.rst,
	.flush,
	.full,
	.empty,
	.stall_push,
	.stall_pop,
	.data_push,
	.push_num    ( valid_num ),
	.push_offset ( offset    ),
	.data_pop,
	.pop_num     ( fetch_ack ),
	.pop_valid
);

endmodule
