`include "cpu_defs.svh"

module fpu_exec(
	input  logic    clk,
	input  logic    rst,
	input  logic    stall,
	input  logic    flush,

	input  pipeline_decode_t [1:0] request,
	output logic    stall_req,

	output uint32_t     reg_o,
	output fpu_fcsr_t   fcsr_o,
	output fpu_except_t except_o
);

localparam int FPU_ADD_LATENCY  = 2;
localparam int FPU_SUB_LATENCY  = 2;
localparam int FPU_MUL_LATENCY  = 2;
localparam int FPU_DIV_LATENCY  = 8;
localparam int FPU_SQRT_LATENCY = 8;
localparam int FPU_COND_LATENCY = 1;
localparam int FPU_CVTS_LATENCY = 1;
localparam int MAX_CYC = 10;

enum logic [1:0] {
	IDLE,
	WAIT,
	FINISH
} state, state_d;

uint32_t instr;
fpu_except_t except;
oper_t op, op0;
uint32_t reg1, reg2;
fpu_fcsr_t fcsr, fcsr_ret;
uint32_t reg_ret;
logic data_ready;
logic [1:0] is_multicyc;

assign is_multicyc[0] = request[0].decoded.is_fpu_multicyc;
assign is_multicyc[1] = request[1].decoded.is_fpu_multicyc;
assign op0 = is_multicyc[1] ? request[1].decoded.op : request[0].decoded.op;

assign stall_req = ~(state == IDLE && ~(|is_multicyc) || state == FINISH);

always_comb begin
	state_d = state;
	unique case(state)
		IDLE:   if(|is_multicyc) state_d = WAIT;
		WAIT:   if(data_ready) state_d = FINISH;
		FINISH: if(~stall) state_d = IDLE;
	endcase
end

always_ff @(posedge clk) begin
	if(rst) begin
		reg_o  <= '0;
		fcsr_o <= '0;
		except_o <= '0;
	end else if(state == WAIT) begin
		reg_o  <= reg_ret;
		fcsr_o <= fcsr_ret;
		except_o <= except;
	end
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		state <= IDLE;
	end else begin
		state <= state_d;
	end
end

/* read operands */
always_ff @(posedge clk) begin
	if(rst) begin
		reg1 <= '0;
		reg2 <= '0;
		fcsr <= '0;
		instr <= '0;
		op   <= OP_SLL;
	end else if(state == IDLE) begin
		reg1 <= is_multicyc[1] ? request[1].fpu_reg1 : request[0].fpu_reg1;
		reg2 <= is_multicyc[1] ? request[1].fpu_reg2 : request[0].fpu_reg2;
		fcsr <= is_multicyc[1] ? request[1].fpu_fcsr : request[0].fpu_fcsr;
		instr <= is_multicyc[1] ? request[1].fetch.instr : request[0].fetch.instr;
		op   <= op0;
	end
end

/* cycle control */
logic [MAX_CYC:0] cyc_stage, cyc_stage_d;
assign data_ready = cyc_stage[0];

always_comb begin
	unique case(state)
		IDLE: begin
			unique case(op0)
				OP_FPU_NEG:   cyc_stage_d = 1;
				OP_FPU_ABS:   cyc_stage_d = 1;
				OP_FPU_ADD:   cyc_stage_d = 1 << FPU_ADD_LATENCY;
				OP_FPU_SUB:   cyc_stage_d = 1 << FPU_SUB_LATENCY;
				OP_FPU_MUL:   cyc_stage_d = 1 << FPU_MUL_LATENCY;
				OP_FPU_DIV:   cyc_stage_d = 1 << FPU_DIV_LATENCY;
				OP_FPU_SQRT:  cyc_stage_d = 1 << FPU_SQRT_LATENCY;
				OP_FPU_COND:  cyc_stage_d = 1 << FPU_COND_LATENCY;
				OP_FPU_CVTS:  cyc_stage_d = 1 << FPU_CVTS_LATENCY;
				OP_FPU_CVTW:  cyc_stage_d = 1;
				OP_FPU_CEIL:  cyc_stage_d = 1;
				OP_FPU_TRUNC: cyc_stage_d = 1;
				OP_FPU_ROUND: cyc_stage_d = 1;
				OP_FPU_FLOOR: cyc_stage_d = 1;
				default:      cyc_stage_d = '0;
			endcase
		end
		WAIT: cyc_stage_d = cyc_stage >> 1;
		default: cyc_stage_d = '0;
	endcase
end

always @(posedge clk) begin
	if(rst || flush) begin
		cyc_stage <= 0;
	end else begin
		cyc_stage <= cyc_stage_d;
	end
end

/* FPU exec */
function logic is_nan(input uint32_t x);
	return (x == 32'h7fffffff || x == 32'h7fbfffff);
endfunction

// invalid
logic exp_sqrt;
// divide_by_zero, invalid, overflow, underflow
logic [3:0] exp_divide;
// invalid, overflow, underflow
logic [2:0] exp_addsub, exp_multiply;

logic reg1_nan;
uint32_t ret, ret_addsub, ret_multiply;
uint32_t ret_divide, ret_sqrt, ret_neg, ret_abs;

assign reg1_nan = is_nan(reg1);
assign ret_abs = reg1_nan ? reg1 : { 1'b0, reg1[30:0] };
assign ret_neg = reg1_nan ? reg1 : { ~reg1[31], reg1[30:0] };

floating_point_addsub fpu_addsub(
	.s_axis_a_tdata(reg1),
	.s_axis_a_tvalid(1'b1),
	.s_axis_b_tdata(reg2),
	.s_axis_b_tvalid(1'b1),
	.s_axis_operation_tdata( { 7'b0, op == OP_FPU_SUB } ),
	.s_axis_operation_tvalid(1'b1),
	.aclk(clk),
	.m_axis_result_tdata(ret_addsub),
	.m_axis_result_tuser(exp_addsub),
	.m_axis_result_tvalid()
);

floating_point_multiply fpu_multiply(
	.s_axis_a_tdata(reg1),
	.s_axis_a_tvalid(1'b1),
	.s_axis_b_tdata(reg2),
	.s_axis_b_tvalid(1'b1),
	.aclk(clk),
	.m_axis_result_tdata(ret_multiply),
	.m_axis_result_tuser(exp_multiply),
	.m_axis_result_tvalid()
);

floating_point_divide fpu_divide(
	.s_axis_a_tdata(reg1),
	.s_axis_a_tvalid(1'b1),
	.s_axis_b_tdata(reg2),
	.s_axis_b_tvalid(1'b1),
	.aclk(clk),
	.m_axis_result_tdata(ret_divide),
	.m_axis_result_tuser(exp_divide),
	.m_axis_result_tvalid()
);

floating_point_sqrt fpu_sqrt(
	.s_axis_a_tdata(reg1),
	.s_axis_a_tvalid(1'b1),
	.aclk(clk),
	.m_axis_result_tdata(ret_sqrt),
	.m_axis_result_tuser(exp_sqrt),
	.m_axis_result_tvalid()
);

logic [7:0] ret_compare_fcc;
logic [3:0] expected_cond_code;
logic [7:0] compare_cond_code;  // ( unordered, >, <, EQ )
floating_point_compare fpu_compare(
	.s_axis_a_tdata(reg1),
	.s_axis_a_tvalid(1'b1),
	.s_axis_b_tdata(reg2),
	.s_axis_b_tvalid(1'b1),
	.aclk(clk),
	.m_axis_result_tdata(compare_cond_code),
	.m_axis_result_tvalid()
);

always_comb
begin
	ret_compare_fcc = fcsr.fcc;
	ret_compare_fcc[instr[10:8]] = |(compare_cond_code[3:0] & expected_cond_code);
end

always_comb
begin
	unique case(instr[2:0])
		3'd0: expected_cond_code = 4'b0000;  // always false
		3'd1: expected_cond_code = 4'b1000;  // unordered
		3'd2: expected_cond_code = 4'b0001;  // equal
		3'd3: expected_cond_code = 4'b1001;  // unordered or equal
		3'd4: expected_cond_code = 4'b0010;  // ordered or less than
		3'd5: expected_cond_code = 4'b1010;  // unordered or less than
		3'd6: expected_cond_code = 4'b0011;  // ordered or less than or equal
		3'd7: expected_cond_code = 4'b1011;  // unordered or less than or equal
		default: expected_cond_code = 4'b0000;
	endcase
end

uint32_t ret_ceil, ret_floor, ret_trunc, ret_round;
logic invalid_ceil, invalid_floor, invalid_trunc, invalid_round;
float2int float2int_instance(
	.float(reg1),
	.invalid_ceil,
	.invalid_floor,
	.invalid_trunc,
	.invalid_round,
	.ceil(ret_ceil),
	.floor(ret_floor),
	.trunc(ret_trunc),
	.round(ret_round)
);

uint32_t ret_int2float;
floating_point_int2float fpu_int2float_instance(
	.s_axis_a_tdata(reg1),
	.s_axis_a_tvalid(1'b1),
	.aclk(clk),
	.m_axis_result_tdata(ret_int2float),
	.m_axis_result_tvalid()
);

/* set result */
always_comb begin
	unique case(op)
		OP_FPU_NEG:   reg_ret = ret_neg;
		OP_FPU_ABS:   reg_ret = ret_abs;
		OP_FPU_ADD:   reg_ret = ret_addsub;
		OP_FPU_SUB:   reg_ret = ret_addsub;
		OP_FPU_MUL:   reg_ret = ret_multiply;
		OP_FPU_DIV:   reg_ret = ret_divide;
		OP_FPU_SQRT:  reg_ret = ret_sqrt;
		OP_FPU_CEIL:  reg_ret = ret_ceil;
		OP_FPU_TRUNC: reg_ret = ret_trunc;
		OP_FPU_ROUND: reg_ret = ret_round;
		OP_FPU_FLOOR: reg_ret = ret_floor;
		OP_FPU_CVTS:  reg_ret = ret_int2float;
		OP_FPU_CVTW: begin
			unique casez(fcsr.rm)
				2'd0: reg_ret = ret_round;
				2'd1: reg_ret = ret_trunc;
				2'd2: reg_ret = ret_ceil;
				2'd3: reg_ret = ret_floor;
			endcase
		end
		default: reg_ret = '0;
	endcase
end

/* exception */
`define FPU_EXP3 { except.invalid, except.overflow, except.underflow }
`define FPU_EXP4 { except.divided_by_zero, except.invalid, except.overflow, except.underflow }
always_comb begin
	except = '0;
	unique case(op)
		OP_FPU_ADD: `FPU_EXP3 = exp_addsub;
		OP_FPU_SUB: `FPU_EXP3 = exp_addsub;
		OP_FPU_MUL: `FPU_EXP3 = exp_multiply;
		OP_FPU_DIV: `FPU_EXP4 = exp_divide;
		OP_FPU_NEG:  except.invalid = reg1_nan;
		OP_FPU_ABS:  except.invalid = reg1_nan;
		OP_FPU_SQRT: except.invalid = exp_sqrt;
		OP_FPU_CEIL: except.invalid = invalid_ceil;
		OP_FPU_TRUNC: except.invalid = invalid_trunc;
		OP_FPU_ROUND: except.invalid = invalid_round;
		OP_FPU_FLOOR: except.invalid = invalid_floor;
		OP_FPU_CVTW:
		begin
			unique casez(fcsr.rm)
				2'd0: except.invalid = invalid_round;
				2'd1: except.invalid = invalid_trunc;
				2'd2: except.invalid = invalid_ceil;
				2'd3: except.invalid = invalid_floor;
			endcase
		end
//		OP_INVALID: except.unimpl = 1'b1;
		default: ; 
	endcase
end

/* FCSR register result */
always_comb begin
	fcsr_ret = fcsr;
	unique case(op)
		OP_FPU_COND: fcsr_ret.fcc = ret_compare_fcc;
		OP_FPU_ADD, OP_FPU_SUB, OP_FPU_MUL, OP_FPU_DIV, OP_FPU_SQRT,
		OP_FPU_CEIL, OP_FPU_TRUNC, OP_FPU_FLOOR, OP_FPU_ROUND, OP_FPU_CVTS,
		OP_FPU_CVTW, OP_FPU_NEG, OP_FPU_ABS: begin
			fcsr_ret.cause      = except;
			fcsr_ret.flags[4:0] = fcsr.flags[4:0] | except[4:0];
		end
		default: fcsr_ret = fcsr;
	endcase
end

endmodule
