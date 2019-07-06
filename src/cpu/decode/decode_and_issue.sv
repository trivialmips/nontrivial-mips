`include "cpu_defs.svh"

module decode_and_issue(
	input  logic             delayslot_not_exec,
	input  fetch_entry_t     [`ISSUE_NUM-1:0] fetch_entry,
	input  pipeline_exec_t   [`ISSUE_NUM-1:0] pipeline_exec,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_mem,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_wb,
	output pipeline_decode_t [`ISSUE_NUM-1:0] pipeline_decode,
	output logic   [$clog2(`ISSUE_NUM+1)-1:0] issue_num,

	output logic       stall_req,

	output reg_addr_t  [`ISSUE_NUM * 2 - 1:0] reg_raddr,
	input  uint32_t    [`ISSUE_NUM * 2 - 1:0] reg_rdata
);

decoded_instr_t [`ISSUE_NUM-1:0] decoded_instr;
decoded_instr_t [`ISSUE_NUM-1:0] ex_decoded;
decoded_instr_t [`ISSUE_NUM-1:0] issue_instr;

reg_addr_t  [`ISSUE_NUM - 1:0] ex_waddr, mm_waddr, wb_waddr;
uint32_t    [`ISSUE_NUM - 1:0] ex_wdata, mm_wdata, wb_wdata;
uint32_t    [`ISSUE_NUM * 2 - 1:0] reg_forward;

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_decoder
	assign ex_decoded[i] = pipeline_exec[i].decoded;

	decoder decoder_inst(
		.instr         ( fetch_entry[i].instr ),
		.decoded_instr ( decoded_instr[i] )
	);

	assign reg_raddr[i * 2]     = decoded_instr[i].rs1;
	assign reg_raddr[i * 2 + 1] = decoded_instr[i].rs2;
	assign ex_waddr[i] = pipeline_exec[i].decoded.rd;
	assign ex_wdata[i] = pipeline_exec[i].result;
	assign mm_waddr[i] = pipeline_mem[i].rd;
	assign mm_wdata[i] = pipeline_mem[i].wdata;
	assign wb_waddr[i] = pipeline_wb[i].rd;
	assign wb_wdata[i] = pipeline_wb[i].wdata;

	register_forward reg_forward_inst(
		.*, // forward from EX/MM/WB
		.instr         ( fetch_entry[i].instr   ),
		.decoded_instr ( decoded_instr[i]       ),
		.reg1_i        ( reg_rdata[i * 2]       ),
		.reg2_i        ( reg_rdata[i * 2 + 1]   ),
		.reg1_o        ( reg_forward[i * 2]     ),
		.reg2_o        ( reg_forward[i * 2 + 1] )
	);
end

instr_issue issue_inst(
	.fetch_entry,
	.id_decoded ( decoded_instr ),
	.ex_decoded,
	.delayslot_not_exec,
	.issue_instr,
	.issue_num,
	.stall_req
);

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_issue
	assign pipeline_decode[i].fetch = fetch_entry[i];
	assign pipeline_decode[i].reg1 = reg_forward[i * 2];
	assign pipeline_decode[i].reg2 = reg_forward[i * 2 + 1];
	assign pipeline_decode[i].decoded = issue_instr[i];
	assign pipeline_decode[i].valid = (i < issue_num);
end

endmodule
