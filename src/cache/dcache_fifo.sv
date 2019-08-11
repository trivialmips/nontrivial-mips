// FIFO with query / random write
// Tag must only appear once in the FIFO

module dcache_fifo #(
    parameter int unsigned DEPTH = 8, // Needs to be greater than 1
    parameter int unsigned TAG_WIDTH = 32,
    parameter int unsigned DATA_WIDTH = 128,

    parameter type line_t = logic [TAG_WIDTH + DATA_WIDTH - 1:0],
    parameter type tag_t = logic [TAG_WIDTH-1:0],
    parameter type data_t = logic [DATA_WIDTH-1:0],
    parameter type be_t = logic [DATA_WIDTH/8-1:0]
) (
    input logic  clk,
    input logic  rst,

    output line_t rline,
    input line_t pline,

    output logic full,
    output logic empty,

    input tag_t query_tag,
    output logic query_found,
    input data_t query_wdata,
    output data_t query_rdata,
    input be_t query_wbe,

    input logic pop,
    input logic push,
    input logic write,

    output logic written,
    output logic pushed
);

localparam int unsigned ADDR_WIDTH = DEPTH == 0 ? 0 : $clog2(DEPTH) + 1; // For example, we need 4 bit to store 0~8

generate if(DEPTH > 0) begin
    typedef logic [ADDR_WIDTH-1:0] addr_t;

    addr_t head, head_d, tail, tail_d;
    addr_t cnt, cnt_d;

    line_t [DEPTH-1:0] mem, mem_d;
    logic [DEPTH-1:0] valid, valid_d;

    logic [DEPTH-1:0] hit;
    logic [DEPTH-1:0] hit_non_pop;
    for(genvar i = 0; i < DEPTH; i++) begin
        assign hit[i] = valid[i] && mem[i][DATA_WIDTH +: TAG_WIDTH] == query_tag;
        assign hit_non_pop[i] = (pop && head == i[ADDR_WIDTH-1:0]) ? 1'b0 : hit[i];
    end

    assign query_found = |hit;

    always_comb begin
        query_rdata = '0;

        for(int i = 0; i < DEPTH; i++) begin
            query_rdata |= hit[i] ? mem[i][0 +: DATA_WIDTH] : '0;
        end
    end

    // Grow --->
    // O O O X X X X O O
    //       H       T

    assign empty = cnt == '0;
    assign full = cnt == DEPTH[ADDR_WIDTH-1:0];

    assign rline = mem[head];

    always_comb begin
        cnt_d = cnt;
        head_d = head;
        tail_d = tail;
        mem_d = mem;
        valid_d = valid;

        written = 1'b0;
        pushed = 1'b0;

        if(push && ~full) begin
            mem_d[tail] = pline;
            valid_d[tail] = 1'b1;

            if(tail == DEPTH[ADDR_WIDTH-1:0] - 1) begin
                tail_d = '0;
            end else begin
                tail_d = tail + 1;
            end

            cnt_d = cnt+1;

            pushed = 1'b1;
        end

        if(pop && ~empty) begin
            valid_d[head] = 1'b0;

            if(head == DEPTH[ADDR_WIDTH-1:0] - 1) begin
                head_d = '0;
            end else begin
                head_d = head + 1;
            end

            cnt_d = cnt - 1;
        end

        if(push && ~full && pop && ~empty) begin
            cnt_d = cnt;
        end

        if(write && |hit_non_pop) begin
            for(int i = 0; i < DEPTH; i++) if(hit_non_pop[i])
                for(int j = 0; j<DATA_WIDTH/8; j++) if(query_wbe[j])
                    mem_d[i][j*8+:8] = query_wdata[j*8+:8];

            written = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            head <= '0;
            tail <= '0;
            cnt <= '0;
            valid <= '0;
        end else begin
            head <= head_d;
            tail <= tail_d;
            cnt <= cnt_d;
            valid <= valid_d;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            mem <= '0;
        end else if(written || pushed) begin
            mem <= mem_d;
        end
    end

end else begin
    // 0-depth fallthrough
    
    // Because this is a 0-depth fallthrough FIFO, random RW never happens
    assign written = 1'b0;
    assign query_found = 1'b0;

    // Reject push unless there is a concurrent pop request
    assign full = ~pop;
    assign pushed = pop & push;

    // Same for pop
    assign empty = ~push;

    assign rline = pline;
end endgenerate
endmodule
