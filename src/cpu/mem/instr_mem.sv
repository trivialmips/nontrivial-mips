`include "cpu_defs.svh"

module instr_mem (
	input  uint32_t          cached_rddata,
	input  uint32_t          uncached_rddata,
	input  pipeline_exec_t   data,
	output pipeline_memwb_t  result
);

oper_t op;
uint32_t data_rd;
assign op = data.decoded.op;
assign data_rd = data.memreq.uncached ? uncached_rddata : cached_rddata;
assign result.pc = data.pc;
assign result.valid = data.valid;
assign result.hiloreq = data.hiloreq;

logic [1:0] addr_offset;
uint32_t aligned_data_rd, unaligned_data_rd, ext_sel;
uint32_t signed_ext_byte, signed_ext_half_word;
uint32_t zero_ext_byte, zero_ext_half_word;
uint32_t unaligned_word;
assign aligned_data_rd = data_rd >> (addr_offset * 8);
assign ext_sel = {
	{8{data.memreq.byteenable[3]}},
	{8{data.memreq.byteenable[2]}},
	{8{data.memreq.byteenable[1]}},
	{8{data.memreq.byteenable[0]}}
};
assign addr_offset          = data.memreq.paddr[1:0];
assign signed_ext_byte      = { {24{aligned_data_rd[7]}}, aligned_data_rd[7:0] };
assign signed_ext_half_word = { {16{aligned_data_rd[15]}}, aligned_data_rd[15:0] };
assign zero_ext_byte      = { 24'b0, aligned_data_rd[7:0] };
assign zero_ext_half_word = { 16'b0, aligned_data_rd[15:0] };
// for LWL/LWR, memreq.wdata = reg2
generate if(`CPU_LWLR_ENABLED) begin
	assign unaligned_word = (data.memreq.wrdata & ~ext_sel) | (unaligned_data_rd & ext_sel);
end else begin
	assign unaligned_word = '0;
end endgenerate
always_comb
begin
	if(op == OP_LWL) begin
		unaligned_data_rd = data_rd << ((3 - addr_offset) * 8);
	end else begin
		unaligned_data_rd = data_rd >> (addr_offset * 8);
	end
end

always_comb begin
	result.rd    = data.decoded.rd;
	result.wdata = data.result;
	if(data.memreq.read) begin
		unique case(data.decoded.op)
			OP_LB:  result.wdata = signed_ext_byte;
			OP_LH:  result.wdata = signed_ext_half_word;
			OP_LBU: result.wdata = zero_ext_byte;
			OP_LHU: result.wdata = zero_ext_half_word;
			OP_LWL, OP_LWR: result.wdata = unaligned_word;
			default: result.wdata = aligned_data_rd;
		endcase
	end
end

`ifdef ENABLE_FPU
always_comb begin
	result.fpu_req = data.fpu_req;
	if(data.decoded.op == OP_LWC1 || data.decoded.op == OP_LDC1A || data.decoded.op == OP_LDC1B)
		result.fpu_req.wdata = aligned_data_rd;
end
`endif

endmodule
