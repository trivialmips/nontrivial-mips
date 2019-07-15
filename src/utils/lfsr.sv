
module lfsr_32bits(
	input  logic clk,
	input  logic rst,
	input  logic update,
	output reg [31:0] val
);

logic [31:0] mov_val;
// x^32 + x^30 + x^11 + x^5 + 1
assign mov_val = (val >> 0) ^ (val >> 2) ^ (val >> 21) ^ (val >> 27);

always @(posedge clk)
begin
	if(rst) begin
		val <= 32'hdeadface;
	end else if(update) begin
		val[30:0] <= val[31:1];
		val[31]   <= mov_val[0];
	end
end

endmodule 

module lfsr_8bits(
	input  logic clk,
	input  logic rst,
	input  logic update,
	output reg [7:0] val
);

logic feedback;
assign feedback = val[7];

always @(posedge clk) begin
	if(rst) begin
		val <= 8'd255;
	end else if(update) begin
		val[0] <= feedback;
		val[1] <= val[0];
		val[2] <= val[1] ^ feedback;
		val[3] <= val[2] ^ feedback;
		val[4] <= val[3] ^ feedback;
		val[5] <= val[4];
		val[6] <= val[5];
		val[7] <= val[6];
	end
end

endmodule
