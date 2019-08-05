`include "cpu_defs.svh"

module bht #(
	parameter int SIZE = 4096
) (
	input  logic         clk,
	input  logic         rst,

	// lookup address, aligned in 8-bytes
	input  virt_t        vaddr,
	input  bht_update_t  update,
	output bht_predict_t [1:0] predict
);

localparam OFFSET        = 2;
localparam CHANNEL_SIZE  = SIZE / 2;

typedef logic [$clog2(CHANNEL_SIZE) - 1:0] index_t;
function index_t get_index(input virt_t vaddr);
	return vaddr[$clog2(CHANNEL_SIZE) + 2:3];
endfunction

function logic [1:0] next_counter(
	input logic [1:0] counter,
	input logic taken
);
	if(taken) begin
		unique case(counter)
			2'b00: next_counter = 2'b01;
			2'b01: next_counter = 2'b11;
			2'b10: next_counter = 2'b11;
			2'b11: next_counter = 2'b11;
		endcase
	end else begin
		unique case(counter)
			2'b00: next_counter = 2'b00;
			2'b01: next_counter = 2'b00;
			2'b10: next_counter = 2'b00;
			2'b11: next_counter = 2'b10;
		endcase
	end
endfunction

logic [1:0] we;
index_t waddr, raddr;
bht_predict_t wdata;
bht_predict_t [1:0] rdata;

// read request
assign raddr   = get_index(vaddr);
assign predict = rdata;

// write request
assign we[0] = ~update.pc[2] & update.valid;
assign we[1] = update.pc[2]  & update.valid;
assign waddr = get_index(update.pc);
assign wdata = next_counter(update.counter, update.taken);

for(genvar i = 0; i < 2; ++i) begin : gen_bht_ram
	dual_port_ram #(
		.SIZE  ( CHANNEL_SIZE  ),
		.dtype ( bht_predict_t )
	) bht_ram (
		.clk,
		.rst,
		.ena   ( 1'b1     ),
		.enb   ( 1'b1     ),
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
