`include "cpu_defs.svh"

module bht #(
	parameter int ENTRIES_NUM = 1024
)(
	input  logic         clk,
	input  logic         rst,
	input  logic         flush,

	input  virt_t        pc,
	input  bht_update_t  update,
	output bht_predict_t [`FETCH_NUM-1:0] predict
);

localparam OFFSET        = 2;
localparam ROW_NUM       = ENTRIES_NUM / `FETCH_NUM;
localparam ROW_ADDR_BITS = $clog2(`FETCH_NUM);
localparam INDEX_OFFSET  = OFFSET + ROW_ADDR_BITS;
localparam ADDR_BITS     = $clog2(ENTRIES_NUM) + OFFSET;

typedef struct packed {
	// TODO: we can remove the `valid` field
	logic valid;
	logic [1:0] counter;
} bht_status_t;

bht_status_t bht_now[ROW_NUM-1:0][`FETCH_NUM-1:0];
bht_status_t bht_nxt[ROW_NUM-1:0][`FETCH_NUM-1:0];

// output prediction
logic [$clog2(ROW_NUM)-1:0] index;
assign index = pc[ADDR_BITS-1:INDEX_OFFSET];

for(genvar i = 0; i < `FETCH_NUM; ++i) begin: gen_assign_bht_predict
	assign predict[i].valid = bht_now[index][i].valid;
	assign predict[i].taken = bht_now[index][i].counter[1];
end

// set new prediction
logic [$clog2(ROW_NUM)-1:0] update_index;
logic [ROW_ADDR_BITS-1:0] update_row_addr;
assign update_index = update.pc[ADDR_BITS-1:INDEX_OFFSET];
assign update_row_addr = update.pc[INDEX_OFFSET-1:OFFSET];

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

always_comb begin
	bht_nxt = bht_now;
	if(update.valid) begin
		bht_nxt[update_index][update_row_addr].valid = 1'b1;
		bht_nxt[update_index][update_row_addr].counter = next_counter(
			bht_now[update_index][update_row_addr].counter, update.taken);
	end
end

// update prediction
always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		for(int i = 0; i < ROW_NUM; ++i) begin
			bht_now[i] <= '{default: 0};
		end
	end else begin
		if(flush) begin
			for(int i = 0; i < ROW_NUM; ++i) begin
				for(int j = 0; j < `FETCH_NUM; ++j) begin
					bht_now[i][j].valid   <= 1'b0;
					bht_now[i][j].counter <= 2'b10;
				end
			end
		end else begin
			bht_now <= bht_nxt;
		end
	end
end

endmodule
