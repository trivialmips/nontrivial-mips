`include "cpu_defs.svh"

module cp0(
	input  logic         clk,
	input  logic         rst,
	input  logic         flush_delayed_mispredict,

	input  reg_addr_t    raddr,
	input  logic [2:0]   rsel,
	input  cp0_req_t     wreq,
	input  except_req_t  except_req_i,
	input  logic [7:0]   interrupt_flag,

	input  logic         tlbr_req,
	input  tlb_entry_t   tlbr_res,
	input  logic         tlbp_req,
	input  uint32_t      tlbp_res,
	input  logic         tlbwr_req,

	output tlb_entry_t   tlbrw_wdata,

	output uint32_t      rdata,
	output cp0_regs_t    regs,
	output logic [7:0]   asid,
	output logic         user_mode,
	output logic         kseg0_uncached,
	output logic         timer_int
);

localparam int TLB_WIDTH = $clog2(`TLB_ENTRIES_NUM);

cp0_regs_t regs_now, regs_nxt;
assign regs = regs_now;
`ifdef COMPILE_FULL_M
assign asid = regs.entry_hi[7:0];
assign user_mode = (regs.status[4:1] == 4'b1000);
assign kseg0_uncached = (regs.config0[2:0] == 3'd2);
`else
assign asid = '0;
assign user_mode = 1'b0;
assign kseg0_uncached = 1'b0;
`endif

assign tlbrw_wdata.vpn2 = regs.entry_hi[31:13];
assign tlbrw_wdata.asid = regs.entry_hi[7:0];
assign tlbrw_wdata.pfn1 = regs.entry_lo1[29:6];
assign tlbrw_wdata.c1   = regs.entry_lo1[5:3];
assign tlbrw_wdata.d1   = regs.entry_lo1[2];
assign tlbrw_wdata.v1   = regs.entry_lo1[1];
assign tlbrw_wdata.pfn0 = regs.entry_lo0[29:6];
assign tlbrw_wdata.c0   = regs.entry_lo0[5:3];
assign tlbrw_wdata.d0   = regs.entry_lo0[2];
assign tlbrw_wdata.v0   = regs.entry_lo0[1];
assign tlbrw_wdata.G    = regs.entry_lo0[0] & regs.entry_lo1[0];

/* pipeline exception request */
except_req_t except_req;
always_ff @(posedge clk) begin
	if(rst || flush_delayed_mispredict)
		except_req <= '0;
	else except_req <= except_req_i;
end

uint32_t rdata_d;
always_comb begin
	if(rsel == 3'b0) begin
		unique case(raddr)
			5'd0:  rdata_d = regs.index;
			5'd1:  rdata_d = regs.random;
			5'd2:  rdata_d = regs.entry_lo0;
			5'd3:  rdata_d = regs.entry_lo1;
			5'd4:  rdata_d = regs.context_;
			5'd5:  rdata_d = regs.page_mask;
			5'd6:  rdata_d = regs.wired;
			5'd8:  rdata_d = regs.bad_vaddr;
			5'd9:  rdata_d = regs.count;
			5'd10: rdata_d = regs.entry_hi;
			5'd11: rdata_d = regs.compare;
			5'd12: rdata_d = regs.status;
			5'd13: rdata_d = regs.cause;
			5'd14: rdata_d = regs.epc;
			5'd15: rdata_d = regs.prid;
			5'd16: rdata_d = regs.config0;
			default: rdata_d = '0;
		endcase
	end else if(rsel == 3'b1 && `COMPILE_FULL) begin
		unique case(raddr)
			5'd15: rdata_d = regs.ebase;
			5'd16: rdata_d = regs.config1;
			default: rdata_d = '0;
		endcase
	end else begin
		rdata_d = 32'b0;
	end
end

always_ff @(posedge clk) begin
	if(rst) rdata <= '0;
	else rdata <= rdata_d;
end

uint32_t config0_default, config1_default, prid_default;
assign config0_default = {
	1'b1,   // M, config1 not implemented
	21'b0,
	3'b1,   // MMU Type ( Standard TLB )
	4'b0,
	3'd3
};

localparam int IC_SET_PER_WAY = $clog2(`ICACHE_SIZE / `ICACHE_SET_ASSOC / `ICACHE_LINE_WIDTH / 64);
localparam int IC_LINE_SIZE   = $clog2(`ICACHE_LINE_WIDTH / 32) + 1;
localparam int IC_ASSOC       = `ICACHE_SET_ASSOC - 1;
localparam int DC_SET_PER_WAY = $clog2(`DCACHE_SIZE / `DCACHE_SET_ASSOC / `DCACHE_LINE_WIDTH / 64);
localparam int DC_LINE_SIZE   = $clog2(`DCACHE_LINE_WIDTH / 32) + 1;
localparam int DC_ASSOC       = `DCACHE_SET_ASSOC - 1;
`ifdef ENABLE_FPU
localparam logic FPU_ENABLED  = 1'b1;
`else
localparam logic FPU_ENABLED  = 1'b0;
`endif

assign config1_default = {
	1'b0,
	6'd15,
	IC_SET_PER_WAY[2:0],
	IC_LINE_SIZE[2:0],
	IC_ASSOC[2:0],
	DC_SET_PER_WAY[2:0],
	DC_LINE_SIZE[2:0],
	DC_ASSOC[2:0],
	6'd0,
	FPU_ENABLED
};

assign prid_default = {8'b0, 8'b1, 16'h8000};

always @(posedge clk)
begin
	if(rst) begin
		regs_now.index     <= '0;
		regs_now.random    <= `TLB_ENTRIES_NUM - 1;
		regs_now.entry_lo0 <= '0;
		regs_now.entry_lo1 <= '0;
		regs_now.context_  <= '0;
		regs_now.page_mask <= '0;
		regs_now.wired     <= '0;
		regs_now.bad_vaddr <= '0;
		regs_now.count     <= '0;
		regs_now.entry_hi  <= '0;
		regs_now.compare   <= '0;
		`ifdef ENABLE_FPU
		regs_now.status    <= 32'b0011_0000_0100_0000_0000_0000_0000_0000;
		`else
		regs_now.status    <= 32'b0001_0000_0100_0000_0000_0000_0000_0000;
		`endif
		regs_now.cause     <= '0;
		regs_now.epc       <= '0;
		regs_now.error_epc <= '0;
		regs_now.ebase     <= 32'h80000000;
		regs_now.config0   <= config0_default;
		regs_now.config1   <= config1_default;
		regs_now.prid      <= prid_default;
	end else begin
		regs_now <= regs_nxt;
	end
end

always @(posedge clk) begin
	if(rst)
		timer_int <= 1'b0;
	else if(regs.compare != 32'b0 && regs.compare == regs.count)
		timer_int <= 1'b1;
	else if(wreq.we && wreq.wsel == 3'b0 && wreq.waddr == 5'd11)
		timer_int <= 1'b0;
end

uint32_t wdata;
assign wdata = wreq.wdata;

logic count_switch;
always_ff @(posedge clk) begin
	if(rst) count_switch <= 1'b0;
	else count_switch <= ~count_switch;
end

always_comb begin
	regs_nxt = regs_now;
	regs_nxt.count  = regs_now.count + count_switch;
`ifdef COMPILE_FULL_M
	regs_nxt.random[TLB_WIDTH-1:0] = regs_now.random[TLB_WIDTH-1:0] + tlbwr_req;
	if((&regs_now.random[TLB_WIDTH-1:0]) & tlbwr_req)
		regs_nxt.random = regs_now.wired;
`endif
	regs_nxt.cause.ip[7:2] = interrupt_flag[7:2];

	/* write register (WB stage) */
	if(wreq.we) begin
		if(wreq.wsel == 3'b0) begin
			case(wreq.waddr)
				5'd0:  regs_nxt.index[TLB_WIDTH-1:0] = wdata[TLB_WIDTH-1:0];
				5'd2:  regs_nxt.entry_lo0 = wdata[29:0];
				5'd3:  regs_nxt.entry_lo1 = wdata[29:0];
				5'd4:  regs_nxt.context_[31:23] = wdata[31:23];
				5'd6:  begin
					regs_nxt.random = `TLB_ENTRIES_NUM - 1;
					regs_nxt.wired[TLB_WIDTH-1:0] = wdata[TLB_WIDTH-1:0];
				end
				5'd9:  regs_nxt.count = wdata;
				5'd10: begin
					regs_nxt.entry_hi[31:13] = wdata[31:13];
					regs_nxt.entry_hi[7:0] = wdata[7:0];
				end
				5'd11: regs_nxt.compare = wdata;
				5'd12: begin
					regs_nxt.status.cu0 = wdata[28];
					`ifdef ENABLE_FPU
					regs_nxt.status.cu1 = wdata[29];
					`endif
					regs_nxt.status.bev = wdata[22];
					regs_nxt.status.im = wdata[15:8];
					regs_nxt.status.um = wdata[4];
					regs_nxt.status[2:0] = wdata[2:0]; // ERL/EXL/IE
				end
				5'd13: begin
					regs_nxt.cause.iv = wdata[23];
					regs_nxt.cause.ip[1:0] = wdata[9:8];
				end
				5'd14: regs_nxt.epc = wdata;
				5'd16: regs_nxt.config0[2:0] = wdata[2:0];
			endcase
		end else if(wreq.wsel == 3'b1) begin
			if(wreq.waddr == 5'd15)
				regs_nxt.ebase[29:12] = wreq.wdata[29:12];
		end
	end

	/* TLBR/TLBP instruction (WB stage) */
	if(tlbr_req) begin
		regs_nxt.entry_hi[31:13] = tlbr_res.vpn2;
		regs_nxt.entry_hi[7:0]   = tlbr_res.asid;
		regs_nxt.entry_lo1 = {
			2'b0, tlbr_res.pfn1, tlbr_res.c1,
			tlbr_res.d1, tlbr_res.v1, tlbr_res.G };
		regs_nxt.entry_lo0 = {
			2'b0, tlbr_res.pfn0, tlbr_res.c0,
			tlbr_res.d0, tlbr_res.v0, tlbr_res.G };
	end

	if(tlbp_req) regs_nxt.index = tlbp_res;

	/* exception (MEM stage) */
	if(except_req.valid) begin
		if(except_req.eret) begin
			if(regs_nxt.status.erl)
				regs_nxt.status.erl = 1'b0;
			else regs_nxt.status.exl = 1'b0;
		end else begin
			if(regs_nxt.status.exl == 1'b0)
			begin
				if(except_req.delayslot)
				begin
					regs_nxt.epc = except_req.pc - 32'h4;
					regs_nxt.cause.bd = 1'b1;
				end else begin
					regs_nxt.epc = except_req.pc;
					regs_nxt.cause.bd = 1'b0;
				end
			end

			regs_nxt.status.exl = 1'b1;
			regs_nxt.cause.exc_code = except_req.code;

			if(except_req.code == `EXCCODE_CpU)
				regs_nxt.cause.ce = except_req.extra[1:0];

			if(except_req.code == `EXCCODE_ADEL || except_req.code == `EXCCODE_ADES) begin
				regs_nxt.bad_vaddr = except_req.extra;
			end else if(except_req.code == `EXCCODE_TLBL || except_req.code == `EXCCODE_TLBS || except_req.code == `EXCCODE_MOD) begin
				regs_nxt.bad_vaddr = except_req.extra;
				regs_nxt.context_[22:4] = except_req.extra[31:13];   // context.bad_vpn2
				regs_nxt.entry_hi[31:13] = except_req.extra[31:13];  // entry_hi.vpn2
			end
		end
	end
end

endmodule
