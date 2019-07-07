`include "cpu_defs.svh"

module cpu_core(
	input  logic           clk,
	input  logic           rst,
	input  cpu_interrupt_t intr,
	cpu_ibus_if.master     ibus,
	cpu_dbus_if.master     dbus
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
uint32_t   [3:0] reg_rdata;
reg_addr_t [3:0] reg_raddr;

// waddr is 0 if we do not write registers
assign reg_we[0] = 1'b1;
assign reg_we[1] = 1'b1;

// HILO register
hilo_req_t hilo_req;
uint64_t   hilo_rddata;

// pipeline data
pipeline_decode_t [1:0] pipeline_decode, pipeline_decode_d;
pipeline_exec_t   [1:0] pipeline_exec, pipeline_exec_d;
pipeline_memwb_t  [1:0] pipeline_mem, pipeline_mem_d;
pipeline_memwb_t  [1:0] pipeline_wb;
assign pipeline_wb = pipeline_mem_d;

logic                if_except_valid;
virt_t               if_except_vec;
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
logic [7:0] cp0_asid;
logic    cp0_user_mode;
uint32_t cp0_entry_hi;
assign cp0_user_mode = 1'b0;  // TODO: set correct value

/* setup I$ request/response */
assign mmu_inst_vaddr   = icache_req.vaddr;
assign ibus.flush_1     = icache_req.flush_s1;
assign ibus.flush_2     = icache_req.flush_s2;
assign ibus.read        = icache_req.read;
assign ibus.address     = mmu_inst_result.phy_addr;
assign icache_res.data  = ibus.rddata;
assign icache_res.stall = ibus.stall;
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
	.READ_PORTS  ( 4        ),
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
	.is_user_mode(cp0_user_mode),
	.inst_vaddr(mmu_inst_vaddr),
	.data_vaddr(mmu_data_vaddr),
	.inst_result(mmu_inst_result),
	.data_result(mmu_data_result),

	.tlbrw_index,
	.tlbrw_we,
	.tlbrw_wdata,
	.tlbrw_rdata,

	.tlbp_entry_hi(cp0_entry_hi),
	.tlbp_index
);

instr_fetch #(
	.BTB_SIZE ( `BTB_SIZE ),
	.BHT_SIZE ( `BHT_SIZE ),
	.RAS_SIZE ( `RAS_SIZE ),
	.INSTR_FIFO_DEPTH ( `INSTR_FIFO_DEPTH )
) instr_fetch_inst (
	.clk,
	.rst,
	.flush_pc     ( flush_if        ),
	.flush_bp     ( 1'b0            ),
	.stall_s2     ( stall_if        ),
	.except_valid ( if_except_valid ),
	.except_vec   ( if_except_vec   ),
	.resolved_branch_i ( resolved_branch ),
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
	.pipeline_mem,
	.pipeline_wb,
	.pipeline_decode,
	.reg_raddr,
	.reg_rdata,
	.stall_req    ( stall_from_id  )
);

// pipeline between ID and EX
always_ff @(posedge clk or posedge rst) begin
	if(rst || flush_id || (stall_id && ~stall_ex)) begin
		pipeline_decode_d <= '0;
	end else if(~stall_id) begin
		pipeline_decode_d <= pipeline_decode;
	end
end

uint64_t hilo_forward;
hilo_forward hilo_forward_inst(
	.pipe_mm ( pipeline_mem ),
	.pipe_wb ( pipeline_wb  ),
	.hilo_i  ( hilo_rddata  ),
	.hilo_o  ( hilo_forward )
);

logic [`ISSUE_NUM-1:0] stall_req_ex;
assign stall_from_ex = |stall_req_ex;
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_exec
	instr_exec exec_inst(
		.clk,
		.rst,
		.flush      ( flush_ex             ),
		.hilo       ( hilo_forward         ),
		.data       ( pipeline_decode_d[i] ),
		.result     ( pipeline_exec[i]     ),
		.stall_req  ( stall_req_ex[i]      ),
		.mmu_vaddr  ( mmu_data_vaddr[i]    ),
		.mmu_result ( mmu_data_result[i]   ),
		.resolved_branch ( ex_resolved_branch[i] )
	);
end

// pipeline between EX and MEM
always_ff @(posedge clk or posedge rst) begin
	if(rst || flush_ex || (stall_ex && ~stall_mm)) begin
		pipeline_exec_d <= '0;
	end else if(~stall_ex) begin
		pipeline_exec_d <= pipeline_exec;
	end
end

dbus_mux dbus_mux_inst(
	.data ( pipeline_exec_d ),
	.dbus
);

assign stall_from_mm = dbus.stall | dbus.uncached_stall;
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_mem
	instr_mem mem_inst(
		.cached_rddata   ( dbus.rddata          ),
		.uncached_rddata ( dbus.uncached_rddata ),
		.data            ( pipeline_exec_d[i]   ),
		.result          ( pipeline_mem[i]      )
	);
end

// pipeline between MEM and WB
always_ff @(posedge clk or posedge rst) begin
	if(rst || flush_mm || stall_mm) begin
		pipeline_mem_d <= '0;
	end else if(~stall_mm) begin
		pipeline_mem_d <= pipeline_mem;
	end
end

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
