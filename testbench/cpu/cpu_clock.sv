`include "cpu_defs.svh"

module cpu_clock(
	output logic clk,
	output logic rst_n
);

always #20 clk = ~clk;
initial
begin
	rst_n = 1'b0;
	clk   = 1'b0;
	#50 rst_n = 1'b1;
end

endmodule
