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
logic flush_if;
logic flush_is;
logic flush_rob;
logic flush_ex;
logic flush_cp0;
logic flush_regstat;

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

// HILO
logic hilo_commit, hilo_ready, hilo_data_valid;
uint64_t hilo_in, hilo_out;

// CDB
cdb_packet_t cdb;

// ROB
logic rob_push, rob_pop, rob_full, rob_empty;
rob_packet_t rob_push_data, rob_pop_data;
rob_index_t [1:0] rob_reorder, rob_reorder_commit;

// instruction fetch
fetch_ack_t          if_fetch_ack;
fetch_entry_t [1:0]  if_fetch_entry;
instr_fetch_memres_t icache_res;
instr_fetch_memreq_t icache_req;
branch_resolved_t resolved_branch;

// instruction issue/exec
logic       [1:0] alu_ready, branch_ready, lsu_ready;
rs_index_t  [1:0] alu_index, branch_index, lsu_index;
logic       [1:0] alu_taken, branch_taken, lsu_taken;
logic       [1:0] cp0_taken, mul_taken;
logic       lsu_store_push, lsu_store_full, lsu_store_empty, lsu_locked;
data_memreq_t lsu_store_memreq;
reserve_station_t [1:0] issue_rs;

// MMU
virt_t       mmu_inst_vaddr;
virt_t       mmu_data_vaddr;
mmu_result_t mmu_inst_result;
mmu_result_t mmu_data_result;
logic        tlbrw_we;
tlb_index_t  tlbrw_index;
tlb_entry_t  tlbrw_wdata;
tlb_entry_t  tlbrw_rdata;
uint32_t     tlbp_index;
tlb_request_t tlbreq;

// CP0
logic [7:0]  cp0_asid;
logic        cp0_kseg0_uncached;
cp0_regs_t   cp0_regs;
reg_addr_t   cp0_raddr;
logic [2:0]  cp0_rsel;
cp0_req_t    cp0_reg_wr;
uint32_t     cp0_rdata;
logic        cp0_user_mode;
logic        cp0_timer_int;
logic        cp0_locked, cp0_commit;
except_req_t except_req;
assign cp0_lock_eret = (issue_rs[0].decoded.op == OP_ERET);

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

ctrl ctrl_inst(
	.*
);

regfile #(
	.REG_NUM     ( `REG_NUM ),
	.DATA_WIDTH  ( 32 ),
	.WRITE_PORTS ( 2  ),
	.READ_PORTS  ( 4  ),
	.ZERO_KEEP   ( 1  ),
	.WRITE_FIRST ( 1  )
) regfile_inst (
	.clk,
	.rst,
	.we    ( reg_we    ),
	.wdata ( reg_wdata ),
	.waddr ( reg_waddr ),
	.raddr ( reg_raddr ),
	.rdata ( reg_rdata )
);

regfile_status #(
	.REG_NUM     ( `REG_NUM ),
	.WRITE_PORTS ( 2 ),
	.READ_PORTS  ( 4 ),
	.ZERO_KEEP   ( 1 )
) regfile_status_inst (
	.clk,
	.rst,
	.flush    ( flush_regstat      ),
	.we       ( reg_status_we      ),
	.wdata    ( reg_status_wdata   ),
	.waddr    ( reg_status_waddr   ),
	.wrst     ( {2{rob_pop}}       ),
	.wreorder ( rob_reorder_commit ),
	.raddr    ( reg_raddr          ),
	.rdata    ( reg_status_rdata   ),
	.cdb
);

hilo hilo_inst(
	.clk,
	.rst,
	.flush      ( flush_regstat   ),
	.lock       ( |mul_taken      ),
	.commit     ( hilo_commit     ),
	.ready      ( hilo_ready      ),
	.data_valid ( hilo_data_valid ),
	.data_i     ( hilo_in         ),
	.data_o     ( hilo_out        )
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
	.reorder_commit ( rob_reorder_commit ),
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
	.stall_pop    ( 1'b0                  ),
	.except_valid ( except_req.valid      ),
	.except_vec   ( except_req.except_vec ),
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
	.alu_ready,
	.alu_index,
	.alu_taken,
	.lsu_locked,
	.lsu_ready,
	.lsu_index,
	.lsu_taken,
	.branch_taken,
	.branch_ready,
	.branch_index,
	.mul_ready ( hilo_ready  ),
	.mul_taken,
	.cp0_ready ( ~cp0_locked ),
	.cp0_taken,
	.rs_o ( issue_rs ),
	.reg_raddr,
	.reg_rdata,
	.reg_status ( reg_status_rdata ),
	.reg_status_we,
	.reg_status_waddr,
	.reg_status_wdata
);

lsu_status lsu_status_inst(
	.clk,
	.rst,
	.flush        ( flush_is       ),
	.lsu_store_empty,
	.rs           ( issue_rs       ),
	.commit_store ( lsu_store_push ),
	.locked       ( lsu_locked     )
);

instr_exec instr_exec_inst(
	.clk,
	.rst,
	.flush ( flush_ex ),
	.alu_taken,
	.alu_ready,
	.alu_index,
	.lsu_taken,
	.lsu_ready,
	.lsu_index,
	.branch_taken,
	.branch_ready,
	.branch_index,
	.mul_taken,
	.mul_valid   ( hilo_data_valid ),
	.hilo_result ( hilo_in    ),
	.hilo_data   ( hilo_out   ),
	.cp0_taken,
	.cp0_req     ( cp0_reg_wr ),
	.cp0_tlbreq  ( tlbreq     ),
	.cp0_rdata,
	.cp0_raddr,
	.cp0_rsel,
	.lsu_store_memreq,
	.lsu_store_push,
	.lsu_store_full,
	.lsu_store_empty,
	.rs_i        ( issue_rs           ),
	.mmu_result  ( mmu_data_result    ),
	.mmu_vaddr   ( mmu_data_vaddr     ),
	.rob_packet  ( rob_pop_data       ),
	.rob_reorder ( rob_reorder_commit ),
	.dbus,
	.dbus_uncached,
	.cdb_o       ( cdb                )
);

// resolve interrupt requests
logic [7:0] pipe_interrupt, interrupt_flag;
assign interrupt_flag = cp0_regs.status.im & {
	cp0_timer_int,
	intr[4:0],
	cp0_regs.cause.ip[1:0]
};

always_ff @(posedge clk) begin
	if(rst || except_req.valid)
		pipe_interrupt <= '0;
	else if(pipe_interrupt == '0)
		pipe_interrupt <= interrupt_flag;
end

instr_commit instr_commit_inst(
	.rob_packet  ( rob_pop_data       ),
	.rob_ack     ( rob_pop            ),
	.rob_reorder ( rob_reorder_commit ),
	.rob_empty,
	.lsu_store_memreq,
	.lsu_store_push,
	.lsu_store_full,
	.reg_we,
	.reg_waddr,
	.reg_wdata,
	.resolved_branch,
	.except_req,
	.cp0_regs,
	.interrupt_flag ( pipe_interrupt  ),
	.commit_cp0 ( cp0_commit  ),
	.commit_mul ( hilo_commit ),
	.commit_flush,
	.commit_flush_pc
);

// CP0
cp0 cp0_inst(
	.clk,
	.rst,
	.flush     ( flush_cp0     ),
	.raddr     ( cp0_raddr     ),
	.rsel      ( cp0_rsel      ),
	.wreq      ( cp0_reg_wr    ),
	.except_req,

	.lock        ( |cp0_taken      ),
	.locked      ( cp0_locked      ),
	.commit      ( cp0_commit      ),

	.tlbp_res  ( tlbp_index    ),
	.tlbr_res  ( tlbrw_rdata   ),
	.tlbp_req  ( tlbreq.probe  ),
	.tlbr_req  ( tlbreq.read   ),
	.tlbwr_req ( tlbreq.tlbwr  ),

	.tlbrw_wdata,

	.kseg0_uncached ( cp0_kseg0_uncached ),
	.rdata     ( cp0_rdata     ),
	.regs      ( cp0_regs      ),
	.asid      ( cp0_asid      ),
	.user_mode ( cp0_user_mode ),
	.timer_int ( cp0_timer_int )
);

mmu mmu_inst(
	.clk,
	.rst,
	.asid(cp0_asid),
	.kseg0_uncached(cp0_kseg0_uncached),
	.is_user_mode(cp0_user_mode),
	.inst_vaddr(mmu_inst_vaddr),
	.data_vaddr(mmu_data_vaddr),
	.inst_result(mmu_inst_result),
	.data_result(mmu_data_result),

	.tlbrw_index,
	.tlbrw_we,
	.tlbrw_wdata,
	.tlbrw_rdata,

	.tlbp_entry_hi(cp0_regs.entry_hi),
	.tlbp_index
);


endmodule
