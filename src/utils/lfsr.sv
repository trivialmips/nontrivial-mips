
module lfsr32(
	input  logic clk,
	input  logic rst,
	output reg [31:0] val
);

logic [31:0] mov_val;
// x^32 + x^30 + x^11 + x^5 + 1
assign mov_val = (val >> 0) ^ (val >> 2) ^ (val >> 21) ^ (val >> 27);

always @(posedge clk or posedge rst)
begin
	if(rst)
	begin
		val <= 32'hdeadface;
	end else begin
		val[30:0] <= val[31:1];
		val[31]   <= mov_val[0];
	end
end

endmodule 
