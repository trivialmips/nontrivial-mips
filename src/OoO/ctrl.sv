`include "cpu_defs.svh"

module ctrl(
	output logic flush_if,
	output logic flush_is,
	output logic flush_ex,
	output logic flush_cp0,
	output logic flush_rob,
	output logic flush_regstat,

	input  except_req_t      except_req,
	input  branch_resolved_t resolved_branch
);

logic flush_mispredict, flush_except, flush_all;
assign flush_mispredict = resolved_branch.valid & resolved_branch.mispredict;
assign flush_except = except_req.valid;

assign flush_all = flush_mispredict | flush_except;

assign flush_if      = flush_all;
assign flush_is      = flush_all;
assign flush_rob     = flush_all;
assign flush_ex      = flush_all;
assign flush_cp0     = flush_all;
assign flush_regstat = flush_all;

endmodule
