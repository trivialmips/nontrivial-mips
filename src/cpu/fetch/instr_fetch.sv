`include "cpu_defs.svh"

module instr_fetch (
	input  logic    clk,
	input  logic    rst_n,
	input  logic    flush_pc,
	input  logic    flush_bp,
	input  logic    stall_req,

	// exception
	input  logic    except_valid,
	input  virt_t   except_vec,

	// mispredict
	input  branch_resolved_t    resolved_branch,

	// memory request
	input  instr_fetch_memres_t icache_res,
	output instr_fetch_memreq_t icache_req,

	// fetch
	input  logic         [`FETCH_NUM-1:0] fetch_ack,
	output fetch_entry_t [`FETCH_NUM-1:0] fetch_entry
);

endmodule
