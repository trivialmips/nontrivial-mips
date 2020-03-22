`include "common_defs.svh"

`define PATH_PREFIX "testbench/cache/cases/"

`define CASE_NAME "random.be.data"
localparam int unsigned REQ_COUNT = 50000;

module dcache_tb();

  logic rst, clk;
  axi_req_t axi_req;
  axi_resp_t axi_resp;

  always #5 clk = ~clk;

  mem_device mem (
               .clk (clk),
               .rst (rst),
               .axi_req (axi_req),
               .axi_resp (axi_resp)
             );

  cpu_dbus_if dbus();
  cpu_dbus_if dbus_dummy();

  assign dbus_dummy.invalidate = 1'b0;
  assign dbus_dummy.read = 1'b0;
  assign dbus_dummy.write = 1'b0;

  // Size = 2048, Line-Width = 256 => 8 lines
  // Assoc = 2, so we have 4 lines in each ram
  //
  // Line byte offset = 5,
  // Index width = 2
  // So we generated data in addr 0x00 ~ 0xFF should be enough to test all
  // scenarios

  dcache #(
           .CACHE_SIZE (2048),
           .WB_FIFO_DEPTH (2)
         ) cache (
           .clk (clk),
           .rst (rst),
           .axi_req (axi_req),
           .axi_resp (axi_resp),

           .dbus (dbus),
           .dbus_uncached (dbus_dummy),

           .axi_req_awid ( /* open */ ),
           .axi_req_arid ( /* open */ ),
           .axi_req_wid ( /* open */ ),
           .axi_resp_rid (4'b0000),
           .axi_resp_bid (4'b0000)
         );

  logic [$clog2(REQ_COUNT+3):0] req;
  logic [REQ_COUNT+3:0][31:0] address;
  logic [REQ_COUNT+3:0][31:0] data;
  logic [REQ_COUNT+3:0][3:0] be;
  typedef enum logic [1:0] {
            READ, WRITE, INVALIDATE
          } req_type_t;
  req_type_t req_type [REQ_COUNT+3:0];
  req_type_t current_type;

  assign dbus.address = address[req];
  assign dbus.wrdata = data[req];
  assign current_type = req_type[req];
  assign dbus.read           = current_type == READ;
  assign dbus.write          = current_type == WRITE;
  assign dbus.invalidate     = current_type == INVALIDATE;
  assign dbus.byteenable     = be[req];

  always_ff @(posedge clk or posedge rst)
    begin
      if(rst)
        begin
          req <= 0;
        end
      else if(~dbus.stall)
        begin
          req <= req + 1;
        end
    end

  integer cycle;
  int stall_counter;
  int w_counter;
  int r_counter;

  always_ff @(negedge clk)
    begin
      cycle <= rst ? '0 : cycle + 1;
      if(~rst && req > 1 && ~dbus.stall)
        begin
          $display("[%0d] req = %0d, data = %08x", cycle, req-2, dbus.rddata);
          if(req_type[req-2] == READ && ~(dbus.rddata == data[req-2]))
            begin
              $display("[Error] expected = %08x", data[req-2]);
              $stop;
            end

          // if(dbus.early_valid) begin
          //     $display("[%0d] early: req = %0d, data = %08x", cycle, req-1, dbus.early_rddata);
          //     if(~(dbus.early_rddata == data[req-1])) begin
          //         $display("[Error] expected early_rddata = %08x, got", data[req-1]);
          //         $stop;
          //     end
          // end

          if(req == REQ_COUNT+1)
            begin
              $display("[pass]");
              $display("  Stall count: %d", stall_counter);
              $display("  Read count: %d", r_counter);
              $display("  Write count: %d", w_counter);
              $finish;
            end
        end
    end

  always_ff @(posedge rst or posedge dbus.stall)
    begin
      if(rst)
        begin
          stall_counter <= 0;
        end
      else
        begin
          stall_counter <= stall_counter + 1;
        end
    end

  always_ff @(posedge rst or posedge axi_req.arvalid)
    begin
      if(rst)
        begin
          r_counter <= 0;
        end
      else
        begin
          r_counter <= r_counter + 1;
        end
    end

  always_ff @(posedge rst or posedge axi_req.awvalid)
    begin
      if(rst)
        begin
          w_counter <= 0;
        end
      else
        begin
          w_counter <= w_counter + 1;
        end
    end

  int fd, path_counter;
  byte mode [REQ_COUNT-1:0];
  int status;
  string path;

  initial
    begin
      rst = 1'b1;
      clk = 1'b1;

      path_counter = 0;
      if(!$fopen({ path, `CASE_NAME }, "r"))
        begin
          path = `PATH_PREFIX;
          while(!$fopen({ path, `CASE_NAME }, "r") && path_counter < 20)
            begin
              path_counter++;
              path = { "../", path };
            end
        end

      fd = $fopen({ path, `CASE_NAME }, "r");
      for(int i = 0; i < REQ_COUNT; i++)
        begin
          status = $fscanf(fd, "%c %h %h %h\n", mode[i], address[i], data[i], be[i]);
          $display("%d", status);
          case(mode[i])
            "r"
            :
              req_type[i] = READ;
            "w"
            :
              req_type[i] = WRITE;
            "i"
            :
              req_type[i] = INVALIDATE;
          endcase
        end

      // Read file

      #51 rst = 1'b0;
      wait(req == REQ_COUNT + 2);
    end

endmodule
