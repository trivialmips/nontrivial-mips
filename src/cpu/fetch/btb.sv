`include "cpu_defs.svh"

module btb #(
	parameter int SIZE = 4096,
)(
	input  logic         clk,
	input  logic         rst,

	// lookup address, aligned in 8-bytes
	input  virt_t        vaddr,
	input  btb_update_t  update,
	output btb_predict_t [1:0] predict
);

localparam OFFSET        = 2;
localparam CHANNEL_SIZE  = ENTRIES_NUM / 2;

typedef logic [$clog2(CHANNEL_SIZE) - 1:0] index_t;
function index_t get_index(input virt_t vaddr);
	return vaddr[$clog2(CHANNEL_SIZE) + 2:3];
endfunction

logic [1:0] we;
index_t waddr, raddr;
btb_predict_t wdata;
bht_predict_t [1:0] rdata;

// read request
assign raddr   = get_index(vaddr);
assign predict = rdata;

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
		.wea   ( 1'b0     ),
		.addra ( raddr    ),
		.dina  (          ),
		.douta ( rdata[i] ),
		.web   ( we[i]    ),
		.addrb ( waddr    ),
		.dinb  ( wdata    ),
		.doutb (          )
	);
end

endmodule
