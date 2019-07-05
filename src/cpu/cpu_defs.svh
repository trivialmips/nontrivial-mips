`ifndef CPU_DEFS_SVH
`define CPU_DEFS_SVH
`include "common_defs.svh"

/*
	This header defines data structures and constants used in CPU internally
*/

`define FETCH_NUM            2
`define ISSUE_NUM            2
`define REG_NUM              32
`define TLB_ENTRIES_NUM      16
`define BOOT_VEC             32'hbfc00000
`define ENABLE_CPU_MMU       1

typedef logic [$clog2(`REG_NUM)-1:0] reg_addr_t;

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
	logic stall;
	uint64_t data;
	address_exception_t iaddr_ex;
} instr_fetch_memres_t;

// operator
typedef enum logic {
	/* shift */
	OP_SLL, OP_SRL, OP_SRA, OP_SLLV, OP_SRLV, OP_SRAV,
	/* unconditional jump (reg) */
	OP_JALR,
	/* conditional move */
	OP_MOVN, OP_MOVZ,
	/* breakpoint and syscall */
	OP_SYSCALL, OP_BREAK,
	/* HI/LO move */
	OP_MFHI, OP_MFLO, OP_MTHI, OP_MTLO,
	/* multiplication and division */
	OP_MULT, OP_MULTU, OP_DIV, OP_DIVU,
	OP_MADD, OP_MADDU, OP_MSUB, OP_MSUBU, OP_MUL,
	/* add and substract */
	OP_ADD, OP_ADDU, OP_SUB, OP_SUBU,
	/* logical */
	OP_AND, OP_OR, OP_XOR, OP_NOR,
	/* compare and set */
	OP_SLT, OP_SLTU,
	/* trap */
	OP_TGE, OP_TGEU, OP_TLT, OP_TLTU, OP_TEQ, OP_TNE,
	/* count bits */
	OP_CLZ, OP_CLO,
	/* branch */
	OP_BLTZ, OP_BGEZ, OP_BLTZAL, OP_BGEZAL,
	OP_BEQ, OP_BNE, OP_BLEZ, OP_BGTZ,
	/* set */
	OP_LUI,
	/* load */
	OP_LB, OP_LH, OP_LWL, OP_LW, OP_LBU, OP_LHU, OP_LWR,
	/* cache */
	OP_CACHE,
	/* LL/SC */
	OP_LL, OP_SC,
	/* long jump */
	OP_JAL
	/* invalid */
	OP_INVALID
} oper_t;

// decode instruction
typedef struct packed {
	reg_addr_t   rs1;
	reg_addr_t   rs2;
	reg_addr_t   rd;
	oper_t       op;
	logic  use_imm;         // use immediate as reg2
	logic  is_controlflow;  // controlflow maybe changed
	logic  is_load;         // load data
	logic  is_store;        // store data
} decoded_instr_t;

// pipeline data (ID -> EX)
typedef struct packed {
	logic            valid;
	uint32_t         reg1;
	uint32_t         reg2;
	fetch_entry_t    fetch;
	decoded_instr_t  decoded;
} pipeline_decode_t;

// pipeline data (EX -> MEM)
typedef struct packed {
	virt_t          pc;
	uint32_t        result;
	logic           delayslot;
	exception_t     ex;
	decoded_instr_t decoded;
} pipeline_exec_t;

// pipeline data (MEM -> WB)
typedef struct packed {
	reg_addr_t   rd;
	uint32_t     wdata;
	logic [1:0]  hilo_we;
	uint64_t     hilo_wdata;
} pipeline_memwb_t;

// MMU/TLB
typedef logic [$clog2(`TLB_ENTRIES_NUM)-1:0] tlb_index_t;
typedef struct packed {
	phys_t phy_addr;
	logic [3:0] which;
	logic miss, dirty, valid;
	logic [2:0] cache_flag;
} tlb_result_t;

typedef struct packed {
	logic [2:0] c0, c1;
	logic [7:0] asid;
	logic [18:0] vpn2;
	logic [23:0] pfn0, pfn1;
	logic d1, v1, d0, v0;
	logic G;
} tlb_entry_t;

typedef struct packed {
	phys_t phy_addr;
	virt_t virt_addr;
	logic invalid, miss, dirty, illegal;
} mmu_result_t;

`endif
