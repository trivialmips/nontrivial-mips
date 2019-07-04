`ifndef CPU_DEFS_SVH
`define CPU_DEFS_SVH
`include "common_defs.svh"

/*
	This header defines data structures and constants used in CPU internally
*/

`define FETCH_NUM   2
`define BOOT_VEC    32'hbfc00000

// exception
typedef struct packed {
	logic miss, illegal, invalid;
} address_exception_t;

typedef struct packed {
	address_exception_t iaddr, daddr;
	logic syscall, breakpoint, priv_inst, overflow;
	logic invalid_inst, trap, eret;
} exception_t;

// control flow type
typedef enum logic [2:0] {
	ControlFlow_None,
	ControlFlow_Branch,
	ControlFlow_JumpImm,
	ControlFlow_JumpReg,
	ControlFlow_Return
} controlflow_t;

// resolved branch information (forward)
typedef struct packed {
	logic valid, mispredict, taken;
	virt_t pc, target;
	controlflow_t cf;
} branch_resolved_t;

// branch prediction information
typedef struct packed {
	controlflow_t cf;
	virt_t predict_vaddr;
} branch_predict_t;

// RAS information
typedef struct packed {
	logic valid;
	virt_t data;
} ras_t;

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

// fetched instruction
typedef struct packed {
	logic            valid;
	virt_t           vaddr;
	uint32_t         instr;
	branch_predict_t branch_predict;
	exception_t      ex;
} fetch_entry_t;
typedef logic [$clog2(`FETCH_NUM+1)-1:0] fetch_ack_t;

// memory request for instruction fetch
typedef struct packed {
	logic read;
	virt_t vaddr;
	logic flush_s1, flush_s2;
} instr_fetch_memreq_t;

typedef struct packed {
	uint64_t data;
	address_exception_t iaddr_ex;
} instr_fetch_memres_t;

`endif
