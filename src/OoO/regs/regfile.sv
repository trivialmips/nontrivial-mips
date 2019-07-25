module regfile #(
	parameter int REG_NUM     = 32,
	parameter int DATA_WIDTH  = 32,
	parameter int WRITE_PORTS = 1,
	parameter int READ_PORTS  = 2,
	parameter int ZERO_KEEP   = 1   // regs[0:ZERO_KEEP-1] = 0
)(
	input  logic clk,
	input  logic rst,

	input  logic [WRITE_PORTS-1:0]                      we,
	input  logic [WRITE_PORTS-1:0][DATA_WIDTH-1:0]      wdata,
	input  logic [WRITE_PORTS-1:0][$clog2(REG_NUM)-1:0] waddr,

	input  logic [READ_PORTS-1:0][$clog2(REG_NUM)-1:0]  raddr,
	output logic [READ_PORTS-1:0][DATA_WIDTH-1:0]       rdata
);

logic [REG_NUM-1:0][DATA_WIDTH-1:0] regs, regs_new;

// read data
for(genvar i = 0; i < READ_PORTS; ++i) begin : gen_read
	assign rdata[i] = regs[raddr[i]];
end

// write data
always_comb begin
	regs_new = regs;
	for(int i = ZERO_KEEP; i < REG_NUM; ++i) begin
		for(int j = 0; j < WRITE_PORTS; ++j) begin
			if(we[j] && waddr[j] == i)
				regs_new[i] = wdata[j];
		end
	end
end

always_ff @(posedge clk) begin
	if(rst) begin
		regs <= '0;
	end else begin
		regs <= regs_new;
	end
end

endmodule
