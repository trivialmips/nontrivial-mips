`include "cpu_defs.svh"

module hilo_forward(
	// from MM
	input  pipeline_exec_t  [1:0][`ISSUE_NUM-1:0] pipe_dcache,

	input  uint64_t   hilo_i,
	output uint64_t   hilo_o
);

always_comb begin
	hilo_o = hilo_i;
	for(int k = 1; k >= 0; --k) begin
		for(int i = 0; i < `ISSUE_NUM; ++i) begin
			if(pipe_dcache[k][i].hiloreq.we)
				hilo_o = pipe_dcache[k][i].hiloreq.wdata;
		end
	end
end

endmodule
