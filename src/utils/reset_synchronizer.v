module reset_synchronizer #(
    parameter RESET_STAGE = 3,
    parameter RESET_POSEDGE = 0
) (
    input wire clk,
    input wire rst_i,
    output wire rst_o
);

    reg [RESET_STAGE - 1 : 0] reset_sync;

    assign rst_o = reset_sync[RESET_STAGE - 1];

    generate
    if (RESET_POSEDGE == 0) begin: reset_negedge
        always @(posedge clk, negedge rst_i) begin
            if (!rst_i) begin
                reset_sync <= {RESET_STAGE{1'b0}};
            end else begin
                reset_sync <= {reset_sync[RESET_STAGE - 2:0], 1'b1};
            end
        end
    end else begin: reset_posedge
        always @(posedge clk, posedge rst_i) begin
            if (rst_i) begin
                reset_sync <= {RESET_STAGE{1'b1}};
            end else begin
                reset_sync <= {reset_sync[RESET_STAGE - 2:0], 1'b0};
            end
        end
    end
    endgenerate

endmodule
