`include "cpu_defs.svh"

module float2int(
	input  uint32_t float,
	output logic    invalid_ceil,
	output logic    invalid_floor,
	output logic    invalid_trunc,
	output logic    invalid_round,
	output uint32_t ceil,
	output uint32_t floor,
	output uint32_t trunc,
	output uint32_t round
);

logic sign, frac_half, frac_nonzero;
logic [31:0] fixed, fixed_plus1;
logic [7:0] exponent_biased;
logic [5:0] exponent_minus1;
logic [22:0] fraction;
logic [22:0] frac_remain;
assign { sign, exponent_biased, fraction } = float;
assign exponent_minus1 = exponent_biased - 8'd126;
assign { fixed, frac_half, frac_remain } = { 32'b0, 1'b1, fraction } << exponent_minus1;
assign frac_nonzero = (|frac_remain) | frac_half;
assign fixed_plus1  = fixed + 32'd1;

function is_invalid(
	input sign,
	input [31:0] val
);
	is_invalid = (~sign & val[31]) | (sign & val > 32'h80000000);
endfunction

always_comb
begin
	if(exponent_biased < 126)
	begin
		ceil  = (sign || exponent_biased == 0) ? 32'b0 : 32'b1;
		floor = (sign && exponent_biased != 0) ? 32'hffffffff : 32'b0;
		trunc = 32'b0;
		round = 32'b0;
		invalid_ceil  = 1'b0;
		invalid_floor = 1'b0;
		invalid_round = 1'b0;
		invalid_trunc = 1'b0;
	end else if(exponent_biased > 127 + 31) begin
		ceil  = 32'h7fffffff;
		floor = 32'h7fffffff;
		trunc = 32'h7fffffff;
		round = 32'h7fffffff;
		invalid_ceil  = 1'b1;
		invalid_floor = 1'b1;
		invalid_round = 1'b1;
		invalid_trunc = 1'b1;
	end else begin
		trunc = fixed;
		if(frac_nonzero)
		begin
			ceil  = sign ? fixed : fixed_plus1;
			floor = sign ? fixed_plus1 : fixed;
			round = frac_half ? fixed_plus1 : fixed;
		end else begin
			ceil  = fixed;
			floor = fixed;
			round = fixed;
		end

		invalid_ceil  = is_invalid(sign, ceil);
		invalid_floor = is_invalid(sign, floor);
		invalid_trunc = is_invalid(sign, trunc);
		invalid_round = is_invalid(sign, round);

		if(invalid_ceil)  ceil = 32'h7fffffff;
		if(invalid_floor) floor = 32'h7fffffff;
		if(invalid_round) round = 32'h7fffffff;
		if(invalid_trunc) trunc = 32'h7fffffff;

		ceil  = sign ? -ceil : ceil;
		floor = sign ? -floor : floor;
		round = sign ? -round : round;
		trunc = sign ? -trunc : trunc;
	end
end

endmodule
