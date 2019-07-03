`include "cpu_defs.svh"

module btb #(
	parameter int ENTRIES_NUM = 16
)(
	input  logic         clk,
	input  logic         rst_n,
	input  logic         flush,

	input  virt_t        pc,     // aligned in 8-bytes
	input  btb_update_t  update,
	output btb_predict_t [`FETCH_NUM-1:0] predict
);

localparam OFFSET        = 2;
localparam ROW_NUM       = ENTRIES_NUM / `FETCH_NUM;
localparam ROW_ADDR_BITS = $clog2(`FETCH_NUM);
localparam INDEX_OFFSET  = OFFSET + ROW_ADDR_BITS;
localparam ADDR_BITS     = $clog2(ENTRIES_NUM) + OFFSET;

btb_predict_t btb_now[ROW_NUM-1:0][`FETCH_NUM-1:0];
btb_predict_t btb_nxt[ROW_NUM-1:0][`FETCH_NUM-1:0];

// output prediction
logic [$clog2(ROW_NUM)-1:0] index;
assign index = pc[ADDR_BITS-1:INDEX_OFFSET];

for(genvar i = 0; i < `FETCH_NUM; ++i) begin: gen_assign_btb_predict
	assign predict[i] = btb_now[index][i];
end

// set new prediction
logic [$clog2(ROW_NUM)-1:0] update_index;
logic [ROW_ADDR_BITS-1:0] update_row_addr;
assign update_index = update.pc[ADDR_BITS-1:INDEX_OFFSET];
assign update_row_addr = update.pc[INDEX_OFFSET-1:OFFSET];

always_comb begin
	btb_nxt = btb_now;
	if(update.valid) begin
		btb_nxt[update_index][update_row_addr].valid  = 1'b1;
		btb_nxt[update_index][update_row_addr].target = update.target;
	end
end

// update prediction
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(int i = 0; i < ROW_NUM; ++i) begin
			btb_now[i] <= '{default: 0};
		end
	end else begin
		if(flush) begin
			for(int i = 0; i < ROW_NUM; ++i) begin
				for(int j = 0; j < `FETCH_NUM; ++j) begin
					btb_now[i][j].valid <= 1'b0;
				end
			end
		end else begin
			btb_now <= btb_nxt;
		end
	end
end

endmodule
