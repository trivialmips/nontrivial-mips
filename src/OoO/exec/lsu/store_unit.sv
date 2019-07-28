`include "cpu_defs.svh"

module store_unit(
	input logic              clk,
	input logic              rst,

	// dbus request
	output data_memreq_t     dbus_req,
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
assign pop             = dbus_ready;
assign dbus_request    = ~empty;

fifo_v3 #(
	.DEPTH   ( `LSU_FIFO_DEPTH ),
	.dtype   ( data_memreq_t   )
) store_fifo (
	.clk_i       ( clk        ),
	.rst_i       ( rst        ),
	.flush_i     ( 1'b0       ),
	.testmode_i  ( 1'b0       ),
	.full_o      ( full       ),
	.empty_o     ( empty      ),
	.usage_o     (            ),
	.data_i      ( memreq_i   ),
	.data_o      ( dbus_req   ),
	.push_i      ( push       ),
	.pop_i       ( dbus_ready )
);

endmodule
