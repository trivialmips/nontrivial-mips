module mem #(
    parameter WIDTH = 32,
    parameter SIZE = 1024
) (
    input wire clk,

    input wire write,

    input wire [$clog2(SIZE)-1:0] addr,
    input wire [WIDTH-1:0] wdata,
    // input wire [WIDTH/8-1:0] byteenable,
    output logic [WIDTH-1:0] rdata
);

logic [WIDTH-1:0] mem [SIZE-1:0];

always_comb
begin
    rdata = mem[addr];
end

always_ff @(posedge clk)
begin
    if(write) begin
        mem[addr] <= wdata;
    end
end

endmodule
