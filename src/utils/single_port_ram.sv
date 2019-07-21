module single_port_ram #(
	// default data width if the fifo is of type logic
	parameter int unsigned DATA_WIDTH = 32,
	// $bits(dtype) * SIZE = bits of the block RAM
	parameter int unsigned SIZE       = 1024,
	parameter type dtype              = logic [DATA_WIDTH-1:0],
	parameter int unsigned LATENCY    = 1
) (
	input  logic  clk,
	input  logic  rst,
	input  logic  we,
	input  logic  [$clog2(SIZE)-1:0] addr,
	input  dtype  din,
	output dtype  dout
);

// xpm_memory_spram: Single Port RAM
// Xilinx Parameterized Macro, Version 2016.2
xpm_memory_spram #(
	// Common module parameters
	.MEMORY_SIZE($bits(dtype) * SIZE),
	.MEMORY_PRIMITIVE("auto"),
	.USE_MEM_INIT(0),
	.WAKEUP_TIME("disable_sleep"),
	.MESSAGE_CONTROL(0),

	// Port A module parameters
	.WRITE_DATA_WIDTH_A($bits(dtype)),
	.READ_DATA_WIDTH_A($bits(dtype)),
	.READ_RESET_VALUE_A("0"),
	.READ_LATENCY_A(LATENCY),
	.WRITE_MODE_A("write_first")
) xpm_mem (
	// Common module ports
	.sleep          ( 1'b0  ),

	// Port A module ports
	.clka           ( clk   ),
	.rsta           ( rst   ),
	.ena            ( 1'b1  ),
	.regcea         ( 1'b0  ),
	.wea            ( we    ),
	.addra          ( addr  ),
	.dina           ( din   ),
	.injectsbiterra ( 1'b0  ), // do not change
	.injectdbiterra ( 1'b0  ), // do not change
	.douta          ( dout  ),
	.sbiterra       (       ), // do not change
	.dbiterra       (       )  // do not change
);

endmodule

module single_port_byte_ram #(
	parameter int unsigned BYTES_WIDTH = 4,
	// BYTES_WIDTH * SIZE * 8 = bits of the block RAM
	parameter int unsigned SIZE        = 1024
) (
	input  logic  clk,
	input  logic  rst,
	input  logic  we,
	input  logic  [BYTES_WIDTH-1:0]   byteenable,
	input  logic  [$clog2(SIZE)-1:0]  addr,
	input  logic  [BYTES_WIDTH*8-1:0] din,
	output logic  [BYTES_WIDTH*8-1:0] dout
);

logic [BYTES_WIDTH-1:0][7:0] bytes_i, bytes_o;

for(genvar i = 0; i < BYTES_WIDTH; ++i) begin : gen_spram
	assign bytes_i[i] = din[i * 8 + 7 : i * 8];
	assign dout[i * 8 + 7 : i * 8] = bytes_o[i];

	xpm_memory_spram #(
		// Common module parameters
		.MEMORY_SIZE(8 * SIZE),
		.MEMORY_PRIMITIVE("auto"),
		.USE_MEM_INIT(0),
		.WAKEUP_TIME("disable_sleep"),
		.MESSAGE_CONTROL(0),

		// Port A module parameters
		.WRITE_DATA_WIDTH_A(8),
		.READ_DATA_WIDTH_A(8),
		.READ_RESET_VALUE_A("0"),
		.READ_LATENCY_A(1),
		.WRITE_MODE_A("write_first")
	) xpm_mem (
		// Common module ports
		.sleep          ( 1'b0               ),

		// Port A module ports
		.clka           ( clk                ),
		.rsta           ( rst                ),
		.ena            ( 1'b1               ),
		.regcea         ( 1'b0               ),
		.wea            ( we & byteenable[i] ),
		.addra          ( addr               ),
		.dina           ( bytes_i[i]         ),
		.injectsbiterra ( 1'b0               ), // do not change
		.injectdbiterra ( 1'b0               ), // do not change
		.douta          ( bytes_o[i]         ),
		.sbiterra       (                    ), // do not change
		.dbiterra       (                    )  // do not change
	);
end

endmodule
