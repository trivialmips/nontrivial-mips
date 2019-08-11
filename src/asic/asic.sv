
module asic(
	input  logic  clk,
	input  logic  rst,

	input  logic  we,

	input  logic  endian,
	input  logic  [6:0]  chip,
	input  logic  [7:0]  address,
	input  logic  [31:0] wdata,
	output logic  [31:0] rdata
);

localparam AES_CHIP = 1;

logic [31:0] rdata_n, wdata_q;
logic [31:0] aes_rdata;

always_comb begin
	unique case(chip)
		AES_CHIP: rdata_n = aes_rdata;
		default:  rdata_n = '0;
	endcase

	if(endian) begin
		rdata_n = {
			rdata_n[7:0],
			rdata_n[15:8],
			rdata_n[23:16],
			rdata_n[31:24]
		};
	end
end

always_comb begin
	wdata_q = wdata;
	if(endian) begin
		wdata_q = {
			wdata_q[7:0],
			wdata_q[15:8],
			wdata_q[23:16],
			wdata_q[31:24]
		};
	end
end

always_ff @(posedge clk) begin
	if(rst) rdata <= '0;
	else    rdata <= rdata_n;
end

aes aes_inst(
	.clk,
	.reset_n ( ~rst             ),
	.cs      ( chip == AES_CHIP ),
	.we,
	.address,
	.write_data ( wdata_q   ),
	.read_data  ( aes_rdata )
);

endmodule
