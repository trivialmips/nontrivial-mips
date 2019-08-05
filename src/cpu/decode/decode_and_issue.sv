`include "cpu_defs.svh"

module decode_and_issue(
	input logic clk,
	input logic rst,
	input logic stall_id,
	input logic stall_ro,
	input logic flush_ro,

	input  logic	     delayslot_not_exec,
	input  fetch_entry_t     [`ISSUE_NUM-1:0] fetch_entry,
	input  pipeline_exec_t   [`ISSUE_NUM-1:0] pipeline_exec,
	input  pipeline_exec_t   [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] pipeline_dcache,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_mem,
	input  pipeline_memwb_t  [`ISSUE_NUM-1:0] pipeline_wb,
	output pipeline_decode_t [`ISSUE_NUM-1:0] pipeline_decode,
	output logic   [$clog2(`ISSUE_NUM+1)-1:0] issue_num,

	output logic       stall_from_id,

	output reg_addr_t  [`ISSUE_NUM * 2 - 1:0] reg_raddr,
	input  uint32_t    [`ISSUE_NUM * 2 - 1:0] reg_rdata
);

pipeline_decode_t [`ISSUE_NUM-1:0] pipeline_issue, pipeline_issue_d;
decoded_instr_t [`ISSUE_NUM-1:0] ex_decoded, id_decoded;
decoded_instr_t [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] dcache_decoded;
decoded_instr_t [`ISSUE_NUM-1:0] issue_instr;

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_decoder_info
	assign id_decoded[i]        = fetch_entry[i].decoded;
	assign ex_decoded[i]        = pipeline_issue_d[i].decoded;
	assign dcache_decoded[0][i] = pipeline_exec[i].decoded;
	assign dcache_decoded[1][i] = pipeline_dcache[0][i].decoded;
	assign dcache_decoded[2][i] = pipeline_dcache[1][i].decoded;
end

instr_issue issue_inst(
	.fetch_entry,
	.id_decoded,
	.ex_decoded,
	.dcache_decoded,
	.delayslot_not_exec,
	.issue_instr,
	.issue_num,
	.stall_req  ( stall_from_id )
);

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_issue
	assign pipeline_issue[i].fetch   = fetch_entry[i];
	assign pipeline_issue[i].reg1    = '0;
	assign pipeline_issue[i].reg2    = '0;
	assign pipeline_issue[i].decoded = issue_instr[i];
	assign pipeline_issue[i].valid   = (i < issue_num);
end

/* Pipeline between IS and RO */
always_ff @(posedge clk) begin
	if(rst || flush_ro || (stall_id && ~stall_ro)) begin
		pipeline_issue_d <= '0;
	end else if(~stall_ro) begin
		pipeline_issue_d <= pipeline_issue;
	end
end

/* Read Operands Stage */
reg_addr_t [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] dcache_waddr;
uint32_t   [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] dcache_wdata;
reg_addr_t [`ISSUE_NUM - 1:0] ex_waddr, mm_waddr, wb_waddr;
uint32_t   [`ISSUE_NUM - 1:0] ex_wdata, mm_wdata, wb_wdata;
uint32_t   [`ISSUE_NUM * 2 - 1:0] reg_forward;
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_ro_info
	assign reg_raddr[i * 2]     = pipeline_issue_d[i].decoded.rs1;
	assign reg_raddr[i * 2 + 1] = pipeline_issue_d[i].decoded.rs2;
	assign ex_waddr[i] = pipeline_exec[i].decoded.rd;
	assign ex_wdata[i] = pipeline_exec[i].result;
	assign mm_waddr[i] = pipeline_mem[i].rd;
	assign mm_wdata[i] = pipeline_mem[i].wdata;
	assign wb_waddr[i] = pipeline_wb[i].rd;
	assign wb_wdata[i] = pipeline_wb[i].wdata;
	for(genvar j = 0; j < `DCACHE_PIPE_DEPTH; ++j) begin : gen_dcache_reg
		assign dcache_waddr[j][i] = pipeline_dcache[j][i].decoded.rd;
		assign dcache_wdata[j][i] = pipeline_dcache[j][i].result;
	end

	register_forward reg_forward_inst(
		.*, // forward from EX/D$/MM/WB
		.instr         ( pipeline_issue_d[i].fetch.instr ),
		.decoded_instr ( pipeline_issue_d[i].decoded     ),
		.reg1_i        ( reg_rdata[i * 2]       ),
		.reg2_i        ( reg_rdata[i * 2 + 1]   ),
		.reg1_o        ( reg_forward[i * 2]     ),
		.reg2_o        ( reg_forward[i * 2 + 1] )
	);
end

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_ro
	assign pipeline_decode[i].reg1    = reg_forward[i * 2];
	assign pipeline_decode[i].reg2    = reg_forward[i * 2 + 1];
	assign pipeline_decode[i].fetch   = pipeline_issue_d[i].fetch;
	assign pipeline_decode[i].decoded = pipeline_issue_d[i].decoded;
	assign pipeline_decode[i].valid   = pipeline_issue_d[i].valid;
end

endmodule
