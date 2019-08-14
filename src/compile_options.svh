`ifndef COMPILE_OPTIONS_SVH
`define COMPILE_OPTIONS_SVH

/**
    Options to control optional components to be compiled
    These options are used to speed up compilation when debugging

**/

`define COMPILE_FULL_M

`ifdef COMPILE_FULL_M
	`define COMPILE_FULL 1
`else
	`define COMPILE_FULL 0
`endif

`define CPU_MMU_ENABLED      `COMPILE_FULL
`define CPU_MUTEX_PRIV       `COMPILE_FULL
`define CPU_LWLR_ENABLED     `COMPILE_FULL

`ifdef COMPILE_FULL_M
	`define ENABLE_ASIC
`endif

// `define CPU_LLSC_ENABLED_M

// Instead of modifying this, define CPU_LLSC_ENABLED_M to enable ll/sc
`ifdef CPU_LLSC_ENABLED_M
	`define CPU_LLSC_ENABLED     1
`else
	`define CPU_LLSC_ENABLED     0
`endif

`define CPU_PERFORMANCE      1
`define CPU_DELAYED_BRANCH   `CPU_PERFORMANCE

`define FETCH_NUM            2
`define ISSUE_NUM            2
`define REG_NUM              32
`define TLB_ENTRIES_NUM      16
`define BOOT_VEC             32'hbfc00000
`define BPU_SIZE             2048
`define INSTR_FIFO_DEPTH     3
`define DCACHE_PIPE_DEPTH    3

`define ICACHE_LINE_WIDTH    256
`define ICACHE_SET_ASSOC     2
`define ICACHE_SIZE          16 * 1024 * 8
`define DCACHE_LINE_WIDTH    256
`define DCACHE_SET_ASSOC     2
`define DCACHE_SIZE          16 * 1024 * 8
`define DCACHE_WB_FIFO_DEPTH 2
`define DBUS_TRANS_WIDTH     8

`endif
