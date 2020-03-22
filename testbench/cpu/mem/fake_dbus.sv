`include "cpu_defs.svh"

module fake_dbus #(
    parameter DATA_WIDTH = 32,
    parameter CACHE_LINE = 4,
    parameter SIZE       = 8192
  )(
    input logic clk,
    input logic rst,
    input logic fake_stall_en,
    cpu_dbus_if.slave dbus,
    cpu_dbus_if.slave dbus_uncached
  );

  localparam int ADDR_WIDTH = $clog2(SIZE) + 2;
  reg [DATA_WIDTH-1:0] mem[SIZE-1:0];
  reg [SIZE / $clog2(CACHE_LINE)-1:0] hit;

  logic pipe_read, pipe_write, pipe_uncached_read, pipe_uncached_write;
  uint32_t pipe_addr;
  logic [3:0] pipe_sel;
  uint32_t pipe_wrdata;
  logic pipe0_read, pipe0_write, pipe0_uncached_read, pipe0_uncached_write;
  uint32_t pipe0_addr;
  logic [3:0] pipe0_sel;
  uint32_t pipe0_wrdata;

  uint32_t wrdata, rddata;
  assign rddata = mem[pipe_addr[ADDR_WIDTH-1:2]];
  assign wrdata = {
           pipe_sel[3] ? pipe_wrdata[31:24] : rddata[31:24],
           pipe_sel[2] ? pipe_wrdata[23:16] : rddata[23:16],
           pipe_sel[1] ? pipe_wrdata[15:8] : rddata[15:8],
           pipe_sel[0] ? pipe_wrdata[7:0] : rddata[7:0]
         };

  generate if(`DCACHE_PIPE_DEPTH == 1)
      begin : dcache_pipe1
        assign pipe_wrdata = dbus.wrdata;
        assign pipe_read   = dbus.read;
        assign pipe_write  = dbus.write;
        assign pipe_addr   = dbus.address;
        assign pipe_sel    = dbus.byteenable;
        assign pipe_uncached_read  = dbus_uncached.read;
        assign pipe_uncached_write = dbus_uncached.write;
      end
    else
      begin : dcache_pipe2
        always_ff @(posedge clk or posedge rst)
          begin
            if(rst)
              begin
                pipe_wrdata <= '0;
                pipe_read   <= '0;
                pipe_write  <= '0;
                pipe_addr   <= '0;
                pipe_sel    <= '0;
                pipe_uncached_read  <= '0;
                pipe_uncached_write <= '0;
                pipe0_wrdata <= '0;
                pipe0_read   <= '0;
                pipe0_write  <= '0;
                pipe0_addr   <= '0;
                pipe0_sel    <= '0;
                pipe0_uncached_read  <= '0;
                pipe0_uncached_write <= '0;
              end
            else if(~dbus.stall)
              begin
                pipe0_wrdata <= dbus.wrdata;
                pipe0_read   <= dbus.read;
                pipe0_write  <= dbus.write;
                pipe0_addr   <= dbus.address;
                pipe0_sel    <= dbus.byteenable;
                pipe0_uncached_read  <= dbus_uncached.read;
                pipe0_uncached_write <= dbus_uncached.write;
                pipe_wrdata <= pipe0_wrdata;
                pipe_read   <= pipe0_read;
                pipe_write  <= pipe0_write;
                pipe_addr   <= pipe0_addr;
                pipe_sel    <= pipe0_sel;
                pipe_uncached_read  <= pipe0_uncached_read;
                pipe_uncached_write <= pipe0_uncached_write;
              end
          end
      end
  endgenerate

  always_ff @(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          hit       <= '0;
        end
      else if(pipe_read | pipe_write | pipe_uncached_read | pipe_uncached_write)
        begin
          hit[pipe_addr[ADDR_WIDTH-1:2+$clog2(CACHE_LINE)]] <= 1'b1;
        end
    end

  always_ff @(posedge clk or posedge rst)
    begin
      if(~rst)
        begin
          if(pipe_write | pipe_uncached_write)
            begin
              mem[pipe_addr[ADDR_WIDTH-1:2]] <= wrdata;
            end
        end
    end

  logic cache_miss;
  assign cache_miss = (pipe_read | pipe_write | pipe_uncached_read | pipe_uncached_write) & ~hit[pipe_addr[ADDR_WIDTH-1:2+$clog2(CACHE_LINE)]];

  logic [7:0] stall;
  always_ff @(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          stall <= '0;
        end
      else if(fake_stall_en & cache_miss & ~(|stall))
        begin
          stall <= 8'b1000_0000;
        end
      else
        begin
          stall <= stall >> 1;
        end
    end

  always_comb
    begin
      if(rst)
        begin
          dbus.stall  = 1'b0;
          dbus.rddata = 'x;
          dbus_uncached.stall  = 1'b0;
          dbus_uncached.rddata = 'x;
        end
      else
        begin
          dbus.stall  = (cache_miss | (|stall)) & fake_stall_en;
          dbus.rddata = pipe_read ? rddata : 'x;
          dbus_uncached.stall  = (cache_miss | (|stall)) & fake_stall_en;
          dbus_uncached.rddata = pipe_uncached_read ? rddata : 'x;
        end
    end

endmodule
