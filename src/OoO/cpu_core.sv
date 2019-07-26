`include "cpu_defs.svh"

module cpu_core(
	input  logic           clk,
	input  logic           rst,
	input  cpu_interrupt_t intr,
	cpu_ibus_if.master     ibus,
	cpu_dbus_if.master     dbus,
	cpu_dbus_if.master     dbus_uncached
);

// flush and stall signals
logic flush_if, stall_if;
logic flush_rob;
logic flush_ex;

// register file
logic      [1:0] reg_we;
uint32_t   [1:0] reg_wdata;
reg_addr_t [1:0] reg_waddr;
uint32_t   [3:0] reg_rdata;
reg_addr_t [3:0] reg_raddr;

// register status
logic             [1:0] reg_status_we;
register_status_t [1:0] reg_status_wdata;
reg_addr_t        [1:0] reg_status_waddr;
register_status_t [3:0] reg_status_rdata;
register_status_t [1:0] reg_status_commit;

// CDB
cdb_packet_t cdb;

// ROB
logic rob_push, rob_pop, rob_full, rob_empty;
rob_packet_t rob_push_data, rob_pop_data;
rob_index_t [1:0] rob_reorder;
rob_index_t [3:0] rob_raddr;
logic [3:0] rob_rdata_valid;
uint32_t [3:0] rob_rdata;

// instruction fetch
fetch_ack_t          if_fetch_ack;
fetch_entry_t [1:0]  if_fetch_entry;
instr_fetch_memres_t icache_res;
instr_fetch_memreq_t icache_req;
branch_resolved_t resolved_branch;
logic except_valid;
virt_t except_vec;

// instruction issue/exec
logic       [1:0] alu_ready;
rs_index_t  [1:0] alu_index;
logic       [1:0] alu_taken;
reserve_station_t [1:0] issue_rs;

// instruction commit
// TODO:
logic commit_flush;
virt_t commit_flush_pc;

/* setup I$ request/response */
assign ibus.flush_1     = icache_req.flush_s1;
assign ibus.flush_2     = icache_req.flush_s2;
assign ibus.read        = icache_req.read;
assign ibus.address     = { 3'b0, icache_req.vaddr[28:0] };
assign icache_res.data  = ibus.rddata;
assign icache_res.valid = ibus.valid;
assign icache_res.stall = ibus.stall;
assign icache_res.data_extra       = ibus.rddata_extra;
assign icache_res.valid_extra      = ibus.extra_valid;
assign icache_res.icache_ready     = ibus.ready;
// TODO: Add MMU
assign icache_res.iaddr_ex.miss    = 1'b0;
assign icache_res.iaddr_ex.illegal = 1'b0;
assign icache_res.iaddr_ex.invalid = 1'b0;

regfile #(
	.REG_NUM     ( `REG_NUM ),
	.DATA_WIDTH  ( 32       ),
	.WRITE_PORTS ( 2        ),
	.READ_PORTS  ( 4        ),
	.ZERO_KEEP   ( 1        )
) regfile_inst (
	.clk,
	.rst,
	.we    ( reg_we    ),
	.wrst  ( '0        ),
	.wdata ( reg_wdata ),
	.waddr ( reg_waddr ),
	.raddr ( reg_raddr ),
	.rdata ( reg_rdata )
);

regfile #(
	.REG_NUM     ( `REG_NUM ),
	.WRITE_PORTS ( 4        ),
	.READ_PORTS  ( 4        ),
	.ZERO_KEEP   ( 1        ),
	.dtype       ( register_status_t )
) regfile_status_inst (
	.clk,
	.rst,
	.we    ( { reg_we, reg_status_we }               ),
	.wrst  ( 4'b1100                                 ),
	.wdata ( { reg_status_commit, reg_status_wdata } ),
	.waddr ( { reg_waddr, reg_status_waddr }         ),
	.raddr ( reg_raddr         ),
	.rdata ( reg_status_rdata  )
);

rob rob_inst(
	.clk,
	.rst,
	.flush   ( flush_rob     ),
	.push    ( rob_push      ),
	.pop     ( rob_pop       ),
	.data_i  ( rob_push_data ),
	.data_o  ( rob_pop_data  ),
	.full    ( rob_full      ),
	.empty   ( rob_empty     ),
	.reorder ( rob_reorder   ),
	.rob_raddr,
	.rob_rdata_valid,
	.rob_rdata,
	.cdb
);

instr_fetch #(
	.BPU_SIZE ( `BPU_SIZE ),
	.INSTR_FIFO_DEPTH  ( `INSTR_FIFO_DEPTH  ),
	.ICACHE_LINE_WIDTH ( `ICACHE_LINE_WIDTH )
) instr_fetch_inst (
	.clk,
	.rst,
	.flush_pc     ( flush_if              ),
	.stall_pop    ( stall_if              ),
	.except_valid ( except_valid          ),
	.except_vec   ( except_vec            ),
	.resolved_branch_i ( resolved_branch  ),
	.hold_resolved_branch  ( 1'b0 ),
	.icache_res,
	.icache_req,
	.fetch_ack    ( if_fetch_ack   ),
	.fetch_entry  ( if_fetch_entry )
);

instr_issue instr_issue_inst(
	.fetch_entry  ( if_fetch_entry  ),
	.fetch_ack    ( if_fetch_ack    ),
	.rob_full,
	.rob_reorder,
	.rob_packet_valid ( rob_push      ),
	.rob_packet       ( rob_push_data ),
	.rob_raddr,
	.rob_rdata_valid,
	.rob_rdata,
	.alu_ready,
	.alu_index,
	.alu_taken,
	.rs ( issue_rs ),
	.reg_raddr,
	.reg_rdata,
	.reg_status ( reg_status_rdata )
);

instr_exec instr_exec_inst(
	.clk,
	.rst,
	.flush ( flush_ex ),
	.alu_taken,
	.alu_ready,
	.alu_index,
	.rs_i  ( issue_rs ),
	.cdb_o ( cdb      )
);

instr_commit instr_commit_inst(
	.rob_packet ( rob_pop_data      ),
	.rob_ack    ( rob_pop           ),
	.reg_we,
	.reg_waddr,
	.reg_wdata,
	.reg_status ( reg_status_commit ),
	.commit_flush,
	.commit_flush_pc
);

endmodule
