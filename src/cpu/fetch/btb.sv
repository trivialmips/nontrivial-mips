`include "cpu_defs.svh"

module btb #(
	parameter int SIZE = 4096
) (
	input  logic         clk,
	input  logic         rst,

	// lookup address, aligned in 8-bytes
	input  virt_t        vaddr,
	input  btb_update_t  update,
	output btb_predict_t [1:0] predict,
	input  presolved_branch_t presolved_branch
);

localparam OFFSET        = 2;
localparam CHANNEL_SIZE  = SIZE / 2;

typedef logic [$clog2(CHANNEL_SIZE) - 1:0] index_t;
function index_t get_index(input virt_t vaddr);
	return vaddr[$clog2(CHANNEL_SIZE) + 2:3];
endfunction

logic [1:0] we, wea;
index_t waddr, raddr, addra;
btb_predict_t wdata;
btb_predict_t [1:0] rdata;

// read request
assign raddr   = get_index(vaddr);
assign predict = rdata;

// write request through read channel
assign wea[0] = presolved_branch.mispredict & ~presolved_branch.pc[2];
assign wea[1] = presolved_branch.mispredict & presolved_branch.pc[2];
always_comb begin
	if(presolved_branch.mispredict) begin
		addra = get_index(presolved_branch.pc);
	end else begin
		addra = raddr;
	end
end

// write request
assign we[0] = ~update.pc[2] & update.valid;
assign we[1] = update.pc[2]  & update.valid;
assign waddr = get_index(update.pc);
assign wdata.target = update.target;
assign wdata.cf     = update.cf;

for(genvar i = 0; i < 2; ++i) begin : gen_btb_ram
	dual_port_ram #(
		.SIZE  ( CHANNEL_SIZE  ),
		.dtype ( btb_predict_t )
	) btb_ram (
		.clk,
		.rst,
		.wea   ( wea[i]   ),
		.addra ( addra    ),
		.dina  ( '0       ),
		.douta ( rdata[i] ),
		.web   ( we[i]    ),
		.addrb ( waddr    ),
		.dinb  ( wdata    ),
		.doutb (          )
	);
end

endmodule
