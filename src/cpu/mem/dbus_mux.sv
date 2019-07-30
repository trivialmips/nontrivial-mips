`include "cpu_defs.svh"

module dbus_mux(
	input  except_req_t    except_req,
	input  pipeline_exec_t [`ISSUE_NUM-1:0] data,
	cpu_dbus_if.master     dbus,
	cpu_dbus_if.master     dbus_uncached
);

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

assign kill[0] = (except_req.valid & except_req.alpha_taken);
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
	dbus.wrdata     = '0;
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
		dbus.wrdata     |= {32{we[i]}} & memreq[i].wrdata;
		dbus.address    |= {32{ce[i]}} & { memreq[i].paddr[31:2], 2'b0 };
		dbus.byteenable |= {4{ce[i]}}  & memreq[i].byteenable;
	end
end

endmodule
