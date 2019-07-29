`include "cpu_defs.svh"

module cpu_core(
	input  logic           clk,
	input  logic           rst,
	input  cpu_interrupt_t intr,
	(* mark_debug = "true" *) cpu_ibus_if.master     ibus,
	(* mark_debug = "true" *) cpu_dbus_if.master     dbus,
	(* mark_debug = "true" *) cpu_dbus_if.master     dbus_uncached
);

// flush and stall signals
logic flush_if, stall_if;
logic flush_id, stall_id, stall_from_id;
logic flush_ex, stall_ex, stall_from_ex;
logic flush_mm, stall_mm, stall_from_mm;
logic delayslot_not_exec, hold_resolved_branch;

// register file
logic      [1:0] reg_we;
uint32_t   [1:0] reg_wdata;
reg_addr_t [1:0] reg_waddr;
uint32_t   [5:0] reg_rdata;
reg_addr_t [5:0] reg_raddr;

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
pipeline_exec_t   [`DCACHE_PIPE_DEPTH-1:0][1:0] pipeline_dcache;
pipeline_exec_t   [1:0] pipeline_dcache_last;
pipeline_memwb_t  [1:0] pipeline_mem, pipeline_mem_d;
pipeline_memwb_t  [1:0] pipeline_wb;
assign pipeline_dcache_last = pipeline_dcache[`DCACHE_PIPE_DEPTH-1];
assign pipeline_exec_d = pipeline_dcache[0];
assign pipeline_wb = pipeline_mem_d;

fetch_ack_t          if_fetch_ack;
fetch_entry_t [1:0]  if_fetch_entry;
instr_fetch_memres_t icache_res;
instr_fetch_memreq_t icache_req;
branch_resolved_t resolved_branch;
branch_resolved_t [`ISSUE_NUM-1:0] ex_resolved_branch;

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
	.*,
	.fetch_entry       ( if_fetch_entry     ),
	.resolved_branch_i ( ex_resolved_branch ),
	.resolved_branch_o ( resolved_branch    )
);

regfile #(
	.REG_NUM     ( `REG_NUM ),
	.DATA_WIDTH  ( 32       ),
	.WRITE_PORTS ( 2        ),
	.READ_PORTS  ( 6        ),
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
	.resolved_branch_i ( resolved_branch  ),
	.hold_resolved_branch,
	.icache_res,
	.icache_req,
	.fetch_ack    ( if_fetch_ack   ),
	.fetch_entry  ( if_fetch_entry )
);

decode_and_issue decode_issue_inst(
	.fetch_entry  ( if_fetch_entry ),
	.issue_num    ( if_fetch_ack   ),
	.delayslot_not_exec,
	.pipeline_exec,
	.pipeline_dcache,
	.pipeline_mem,
	.pipeline_wb,
	.pipeline_decode,
	.reg_raddr    ( reg_raddr[3:0] ),
	.reg_rdata    ( reg_rdata[3:0] ),
	.stall_req    ( stall_from_id  )
);

// pipeline between ID and EX
always_ff @(posedge clk) begin
	if(rst || flush_id || (stall_id && ~stall_ex)) begin
		pipeline_decode_d <= '0;
	end else if(~stall_id) begin
		pipeline_decode_d <= pipeline_decode;
	end
end

uint64_t hilo_forward;
hilo_forward hilo_forward_inst(
	.pipe_dcache ( pipeline_dcache ),
	.pipe_wb     ( pipeline_wb     ),
	.hilo_i      ( hilo_rddata     ),
	.hilo_o      ( hilo_forward    )
);

logic [`ISSUE_NUM-1:0] resolved_delayslot;
logic [`ISSUE_NUM-1:0][2:0] ex_cp0_rsel;
reg_addr_t [`ISSUE_NUM-1:0] ex_cp0_raddr;
logic [`ISSUE_NUM-1:0] stall_req_ex;
assign stall_from_ex = |stall_req_ex;
// only pipeline 0 will access CP0
assign cp0_rsel  = ex_cp0_rsel[0];
assign cp0_raddr = ex_cp0_raddr[0];

resolve_delayslot resolve_delayslot_inst(
	.clk,
	.rst,
	.flush ( flush_ex ),
	.stall ( stall_ex ),
	.data  ( pipeline_decode_d ),
	.resolved_delayslot
);

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_exec
	instr_exec #(
		.HAS_DIV(i == 0)
	) exec_inst (
		.clk,
		.rst,
		.flush       ( flush_ex                   ),
		.hilo        ( hilo_forward               ),
		.data        ( pipeline_decode_d[i]       ),
		.result      ( pipeline_exec[i]           ),
		.stall_req   ( stall_req_ex[i]            ),
		.llbit_value ( llbit_value                ),
		.mmu_vaddr   ( mmu_data_vaddr[i]          ),
		.mmu_result  ( mmu_data_result[i]         ),
		.is_usermode ( cp0_user_mode              ),
		.cp0_req_fwd ( pipeline_exec_d[0].cp0_req ),
		.cp0_rdata_i ( cp0_rdata                  ),
		.cp0_rsel    ( ex_cp0_rsel[i]             ),
		.cp0_raddr   ( ex_cp0_raddr[i]            ),
		.delayslot   ( resolved_delayslot[i]      ),
		.resolved_branch ( ex_resolved_branch[i]  )
	);
end

// pipeline between EX and D$
always_ff @(posedge clk) begin
	if(rst || flush_ex || (stall_ex && ~stall_mm)) begin
		pipeline_dcache[0] <= '0;
	end else if(except_req.valid & ~except_req.alpha_taken) begin
		if(~stall_mm)
			pipeline_dcache[0][0] <= '0;
		pipeline_dcache[0][1] <= '0;
	end else if(~stall_ex) begin
		pipeline_dcache[0] <= pipeline_exec;
	end
end

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

ll_bit llbit_inst(
	.clk,
	.rst,
	.except_req,
	.pipe_mm ( pipeline_exec_d ),
	.data    ( llbit_value     )
);

except except_inst(
	.rst,
	.cp0_regs,
	.pipe_mm        ( pipeline_exec_d ),
	.interrupt_flag ( pipe_interrupt  ),
	.except_req
);

// CP0
cp0 cp0_inst(
	.clk,
	.rst,
	.raddr     ( cp0_raddr     ),
	.rsel      ( cp0_rsel      ),
	.wreq      ( cp0_reg_wr    ),
	.except_req,

	.tlbp_res  ( tlbp_index    ),
	.tlbr_res  ( tlbrw_rdata   ),
	.tlbp_req  ( pipeline_exec_d[0].tlbreq.probe ),
	.tlbr_req  ( pipeline_exec_d[0].tlbreq.read  ),
	.tlbwr_req ( pipeline_exec_d[0].tlbreq.tlbwr ),

	.tlbrw_wdata,

	.kseg0_uncached ( cp0_kseg0_uncached ),
	.rdata     ( cp0_rdata     ),
	.regs      ( cp0_regs      ),
	.asid      ( cp0_asid      ),
	.user_mode ( cp0_user_mode ),
	.timer_int ( cp0_timer_int )
);

assign cp0_reg_wr  = pipeline_exec_d[0].cp0_req & ~except_req.valid;
assign tlbrw_we    = pipeline_exec_d[0].tlbreq.tlbwi | pipeline_exec_d[0].tlbreq.tlbwr;
assign tlbrw_index = pipeline_exec_d[0].tlbreq.tlbwi ? cp0_regs.index : cp0_regs.random;

dbus_mux dbus_mux_inst(
	.except_req,
	.reg_raddr   ( reg_raddr[5:4]  ),
	.reg_rdata   ( reg_rdata[5:4]  ),
	.pipeline_dcache ( pipeline_dcache[1] ),
	.pipeline_mem,
	.pipeline_wb,
	.data      ( pipeline_exec_d ),
	.dbus,
	.dbus_uncached
);

// pipeline between D$ and MEM
for(genvar i = 1; i < `DCACHE_PIPE_DEPTH; ++i) begin : gen_pipe_dcache
	if(i == 1) begin : gen_first_pipe_dcache
		always_ff @(posedge clk) begin
			if(rst || flush_mm && ~stall_mm) begin
				pipeline_dcache[1] <= '0;
			end else if(~stall_mm) begin
				if(except_req.valid & ~except_req.alpha_taken) begin
					pipeline_dcache[1][0] <= pipeline_dcache[0][0];
					pipeline_dcache[1][1] <= '0;
				end else begin
					pipeline_dcache[1] <= pipeline_dcache[0];
				end
			end
		end
	end else begin : generate_other_pipe_dcache
		always_ff @(posedge clk) begin
			if(rst) begin
				pipeline_dcache[i] <= '0;
			end else if(~stall_mm) begin
				pipeline_dcache[i] <= pipeline_dcache[i - 1];
			end
		end
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
generate if(`DCACHE_PIPE_DEPTH == 1) begin : dcache_no_pipe
	always_ff @(posedge clk) begin
		if(rst || flush_mm || stall_mm) begin
			pipeline_mem_d <= '0;
		end else begin
			if(except_req.valid & ~except_req.alpha_taken) begin
				pipeline_mem_d[0] <= pipeline_mem[0];
				pipeline_mem_d[1] <= '0;
			end else begin
				pipeline_mem_d <= pipeline_mem;
			end
		end
	end
end else begin : dcache_pipe
	always_ff @(posedge clk) begin
		if(rst || stall_mm) begin
			pipeline_mem_d <= '0;
		end else if(~stall_mm) begin
			pipeline_mem_d <= pipeline_mem;
		end
	end
end
endgenerate

// write back
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_write_back
	assign reg_waddr[i] = pipeline_wb[i].rd;
	assign reg_wdata[i] = pipeline_wb[i].wdata;
end

always_comb begin
	hilo_req = '0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		if(pipeline_wb[i].hiloreq.we)
			hilo_req = pipeline_wb[i].hiloreq;
	end
end

endmodule
