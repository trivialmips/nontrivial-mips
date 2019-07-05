module count_bit(
	input         bit_val,
	input  [31:0] val,
	output [31:0] count
);

logic [3:0] count3, count2, count1, count0;

count_bit_byte bit_count3(
	.bit_val,
	.val(val[31:24]),
	.count(count3)
);

count_bit_byte bit_count2(
	.bit_val,
	.val(val[23:16]),
	.count(count2)
);

count_bit_byte bit_count1(
	.bit_val,
	.val(val[15:8]),
	.count(count1)
);

count_bit_byte bit_count0(
	.bit_val,
	.val(val[7:0]),
	.count(count0)
);

logic [31:0] cnt;
assign count = cnt;

always_comb
begin
	if(count3 != 4'd8)
	begin
		cnt = { 29'b0, count3[2:0] };
	end else if(count2 != 4'd8) begin
		cnt = { 27'b0, 2'b01, count2[2:0] };
	end else if(count1 != 4'd8) begin
		cnt = { 27'b0, 2'b10, count1[2:0] };
	end else begin
		cnt = { 27'b0, 2'b11, 3'b0 } + { 28'b0, count0 };
	end
end

endmodule

module count_bit_byte(
	input        bit_val,
	input  [7:0] val,
	output [3:0] count
);

logic [3:0] cnt;
assign count = cnt;

always_comb
begin
	if(bit_val)
	begin
		casez(val)
			8'b0???????: cnt = 4'd0;
			8'b10??????: cnt = 4'd1;
			8'b110?????: cnt = 4'd2;
			8'b1110????: cnt = 4'd3;
			8'b11110???: cnt = 4'd4;
			8'b111110??: cnt = 4'd5;
			8'b1111110?: cnt = 4'd6;
			8'b11111110: cnt = 4'd7;
			8'b11111111: cnt = 4'd8;
		endcase
	end else begin
		casez(val)
			8'b1???????: cnt = 4'd0;
			8'b01??????: cnt = 4'd1;
			8'b001?????: cnt = 4'd2;
			8'b0001????: cnt = 4'd3;
			8'b00001???: cnt = 4'd4;
			8'b000001??: cnt = 4'd5;
			8'b0000001?: cnt = 4'd6;
			8'b00000001: cnt = 4'd7;
			8'b00000000: cnt = 4'd8;
		endcase
	end
end

endmodule
