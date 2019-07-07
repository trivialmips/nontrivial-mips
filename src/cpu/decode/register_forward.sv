`include "cpu_defs.svh"

module register_forward(
	input  uint32_t        instr,
	input  decoded_instr_t decoded_instr,

	// from EX
	input  reg_addr_t [`ISSUE_NUM-1:0] ex_waddr,
	input  uint32_t   [`ISSUE_NUM-1:0] ex_wdata,

	// from D$
	input  reg_addr_t [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] dcache_waddr,
	input  uint32_t   [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] dcache_wdata,

	// from MM
	input  reg_addr_t [`ISSUE_NUM-1:0] mm_waddr,
	input  uint32_t   [`ISSUE_NUM-1:0] mm_wdata,

	// from WB
	input  reg_addr_t [`ISSUE_NUM-1:0] wb_waddr,
	input  uint32_t   [`ISSUE_NUM-1:0] wb_wdata,

	// from regfile
	input  uint32_t   reg1_i,
	input  uint32_t   reg2_i,

	// results
	output uint32_t   reg1_o,
	output uint32_t   reg2_o
);

reg_addr_t [1:0] pack_rs;
uint32_t [1:0] pack_reg_o;

assign reg1_o = pack_reg_o[0];
assign reg2_o = pack_reg_o[1];
assign pack_rs[0] = decoded_instr.rs1;
assign pack_rs[1] = decoded_instr.rs2;

always_comb begin
	pack_reg_o[0] = reg1_i;
	pack_reg_o[1] = reg2_i;

	for(int i = 0; i < 2; ++i) begin
		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			if(wb_waddr[j] == pack_rs[i])
				pack_reg_o[i] = wb_wdata[j];
		end

		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			if(mm_waddr[j] == pack_rs[i])
				pack_reg_o[i] = mm_wdata[j];
		end

		for(int k = `DCACHE_PIPE_DEPTH - 2; k >= 0; --k) begin
			for(int j = 0; j < `ISSUE_NUM; ++j) begin
				if(dcache_waddr[k][j] == pack_rs[i])
					pack_reg_o[i] = dcache_wdata[k][j];
			end
		end

		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			if(ex_waddr[j] == pack_rs[i])
				pack_reg_o[i] = ex_wdata[j];
		end

		if(pack_rs[i] == '0)
			pack_reg_o[i] = '0;
	end


	if(decoded_instr.use_imm) begin
		pack_reg_o[1] = { {16{instr[15] & decoded_instr.imm_signed}}, instr[15:0] };
	end
end

endmodule
