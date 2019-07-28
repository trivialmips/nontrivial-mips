`include "cpu_defs.svh"

module mmu(
	input  logic        clk,
	input  logic        rst,
	input  logic [7:0]  asid,
	input  logic        kseg0_uncached,
	input  logic        is_user_mode,
	input  virt_t       inst_vaddr,
	input  virt_t       data_vaddr,

	output mmu_result_t inst_result,
	output mmu_result_t data_result,

	// for TLBR/TLBWI/TLBWR
	input  tlb_index_t  tlbrw_index,
	input  logic        tlbrw_we,
	input  tlb_entry_t  tlbrw_wdata,
	output tlb_entry_t  tlbrw_rdata,

	// for TLBP
	input  uint32_t     tlbp_entry_hi,
	output uint32_t     tlbp_index
);

function logic is_vaddr_mapped(
	input virt_t vaddr
);
	// useg (0xx), kseg2 (110), kseg3 (111)
	return (~vaddr[31] || vaddr[31:30] == 2'b11);
endfunction

function logic is_vaddr_uncached(
	input virt_t vaddr
); 
	return vaddr[31:29] == 3'b101 || kseg0_uncached && vaddr[31:29] == 3'b100;
endfunction

generate if(`CPU_MMU_ENABLED)
begin: generate_mmu_enabled_code

	logic inst_mapped;
	logic data_mapped;
	tlb_result_t inst_tlb_result;
	tlb_result_t data_tlb_result;

	assign inst_mapped   = is_vaddr_mapped(inst_vaddr);

	assign inst_result.dirty    = 1'b0;
	assign inst_result.miss     = (inst_mapped & inst_tlb_result.miss);
	assign inst_result.illegal  = (is_user_mode & inst_vaddr[31]);
	assign inst_result.invalid  = (inst_mapped & ~inst_tlb_result.valid);
	assign inst_result.uncached = is_vaddr_uncached(inst_vaddr);
	assign inst_result.phy_addr = inst_mapped ? inst_tlb_result.phy_addr : { 3'b0, inst_vaddr[28:0] };
	assign inst_result.virt_addr = inst_vaddr;

	// note that dirty = 1 when writable
	assign data_mapped          = is_vaddr_mapped(data_vaddr);
	assign data_result.uncached = is_vaddr_uncached(data_vaddr);
	assign data_result.dirty    = (~data_mapped | data_tlb_result.dirty);
	assign data_result.miss     = (data_mapped & data_tlb_result.miss);
	assign data_result.illegal  = (is_user_mode & data_vaddr[31]);
	assign data_result.invalid  = (data_mapped & ~data_tlb_result.valid);
	assign data_result.phy_addr = data_mapped ? data_tlb_result.phy_addr : { 3'b0, data_vaddr[28:0] };
	assign data_result.virt_addr = data_vaddr;

	tlb tlb_instance(
		.clk,
		.rst,
		.asid,
		.inst_vaddr,
		.data_vaddr,
		.inst_result(inst_tlb_result),
		.data_result(data_tlb_result),

		.tlbrw_index,
		.tlbrw_we,
		.tlbrw_wdata,
		.tlbrw_rdata,

		.tlbp_entry_hi,
		.tlbp_index
	);

end else begin: generate_mmu_disabled_code
	always_comb
	begin
		inst_result = '0;
		inst_result.dirty = 1'b0;
		inst_result.phy_addr = { 3'b0, inst_vaddr[28:0] };
		data_result = '0;
		data_result.dirty = 1'b1;
		data_result.uncached = is_vaddr_uncached(data_vaddr);
		data_result.phy_addr = { 3'b0, data_vaddr[28:0] };
	end
end
endgenerate

endmodule
