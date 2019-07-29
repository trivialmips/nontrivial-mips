`include "cpu_defs.svh"

module dbus_mux(
	output reg_addr_t  [`ISSUE_NUM - 1:0] reg_raddr,
	input  uint32_t    [`ISSUE_NUM - 1:0] reg_rdata,
	input  pipeline_exec_t   [`ISSUE_NUM-1:0] pipeline_dcache,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_mem,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_wb,
	input  except_req_t    except_req,
	input  pipeline_exec_t [`ISSUE_NUM-1:0] data,
	cpu_dbus_if.master     dbus,
	cpu_dbus_if.master     dbus_uncached
);

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin: gen_regaddr
	assign reg_raddr[i] = data[i].decoded.rs2;
end

virt_t mmu_vaddr;
oper_t op;
uint32_t [1:0] sw_reg2;
uint32_t reg2, mem_wrdata;

assign reg2 = data[1].memreq.write ? sw_reg2[1] : sw_reg2[0];
assign op = data[1].memreq.write ? data[1].decoded.op : data[0].decoded.op;
assign mmu_vaddr = data[1].memreq.write ? data[1].memreq.vaddr : data[0].memreq.vaddr;

always_comb begin
	sw_reg2 = reg_rdata;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		for(int j = 0; j < `ISSUE_NUM; ++j)
			if(pipeline_wb[j].rd == data[i].decoded.rs2)
				sw_reg2[i] = pipeline_wb[j].wdata;
		for(int j = 0; j < `ISSUE_NUM; ++j)
			if(pipeline_mem[j].rd == data[i].decoded.rs2)
				sw_reg2[i] = pipeline_mem[j].wdata;
		for(int j = 0; j < `ISSUE_NUM; ++j)
			if(pipeline_dcache[j].decoded.rd == data[i].decoded.rs2)
				sw_reg2[i] = pipeline_dcache[j].result;
		if(data[i].decoded.rs2 == '0)
			sw_reg2[i] = '0;
	end
end
always_comb begin
	unique case(op)
		OP_SW, OP_SC: mem_wrdata = reg2;
		OP_SB: mem_wrdata = reg2 << (mmu_vaddr[1:0] * 8);
		OP_SH: mem_wrdata = mmu_vaddr[1] ? (reg2 << 16) : reg2;
		OP_SWL: mem_wrdata = reg2 >> ((3 - mmu_vaddr[1:0]) * 8);
		OP_SWR: mem_wrdata = reg2 << (mmu_vaddr[1:0] * 8);
		default: mem_wrdata = '0;
	endcase
end

logic [`ISSUE_NUM-1:0] re, we, ce, inv, inv_icache, kill;
data_memreq_t [`ISSUE_NUM-1:0] memreq;
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_flat_memreq
	assign memreq[i] = data[i].memreq;
	assign re[i] = memreq[i].read;
	assign we[i] = memreq[i].write;
	assign inv[i] = memreq[i].invalidate;
	assign inv_icache[i] = memreq[i].invalidate_icache;
	assign ce[i] = we[i] | re[i] | inv[i] | inv_icache[i];
end

assign kill[0] = except_req.valid & except_req.alpha_taken;
assign kill[1] = except_req.valid;

//assign dbus.icache_inv = 1'b0;
//assign dbus.dcache_inv = 1'b0;

assign dbus_uncached.wrdata     = dbus.wrdata;
assign dbus_uncached.address    = dbus.address;
assign dbus_uncached.byteenable = dbus.byteenable;
assign dbus_uncached.invalidate = 1'b0;

always_comb begin
	dbus.read       = 1'b0;
	dbus.write      = 1'b0;
	dbus.wrdata     = mem_wrdata;
	dbus.address    = '0;
	dbus.byteenable = '0;
	dbus_uncached.read   = 1'b0;
	dbus_uncached.write  = 1'b0;
	dbus.invalidate_icache = 1'b0;
	dbus.invalidate = 1'b0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		dbus.invalidate_icache |= inv_icache[i] & ~kill[i];
		dbus.invalidate   |= inv[i] & ~kill[i];
		dbus.read  |= re[i] & ~memreq[i].uncached & ~kill[i];
		dbus.write |= we[i] & ~memreq[i].uncached & ~kill[i];
		dbus_uncached.read  |= re[i] & memreq[i].uncached & ~kill[i];
		dbus_uncached.write |= we[i] & memreq[i].uncached & ~kill[i];
//		dbus.wrdata     |= {32{we[i]}} & memreq[i].wrdata;
		dbus.address    |= {32{ce[i]}} & { memreq[i].paddr[31:2], 2'b0 };
		dbus.byteenable |= {4{ce[i]}}  & memreq[i].byteenable;
	end
end

endmodule
