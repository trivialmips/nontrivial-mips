`include "cpu_defs.svh"

module fake_ibus #(
	parameter DATA_WIDTH = 32,
	parameter CACHE_LINE = 8,
	parameter SIZE       = 8192
)(
	input logic clk,
	input logic rst,
	input logic fake_stall_en,
	cpu_ibus_if.slave ibus
);

localparam int ADDR_WIDTH = $clog2(SIZE) + 2;
reg [DATA_WIDTH-1:0] mem[SIZE-1:0];
reg [SIZE / $clog2(CACHE_LINE)-1:0] hit;

logic pipe_read;
virt_t pipe_addr;

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		pipe_read <= 1'b0;
		pipe_addr <= '0;
	end else if(ibus.flush_2) begin
		pipe_read <= ibus.read & ~ibus.flush_1;
		pipe_addr <= ibus.address;
	end else if(~ibus.stall) begin
		pipe_read <= ibus.read;
		pipe_addr <= ibus.address;
	end

	if(rst) begin
		hit       <= '0;
	end else begin
		hit[pipe_addr[ADDR_WIDTH-1:2+$clog2(CACHE_LINE)]] <= 1'b1;
	end
end

logic cache_miss;
assign cache_miss = pipe_read & ~hit[pipe_addr[ADDR_WIDTH-1:2+$clog2(CACHE_LINE)]];

logic [4:0] stall;
always_ff @(posedge clk or posedge rst) begin
	if(rst || ibus.flush_2) begin
		stall <= '0;
	end else if(cache_miss & ~(|stall)) begin
		stall <= 5'b10000;
	end else begin
		stall <= stall >> 1;
	end
end

always_ff @(posedge clk) begin
	if(rst || ~pipe_read) begin
		ibus.rddata       <= 'x;
		ibus.rddata_extra <= 'x;
	end else begin
		ibus.rddata_extra[63:32] <= mem[pipe_addr[ADDR_WIDTH-1:2] + 3];
		ibus.rddata_extra[31:0]  <= mem[pipe_addr[ADDR_WIDTH-1:2] + 2];
		ibus.rddata[63:32]       <= mem[pipe_addr[ADDR_WIDTH-1:2] + 1];
		ibus.rddata[31:0]        <= mem[pipe_addr[ADDR_WIDTH-1:2]];
	end
end

always_comb
begin
	if(rst || ~pipe_read)
	begin
		ibus.stall  = 1'b0;
		ibus.rddata = 'x;
	end else begin
		ibus.stall  = (cache_miss | (|stall)) & fake_stall_en & ~ibus.flush_2;
	end
end

endmodule 
