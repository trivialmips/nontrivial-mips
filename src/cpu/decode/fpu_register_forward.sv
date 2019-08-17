`include "cpu_defs.svh"

module fpu_register_forward(
	input  decoded_instr_t   decoded_instr,

	input  pipeline_exec_t   [`ISSUE_NUM-1:0] pipeline_exec,
	input  pipeline_exec_t   [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] pipeline_dcache,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_mem,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_wb,

	// from regfile
	input  uint32_t   reg1_i,
	input  uint32_t   reg2_i,
	input  fpu_fcsr_t fcsr_i,

	// results
	output uint32_t   reg1_o,
	output uint32_t   reg2_o,
	output fpu_fcsr_t fcsr_o
);

reg_addr_t [1:0] pack_rs;
uint32_t [1:0] pack_reg_o;

assign reg1_o = pack_reg_o[0];
assign reg2_o = pack_reg_o[1];
assign pack_rs[0] = decoded_instr.fs1;
assign pack_rs[1] = decoded_instr.fs2;

always_comb begin
	pack_reg_o[0] = reg1_i;
	pack_reg_o[1] = reg2_i;
	fcsr_o = fcsr_i;

	for(int i = 0; i < 2; ++i) begin
		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			if(pipeline_wb[j].fpu_req.we
				&& pipeline_wb[j].fpu_req.waddr == pack_rs[i])
				pack_reg_o[i] = pipeline_wb[j].fpu_req.wdata;
			if(pipeline_wb[j].fpu_req.fcsr_we)
				fcsr_o = pipeline_wb[j].fpu_req.fcsr;
		end

		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			if(pipeline_mem[j].fpu_req.we
				&& pipeline_mem[j].fpu_req.waddr == pack_rs[i])
				pack_reg_o[i] = pipeline_mem[j].fpu_req.wdata;
			if(pipeline_mem[j].fpu_req.fcsr_we)
				fcsr_o = pipeline_mem[j].fpu_req.fcsr;
		end

		for(int k = `DCACHE_PIPE_DEPTH - 2; k >= 0; --k) begin
			for(int j = 0; j < `ISSUE_NUM; ++j) begin
				if(pipeline_dcache[k][j].fpu_req.we
					&& pipeline_dcache[k][j].fpu_req.waddr == pack_rs[i])
					pack_reg_o[i] = pipeline_dcache[k][j].fpu_req.wdata;
				if(pipeline_dcache[k][j].fpu_req.fcsr_we)
					fcsr_o = pipeline_dcache[k][j].fpu_req.fcsr;
			end
		end

		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			if(pipeline_exec[j].fpu_req.we
				&& pipeline_exec[j].fpu_req.waddr == pack_rs[i])
				pack_reg_o[i] = pipeline_exec[j].fpu_req.wdata;
			if(pipeline_exec[j].fpu_req.fcsr_we)
				fcsr_o = pipeline_exec[j].fpu_req.fcsr;
		end
	end
end

endmodule
