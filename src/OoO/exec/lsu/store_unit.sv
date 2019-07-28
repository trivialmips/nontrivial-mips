`include "cpu_defs.svh"

module store_unit(
	input logic              clk,
	input logic              rst,

	// dbus request
	cpu_dbus_if.master       dbus,
	output logic             dbus_request,
	input  logic             dbus_ready,

	// data request
	input  logic             push,
	input  data_memreq_t     memreq_i,

	// FIFO status
	output logic             full,
	output logic             empty
);

logic pop;
data_memreq_t memreq;

assign pop             = dbus_ready;
assign dbus_request    = ~empty;
assign dbus.read       = 1'b0;
assign dbus.write      = 1'b1;
assign dbus.wrdata     = memreq.wrdata;
assign dbus.address    = memreq.paddr;
assign dbus.byteenable = memreq.byteenable;
assign dbus.invalidate = memreq.invalidate;
assign dbus.invalidate_icache = memreq.invalidate_icache;

fifo_v3 #(
	.DEPTH   ( LSU_FIFO_DEPTH ),
	.dtype   ( data_memreq_t  )
) store_fifo (
	.clk_i       ( clk      ),
	.rst_i       ( rst      ),
	.flush_i     ( 1'b0     ),
	.testmode_i  ( 1'b0     ),
	.full_o      ( full     ),
	.empty_o     ( empty    ),
	.usage_o     (          ),
	.data_i      ( memreq_i ),
	.data_o      ( memreq   ),
	.push_i      ( push     ),
	.pop_i       ( pop      )
);

endmodule
