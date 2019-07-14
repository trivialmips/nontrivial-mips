`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/14/2017 04:46:38 PM
// Design Name: 
// Module Name: ps2_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ps2_tb(
    );

reg[31:0] paddr = 0;
reg chipselect = 0;
reg psel = 0;
reg [3:0] byteenable = 'b1111;
reg write = 0;
reg clk = 0, reset_n = 0;
reg [31:0] writedata = 0;
reg PS2_CLK_DEV = 1, PS2_DAT_DEV = 1;
wire PS2_CLK_t, PS2_CLK_i, PS2_DAT_t, PS2_DAT_i;
wire waitrequest_n;

always #5 clk = ~clk;

initial begin 
    repeat(10) @(negedge clk);
    reset_n = 1;
    @(negedge clk);
    psel = 1;
    paddr = 0;
    write = 1;
    writedata = 'hee;
    @(negedge clk);
    chipselect = 1;
    do begin
        @(negedge clk);
    end while(waitrequest_n == 0);
    chipselect = 0;
    psel = 0;

    @(negedge clk);
    psel = 1;
    paddr = 0;
    write = 1;
    writedata = 'hee;
    @(negedge clk);
    chipselect = 1;
    do begin
        @(negedge clk);
    end while(waitrequest_n == 0);
    chipselect = 0;
    psel = 0;

    #2200000;
    @(negedge clk);
    psel = 1;
    paddr = 0;
    write = 0;
    @(negedge clk);
    chipselect = 1;
    do begin
        @(negedge clk);
    end while(waitrequest_n == 0);
    chipselect = 0;
    psel = 0;

    @(negedge clk);
    psel = 1;
    paddr = 0;
    write = 0;
    @(negedge clk);
    chipselect = 1;
    do begin
        @(negedge clk);
    end while(waitrequest_n == 0);
    chipselect = 0;
    psel = 0;

end

integer tmp_data;
always begin 
    @(negedge PS2_CLK_i);
    @(posedge PS2_CLK_i);
    #138000;
    repeat(11)begin
        #40000;
        PS2_CLK_DEV = 0;
        #40000;
        PS2_CLK_DEV = 1;
    end

    @(negedge PS2_CLK_i);
    @(posedge PS2_CLK_i);
    #138000;
    repeat(11)begin
        #40000;
        PS2_CLK_DEV = 0;
        #40000;
        PS2_CLK_DEV = 1;
    end

    #200000;
    tmp_data = 11'b11001110100;
    repeat(11)begin
        PS2_DAT_DEV = tmp_data & 1;
        tmp_data >>= 1;
        #20000;
        PS2_CLK_DEV = 0;
        #40000;
        PS2_CLK_DEV = 1;
        #20000;
    end
    #200000;
    tmp_data = 11'b11010110100;
    repeat(11)begin
        PS2_DAT_DEV = tmp_data & 1;
        tmp_data >>= 1;
        #20000;
        PS2_CLK_DEV = 0;
        #40000;
        PS2_CLK_DEV = 1;
        #20000;
    end
end

assign PS2_CLK_i = PS2_CLK_DEV & PS2_CLK_t;
assign PS2_DAT_i = PS2_DAT_DEV & PS2_DAT_t;

testPS2qsys_ps2_0 dut(
    .paddr        (paddr),
    .chipselect   (chipselect),
    .psel         (psel),
    .byteenable   (byteenable),
    .write        (write),
    .writedata    (writedata),
    .PS2_CLK_i    (PS2_CLK_i),
    .PS2_CLK_o    (),
    .PS2_CLK_t    (PS2_CLK_t),
    .PS2_DAT_i    (PS2_DAT_i),
    .PS2_DAT_o    (),
    .PS2_DAT_t    (PS2_DAT_t),
    .irq          (),
    .readdata     (),
    .waitrequest_n(waitrequest_n),
    .clk          (clk),
    .reset_n      (reset_n)
);

endmodule
