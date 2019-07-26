`ifndef COMPILE_OPTIONS_SVH
`define COMPILE_OPTIONS_SVH

/**
    Options to control optional components to be compiled
    These options are used to speed up compilation when debugging

**/

`define CPU_MMU_ENABLED      1

`define FETCH_NUM            2
`define ISSUE_NUM            2
`define REG_NUM              32
`define TLB_ENTRIES_NUM      16
`define BOOT_VEC             32'hbfc00000
`define BPU_SIZE             4096
`define INSTR_FIFO_DEPTH     3
`define DCACHE_PIPE_DEPTH    3

`define ICACHE_LINE_WIDTH    256
`define ICACHE_SET_ASSOC     4
`define ICACHE_SIZE          16 * 1024 * 8
`define DCACHE_LINE_WIDTH    256
`define DCACHE_SET_ASSOC     4
`define DCACHE_SIZE          16 * 1024 * 8
`define DCACHE_WB_FIFO_DEPTH 8

`endif
