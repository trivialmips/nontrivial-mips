`include "cpu_defs.svh"

module ctrl(
	input  logic rst,
	input  logic stall_from_id,
	input  logic stall_from_ex,
	input  logic stall_from_mm,
	output logic stall_if,
	output logic stall_id,
	output logic stall_ro,
	output logic stall_ex,
	output logic stall_mm,
	output logic flush_if,
	output logic flush_id,
	output logic flush_ro,
	output logic flush_ex,
	output logic flush_mm,
	output logic flush_delayed_mispredict,

	input  pipeline_exec_t   [`DCACHE_PIPE_DEPTH-1:0][1:0] pipeline_dcache,

	input  except_req_t      except_req,
	input  pipeline_exec_t   [1:0] pipeline_exec,
	input  branch_resolved_t [1:0] ex_resolved_branch,
	input  branch_resolved_t [1:0] delayed_resolved_branch,
	// mispredict but delayslot does not executed
	output logic   delayslot_not_exec,
	output logic   hold_resolved_branch
);

logic [4:0] stall, flush;
assign { stall_if, stall_id, stall_ro, stall_ex, stall_mm } = stall;
assign { flush_if, flush_id, flush_ro, flush_ex, flush_mm } = flush;

logic mispredict, delayed_mispredict;
assign mispredict = ex_resolved_branch[0].valid & ex_resolved_branch[0].mispredict;
assign delayed_mispredict = delayed_resolved_branch[0].valid & delayed_resolved_branch[0].mispredict;

assign hold_resolved_branch = (mispredict & (stall_ex | stall_mm) & ~flush_id);

logic flush_mispredict;
assign delayslot_not_exec = ex_resolved_branch[0].valid & ~pipeline_exec[1].valid;

logic mispredict_with_delayslot;
assign mispredict_with_delayslot = mispredict & pipeline_exec[1].valid;

assign flush_delayed_mispredict = delayed_mispredict;

assign flush_mispredict = (mispredict)
	& ~delayslot_not_exec
	// when a multi-cycle instruction does not finished, we do not resolve a branch
	& ~stall_from_ex
	// delayslot cannot pass
	& ~(mispredict_with_delayslot & stall_ex);

function logic is_memory(input pipeline_exec_t pipe);
	return pipe.memreq.read | pipe.memreq.write;
endfunction

function logic is_uncached(input pipeline_exec_t pipe);
	return is_memory(pipe) & pipe.memreq.uncached;
endfunction

always_comb begin
	flush = '0;
	if(flush_delayed_mispredict) begin
		flush = 5'b11111;
	end else if(except_req.valid) begin
		flush = { 3'b111, {2{except_req.alpha_taken | except_req.delayslot}} };
	end else if(flush_mispredict) begin
		flush = 5'b11100;
	end
end

always_comb begin
	if(rst)
		stall = 5'b11111;
	else if(stall_from_mm)
		stall = 5'b11111;
	else if(stall_from_ex)
		stall = 5'b11110;
	else if(stall_from_id)
		stall = 5'b11000;
	else stall = '0;
end

endmodule
