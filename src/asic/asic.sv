
module asic(
	input  logic  clk,
	input  logic  rst,

	input  logic  we,

	input  logic  [7:0]  chip,
	input  logic  [7:0]  address,
	input  logic  [31:0] wdata,
	output logic  [31:0] rdata
);

localparam AES_CHIP = 1;

logic [31:0] rdata_n;
logic [31:0] aes_rdata;

always_comb begin
	unique case(address)
		AES_CHIP: rdata_n = aes_rdata;
		default:  rdata_n = '0;
	endcase
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
	.write_data ( wdata ),
	.read_data  ( aes_rdata )
);

endmodule
