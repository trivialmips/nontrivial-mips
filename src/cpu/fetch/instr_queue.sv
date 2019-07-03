`include "cpu_defs.svh"

module instr_queue #(
	parameter int ENTRIES_NUM = 8
)(
	input  logic    clk,
	input  logic    rst_n,
	input  logic    flush,

	input  uint32_t [`FETCH_NUM-1:0] instr,
	input  virt_t   [`FETCH_NUM-1:0] vaddr,
	input  logic    [`FETCH_NUM-1:0] valid,
	input  logic    exception,    // page-table faults

	input  logic         [`FETCH_NUM-1:0] fetch_ack,
	output fetch_entry_t [`FETCH_NUM-1:0] fetch_entry,

	output logic         queue_full,
	output logic         queue_empty
);

endmodule
