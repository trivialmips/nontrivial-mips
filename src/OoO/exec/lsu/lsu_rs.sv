`include "cpu_defs.svh"

module lsu_rs(
	input  logic             clk,
	input  logic             rst,
	input  logic             flush,

	input  logic             [1:0] rs_taken,
	output logic             [1:0] rs_ready,
	output rs_index_t        [1:0] rs_index,
	input  reserve_station_t [1:0] rs_i,

	// result
	output exception_t       [`LSU_RS_SIZE-1:0] ex,
	output data_memreq_t     [`LSU_RS_SIZE-1:0] memreq,
	output uint32_t          [`LSU_RS_SIZE-1:0] data,
	output logic             [`LSU_RS_SIZE-1:0] data_ready,
	output rob_index_t       [`LSU_RS_SIZE-1:0] data_reorder,
	input  logic             [`LSU_RS_SIZE-1:0] data_ack,

	// store unit
	input  logic             store_push,
	input  data_memreq_t     store_memreq,
	output logic             store_full,
	output logic             store_empty,

	// MMU
	output virt_t            mmu_vaddr,
	input  mmu_result_t      mmu_result,

	// dbus
	cpu_dbus_if.master       dbus,
	cpu_dbus_if.master       dbus_uncached,

	// ROB (for uncached read)
	input  rob_index_t [1:0] rob_reorder,
	input  rob_packet_t      rob_packet,

	// CDB
	input  cdb_packet_t      cdb
);

// *_q:  current status
// *_n:  next status
// *_ro: after reading operands
logic [`LSU_RS_SIZE-1:0] fu_busy;
reserve_station_t [`LSU_RS_SIZE-1:0] rs_n, rs_ro, rs_q;
logic      [1:0] rs_ready_n, rs_ready_q;
rs_index_t [1:0] rs_index_n, rs_index_q;
assign rs_index = rs_index_q;
assign rs_ready = rs_ready_q;

// allocate ready RS
always_comb begin
	rs_ready_n = '0;
	rs_index_n = '0;
	for(int i = 0; i < `LSU_RS_SIZE; ++i) begin
		if(~rs_n[i].busy & ~fu_busy[i]) begin
			rs_ready_n[0] = 1'b1;
			rs_index_n[0] = i;
		end
	end

	for(int i = 0; i < `LSU_RS_SIZE; ++i) begin
		if(~rs_n[i].busy && ~fu_busy[i] && rs_index_n[0] != i) begin
			rs_ready_n[1] = 1'b1;
			rs_index_n[1] = i;
		end
	end
end

// update RS
always_comb begin
	rs_n = rs_ro;

	// pop RS
	for(int i = 0; i < `LSU_RS_SIZE; ++i)
		if(data_ack[i]) rs_n[i] = '0;

	// push RS
	if(rs_taken[0]) rs_n[rs_i[0].index] = rs_i[0];
	if(rs_taken[1]) rs_n[rs_i[1].index] = rs_i[1];
end

// read operands
for(genvar i = 0; i < `LSU_RS_SIZE; ++i) begin: gen_rs
	read_operands read_ops_inst(
		.cdb_packet ( cdb      ),
		.rs_i       ( rs_q[i]  ),
		.rs_o       ( rs_ro[i] )
	);
end

data_memreq_t store_dbus;
data_memreq_t [`LSU_RS_SIZE-1:0] fu_dbus;
data_memres_t [`LSU_RS_SIZE-1:0] dbus_res;
logic store_dbus_req, store_dbus_ready;
logic [`LSU_RS_SIZE-1:0] fu_dbus_req, fu_dbus_ready;
logic [`LSU_RS_SIZE-1:0] fu_mmu_req, fu_mmu_ready;
virt_t [`LSU_RS_SIZE-1:0] fu_mmu_vaddr;

for(genvar i = 0; i < `LSU_RS_SIZE; ++i) begin
	assign dbus_res[i].stall  = memreq[i].uncached ? dbus_uncached.stall : dbus.stall;
	assign dbus_res[i].rddata = memreq[i].uncached ? dbus_uncached.rddata : dbus.rddata;
end

// store unit
store_unit store_unit_inst(
	.clk,
	.rst,
	.dbus_req     ( store_dbus       ),
	.dbus_request ( store_dbus_req   ),
	.dbus_ready   ( store_dbus_ready ),
	.push         ( store_push       ),
	.memreq_i     ( store_memreq     ),
	.full         ( store_full       ),
	.empty        ( store_empty      )
);

// MMU arbitrator
always_comb begin
	mmu_vaddr    = '0;
	fu_mmu_ready = '0;
	for(int i = 0; i < `LSU_RS_SIZE; ++i) begin
		if(fu_mmu_req[i]) begin
			mmu_vaddr       = fu_mmu_vaddr[i];
			fu_mmu_ready    = '0;
			fu_mmu_ready[i] = 1'b1;
		end
	end
end

// DBus arbitrator
dbus_arbitrator dbus_arbitrator_inst(
	.dbus,
	.dbus_uncached,
	.store_dbus,
	.store_dbus_req,
	.store_dbus_ready,
	.fu_dbus,
	.rob_packet,
	.rob_reorder,
	.rs_reorder ( data_reorder  ),
	.dbus_req   ( fu_dbus_req   ),
	.dbus_ready ( fu_dbus_ready )
);

for(genvar i = 0; i < `LSU_RS_SIZE; ++i) begin: gen_data_valid
	assign data_reorder[i] = rs_q[i].reorder;
end

// LSU
for(genvar i = 0; i < `LSU_RS_SIZE; ++i) begin: gen_lsu
	lsu lsu_inst(
		.clk,
		.rst,
		.flush,
		.rs           ( rs_q[i]          ),
		.fu_busy      ( fu_busy[i]       ),
		.dbus_req     ( fu_dbus[i]       ),
		.dbus_res     ( dbus_res[i]      ),
		.dbus_request ( fu_dbus_req[i]   ),
		.dbus_ready   ( fu_dbus_ready[i] ),
		.mmu_vaddr    ( fu_mmu_vaddr[i]  ),
		.mmu_request  ( fu_mmu_req[i]    ),
		.mmu_result   ( mmu_result       ),
		.mmu_ready    ( fu_mmu_ready[i]  ),
		.ex           ( ex[i]            ),
		.req          ( memreq[i]        ),
		.data         ( data[i]          ),
		.data_ready   ( data_ready[i]    )
	);
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		rs_q       <= '0;
		rs_ready_q <= 2'b11;
		rs_index_q[0] <= 0;
		rs_index_q[1] <= 1;
	end else begin
		rs_q       <= rs_n;
		rs_ready_q <= rs_ready_n;
		rs_index_q <= rs_index_n;
	end
end

endmodule
