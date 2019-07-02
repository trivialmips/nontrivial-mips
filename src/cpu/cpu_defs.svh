`ifndef CPU_DEFS_SVH
`define CPU_DEFS_SVH
`include "common_defs.svh"

/*
	This header defines data structures and constants used in CPU internally
*/

`define FETCH_NUM   2

// fetched instruction
typedef struct packed {
	logic valid;
	uint32_t inst;
} fetch_entry_t;

// resolved branch information (forward)
typedef struct packed {
} branch_resolved_t;

// BTB information
typedef struct packed {
	logic valid;
	virt_t pc, target;
} btb_update_t;

typedef struct packed {
	logic valid;
	virt_t target;
} btb_predict_t;

// BHT information
typedef struct packed {
	logic valid, taken;
	virt_t pc;
} bht_update_t;

typedef struct packed {
	logic valid, taken;
} bht_predict_t;

// memory request for instruction fetch
typedef struct packed {
	logic read;
	virt_t vaddr;
} instr_fetch_memreq_t;

typedef struct packed {
	logic valid;
	uint64_t data;
	exception_t ex;
} instr_fetch_memres_t;

// exception
typedef struct packed {
} exception_t;

`endif
