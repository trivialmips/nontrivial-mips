`include "cpu_defs.svh"

module tlb(
	input  logic        clk,
	input  logic        rst_n,
	input  logic [7:0]  asid,
	input  virt_t       inst_vaddr,
	input  phys_t       data_vaddr,
	output tlb_result_t inst_result,
	output tlb_result_t data_result,

	// for TLBR/TLBWI/TLBWR
	input  tlb_index_t  tlbrw_index,
	input  logic        tlbrw_we,
	input  tlb_entry_t  tlbrw_wdata,
	output tlb_entry_t  tlbrw_rdata,

	// for TLBP
	input  uint32_t     tlbp_entry_hi,
	output uint32_t     tlbp_index
);

tlb_entry_t entries[`TLB_ENTRIES_NUM-1:0];
assign tlbrw_rdata = entries[tlbrw_index];

genvar i;
generate
	for(i = 0; i < `TLB_ENTRIES_NUM; ++i)
	begin: gen_for_tlb
		always_ff @(posedge clk or negedge rst_n) begin
			if(~rst_n)
			begin
				entries[i] <= '0;
			end else begin
				if(tlbrw_we && i == tlbrw_index)
					entries[i] <= tlbrw_wdata;
			end
		end
	end
endgenerate

tlb_lookup inst_lookup(
	.entries,
	.virt_addr(inst_vaddr),
	.asid,
	.result(inst_result)
);

tlb_lookup data_lookup(
	.entries,
	.virt_addr(data_vaddr),
	.asid,
	.result(data_result)
);

tlb_result_t tlbp_result;
tlb_lookup tlbp_lookup(
	.flat_entries,
	.virt_addr(tlbp_entry_hi),
	.asid(tlbp_entry_hi[7:0]),
	.result(tlbp_result)
);

assign tlbp_index = {
	tlbp_result.miss,
	{(32 - $clog2(`TLB_ENTRIES_NUM) - 1){1'b0}},
	tlbp_result.which
};

endmodule
