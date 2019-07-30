`include "cpu_defs.svh"

module delayed_register_forward(
	input  pipeline_exec_t  data,
	output pipeline_exec_t  result,

	output reg_addr_t        [1:0] reg_raddr,
	input  uint32_t          [1:0] reg_rdata,
	input  pipeline_exec_t   [`ISSUE_NUM-1:0] pipeline_dcache,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_mem,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_wb
);

assign reg_raddr[0] = data.decoded.rs1;
assign reg_raddr[1] = data.decoded.rs2;

uint32_t [1:0] regs;

always_comb begin
	regs = reg_rdata;

	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_wb[j].rd == data.decoded.rs1)
			regs[0] = pipeline_wb[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_mem[j].rd == data.decoded.rs1)
			regs[0] = pipeline_mem[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_dcache[j].decoded.rd == data.decoded.rs1)
			regs[0] = pipeline_dcache[j].result;

	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_wb[j].rd == data.decoded.rs2)
			regs[1] = pipeline_wb[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_mem[j].rd == data.decoded.rs2)
			regs[1] = pipeline_mem[j].wdata;
	for(int j = 0; j < `ISSUE_NUM; ++j)
		if(pipeline_dcache[j].decoded.rd == data.decoded.rs2)
			regs[1] = pipeline_dcache[j].result;

	if(data.decoded.rs2 == '0)
		regs[1] = '0;
	if(data.decoded.use_imm)
		regs[1] = data.delayed_reg[1];
end

always_comb begin
	result = data;
	result.delayed_reg = regs;
end

endmodule
