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
logic flush_id, stall_id, stall_from_id;
logic flush_ro, stall_ro;
logic flush_ex, stall_ex, stall_from_ex;
logic flush_mm, stall_mm, stall_from_mm;
logic flush_delayed_mispredict;
logic delayslot_not_exec, hold_resolved_branch;

// register file
logic      [1:0] reg_we;
uint32_t   [1:0] reg_wdata;
reg_addr_t [1:0] reg_waddr;
uint32_t   [9:0] reg_rdata;
reg_addr_t [9:0] reg_raddr;

// waddr is 0 if we do not write registers
assign reg_we[0] = 1'b1;
assign reg_we[1] = 1'b1;

// HILO register
hilo_req_t hilo_req;
uint64_t   hilo_rddata;

// LLBit
logic llbit_value;

// pipeline data
pipeline_decode_t [1:0] pipeline_decode, pipeline_decode_d;
pipeline_exec_t   [1:0] pipeline_exec, pipeline_exec_d;
pipeline_exec_t   [2:0][1:0] pipeline_dcache;
pipeline_exec_t   [1:0] pipeline_delayed_ro_d;
pipeline_exec_t   [1:0] pipeline_dcache_last;
pipeline_memwb_t  [1:0] pipeline_mem, pipeline_mem_d;
pipeline_memwb_t  [1:0] pipeline_wb;
assign pipeline_dcache_last = pipeline_dcache[`DCACHE_PIPE_DEPTH-1];
assign pipeline_wb = pipeline_mem_d;

fetch_ack_t          if_fetch_ack;
fetch_entry_t [1:0]  if_fetch_entry;
instr_fetch_memres_t icache_res;
instr_fetch_memreq_t icache_req;
branch_resolved_t [`ISSUE_NUM-1:0] ex_resolved_branch, delayed_resolved_branch;
branch_early_resolved_t [`ISSUE_NUM-1:0] delayed_early_resolved_ro, delayed_early_resolved_ro_d;

// MMU
virt_t       mmu_inst_vaddr;
virt_t       [`ISSUE_NUM-1:0] mmu_data_vaddr;
mmu_result_t mmu_inst_result;
mmu_result_t [`ISSUE_NUM-1:0] mmu_data_result;
logic        tlbrw_we;
tlb_index_t  tlbrw_index;
tlb_entry_t  tlbrw_wdata;
tlb_entry_t  tlbrw_rdata;
uint32_t     tlbp_index;

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
except_req_t except_req;

/* setup I$ request/response */
assign mmu_inst_vaddr   = icache_req.vaddr;
assign ibus.flush_1     = icache_req.flush_s1;
assign ibus.flush_2     = icache_req.flush_s2;
assign ibus.read        = icache_req.read;
assign ibus.address     = mmu_inst_result.phy_addr;
assign icache_res.data  = ibus.rddata;
assign icache_res.valid = ibus.valid;
assign icache_res.stall = ibus.stall;
assign icache_res.data_extra       = ibus.rddata_extra;
assign icache_res.valid_extra      = ibus.extra_valid;
assign icache_res.icache_ready     = ibus.ready;
assign icache_res.iaddr_ex.miss    = mmu_inst_result.miss;
assign icache_res.iaddr_ex.illegal = mmu_inst_result.illegal;
assign icache_res.iaddr_ex.invalid = mmu_inst_result.invalid;

ctrl ctrl_inst(
	.*
);

regfile #(
	.REG_NUM     ( `REG_NUM ),
	.DATA_WIDTH  ( 32       ),
	.WRITE_PORTS ( 2        ),
	.READ_PORTS  ( 10       ),
	.ZERO_KEEP   ( 1        )
) regfile_inst (
	.clk,
	.rst,
	.we    ( reg_we    ),
	.wdata ( reg_wdata ),
	.waddr ( reg_waddr ),
	.raddr ( reg_raddr ),
	.rdata ( reg_rdata )
);

`ifdef ENABLE_FPU
logic      [1:0] fpu_reg_we;
uint32_t   [1:0] fpu_reg_wdata;
reg_addr_t [1:0] fpu_reg_waddr;
uint32_t   [3:0] fpu_reg_rdata;
reg_addr_t [3:0] fpu_reg_raddr;
logic [1:0] fcsr_we;
fpu_fcsr_t [1:0] fcsr_wdata;
fpu_fcsr_t fcsr_reg;

regfile #(
	.REG_NUM     ( `REG_NUM ),
	.DATA_WIDTH  ( 32       ),
	.WRITE_PORTS ( 2        ),
	.READ_PORTS  ( 4        ),
	.ZERO_KEEP   ( 0        )
) fpu_regfile_inst (
	.clk,
	.rst,
	.we    ( fpu_reg_we    ),
	.wdata ( fpu_reg_wdata ),
	.waddr ( fpu_reg_waddr ),
	.raddr ( fpu_reg_raddr ),
	.rdata ( fpu_reg_rdata )
);

always_ff @(posedge clk) begin
	if(rst) begin
		fcsr_reg <= '0;
	end else if(fcsr_we[1]) begin
		fcsr_reg <= fcsr_wdata[1];
	end else if(fcsr_we[0]) begin
		fcsr_reg <= fcsr_wdata[0];
	end
end
`endif

hilo hilo_inst(
	.clk,
	.rst,
	.we     ( hilo_req.we    ),
	.wrdata ( hilo_req.wdata ),
	.rddata ( hilo_rddata    )
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

instr_fetch #(
	.BPU_SIZE ( `BPU_SIZE ),
	.INSTR_FIFO_DEPTH  ( `INSTR_FIFO_DEPTH  ),
	.ICACHE_LINE_WIDTH ( `ICACHE_LINE_WIDTH )
) instr_fetch_inst (
	.clk,
	.rst,
	.flush_pc     ( flush_if              ),
	.stall_pop    ( stall_if              ),
	.except_valid ( except_req.valid      ),
	.except_vec   ( except_req.except_vec ),
	.resolved_branch_i ( ex_resolved_branch[0] ),
	.delayed_resolved_branch_i ( delayed_resolved_branch[0] ),
	.hold_resolved_branch,
	.icache_res,
	.icache_req,
	.fetch_ack    ( if_fetch_ack   ),
	.fetch_entry  ( if_fetch_entry )
);

decode_and_issue decode_issue_inst(
	.clk,
	.rst,
	.stall_id,
	.flush_id,
	.stall_ro,
	.flush_ro,
	.fetch_entry  ( if_fetch_entry ),
	.issue_num    ( if_fetch_ack   ),
	.delayslot_not_exec,
	.pipeline_exec,
	.pipeline_dcache,
	.pipeline_mem,
	.pipeline_wb,
	.pipeline_decode,
	`ifdef ENABLE_FPU
		.fcsr ( fcsr_reg ),
		.fpu_reg_raddr,
		.fpu_reg_rdata,
	`endif
	.reg_raddr    ( reg_raddr[3:0] ),
	.reg_rdata    ( reg_rdata[3:0] ),
	.stall_from_id
);

// pipeline between ID and EX
always_ff @(posedge clk) begin
	if(rst || flush_ro || (stall_ro && ~stall_ex)) begin
		pipeline_decode_d <= '0;
	end else if(~stall_ro) begin
		pipeline_decode_d <= pipeline_decode;
	end
end

uint64_t hilo_forward;
hilo_forward hilo_forward_inst(
	.pipe_dcache ( pipeline_dcache[1:0] ),
	.hilo_i      ( hilo_rddata          ),
	.hilo_o      ( hilo_forward         )
);

logic [`ISSUE_NUM-1:0] resolved_delayslot;
resolve_delayslot resolve_delayslot_inst(
	.clk,
	.rst,
	.flush ( flush_ex ),
	.stall ( stall_ex ),
	.data  ( pipeline_decode_d ),
	.resolved_delayslot
);

// ASIC
`ifdef ENABLE_ASIC
logic asic_we;
logic [15:0] asic_address, asic_raddr, asic_waddr;
uint32_t asic_wdata, asic_rdata;
assign asic_address = asic_we ? asic_waddr : asic_raddr;
asic asic_inst(
	.clk,
	.rst,
	.we      ( asic_we            ),
	.endian  ( asic_address[15]   ),
	.chip    ( asic_address[14:8] ),
	.address ( asic_address[7:0]  ),
	.wdata   ( asic_wdata         ),
	.rdata   ( asic_rdata         )
);
`endif

logic multicyc_stall;
uint32_t multicyc_reg;
uint64_t multicyc_hilo;
multi_cycle_exec multi_cycle_exec_inst(
	.clk,
	.rst,
	.flush     ( flush_ex          ),
	.stall     ( stall_mm          ),
	.stall_req ( multicyc_stall    ),
	.request   ( pipeline_decode_d ),
	.hilo_i    ( hilo_forward      ),
	.hilo_o    ( multicyc_hilo     ),
	.reg_o     ( multicyc_reg      ),
	`ifdef ENABLE_ASIC
		.asic_raddr,
	`endif
	.cp0_rsel,
	.cp0_raddr
);

`ifdef ENABLE_FPU
	logic fpu_stall;
	assign stall_from_ex = multicyc_stall | fpu_stall;
`else 
	assign stall_from_ex = multicyc_stall;
`endif

`ifdef ENABLE_FPU
uint32_t fpu_exec_ret;
fpu_fcsr_t fpu_exec_fcsr;
fpu_except_t fpu_exec_except;
fpu_exec fpu_exec_inst(
	.clk,
	.rst,
	.flush     ( flush_ex          ),
	.stall     ( stall_mm          ),
	.stall_req ( fpu_stall         ),
	.request   ( pipeline_decode_d ),
	.reg_o     ( fpu_exec_ret      ),
	.fcsr_o    ( fpu_exec_fcsr     ),
	.except_o  ( fpu_exec_except   )
);
`endif

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_exec
	instr_exec exec_inst (
		.data        ( pipeline_decode_d[i]       ),
		.result      ( pipeline_exec[i]           ),
		.reg_raddr   ( reg_raddr[4 + i]           ),
		.reg_rdata   ( reg_rdata[4 + i]           ),
		.hilo_i      ( hilo_forward               ),
		.pipeline_dcache ( pipeline_dcache[1:0]   ),
		.pipeline_mem,
		.pipeline_wb,
		.multicyc_reg,
		.multicyc_hilo,
		.llbit_value ( llbit_value                ),
		.mmu_vaddr   ( mmu_data_vaddr[i]          ),
		.mmu_result  ( mmu_data_result[i]         ),
		.is_usermode ( cp0_user_mode              ),
		.cp0_rdata   ( cp0_rdata                  ),
		`ifdef ENABLE_FPU
			.fpu_valid  ( cp0_regs.status.cu1 ),
			.fpu_result ( fpu_exec_ret        ),
			.fpu_fcsr   ( fpu_exec_fcsr       ),
			.fpu_except ( fpu_exec_except     ),
		`endif
		`ifdef ENABLE_ASIC
			.asic_rdata,
		`endif
		.delayslot   ( resolved_delayslot[i]      ),
		.resolved_branch ( ex_resolved_branch[i]  )
	);
end

// pipeline between EX and D$
always_ff @(posedge clk) begin
	if(rst || flush_ex || (stall_ex && ~stall_mm)) begin
		pipeline_exec_d <= '0;
	end else if(except_req.valid & ~except_req.alpha_taken) begin
		if(~stall_mm)
			pipeline_exec_d[0] <= '0;
		pipeline_exec_d[1] <= '0;
	end else if(~stall_ex) begin
		pipeline_exec_d <= pipeline_exec;
	end
end

// resolve interrupt requests
logic [7:0] pipe0_interrupt, pipe_interrupt, interrupt_flag, pipe_interrupt_req;

assign interrupt_flag = {
	cp0_timer_int,
	intr[4:0],
	cp0_regs.cause.ip[1:0]
};

always_ff @(posedge clk) begin
	if(rst) pipe0_interrupt <= '0;
	else    pipe0_interrupt <= interrupt_flag;

	if(rst) pipe_interrupt <= '0;
	else    pipe_interrupt <= pipe0_interrupt;

	if(rst) pipe_interrupt_req <= '0;
	else    pipe_interrupt_req <= pipe0_interrupt & cp0_regs.status.im;
end

ll_bit llbit_inst(
	.clk,
	.rst,
	.except_req,
	.pipe_mm ( pipeline_exec_d ),
	.data    ( llbit_value     )
);

except except_inst(
	.rst            ( rst | stall_mm     ),
	.cp0_regs,
	.pipe_mm        ( pipeline_exec_d    ),
	.interrupt_req  ( pipe_interrupt_req ),
	.except_req
);

// CP0
cp0 cp0_inst(
	.clk,
	.rst,
	.raddr     ( cp0_raddr     ),
	.rsel      ( cp0_rsel      ),
	.wreq      ( cp0_reg_wr    ),
	.flush_delayed_mispredict,
	.except_req_i ( except_req ),

	.tlbp_res  ( tlbp_index    ),
	.tlbr_res  ( tlbrw_rdata   ),
	.tlbp_req  ( pipeline_exec_d[0].tlbreq.probe | pipeline_exec_d[1].tlbreq.probe ),
	.tlbr_req  ( pipeline_exec_d[0].tlbreq.read  | pipeline_exec_d[1].tlbreq.read  ),
	.tlbwr_req ( pipeline_exec_d[0].tlbreq.tlbwr | pipeline_exec_d[1].tlbreq.tlbwr ),

	.tlbrw_wdata,

	.interrupt_flag ( pipe_interrupt     ),
	.kseg0_uncached ( cp0_kseg0_uncached ),
	.rdata     ( cp0_rdata     ),
	.regs      ( cp0_regs      ),
	.asid      ( cp0_asid      ),
	.user_mode ( cp0_user_mode ),
	.timer_int ( cp0_timer_int )
);

`ifdef ENABLE_ASIC
	assign asic_we    = pipeline_exec_d[0].asic_req.we & ~except_req.valid & ~stall_mm;
	assign asic_waddr = pipeline_exec_d[0].asic_req.waddr;
	assign asic_wdata = pipeline_exec_d[0].asic_req.wdata;
`endif

logic [1:0] tlb_access;
always_comb begin
	cp0_reg_wr = '0;
	tlbrw_we = 1'b0;
	tlbrw_index = '0;
	if(~except_req.valid) begin
		if(pipeline_exec_d[0].decoded.is_priv) begin
			cp0_reg_wr = pipeline_exec_d[0].cp0_req;
			tlbrw_index = pipeline_exec_d[0].tlbreq.tlbwr ?
				cp0_regs.random : cp0_regs.index;
		end else begin
			cp0_reg_wr = pipeline_exec_d[1].cp0_req;
			tlbrw_index = pipeline_exec_d[1].tlbreq.tlbwr ?
				cp0_regs.random : cp0_regs.index;
		end

		tlbrw_we = pipeline_exec_d[0].tlbreq.tlbwi
			| pipeline_exec_d[0].tlbreq.tlbwr
			| pipeline_exec_d[1].tlbreq.tlbwi
			| pipeline_exec_d[1].tlbreq.tlbwr;
	end
end

dbus_mux dbus_mux_inst(
	.except_req,
	.data  ( pipeline_exec_d ),
	.dbus,
	.dbus_uncached
);

// delayed read operands
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin: gen_delayed_ro
	delayed_register_forward delayed_register_forward_inst(
		.data      ( pipeline_exec_d[i]    ),
		.result    ( pipeline_dcache[0][i] ),
		.reg_raddr ( reg_raddr[7 + 2 * i : 6 + 2 * i] ),
		.reg_rdata ( reg_rdata[7 + 2 * i : 6 + 2 * i] ),
		.early_resolved  ( delayed_early_resolved_ro[i] ),
		.pipeline_dcache ( pipeline_dcache[1] ),
		.pipeline_mem    ( pipeline_mem       ),
		.pipeline_wb     ( pipeline_wb        )
	);
end

// pipeline between D$ and MEM
always_ff @(posedge clk) begin
	if(rst || flush_mm && ~stall_mm) begin
		pipeline_delayed_ro_d <= '0;
		delayed_early_resolved_ro_d <= '0;
	end else if(~stall_mm) begin
		if(except_req.valid & ~except_req.alpha_taken) begin
			pipeline_delayed_ro_d[0] <= pipeline_dcache[0][0];
			pipeline_delayed_ro_d[1] <= '0;
			delayed_early_resolved_ro_d <= '0;
		end else begin
			pipeline_delayed_ro_d <= pipeline_dcache[0];
			delayed_early_resolved_ro_d <= delayed_early_resolved_ro;
		end
	end
end

// delayed execution
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin: gen_delayed_exec
	delayed_exec delayed_exec_inst(
		.stall     ( stall_mm                 ),
		.data      ( pipeline_delayed_ro_d[i] ),
		.result    ( pipeline_dcache[1][i]    ),
		.early_resolved  ( delayed_early_resolved_ro_d[i] ),
		.resolved_branch ( delayed_resolved_branch[i]     )
	);
end

always_comb begin
	hilo_req = '0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		if(pipeline_dcache[1][i].hiloreq.we)
			hilo_req = pipeline_dcache[1][i].hiloreq;
	end
end

always_ff @(posedge clk) begin
	if(rst) begin
		pipeline_dcache[2] <= '0;
	end else if(~stall_mm) begin
		pipeline_dcache[2] <= pipeline_dcache[1];
	end
end

assign stall_from_mm = dbus.stall | dbus_uncached.stall;
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_mem
	instr_mem mem_inst(
		.cached_rddata   ( dbus.rddata             ),
		.uncached_rddata ( dbus_uncached.rddata    ),
		.data            ( pipeline_dcache_last[i] ),
		.result          ( pipeline_mem[i]         )
	);
end

// pipeline between MEM and WB
always_ff @(posedge clk) begin
	if(rst || stall_mm) begin
		pipeline_mem_d <= '0;
	end else if(~stall_mm) begin
		pipeline_mem_d <= pipeline_mem;
	end
end

// write back
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_write_back
	assign reg_waddr[i] = pipeline_wb[i].rd;
	assign reg_wdata[i] = pipeline_wb[i].wdata;
	`ifdef ENABLE_FPU
	assign fcsr_we[i]       = pipeline_wb[i].fpu_req.fcsr_we;
	assign fcsr_wdata[i]    = pipeline_wb[i].fpu_req.fcsr;
	assign fpu_reg_we[i]    = pipeline_wb[i].fpu_req.we;
	assign fpu_reg_waddr[i] = pipeline_wb[i].fpu_req.waddr;
	assign fpu_reg_wdata[i] = pipeline_wb[i].fpu_req.wdata;
	`endif
end

endmodule
