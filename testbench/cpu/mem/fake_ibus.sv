`include "cpu_defs.svh"

module fake_ibus #(
	parameter DATA_WIDTH = 32,
	parameter SIZE       = 8192
)(
	input logic clk,
	input logic rst_n,
	cpu_ibus_if.slave ibus
);

localparam int ADDR_WIDTH = $clog2(SIZE) + 2;
reg [DATA_WIDTH-1:0] mem[SIZE-1:0];

logic pipe_read;
virt_t pipe_addr;

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		pipe_read <= 1'b0;
		pipe_addr <= '0;
	end else begin
		pipe_read <= ibus.read;
		pipe_addr <= ibus.address;
	end
end

always_comb
begin
	if(~rst_n || ~pipe_read)
	begin
		ibus.stall  = 1'b0;
		ibus.rddata = 'x;
	end else begin
		ibus.stall  = 1'b0;
		ibus.rddata[63:32] = mem[pipe_addr[ADDR_WIDTH-1:2] + 1];
		ibus.rddata[31:0]  = mem[pipe_addr[ADDR_WIDTH-1:2]];
	end
end

endmodule 
