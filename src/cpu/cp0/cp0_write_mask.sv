`include "cpu_defs.svh"

module cp0_write_mask(
	input            rst,
	input [2:0]      sel,
	input reg_addr_t addr,
	output uint32_t  mask
);

uint32_t tlb_index_mask;
assign tlb_index_mask = {
	{(32 - $clog2(`TLB_ENTRIES_NUM)){1'b0}},
	{$clog2(`TLB_ENTRIES_NUM){1'b1}}
};

always_comb
begin
	if(rst)
	begin
		mask = 32'b0;
	end else if(sel == 3'd0) begin
		unique case(addr)
			5'd0:  mask = tlb_index_mask; // index
			5'd1:  mask = 32'h00000000;  // random
			5'd2:  mask = 32'h7fffffff;  // entry_lo0
			5'd3:  mask = 32'h7fffffff;  // entry_lo1
			5'd4:  mask = 32'b1111_1111_1000_0000_0000_0000_0000_0000;  // context
			5'd5:  mask = 32'b0001_1111_1111_1111_1111_0000_0000_0000;  // page_mask
			5'd6:  mask = tlb_index_mask; // wired
			5'd8:  mask = 32'h00000000;  // bad_vaddr
			5'd9:  mask = 32'hffffffff;  // count
			5'd10: mask = 32'hfffff0ff;  // entry_hi
			5'd11: mask = 32'hffffffff;  // compare
			5'd12: mask = 32'b1111_1010_0111_1000_1111_1111_0001_0111;  // status
			5'd13: mask = 32'b0000_0000_1100_0000_0000_0011_0000_0000;  // cause
			5'd14: mask = 32'hffffffff;  // epc
			5'd15: mask = 32'h00000000;  // prid
			5'd16: mask = 32'b0000_0000_0000_0000_0000_0000_0000_0111;  // config
			5'd30: mask = 32'hffffffff;  // error_epc
			default: mask = 32'b0;
		endcase
	end else if(sel == 3'd1) begin
		unique case(addr)
			5'd15: mask = 32'h3ffff000;  // ebase
			default: mask = 32'b0;
		endcase
	end else begin
		mask = 32'b0;
	end
end

endmodule

