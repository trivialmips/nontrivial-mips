`include "cpu_defs.svh"

module hilo(
	input  logic    clk,
	input  logic    rst,
	input  logic    flush,

	input  logic    lock,
	input  logic    commit,
	output logic    ready,

	input  logic    data_valid,

	input  uint64_t data_i,
	output uint64_t data_o
); 

logic locked;
uint64_t hilo_reg, hilo_tmp;

assign ready  = ~locked;
assign data_o = hilo_reg;

always_ff @(posedge clk)
begin
	if(rst || flush || commit) begin
		locked <= 1'b0;
	end else if(lock) begin
		locked <= 1'b1;
	end

	if(rst || flush) begin
		hilo_tmp <= '0;
	end else if(data_valid) begin
		hilo_tmp <= data_i;
	end else if(lock) begin
		hilo_tmp <= hilo_reg;
	end

	if(rst) begin
		hilo_reg <= '0;
	end else if(commit) begin
		hilo_reg <= hilo_tmp;
	end
end

endmodule
