`include "cpu_defs.svh"

module instr_commit(
	// commit ROB
	input  rob_packet_t  rob_packet,
	output logic         rob_ack,

	// register requests
	output logic             [1:0] reg_we,
	output reg_addr_t        [1:0] reg_waddr,
	output uint32_t          [1:0] reg_wdata,
	output register_status_t [1:0] reg_status,

	// commit flush request
	output logic         commit_flush,
	output virt_t        commit_flush_pc
);

// commit registers
for(genvar i = 0; i < 2; ++i) begin: gen_reg_requests
	assign reg_we[i]    = rob_packet[i].valid & ~rob_packet[i].busy;
	assign reg_waddr[i] = rob_packet[i].dest;
	assign reg_wdata[i] = rob_packet[i].value;
end

assign rob_ack = ~rob_packet[0].busy & ~rob_packet[1].busy;
assign commit_flush    = 1'b0;
assign commit_flush_pc = '0;

endmodule
