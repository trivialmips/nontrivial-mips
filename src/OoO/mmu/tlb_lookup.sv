`include "cpu_defs.svh"

module tlb_lookup(
	input  tlb_entry_t   [`TLB_ENTRIES_NUM-1:0] entries,
	input  virt_t        virt_addr,
	input  logic [7:0]   asid,
	output tlb_result_t  result
);

logic [$clog2(`TLB_ENTRIES_NUM)-1:0] which_matched;
logic [`TLB_ENTRIES_NUM-1:0] matched;
tlb_entry_t matched_entry;
assign matched_entry = entries[which_matched];

assign result.miss = (matched == 16'b0);
assign result.which = which_matched;
assign result.phy_addr[11:0]  = virt_addr[11:0];
always_comb
begin
	if(virt_addr[12])
	begin
		result.dirty = matched_entry.d1;
		result.valid = matched_entry.v1;
		result.cache_flag = matched_entry.c1;
		result.phy_addr[31:12] = matched_entry.pfn1[19:0];
	end else begin
		result.dirty = matched_entry.d0;
		result.valid = matched_entry.v0;
		result.cache_flag = matched_entry.c0;
		result.phy_addr[31:12] = matched_entry.pfn0[19:0];
	end
end

for(genvar i = 0; i < `TLB_ENTRIES_NUM; i = i + 1) begin: gen_for_tlb_match
	assign matched[i] = (
		entries[i].vpn2 == virt_addr[31:13] &&
		(entries[i].asid == asid || entries[i].G)
	);
end

always_comb
begin
	which_matched = '0;
	for(int i = `TLB_ENTRIES_NUM - 1; i >= 0; --i)
		if(matched[i]) which_matched = i;
end

endmodule 
