// Pseudo-LRU generator
// Only supports SET_ASSOC = 2 or 4

module plru #(
    parameter int unsigned SET_ASSOC = 4
) (
    input clk,
    input rst,

    input [SET_ASSOC-1:0] access,
    input update,

    output [$clog2(SET_ASSOC)-1:0] lru
);

logic [SET_ASSOC-2:0] state, state_d;

// Assign output
generate
if(SET_ASSOC == 2) begin
    assign lru = state;
end else begin
    assign lru = state[2] == 1'b0 ? state[2-:2] : {state[2], state[0]};
end
endgenerate

// Update
generate
if(SET_ASSOC == 2) begin
    always_comb begin
        state_d = state;

        if(update && |access) begin
            if(access[0]) begin
                state_d[0] = 1;
            end else begin
                state_d[0] = 0;
            end
        end
    end
end else begin
    always_comb begin
        state_d = state;

        casez(access)
            4'b1???: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            4'b01??: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            4'b001?: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            4'b0001: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end
        endcase
    end
end
endgenerate

always_ff @(posedge clk) begin
    if(rst) begin
        state <= '0;
    end else if(update) begin
        state <= state_d;
    end
end

endmodule
