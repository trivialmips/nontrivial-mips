`include "cpu_defs.svh"

module regfile_status #(
	parameter int REG_NUM     = 32,
	parameter int WRITE_PORTS = 1,
	parameter int READ_PORTS  = 2,
	parameter int ZERO_KEEP   = 1,   // regs[0:ZERO_KEEP-1] = 0
	parameter type dtype = register_status_t
)(
	input  logic clk,
	input  logic rst,
	input  logic flush,

	input  logic [WRITE_PORTS-1:0]                      we,
	input  dtype [WRITE_PORTS-1:0]                      wdata,
	input  logic [WRITE_PORTS-1:0][$clog2(REG_NUM)-1:0] waddr,

	input  logic [WRITE_PORTS-1:0]                      wrst,
	input  rob_index_t [WRITE_PORTS-1:0]                wreorder,

	input  logic [READ_PORTS-1:0][$clog2(REG_NUM)-1:0]  raddr,
	output dtype [READ_PORTS-1:0]                       rdata,

	input  cdb_packet_t cdb
);

dtype [REG_NUM-1:0] regs, regs_wrst, regs_new;

// read data
for(genvar i = 0; i < READ_PORTS; ++i) begin : gen_read
	assign rdata[i] = regs[raddr[i]];
end

// write data
always_comb begin
	regs_wrst = regs;
	for(int i = ZERO_KEEP; i < REG_NUM; ++i)
		for(int j = 0; j < WRITE_PORTS; ++j)
			if(wrst[j] && wreorder[j] == regs[i].reorder)
				regs_wrst[i] = '0;
end

always_comb begin
	regs_new = regs_wrst;
	for(int i = ZERO_KEEP; i < REG_NUM; ++i) begin
		for(int j = 0; j < `CDB_SIZE; ++j) begin
			if(regs[i].busy && cdb[j].valid && regs[i].reorder == cdb[j].reorder) begin
				regs_new[i].data |= cdb[j].value;
				regs_new[i].data_valid = 1'b1;
			end
		end

		for(int j = 0; j < WRITE_PORTS; ++j)
			if(we[j] && waddr[j] == i)
				regs_new[i] = wdata[j];
	end
end

always_ff @(posedge clk) begin
	if(rst || flush) begin
		regs <= '0;
	end else begin
		regs <= regs_new;
	end
end

endmodule
