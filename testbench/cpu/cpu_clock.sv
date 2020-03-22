`include "cpu_defs.svh"

module cpu_clock(
    output logic clk,
    output logic rst
  );

  always #20 clk = ~clk;
  initial
    begin
      rst = 1'b1;
      clk = 1'b0;
      #50 rst = 1'b0;
    end

endmodule
