`include "cpu_defs.svh"

module instr_commit(
	// commit ROB
	input  rob_packet_t  rob_packet,
	input  rob_index_t   [1:0] rob_reorder,
	input  logic         rob_empty,
	output logic         rob_ack,

	// register requests
	output logic             [1:0] reg_we,
	output reg_addr_t        [1:0] reg_waddr,
	output uint32_t          [1:0] reg_wdata,

	// resolved branch
	output branch_resolved_t resolved_branch,

	// exception
	output except_req_t  except_req,
	input  cp0_regs_t    cp0_regs,
	input  logic         locked_eret,
	input  logic [7:0]   interrupt_flag,

	// commit CP0
	output logic         commit_cp0,

	// commit flush request
	output logic         commit_flush,
	output virt_t        commit_flush_pc
);

// commit registers
assign reg_we[0] = rob_ack & rob_packet[0].valid & ~(except_req.valid & except_req.alpha_taken);
assign reg_we[1] = rob_ack & rob_packet[1].valid & ~except_req.valid;
for(genvar i = 0; i < 2; ++i) begin: gen_reg_requests
	assign reg_waddr[i] = rob_packet[i].dest;
	assign reg_wdata[i] = rob_packet[i].value;
end


assign commit_cp0      = rob_ack && rob_packet[0].fu == FU_CP0 && ~except_req.valid;
assign resolved_branch = rob_ack ? rob_packet[0].data.resolved_branch : '0;

assign rob_ack = ~rob_empty & ~rob_packet[0].busy & ~rob_packet[1].busy;
assign commit_flush    = 1'b0;
assign commit_flush_pc = '0;

except except_inst(
	.rst ( ~rob_ack ),
	.locked_eret,
	.rob_packet,
	.cp0_regs,
	.interrupt_flag ( '0 ),
	.except_req
);

endmodule
