`include "cpu_defs.svh"

module ctrl(
	input  logic rst,
	input  logic stall_from_id,
	input  logic stall_from_ex,
	input  logic stall_from_mm,
	output logic stall_if,
	output logic stall_id,
	output logic stall_ex,
	output logic stall_mm,
	output logic flush_if,
	output logic [1:0] flush_id,
	output logic flush_ex,
	output logic flush_mm,

	input  except_req_t      except_req,
	input  fetch_entry_t     [`FETCH_NUM-1:0] fetch_entry,
	input  pipeline_exec_t   [1:0] pipeline_exec,
	input  branch_resolved_t [1:0] resolved_branch_i,
	output branch_resolved_t resolved_branch_o,
	// mispredict but delayslot does not executed
	output logic   delayslot_not_exec,
	output logic   hold_resolved_branch
);

logic [3:0] stall;
assign { stall_if, stall_id, stall_ex, stall_mm } = stall;
assign hold_resolved_branch = (stall_ex | stall_mm) & ~(|flush_id);

logic [1:0] mispredict;
for(genvar i = 0; i < 2; ++i) begin : gen_mispredict
	assign mispredict[i] = resolved_branch_i[i].valid & resolved_branch_i[i].mispredict;
end

logic fetch_entry_avail, wait_delayslot, flush_mispredict;
assign delayslot_not_exec = resolved_branch_i[1].valid
	| (resolved_branch_i[0].valid & ~pipeline_exec[1].valid);
assign wait_delayslot = delayslot_not_exec & ~fetch_entry_avail;

// when a multi-cycle instruction does not finished, we do not resolve a branch
assign flush_mispredict = (|mispredict) & ~delayslot_not_exec & ~stall_from_ex;

always_comb begin
	fetch_entry_avail = 1'b0;
	for(int i = 0; i < `FETCH_NUM; ++i)
		fetch_entry_avail |= fetch_entry[i].valid;
end

always_comb begin
	resolved_branch_o = '0;
	for(int i = 0; i < 2; ++i) begin
		if(resolved_branch_i[i].valid)
			resolved_branch_o = resolved_branch_i[i];
	end

	if(wait_delayslot) resolved_branch_o = '0;
end

logic mispredict_with_delayslot;
assign mispredict_with_delayslot = mispredict[0] & pipeline_exec[1].valid;

always_comb begin
	{ flush_if, flush_id, flush_ex, flush_mm } = '0;
	if(except_req.valid) begin
		flush_if = 1'b1;
		flush_id = 2'b11;
		flush_ex = except_req.alpha_taken;
		flush_mm = except_req.alpha_taken;
	end else if(flush_mispredict) begin
		flush_if = 1'b1;
		flush_id[0] = 1'b1;
		flush_id[1] = ~(mispredict_with_delayslot & stall_ex);
		flush_ex = 1'b0;
		flush_mm = 1'b0;
	end
end

always_comb begin
	if(rst)
		stall = 4'b1111;
	else if(stall_from_mm)
		stall = 4'b1111;
	else if(stall_from_ex | wait_delayslot)
		stall = 4'b1110;
	else if(stall_from_id)
		stall = 4'b1100;
	else stall = '0;
end

endmodule
