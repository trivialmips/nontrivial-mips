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
`define BTB_SIZE             8
`define BHT_SIZE             1024
`define RAS_SIZE             8
`define INSTR_FIFO_DEPTH     3
`define DCACHE_PIPE_DEPTH    2

`endif
