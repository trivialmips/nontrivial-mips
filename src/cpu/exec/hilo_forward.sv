`include "cpu_defs.svh"

module hilo_forward(
	// from MM
	input  pipeline_exec_t  [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] pipe_dcache,
	input  pipeline_memwb_t [`ISSUE_NUM-1:0] pipe_wb,

	input  uint64_t   hilo_i,
	output uint64_t   hilo_o
);

always_comb begin
	hilo_o = hilo_i;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		if(pipe_wb[i].hiloreq.we)
			hilo_o = pipe_wb[i].hiloreq.wdata;
	end

	for(int k = `DCACHE_PIPE_DEPTH - 1; k >= 0; --k) begin
		for(int i = 0; i < `ISSUE_NUM; ++i) begin
			if(pipe_dcache[k][i].hiloreq.we)
				hilo_o = pipe_dcache[k][i].hiloreq.wdata;
		end
	end
end

endmodule
