module dual_port_ram #(
	// default data width if the fifo is of type logic
	parameter int unsigned DATA_WIDTH = 32,
	// $bits(dtype) * SIZE = bits of the block RAM
	parameter int unsigned SIZE       = 1024,
	parameter type dtype              = logic [DATA_WIDTH-1:0],
	parameter int unsigned USE_LUTRAM = 0,
	parameter int unsigned LATENCY    = 1
) (
	input  logic  clk,
	input  logic  rst,
	input  logic  wea,
	input  logic  web,
	input  logic  ena,
	input  logic  enb,
	input  logic  [$clog2(SIZE)-1:0] addra,
	input  logic  [$clog2(SIZE)-1:0] addrb,
	input  dtype  dina,
	input  dtype  dinb,
	output dtype  douta,
	output dtype  doutb
);

generate if(~USE_LUTRAM) begin
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
	.READ_LATENCY_A(LATENCY),
	.WRITE_MODE_A("write_first"),

	// Port B module parameters
	.WRITE_DATA_WIDTH_B($bits(dtype)),
	.READ_DATA_WIDTH_B($bits(dtype)),
	.READ_RESET_VALUE_B("0"),
	.READ_LATENCY_B(LATENCY),
	.WRITE_MODE_B("write_first")
) xpm_mem (
	// Common module ports
	.sleep          ( 1'b0  ),

	// Port A module ports
	.clka           ( clk   ),
	.rsta           ( rst   ),
	.ena            ( ena   ),
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
	.enb            ( enb   ),
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

end else begin
// xpm_memory_dpdistram: Dual Port Distributed RAM
// Xilinx Parameterized Macro, Version 2016.2
xpm_memory_dpdistram #(
	// Common module parameters
	.MEMORY_SIZE($bits(dtype) * SIZE),
	.MEMORY_PRIMITIVE("auto"),
	.CLOCKING_MODE("common_clock"),
	.USE_MEM_INIT(0),
	.MESSAGE_CONTROL(0),

	// Port A module parameters
	.WRITE_DATA_WIDTH_A($bits(dtype)),
	.READ_DATA_WIDTH_A($bits(dtype)),
	.READ_RESET_VALUE_A("0"),
	.READ_LATENCY_A(LATENCY),

	// Port B module parameters
	.WRITE_DATA_WIDTH_B($bits(dtype)),
	.READ_DATA_WIDTH_B($bits(dtype)),
	.READ_RESET_VALUE_B("0"),
	.READ_LATENCY_B(LATENCY)
) xpm_mem (
	// Port A module ports
	.clka           ( clk   ),
	.rsta           ( rst   ),
	.ena            ( ena   ),
	.regcea         ( 1'b0  ),
	.wea            ( wea   ),
	.addra          ( addra ),
	.dina           ( dina  ),
	.douta          ( douta ),

	// Port B module ports
	.clkb           ( clk   ),
	.rstb           ( rst   ),
	.enb            ( enb   ),
	.regceb         ( 1'b0  ),
	.web            ( web   ),
	.addrb          ( addrb ),
	.dinb           ( dinb  ),
	.doutb          ( doutb )
);
end
endgenerate

endmodule

