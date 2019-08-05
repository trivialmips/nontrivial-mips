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

localparam IC_INDEX_OFFSET = $clog2(`ICACHE_LINE_WIDTH / 8);
localparam IC_INDEX_WIDTH  = $clog2(`ICACHE_SIZE / `ICACHE_SET_ASSOC / 8) - IC_INDEX_OFFSET;
typedef logic [IC_INDEX_WIDTH-1:0] icache_index_t;

function icache_index_t get_icache_index(input virt_t vaddr);
	return vaddr[IC_INDEX_OFFSET + IC_INDEX_WIDTH - 1 : IC_INDEX_OFFSET];
endfunction

typedef logic [$clog2(CHANNEL_SIZE) - 1:0] index_t;
function index_t get_index(input virt_t vaddr);
	return vaddr[$clog2(CHANNEL_SIZE) + 2:3];
endfunction

typedef struct packed {
	controlflow_t cf;
} cf_packed_t;

logic [1:0] we, we_d;
index_t waddr, waddr_d, raddr;
btb_predict_t wdata, wdata_d;
btb_predict_t [1:0] rdata;
icache_index_t ic_wdata_d;
icache_index_t [1:0] ic_rdata;
cf_packed_t cf_wdata_d;
cf_packed_t [1:0] cf_rdata;
assign ic_wdata_d = get_icache_index(wdata_d.target);
assign cf_wdata_d.cf = wdata_d.cf;

// reset logic
logic is_reseting;
logic [$clog2(CHANNEL_SIZE)-1:0] reset_addr;
assign btb_ready = ~is_reseting;

// read request
assign raddr   = get_index(vaddr);
for(genvar i = 0; i < 2; ++i) begin: gen_result
	assign predict[i].cf = cf_rdata[i].cf;
	assign predict[i].target = {
		rdata[i].target[31 : IC_INDEX_OFFSET + IC_INDEX_WIDTH],
		ic_rdata[i],
		rdata[i].target[IC_INDEX_OFFSET - 1 : 0]
	};
end

always_comb begin
	we    = '0;
	waddr = '0;
	wdata = '0;

	// write request through read channel
	if(presolved_branch.mispredict) begin
		we[0] = presolved_branch.mispredict & ~presolved_branch.pc[2];
		we[1] = presolved_branch.mispredict & presolved_branch.pc[2];
		waddr = get_index(presolved_branch.pc);
		wdata = '0;
	end

	// write request from branch resolved branch
	if(update.valid) begin
		we[0]        = ~update.pc[2] & update.valid;
		we[1]        = update.pc[2]  & update.valid;
		waddr        = get_index(update.pc);
		wdata.target = update.target;
		wdata.cf     = update.cf;
	end

	// reset request
	if(is_reseting) begin
		we    = 2'b11;
		waddr = reset_addr;
		wdata = '0;
	end
end

// reset control
always_ff @(posedge clk) begin
	if(rst) begin
		is_reseting <= 1'b1;
		reset_addr  <= '0;
	end else if(&reset_addr) begin
		is_reseting <= 1'b0;
	end else begin
		reset_addr  <= reset_addr + 1;
	end
end

// delayed write request
always_ff @(posedge clk) begin
	if(rst) begin
		we_d     <= '0;
		waddr_d  <= '0;
		wdata_d  <= '0;
	end else begin
		we_d     <= we;
		waddr_d  <= waddr;
		wdata_d  <= wdata;
	end
end

for(genvar i = 0; i < 2; ++i) begin : gen_btb_ram
	dual_port_ram #(
		.SIZE  ( CHANNEL_SIZE  ),
		.dtype ( btb_predict_t )
	) btb_ram (
		.clk,
		.rst,
		.ena   ( 1'b1     ),
		.enb   ( 1'b1     ),
		.wea   ( 1'b0     ),
		.addra ( raddr    ),
		.dina  ( '0       ),
		.douta ( rdata[i] ),
		.web   ( we_d[i]  ),
		.addrb ( waddr_d  ),
		.dinb  ( wdata_d  ),
		.doutb (          )
	);

	dual_port_lutram #(
		.SIZE  ( CHANNEL_SIZE   ),
		.dtype ( icache_index_t )
	) btb_icache_index_ram (
		.clk,
		.rst,
		.ena   ( 1'b1        ),
		.enb   ( 1'b1        ),
		.wea   ( we_d[i]     ),
		.addra ( waddr_d     ),
		.dina  ( ic_wdata_d  ),
		.douta (             ),
		.addrb ( raddr       ),
		.doutb ( ic_rdata[i] )
	);

	dual_port_lutram #(
		.SIZE  ( CHANNEL_SIZE   ),
		.dtype ( cf_packed_t    )
	) btb_cf_ram (
		.clk,
		.rst,
		.ena   ( 1'b1        ),
		.enb   ( 1'b1        ),
		.wea   ( we_d[i]     ),
		.addra ( waddr_d     ),
		.dina  ( cf_wdata_d  ),
		.douta (             ),
		.addrb ( raddr       ),
		.doutb ( cf_rdata[i] )
	);
end

endmodule
