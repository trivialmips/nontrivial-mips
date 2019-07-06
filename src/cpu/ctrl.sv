`include "cpu_defs.svh"

module ctrl(
	input  logic rst_n,
	input  logic stall_from_id,
	input  logic stall_from_ex,
	input  logic stall_from_mm,
	output logic stall_if,
	output logic stall_id,
	output logic stall_ex,
	output logic stall_mm,
	output logic flush_if,
	output logic flush_id,
	output logic flush_ex,
	output logic flush_mm
);

logic [3:0] stall, flush;
assign { stall_if, stall_id, stall_ex, stall_mm } = stall;
assign { flush_if, flush_id, flush_ex, flush_mm } = flush;

always_comb begin
	if(~rst_n) begin
		stall = 4'b1111;
		flush = '0;
	end else if(stall_from_mm) begin
		stall = 4'b1111;
		flush = 4'b0000;
	end else if(stall_from_ex) begin
		stall = 4'b1110;
		flush = 4'b0000;
	end else if(stall_from_id) begin
		stall = 4'b1100;
		flush = 4'b0000;
	end else begin
		stall = '0;
		flush = '0;
	end
end

endmodule
