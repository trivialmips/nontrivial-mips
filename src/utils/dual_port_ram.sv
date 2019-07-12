module dual_port_ram #(
	// default data width if the fifo is of type logic
	parameter int unsigned DATA_WIDTH = 32,
	// $bits(dtype) * SIZE = bits of the block RAM
	parameter int unsigned SIZE       = 1024,
	parameter type dtype              = logic [DATA_WIDTH-1:0]
) (
	input  logic  clk,
	input  logic  rst,
	input  logic  wea,
	input  logic  web,
	input  logic  [$clog2(SIZE)-1:0] addra,
	input  logic  [$clog2(SIZE)-1:0] addrb,
	input  dtype  dina,
	input  dtype  dinb,
	output dtype  douta,
	output dtype  doutb
);

// xpm_memory_tdpram: True Dual Port RAM
// Xilinx Parameterized Macro, Version 2016.2
xpm_memory_tdpram #(
	// Common module parameters
	.MEMORY_SIZE($bits(dtype) * SIZE),
	.MEMORY_PRIMITIVE("auto"),
	.CLOCKING_MODE("common_clock"),
	.USE_MEM_INIT(0),
	.WAKEUP_TIME("disable_sleep"),
	.MESSAGE_CONTROL(0),

	// Port A module parameters
	.WRITE_DATA_WIDTH_A($bits(dtype)),
	.READ_DATA_WIDTH_A($bits(dtype)),
	.READ_RESET_VALUE_A("0"),
	.READ_LATENCY_A(1),
	.WRITE_MODE_A("write_first"),

	// Port B module parameters
	.WRITE_DATA_WIDTH_B($bits(dtype)),
	.READ_DATA_WIDTH_B($bits(dtype)),
	.READ_RESET_VALUE_B("0"),
	.READ_LATENCY_B(1),
	.WRITE_MODE_B("write_first")
) xpm_mem (
	// Common module ports
	.sleep          ( 1'b0  ),

	// Port A module ports
	.clka           ( clk   ),
	.rsta           ( rst   ),
	.ena            ( 1'b1  ),
	.regcea         ( 1'b0  ),
	.wea            ( wea   ),
	.addra          ( addra ),
	.dina           ( dina  ),
	.injectsbiterra ( 1'b0  ), // do not change
	.injectdbiterra ( 1'b0  ), // do not change
	.douta          ( douta ),
	.sbiterra       (       ), // do not change
	.dbiterra       (       ), // do not change

	// Port B module ports
	.clkb           ( clk   ),
	.rstb           ( rst   ),
	.enb            ( 1'b1  ),
	.regceb         ( 1'b0  ),
	.web            ( web   ),
	.addrb          ( addrb ),
	.dinb           ( dinb  ),
	.injectsbiterrb ( 1'b0  ), // do not change
	.injectdbiterrb ( 1'b0  ), // do not change
	.doutb          ( doutb ),
	.sbiterrb       (       ), // do not change
	.dbiterrb       (       )  // do not change
);

endmodule

module dual_port_byte_ram #(
	parameter int unsigned BYTES_WIDTH = 4,
	// BYTES_WIDTH * SIZE * 8 = bits of the block RAM
	parameter int unsigned SIZE        = 1024
) (
	input  logic  clk,
	input  logic  rst,
	input  logic  wea,
	input  logic  web,
	input  logic  [BYTES_WIDTH-1:0]   byteenablea,
	input  logic  [BYTES_WIDTH-1:0]   byteenableb,
	input  logic  [$clog2(SIZE)-1:0]  addra,
	input  logic  [$clog2(SIZE)-1:0]  addrb,
	input  logic  [BYTES_WIDTH*8-1:0] dina,
	input  logic  [BYTES_WIDTH*8-1:0] dinb,
	output logic  [BYTES_WIDTH*8-1:0] douta,
	output logic  [BYTES_WIDTH*8-1:0] doutb
);

logic [BYTES_WIDTH-1:0][7:0] bytes_ia, bytes_oa, bytes_ib, bytes_ob;

for(genvar i = 0; i < BYTES_WIDTH; ++i) begin : gen_spram
	assign bytes_ia[i] = dina[i * 8 + 7 : i * 8];
	assign douta[i * 8 + 7 : i * 8] = bytes_oa[i];
	assign bytes_ib[i] = dinb[i * 8 + 7 : i * 8];
	assign doutb[i * 8 + 7 : i * 8] = bytes_ob[i];

	xpm_memory_tdpram #(
		// Common module parameters
		.MEMORY_SIZE(8 * SIZE),
		.MEMORY_PRIMITIVE("auto"),
		.CLOCKING_MODE("common_clock"),
		.USE_MEM_INIT(0),
		.WAKEUP_TIME("disable_sleep"),
		.MESSAGE_CONTROL(0),

		// Port A module parameters
		.WRITE_DATA_WIDTH_A(8),
		.READ_DATA_WIDTH_A(8),
		.READ_RESET_VALUE_A("0"),
		.READ_LATENCY_A(1),
		.WRITE_MODE_A("write_first"),

		// Port B module parameters
		.WRITE_DATA_WIDTH_B($bits(dtype)),
		.READ_DATA_WIDTH_B($bits(dtype)),
		.READ_RESET_VALUE_B("0"),
		.READ_LATENCY_B(1),
		.WRITE_MODE_B("write_first")
	) xpm_mem (
		// Common module ports
		.sleep          ( 1'b0                 ),

		// Port A module ports
		.clka           ( clk                  ),
		.rsta           ( rst                  ),
		.ena            ( 1'b1                 ),
		.regcea         ( 1'b0                 ),
		.wea            ( web & byteenableb[i] ),
		.addra          ( addra                ),
		.dina           ( bytes_ia[i]          ),
		.injectsbiterra ( 1'b0                 ), // do not change
		.injectdbiterra ( 1'b0                 ), // do not change
		.douta          ( bytes_oa[i]          ),
		.sbiterra       (                      ), // do not change
		.dbiterra       (                      ), // do not change

		// Port B module ports
		.clkb           ( clk                  ),
		.rstb           ( rst                  ),
		.enb            ( 1'b1                 ),
		.regceb         ( 1'b0                 ),
		.web            ( web & byteenableb[i] ),
		.addrb          ( addrb                ),
		.dinb           ( bytes_ib[i]          ),
		.injectsbiterrb ( 1'b0                 ), // do not change
		.injectdbiterrb ( 1'b0                 ), // do not change
		.doutb          ( bytes_ob[i]          ),
		.sbiterrb       (                      ), // do not change
		.dbiterrb       (                      ), // do not change
	);
end

endmodule
