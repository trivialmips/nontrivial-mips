`include "cpu_defs.svh"

module dbus_mux(
	input  pipeline_exec_t [`ISSUE_NUM-1:0] data,
	cpu_dbus_if.master     dbus
);

logic [`ISSUE_NUM-1:0] re, we, ce;
data_memreq_t [`ISSUE_NUM-1:0] memreq;
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_flat_memreq
	assign memreq[i] = data[i].memreq;
	assign re[i] = memreq[i].read;
	assign we[i] = memreq[i].write;
	assign ce[i] = we[i] | re[i];
end

assign dbus.icache_inv = 1'b0;
assign dbus.dcache_inv = 1'b0;

always_comb begin
	dbus.read           = 1'b0;
	dbus.write          = 1'b0;
	dbus.uncached_read  = 1'b0;
	dbus.uncached_write = 1'b0;
	dbus.wrdata         = '0;
	dbus.address        = '0;
	dbus.byteenable     = '0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		dbus.read  |= re[i] & ~memreq[i].uncached;
		dbus.write |= we[i] & ~memreq[i].uncached;
		dbus.uncached_read  |= re[i] & memreq[i].uncached;
		dbus.uncached_write |= we[i] & memreq[i].uncached;
		dbus.wrdata     |= {32{we[i]}} & memreq[i].wrdata;
		dbus.address    |= {32{ce[i]}} & memreq[i].paddr;
		dbus.byteenable |= {4{ce[i]}}  & memreq[i].byteenable;
	end
end

endmodule
