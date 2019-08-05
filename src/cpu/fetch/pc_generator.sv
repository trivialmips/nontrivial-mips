`include "cpu_defs.svh"

module pc_generator(
	input  logic   clk,
	input  logic   rst,
	input  logic   ready,
	input  logic   hold_pc,

	// exception
	input  logic   except_valid,
	input  virt_t  except_vec,

	// branch prediction
	input  logic   predict_delayed,
	input  logic   predict_valid,
	input  virt_t  predict_vaddr,

	// branch presolved
	input  presolved_branch_t presolved_branch,
	
	// branch misprediction
	input  logic             hold_resolved_branch,
	input  branch_resolved_t resolved_branch,

	// delayed branch misprediction
	input  branch_resolved_t delayed_resolved_branch,

	// replay
	input  logic   replay_valid,
	input  virt_t  replay_vaddr,

	output virt_t  pc,
	output logic   pc_en
);

virt_t pc_now, npc;

always_comb begin
	// fetch address, i.e. current PC
	pc  = predict_valid & ~predict_delayed ? predict_vaddr : pc_now;
	
	// default
	npc = { pc[31:3] + 1, 3'b0 };

	// fetch delayslot
	if(predict_delayed)
		npc = predict_vaddr;

	// hold pc
	if(hold_pc) npc = pc_now;

	// branch presolved misprediction
	if(presolved_branch.mispredict)
		npc = presolved_branch.target;

	// replay
	if(replay_valid)
		npc = replay_vaddr;

	// branch misprediction
	if(resolved_branch.valid & resolved_branch.mispredict & ~hold_resolved_branch)
		npc = resolved_branch.taken ? resolved_branch.target : resolved_branch.pc + 32'd8;

	// exception
	if(except_valid) npc = except_vec;

	// delayed branch misprediction
	if(delayed_resolved_branch.valid & delayed_resolved_branch.mispredict)
		npc = delayed_resolved_branch.taken ? delayed_resolved_branch.target : delayed_resolved_branch.pc + 32'd8;
end

assign pc_en = ready;
always_ff @(posedge clk) begin
	if(rst || ~pc_en) begin
		pc_now <= `BOOT_VEC;
	end else begin
		pc_now <= npc;
	end
end

endmodule
