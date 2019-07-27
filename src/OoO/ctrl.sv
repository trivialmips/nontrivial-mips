`include "cpu_defs.svh"

module ctrl(
	output logic flush_if,
	output logic flush_ex,
	output logic flush_rob,
	output logic flush_regstat,

	input  branch_resolved_t resolved_branch
);

logic flush_mispredict;
assign flush_mispredict = resolved_branch.valid & resolved_branch.mispredict;

assign flush_if  = flush_mispredict;
assign flush_rob = flush_mispredict;
assign flush_ex  = flush_mispredict;
assign flush_regstat = flush_mispredict;

endmodule
