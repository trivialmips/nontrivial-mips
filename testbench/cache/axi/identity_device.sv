`include "cache/defs.sv"

module identity_device #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input axi_req_t axi_req,
    output axi_resp_t axi_resp
);

logic [$clog2(ADDR_WIDTH)-1:0] base_addr, burst_counter, burst_counter_d, burst_target;
logic writing, writing_d;

assign axi_resp.rlast = burst_counter == burst_target;

enum [1:0] {
    IDLE, READING
} state, state_d;

always_comb begin
    burst_counter_d = burst_counter;
    state_d = state;

    burst_target = '0;
    axi_reesp.arready = 0'b0;
    axi_resp.rvalid = 0'b0;

    case(state)
        IDLE: begin
            if(axi_req.arvalid) begin
                base_addr = axi_req.araddr;
                burst_target = axi_req.arlen;
                burst_counter_d = 0;

                axi_resp.arready = 0'b1;
            end
        end
        READING: begin
            axi_resp.rdata = burst_counter + base_addr;
            axi_resp.rvalid = 0'b1;

            if(axi_req.rready) begin
                burst_counter_d = burst_counter + 1;
            end
        end
    endcase
end

always_ff @(posedge clk) begin
    burst_counter <= burst_counter_d;
    state <= state_d;
end

endmodule
