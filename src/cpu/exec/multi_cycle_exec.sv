`include "cpu_defs.svh"

module multi_cycle_exec(
	input  logic    clk,
	input  logic    rst,
	input  logic    stall,
	input  logic    flush,

	input  pipeline_decode_t [1:0] request,
	output logic    stall_req,

	output reg_addr_t    cp0_raddr,
	output logic [2:0]   cp0_rsel,

	`ifdef ENABLE_ASIC
	output logic [15:0]  asic_raddr,
	`endif

	input  uint64_t hilo_i,
	output uint64_t hilo_o,
	output uint32_t reg_o
);

localparam int DIV_CYC = 36;

enum logic [1:0] {
	IDLE,
	WAIT,
	FINISH
} state, state_d;

oper_t op, op0;
uint32_t reg1, reg2;
uint64_t hilo, hilo_ret;
uint32_t reg_ret;
logic data_ready;
logic [1:0] is_multicyc;

assign is_multicyc[0] = request[0].decoded.is_multicyc;
assign is_multicyc[1] = request[1].decoded.is_multicyc;
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
		hilo_o <= '0;
		reg_o  <= '0;
	end else if(state == WAIT) begin
		hilo_o <= hilo_ret;
		reg_o  <= reg_ret;
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
		hilo <= '0;
		op   <= OP_SLL;
	end else if(state == IDLE) begin
		reg1 <= is_multicyc[1] ? request[1].reg1 : request[0].reg1;
		reg2 <= is_multicyc[1] ? request[1].reg2 : request[0].reg2;
		op   <= op0;
		hilo <= hilo_i;
	end
end

/* setup CP0 address */
always_ff @(posedge clk) begin
	if(rst) begin
		cp0_rsel  <= '0;
		cp0_raddr <= '0;
	end else begin
		if(request[0].decoded.is_priv) begin
			cp0_rsel  <= request[0].fetch.instr[2:0];
			cp0_raddr <= request[0].fetch.instr[15:11];
		end else begin
			cp0_rsel  <= request[1].fetch.instr[2:0];
			cp0_raddr <= request[1].fetch.instr[15:11];
		end
	end
end

`ifdef ENABLE_ASIC
	always_ff @(posedge clk) begin
		if(rst) asic_raddr <= '0;
		else    asic_raddr <= request[0].fetch.instr[15:0];
	end
`endif

/* cycle control */
logic [DIV_CYC:0] cyc_stage, cyc_stage_d;
assign data_ready = cyc_stage[0];

always_comb begin
	unique case(state)
		IDLE: begin
			unique case(op0)
				OP_MADD, OP_MADDU, OP_MSUB, OP_MSUBU,
				OP_MUL, OP_MULT, OP_MULTU:
					cyc_stage_d = 1 << 1;
				OP_DIV, OP_DIVU:
					cyc_stage_d = 1 << DIV_CYC;
				OP_MTHI, OP_MTLO:
					cyc_stage_d = 1;
				OP_MFC0:
					cyc_stage_d = 1;
				`ifdef ENABLE_ASIC
				OP_MFC2:
					cyc_stage_d = 1;
				`endif
				default:
					cyc_stage_d = '0;
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

/* signed setting */
logic is_signed, negate_result;
assign is_signed = (
	op == OP_MADD ||
	op == OP_MSUB ||
	op == OP_MUL  ||
	op == OP_MULT ||
	op == OP_DIV
);

assign negate_result = is_signed && (reg1[31] ^ reg2[31]);
uint32_t abs_reg1, abs_reg2;
assign abs_reg1 = (is_signed && reg1[31]) ? -reg1 : reg1;
assign abs_reg2 = (is_signed && reg2[31]) ? -reg2 : reg2;

uint64_t pipe_absmul;
always_ff @(posedge clk) begin
	if(rst) begin
		pipe_absmul <= '0;
	end else begin
		pipe_absmul <= abs_reg1 * abs_reg2;
	end
end

/* multiply */
uint64_t mul_result;
assign mul_result = negate_result ? -pipe_absmul : pipe_absmul;

/* division */
uint32_t abs_quotient, abs_remainder;
uint32_t div_quotient, div_remainder;

/* Note that the document of MIPS32 says if the divisor is zero,
 * the result is UNDEFINED. */
div_uu #(
	.z_width(64)
) div_uu_instance (
	.clk,
	.ena(op == OP_DIV || op == OP_DIVU),
	.z( { 32'b0, abs_reg1 } ),
	.d(abs_reg2),
	.q(abs_quotient),
	.s(abs_remainder),
	.div0(),
	.ovf()
);

/* |b| = |aq| + |r|
 *   1) b > 0, a < 0 ---> b = (-a)(-q) + r
 *   2) b < 0, a > 0 ---> -b = a(-q) + (-r) */
assign div_quotient  = negate_result ? -abs_quotient : abs_quotient;
assign div_remainder = (is_signed && (reg1[31] ^ abs_remainder[31])) ? -abs_remainder : abs_remainder;

/* set result */
always_comb begin
	unique case(op)
		OP_MADDU, OP_MADD: hilo_ret = hilo + mul_result;
		OP_MSUBU, OP_MSUB: hilo_ret = hilo - mul_result;
		OP_MULT, OP_MULTU: hilo_ret = mul_result;
		OP_DIV, OP_DIVU: hilo_ret = { div_remainder, div_quotient };
		OP_MTLO: hilo_ret = { hilo[63:32], reg1 };
		OP_MTHI: hilo_ret = { reg1, hilo[31:0]  };
		default: hilo_ret = hilo;
	endcase
end

always_comb begin
	unique case(op)
		OP_MUL:  reg_ret = mul_result[31:0];
		/* result of OP_MFC0 is computed in CP0 */
		default: reg_ret = '0;
	endcase
end

endmodule
