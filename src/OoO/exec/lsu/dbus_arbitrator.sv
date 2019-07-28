`include "cpu_defs.svh"

module dbus_arbitrator(
	cpu_dbus_if.master    dbus,
	input  data_memreq_t  store_dbus,
	input  data_memreq_t  [`LSU_RS_SIZE-1:0] fu_dbus,

	input  logic       store_dbus_req,
	output logic       store_dbus_ready,
	input  logic       [`LSU_RS_SIZE-1:0] dbus_req,
	output logic       [`LSU_RS_SIZE-1:0] dbus_ready
);

data_memreq_t req;
assign dbus.read = req.read;
assign dbus.write = req.write;
assign dbus.invalidate = req.invalidate;
assign dbus.invalidate_icache = req.invalidate_icache;
assign dbus.wrdata = req.wrdata;
assign dbus.address = req.paddr;
assign dbus.byteenable = req.byteenable;

always_comb begin
	req        = '0;
	dbus_ready = '0;
	store_dbus_ready = 1'b0;
	for(int i = 0; i < `LSU_RS_SIZE; ++i) begin
		if(dbus_req[i]) begin
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

	if(dbus.stall) begin
		req        = '0;
		dbus_ready = '0;
		store_dbus_ready = 1'b0;
	end
end

endmodule
