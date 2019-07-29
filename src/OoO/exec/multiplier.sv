`include "cpu_defs.svh"

module multiplier (
	input  logic     clk,
	input  logic     rst,
	input  logic     flush,
	input  oper_t    op,
	input  uint32_t  reg1,
	input  uint32_t  reg2,
	input  uint64_t  hilo,
	output uint64_t  ret,
	output uint32_t  mult_word,
	output logic     is_busy
);

localparam int DIV_CYC = 36;

/* cycle control */
logic [5:0] cyc_number;
logic [DIV_CYC:0] cyc_stage;
assign is_busy = (cyc_number != 1 && ~cyc_stage[0]);
always @(posedge clk) begin
	if(rst || flush) begin
		cyc_stage <= 0;
	end else if(cyc_stage != 0) begin
		cyc_stage <= cyc_stage >> 1;
	end else begin
		cyc_stage <= ((1 << cyc_number) >> 2);
	end
end

always_comb
begin
	if(rst || flush) begin
		cyc_number = 1;
	end else begin
		unique case(op)
			OP_MADD, OP_MADDU, OP_MSUB, OP_MSUBU,
			OP_MUL, OP_MULT, OP_MULTU:
				cyc_number = 4;
			OP_DIV, OP_DIVU:
				cyc_number = DIV_CYC;
			default:
				cyc_number = 1;
		endcase
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

uint64_t pipe_hilo, pipe_absmul;
uint32_t pipe_absreg1, pipe_absreg2;
uint32_t pipe_mul_hi, pipe_mul_lo, pipe_mul_md1, pipe_mul_md2;
logic [32:0] pipe_mul_md;
assign pipe_mul_md = pipe_mul_md1 + pipe_mul_md2;
always_ff @(posedge clk) begin
	if(rst) begin
		pipe_hilo <= '0;
		pipe_absreg1 <= '0;
		pipe_absreg2 <= '0;
		pipe_mul_hi  <= '0;
		pipe_mul_lo  <= '0;
		pipe_mul_md1 <= '0;
		pipe_mul_md2 <= '0;
	end else begin
		pipe_hilo <= hilo;
		pipe_absreg1 <= abs_reg1;
		pipe_absreg2 <= abs_reg2;
		pipe_mul_hi  <= pipe_absreg1[31:16] * pipe_absreg2[31:16];
		pipe_mul_md1 <= pipe_absreg1[15:0] * pipe_absreg2[31:16];
		pipe_mul_md2 <= pipe_absreg1[31:16] * pipe_absreg2[15:0];
		pipe_mul_lo  <= pipe_absreg1[15:0] * pipe_absreg2[15:0];
		pipe_absmul  <= { pipe_mul_hi, pipe_mul_lo } + { 15'b0, pipe_mul_md, 16'b0 };
	end
end

/* multiply */
uint64_t mul_result;
assign mul_result = negate_result ? -pipe_absmul : pipe_absmul;
assign mult_word = mul_result[31:0];

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
		OP_MADDU, OP_MADD: ret = pipe_hilo + mul_result;
		OP_MSUBU, OP_MSUB: ret = pipe_hilo - mul_result;
		OP_DIV, OP_DIVU: ret = { div_remainder, div_quotient };
		default: ret = mul_result;
	endcase
end

endmodule
