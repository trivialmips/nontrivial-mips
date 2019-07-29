`include "cpu_defs.svh"

module dbus_arbitrator(
	cpu_dbus_if.master    dbus,
	cpu_dbus_if.master    dbus_uncached,
	input  data_memreq_t  store_dbus,
	input  data_memreq_t  [`LSU_RS_SIZE-1:0] fu_dbus,

	input  logic       store_dbus_req,
	output logic       store_dbus_ready,

	input  rob_packet_t                   rob_packet,
	input  rob_index_t [1:0]              rob_reorder,
	input  rob_index_t [`LSU_RS_SIZE-1:0] rs_reorder,
	input  logic       [`LSU_RS_SIZE-1:0] dbus_req,
	output logic       [`LSU_RS_SIZE-1:0] dbus_ready
);

data_memreq_t req;
assign dbus.read              = req.read & ~req.uncached;
assign dbus.write             = req.write & ~req.uncached;
assign dbus.wrdata            = req.wrdata;
assign dbus.address           = req.paddr;
assign dbus.byteenable        = req.byteenable;
assign dbus.invalidate        = req.invalidate;
assign dbus.invalidate_icache = req.invalidate_icache;
assign dbus_uncached.read               = req.read & req.uncached;
assign dbus_uncached.write              = req.write & req.uncached;
assign dbus_uncached.wrdata            = req.wrdata;
assign dbus_uncached.address           = req.paddr;
assign dbus_uncached.byteenable        = req.byteenable;
assign dbus_uncached.invalidate        = req.invalidate;
assign dbus_uncached.invalidate_icache = req.invalidate_icache;

logic [`LSU_RS_SIZE-1:0] uncached_ready;
for(genvar i = 0; i < `LSU_RS_SIZE; ++i) begin
	assign uncached_ready[i] =
		   ~store_dbus_req
		&& fu_dbus[i].uncached
		&& (rob_reorder[0] == rs_reorder[i]
		 || rob_reorder[1] == rs_reorder[i] && ~rob_packet[0].busy);
end

always_comb begin
	req        = '0;
	dbus_ready = '0;
	store_dbus_ready = 1'b0;
	for(int i = 0; i < `LSU_RS_SIZE; ++i) begin
		if(dbus_req[i] && (uncached_ready[i] || ~fu_dbus[i].uncached)) begin
			req           = fu_dbus[i];
			dbus_ready    = '0;
			dbus_ready[i] = 1'b1;
		end
	end

	if(store_dbus_req) begin
		req        = store_dbus;
		dbus_ready = '0;
		store_dbus_ready = 1'b1;
	end

	if(dbus.stall || dbus_uncached.stall) begin
		req        = '0;
		dbus_ready = '0;
		store_dbus_ready = 1'b0;
	end
end

endmodule
