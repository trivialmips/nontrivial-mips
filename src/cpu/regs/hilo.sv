`include "cpu_defs.svh"

module hilo(
	input  logic    clk,
	input  logic    rst,
	input  logic    we,
	input  uint64_t wrdata,
	output uint64_t rddata
); 

uint64_t reg_hilo;

always @(posedge clk)
begin
	if(rst) begin
		reg_hilo <= '0;
	end else if(we) begin
		reg_hilo <= wrdata;
	end
end

assign rddata = reg_hilo;

endmodule
