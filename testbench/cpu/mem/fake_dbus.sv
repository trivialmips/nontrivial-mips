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

logic pipe_read, pipe_write, pipe_uncached_read, pipe_uncached_write;
uint32_t pipe_addr;
logic [3:0] pipe_sel;
uint32_t wrdata, rddata, pipe_wrdata;
assign rddata = mem[pipe_addr[ADDR_WIDTH-1:2]];
assign wrdata = {
	pipe_sel[3] ? pipe_wrdata[31:24] : rddata[31:24],
	pipe_sel[2] ? pipe_wrdata[23:16] : rddata[23:16],
	pipe_sel[1] ? pipe_wrdata[15:8] : rddata[15:8],
	pipe_sel[0] ? pipe_wrdata[7:0] : rddata[7:0]
};

generate if(`DCACHE_PIPE_DEPTH == 1) begin : dcache_pipe1
	assign pipe_wrdata = dbus.wrdata;
	assign pipe_read   = dbus.read;
	assign pipe_write  = dbus.write;
	assign pipe_addr   = dbus.address;
	assign pipe_sel    = dbus.byteenable;
	assign pipe_uncached_read  = dbus.uncached_read;
	assign pipe_uncached_write = dbus.uncached_write;
end else begin : dcache_pipe2
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			pipe_wrdata <= '0;
			pipe_read   <= '0;
			pipe_write  <= '0;
			pipe_addr   <= '0;
			pipe_sel    <= '0;
			pipe_uncached_read  <= '0;
			pipe_uncached_write <= '0;
		end else begin
			pipe_wrdata <= dbus.wrdata;
			pipe_read   <= dbus.read;
			pipe_write  <= dbus.write;
			pipe_addr   <= dbus.address;
			pipe_sel    <= dbus.byteenable;
			pipe_uncached_read  <= dbus.uncached_read;
			pipe_uncached_write <= dbus.uncached_write;
		end
	end
end
endgenerate

always_ff @(posedge clk or posedge rst) begin
	if(~rst) begin
		if(pipe_write | pipe_uncached_write) begin
			mem[pipe_addr[ADDR_WIDTH-1:2]] <= wrdata;
		end
	end
end

always_comb
begin
	if(rst || ~pipe_read && ~pipe_uncached_read)
	begin
		dbus.stall  = 1'b0;
		dbus.rddata = 'x;
		dbus.uncached_stall  = 1'b0;
		dbus.uncached_rddata = 'x;
	end else begin
		dbus.stall  = 1'b0;
		dbus.rddata = pipe_read ? rddata : 'x;
		dbus.uncached_stall  = 1'b0;
		dbus.uncached_rddata = pipe_uncached_read ? rddata : 'x;
	end
end

endmodule 
