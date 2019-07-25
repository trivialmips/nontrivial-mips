`include "cpu_defs.svh"

module ll_bit(
	input  logic           clk,
	input  logic           rst,
	input  except_req_t    except_req,
	input  pipeline_exec_t [`ISSUE_NUM-1:0] pipe_mm,
	output logic           data
); 

logic data_now, data_nxt;
assign data = data_nxt;

logic [`ISSUE_NUM-1:0] is_ll;
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_isll
	assign is_ll[i] = (pipe_mm[i].decoded.op == OP_LL);
end

always_comb begin
	if(rst || except_req.valid)
		data_nxt = 1'b0;
	else if(|is_ll)
		data_nxt = 1'b1;
	else data_nxt = data_now;
end

always_ff @(posedge clk) begin
	if(rst) data_now <= 1'b0;
	else data_now <= data_nxt;
end

endmodule
