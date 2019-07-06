`include "cpu_defs.svh"

module fake_dbus #(
	parameter DATA_WIDTH = 32,
	parameter SIZE       = 8192
)(
	input logic clk,
	input logic rst_n,
	cpu_dbus_if.slave dbus
);

localparam int ADDR_WIDTH = $clog2(SIZE) + 2;
reg [DATA_WIDTH-1:0] mem[SIZE-1:0];

always_ff @(posedge clk or negedge rst_n) begin
	if(rst_n && dbus.write) begin
		mem[dbus.address[ADDR_WIDTH-1:2]] <= dbus.wrdata;
	end
end

always_comb
begin
	if(~rst_n || ~dbus.read)
	begin
		dbus.stall  = 1'b0;
		dbus.rddata = 'x;
		dbus.uncached_stall  = 1'b0;
		dbus.uncached_rddata = 'x;
	end else begin
		dbus.stall  = 1'b0;
		dbus.rddata = mem[dbus.address[ADDR_WIDTH-1:2]];
		dbus.uncached_stall  = 1'b0;
		dbus.uncached_rddata = '0;
	end
end

endmodule 
