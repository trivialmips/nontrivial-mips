`include "cpu_defs.svh"

module cp0_forward(
	// from MM
	input  pipeline_memwb_t [`ISSUE_NUM-1:0] pipe_mm,
	input  pipeline_memwb_t [`ISSUE_NUM-1:0] pipe_wb,

	input  uint32_t  data_i,
	output uint32_t  data_o
);

always_comb begin
	data_o = data_i;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		if(pipe_wb[i].datareq.we)
			data_o = pipe_wb[i].datareq.wdata;
	end

	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		if(pipe_mm[i].datareq.we)
			data_o = pipe_mm[i].datareq.wdata;
	end
end

endmodule
