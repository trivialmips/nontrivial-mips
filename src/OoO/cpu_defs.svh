`ifndef CPU_DEFS_SVH
`define CPU_DEFS_SVH
`include "common_defs.svh"

/**
	This header defines data structures and constants used in CPU internally
**/

`define RST_CLEAR_BTB     0

/* cause register exc_code field */
`define EXCCODE_INT   5'h00  // interrupt
`define EXCCODE_MOD   5'h01  // TLB modification exception
`define EXCCODE_TLBL  5'h02  // TLB exception (load or instruction fetch)
`define EXCCODE_TLBS  5'h03  // TLB exception (store)
`define EXCCODE_ADEL  5'h04  // address exception (load or instruction fetch)
`define EXCCODE_ADES  5'h05  // address exception (store)
`define EXCCODE_SYS   5'h08  // syscall
`define EXCCODE_BP    5'h09  // breakpoint
`define EXCCODE_RI    5'h0a  // reserved instruction exception
`define EXCCODE_CpU   5'h0b  // coprocesser unusable exception
`define EXCCODE_OV    5'h0c  // overflow
`define EXCCODE_TR    5'h0d  // trap
`define EXCCODE_FPE   5'h0f  // floating point exception

`define SIMU_ONLY_ADDR 32'h4050_000f // used in simulation for debug purposes

typedef logic [$clog2(`REG_NUM)-1:0] reg_addr_t;
typedef logic [4:0] cpu_interrupt_t;

// exception
typedef struct packed {
	logic miss, illegal, invalid;
} address_exception_t;

typedef struct packed {
	logic valid, eret;
	logic [4:0] exc_code;
	uint32_t extra;
} exception_t;

typedef struct packed {
	logic valid, delayslot, eret;
	logic alpha_taken;
	logic [4:0] code;
	virt_t pc, except_vec;
	uint32_t extra;
} except_req_t;

// control flow type
typedef enum logic [2:0] {
	ControlFlow_None,
	ControlFlow_Jump,
	ControlFlow_Branch,
	ControlFlow_Call,
	ControlFlow_Return
} controlflow_t;

// resolved branch information (forward)
typedef struct packed {
	// Are we recognize this instruction as a controlflow?
	logic valid;
	// Are we mispredict?
	logic mispredict;
	// Are we change the controlflow?
	logic taken;
	// Instruction address
	virt_t pc;
	// Controlflow target address
	virt_t target;
	// BHT counter
	logic [1:0] counter;
	// Controlflow type
	controlflow_t cf;
} branch_resolved_t;

typedef struct packed {
	logic mispredict;
	virt_t pc, target;
} presolved_branch_t;

// branch prediction information
typedef struct packed {
	logic valid, taken;
	logic wait_delayslot;
	virt_t target;
	logic [1:0] counter;
	controlflow_t cf;
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
	controlflow_t cf;
} btb_update_t;

typedef struct packed {
	virt_t target;
	controlflow_t cf;
} btb_predict_t;

// BHT information
typedef struct packed {
	logic valid, taken;
	logic [1:0] counter;
	virt_t pc;
} bht_update_t;

typedef logic [1:0] bht_predict_t;

// fetched instruction
typedef struct packed {
	logic            valid;
	virt_t           vaddr;
	uint32_t         instr;
	branch_predict_t branch_predict;
	address_exception_t iaddr_ex;
} fetch_entry_t;
typedef logic [$clog2(`FETCH_NUM+1)-1:0] fetch_ack_t;

// memory request for instruction fetch
typedef struct packed {
	logic read;
	virt_t vaddr;
	logic flush_s1, flush_s2;
} instr_fetch_memreq_t;

typedef struct packed {
	logic icache_ready;
	logic stall, valid, valid_extra;
	uint64_t data, data_extra;
	address_exception_t iaddr_ex;
} instr_fetch_memres_t;

// operator
typedef enum logic [6:0] {
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
	/* store */
	OP_SB, OP_SH, OP_SWL, OP_SW, OP_SWR,
	/* LL/SC */
	OP_LL, OP_SC,
	/* long jump */
	OP_JAL,
	/* privileged instructions */
	OP_CACHE, OP_ERET, OP_MFC0, OP_MTC0,
	OP_TLBP, OP_TLBR, OP_TLBWI, OP_TLBWR, OP_WAIT,
	/* invalid */
	OP_INVALID
} oper_t;

// functional unit
typedef enum logic [2:0] {
	FU_INVALID,
	FU_ALU,
	FU_BRANCH,
	FU_MUL,
	FU_LOAD,
	FU_STORE,
	FU_CP0
} funct_t;

// decode instruction
typedef struct packed {
	reg_addr_t   rs1;
	reg_addr_t   rs2;
	reg_addr_t   rd;
	oper_t       op;
	funct_t      fu;
	controlflow_t cf;       // controlflow type
	logic  imm_signed;      // use sign-extened immediate
	logic  use_imm;         // use immediate as reg2
	logic  is_controlflow;  // controlflow maybe changed
} decoded_instr_t;

// CP0 requests
typedef struct packed {
	logic       we;
	reg_addr_t  waddr;
	logic [2:0] wsel;
	uint32_t    wdata;
} cp0_req_t;

// CP0 registers
typedef struct packed {
	logic cu3, cu2, cu1, cu0;
	logic rp, fr, re, mx;
	logic px, bev, ts, sr;
	logic nmi, zero;
	logic [1:0] impl;
	logic [7:0] im;
	logic kx, sx, ux, um;
	logic r0, erl, exl, ie;
} cp0_status_t;

typedef struct packed {
	logic bd, zero30;
	logic [1:0] ce;
	logic [3:0] zero27_24;
	logic iv, wp;
	logic [5:0] zero21_16;
	logic [7:0] ip;
	logic zero7;
	logic [4:0] exc_code;
	logic [1:0] zero1_0;
} cp0_cause_t;

typedef struct packed {
	uint32_t ebase, config1;
	/* The order of the following registers is important.
	 * DO NOT change them. New registers must be added 
	 * BEFORE this comment */
	/* primary 32 registers (sel = 0) */
	uint32_t 
	 desave,    error_epc,  tag_hi,     tag_lo,    
	 cache_err, err_ctl,    perf_cnt,   depc,      
	 debug,     impl_lfsr32,  reserved21, reserved20,
	 watch_hi,  watch_lo,   ll_addr,    config0,   
	 prid,      epc;
	cp0_cause_t  cause;
	cp0_status_t status;
	uint32_t
	 compare,   entry_hi,   count,      bad_vaddr, 
	 reserved7, wired,      page_mask,  context_,  
	 entry_lo1, entry_lo0,  random,     index;
} cp0_regs_t;

// MMU/TLB
typedef logic [$clog2(`TLB_ENTRIES_NUM)-1:0] tlb_index_t;
typedef struct packed {
	phys_t phy_addr;
	logic [3:0] which;
	logic miss, dirty, valid;
	logic [2:0] cache_flag;
} tlb_result_t;

// TLB requests
typedef struct packed {
	logic probe, read, tlbwr, tlbwi;
} tlb_request_t;

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
	logic uncached;
	logic invalid, miss, dirty, illegal;
} mmu_result_t;

// memory request for load and store
typedef struct packed {
	logic invalidate, invalidate_icache;
	logic read, write, uncached;
	logic [3:0] byteenable;
	virt_t vaddr;
	phys_t paddr;
	uint32_t wrdata;
} data_memreq_t;

typedef struct packed {
	logic    stall;
	uint32_t rddata;
} data_memres_t;

// ROB entry
typedef struct packed {
	data_memreq_t     memreq;
	branch_resolved_t resolved_branch;
} cdb_union_data_t;

typedef struct packed {
	logic      valid;
	logic      busy;
	logic      delayslot;
	virt_t     pc;
	uint32_t   value;
	reg_addr_t dest;
	funct_t    fu;
	exception_t ex;
	cdb_union_data_t data;
} rob_entry_t;

typedef rob_entry_t [1:0] rob_packet_t;
typedef logic [$clog2(`ROB_SIZE)-1:0] rob_index_t;

// CDB
typedef struct packed {
	logic       valid;
	rob_index_t reorder;
	uint32_t    value;
	exception_t ex;
	cdb_union_data_t data;
} cdb_t;

typedef cdb_t [`CDB_SIZE-1:0] cdb_packet_t;

// reserve station
typedef logic [$clog2(`MAX_RS_SIZE)-1:0] rs_index_t;
typedef struct packed {
	logic       busy;
	rs_index_t  index;
	rob_index_t reorder;
	uint32_t    instr;
	uint32_t    [1:0] operand;
	rob_index_t [1:0] operand_addr;
	logic       [1:0] operand_ready;
	decoded_instr_t decoded;
	fetch_entry_t   fetch;
} reserve_station_t;

// register status
typedef struct packed {
	logic       busy;
	rob_index_t reorder;
	logic       data_valid;
	uint32_t    data;
} register_status_t;

`endif
