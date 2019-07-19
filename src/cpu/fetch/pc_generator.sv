`include "cpu_defs.svh"

module pc_generator(
	input  logic   clk,
	input  logic   rst,
	input  logic   hold_pc,

	// exception
	input  logic   except_valid,
	input  virt_t  except_vec,

	// branch prediction
	input  logic   predict_valid,
	input  virt_t  predict_vaddr,
	
	// branch misprediction
	input  branch_resolved_t resolved_branch,

	output virt_t  pc
);

virt_t pc_now, npc;

always_comb begin
	// fetch address, i.e. current PC
	pc  = predict_valid ? predict_vaddr : pc_now;
	
	// default
	npc = { pc[31:3] + 1, 3'b0 };

	// branch prediction
	if(predict_valid) npc = predict_vaddr;

	// hold pc
	if(hold_pc) npc = pc_now;

	// branch misprediction
	if(resolved_branch.valid & resolved_branch.mispredict)
		npc = resolved_branch.taken ? resolved_branch.target : resolved_branch.pc + 32'd8;

	// exception
	if(except_valid) npc = except_vec;
end

always_ff @(posedge clk) begin
	if(rst) pc_now <= `BOOT_VEC;
	else    pc_now <= npc;
end

endmodule
