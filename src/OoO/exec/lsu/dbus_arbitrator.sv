`include "cpu_defs.svh"

module dbus_arbitrator(
	cpu_dbus_if.master dbus,
	cpu_dbus_if.master store_dbus,
	cpu_dbus_if.slave  [`LSU_RS_SIZE-1:0] fu_dbus

	input  logic       store_dbus_req,
	output logic       store_dbus_ready,
	input  logic       [`LSU_RS_SIZE-1:0] dbus_req,
	output logic       [`LSU_RS_SIZE-1:0] dbus_ready
);

for(genvar i = 0; i < `LSU_RS_SIZE; ++i) begin: gen_dbus_output
	assign fu_dbus[i].stall     = dbus.stall;
	assign fu_dbus[i].rddata    = dbus.rddata;
	assign fu_dbus[i].trans_out = dbus.trans_out;
end

always_comb begin
	dbus       = '0;
	dbus_ready = '0;
	store_dbus_ready = 1'b0;
	for(int i = 0; i < `LSU_RS_SIZE; ++i) begin
		if(dbus_req[i]) begin
			dbus          = fu_dbus[i];
			dbus_ready    = '0;
			dbus_ready[i] = 1'b1;
		end
	end

	if(store_dbus_req) begin
		dbus       = store_dbus;
		dbus_ready = '0;
		store_dbus_ready = 1'b1;
	end

	if(dbus.stall) begin
		dbus = '0;
		dbus_ready = '0;
		store_dbus_ready = 1'b0;
	end
end

endmodule
