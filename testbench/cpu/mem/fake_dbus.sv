`include "cpu_defs.svh"

module fake_dbus #(
	parameter DATA_WIDTH = 32,
	parameter SIZE       = 8192
)(
	input logic clk,
	input logic rst,
	cpu_dbus_if.slave dbus
);

localparam int ADDR_WIDTH = $clog2(SIZE) + 2;
reg [DATA_WIDTH-1:0] mem[SIZE-1:0];

uint32_t wrdata, rddata;
assign rddata = mem[dbus.address[ADDR_WIDTH-1:2]];
assign wrdata = {
	dbus.byteenable[3] ? dbus.wrdata[31:24] : rddata[31:24],
	dbus.byteenable[2] ? dbus.wrdata[23:16] : rddata[23:16],
	dbus.byteenable[1] ? dbus.wrdata[15:8] : rddata[15:8],
	dbus.byteenable[0] ? dbus.wrdata[7:0] : rddata[7:0]
};

always_ff @(posedge clk or negedge rst) begin
	if(rst) begin
		if(dbus.write | dbus.uncached_write) begin
			mem[dbus.address[ADDR_WIDTH-1:2]] <= wrdata;
		end
	end
end

always_comb
begin
	if(rst || ~dbus.read && ~dbus.uncached_read)
	begin
		dbus.stall  = 1'b0;
		dbus.rddata = 'x;
		dbus.uncached_stall  = 1'b0;
		dbus.uncached_rddata = 'x;
	end else begin
		dbus.stall  = 1'b0;
		dbus.rddata = rddata;
		dbus.uncached_stall  = 1'b0;
		dbus.uncached_rddata = rddata;
	end
end

endmodule 
