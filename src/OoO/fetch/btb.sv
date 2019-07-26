`include "cpu_defs.svh"

module btb #(
	parameter int SIZE = 4096
) (
	input  logic         clk,
	input  logic         rst,
	output logic         btb_ready,

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

// reset logic
logic is_reseting;
logic [$clog2(CHANNEL_SIZE)-1:0] reset_addr;
assign btb_ready = ~is_reseting;

// read request
assign raddr   = get_index(vaddr);
assign predict = rdata;

always_comb begin
	// write request through read channel
	wea[0] = presolved_branch.mispredict & ~presolved_branch.pc[2];
	wea[1] = presolved_branch.mispredict & presolved_branch.pc[2];
	if(presolved_branch.mispredict) begin
		addra = get_index(presolved_branch.pc);
	end else begin
		addra = raddr;
	end

	// reset request
	if(is_reseting) begin
		wea   = 2'b11;
		addra = reset_addr;
	end
end

// reset control
always_ff @(posedge clk) begin
	if(rst) begin
		is_reseting <= `RST_CLEAR_BTB;
		reset_addr  <= '0;
	end else if(&reset_addr) begin
		is_reseting <= 1'b0;
	end else begin
		reset_addr  <= reset_addr + 1;
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
		.ena   ( 1'b1     ),
		.enb   ( 1'b1     ),
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
