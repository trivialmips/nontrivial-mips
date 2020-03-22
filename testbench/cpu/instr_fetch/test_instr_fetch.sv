`include "cpu_defs.svh"

`define PATH_PREFIX "testbench/cpu/instr_fetch/testcases/"

module resolv_instr_fetch_req(
    output instr_fetch_memres_t icache_res,
    input  instr_fetch_memreq_t icache_req,
    cpu_ibus_if.master ibus
  );

  assign ibus.read = icache_req.read;
  assign ibus.address = icache_req.vaddr;
  assign icache_res.data = ibus.rddata;
  assign icache_res.iaddr_ex = '0;

endmodule

module test_instr_fetch();

  logic rst, clk;
  cpu_clock clk_inst(.rst, .clk);

  cpu_ibus_if ibus();
  fake_ibus ibus_inst(.clk, .rst, .ibus);

  logic flush_pc, flush_bp, stall;
  logic except_valid;
  virt_t except_vec;
  branch_resolved_t    resolved_branch;
  instr_fetch_memres_t icache_res;
  instr_fetch_memreq_t icache_req;
  fetch_ack_t   fetch_ack;
  fetch_entry_t [`FETCH_NUM-1:0] fetch_entry, fetch_entry_p1, fetch_entry_p2;

  instr_fetch #(.RESET_BASE(0)) if_inst(.*);
  resolv_instr_fetch_req resolv_ibus_req_inst(.*);

  always_ff @(posedge clk)
    begin
      fetch_entry_p1 <= fetch_entry;
      fetch_entry_p2 <= fetch_entry_p1;
    end

  always_comb
    begin
      if(rst)
        begin
          fetch_ack = 0;
        end
      else if(fetch_entry[0].valid)
        begin
          fetch_ack = 1;
        end
      else
        begin
          fetch_ack = 0;
        end
    end

  task judge(input integer fans, input integer cycle, input fetch_entry_t entry);
    string cf_type;
    integer pc, mispredict;
    cf_type = "";
    $fscanf(fans, "%d %s", pc, cf_type);
    pc = pc << 2;
    if(cf_type == "")
      return;

    resolved_branch.cf = ControlFlow_None;
    if(cf_type != "None")
      begin
        resolved_branch.valid = 1'b1;
        resolved_branch.pc    = pc;
        if(cf_type == "JumpImm")
          begin
            resolved_branch.cf = ControlFlow_JumpImm;
          end
        else if(cf_type == "JumpReg")
          begin
            resolved_branch.cf = ControlFlow_JumpReg;
            $fscanf(fans, "%d %d", resolved_branch.target, mispredict);
            resolved_branch.target = resolved_branch.target << 2;
          end
        else if(cf_type == "Branch")
          begin
            resolved_branch.cf = ControlFlow_Branch;
            $fscanf(fans, "%d %d", resolved_branch.taken, mispredict);
          end
        else if(cf_type == "Return")
          begin
            resolved_branch.cf = ControlFlow_Return;
          end
        else
          begin
            $display("[Error] Unknown control flow.");
            $stop;
          end
      end
    else
      begin
        resolved_branch.valid = 1'b0;
      end

    resolved_branch.mispredict = resolved_branch.cf != entry.branch_predict.cf;

    if(entry.vaddr[15:0] != pc)
      begin
        $display("[%0d] %d, %s", cycle, pc >> 2, cf_type);
        $display("[Error] Expected: %d, Got: %d", pc >> 2, entry.vaddr[15:0] >> 2);
        $stop;
      end
    else if((cf_type == "Branch" || cf_type == "JumpReg") && resolved_branch.mispredict != mispredict)
      begin
        $display("[%0d] %d, %s", cycle, pc >> 2, cf_type);
        $display("[Error] Mispredict, expected: %d, got: %d",
                 resolved_branch.mispredict, mispredict);
        $stop;
      end
    else
      begin
        case(cf_type)
          "JumpImm"
          :
            $display("[%0d] %d, %s [pass]", cycle, pc >> 2, cf_type);
          "JumpReg"
          , "Branch":
            $display("[%0d] %d, %s, mispredict=%s [pass]",
                     cycle, pc >> 2, cf_type, mispredict ? "True" : "False");
        endcase
      end
  endtask

  string path;

  task unittest(
      input string name
    );

    integer fans, fmem, cycle, path_counter, mem_counter;

    path_counter = 0;
    path = `PATH_PREFIX;
    while(!$fopen({ path, name, ".ans"}, "r") && path_counter < 20)
      begin
        path_counter++;
        path = { "../", path };
      end

    begin
      fans = $fopen({ path, name, ".ans"}, "r");
      fmem = $fopen({ path, name, ".mem"}, "r");
      ibus_inst.mem = '{default: 'x};
      mem_counter = 0;
      while(!$feof(fmem))
        begin
          $fscanf(fmem, "%x", ibus_inst.mem[mem_counter]);
          mem_counter = mem_counter + 1;
        end
      $fclose(fmem);
      //	$readmemh({ path, name, ".mem" }, ibus_inst.mem);
    end

    begin
      rst = 1'b1;
      #50 rst = 1'b0;
    end

    $display("======= unittest: %0s =======", name);

    cycle = 0;
    while(!$feof(fans))
      begin
        @(negedge clk);
        cycle = cycle + 1;

        resolved_branch.valid = 1'b0;
        if(fetch_entry_p1[0].valid)
          begin
            judge(fans, cycle, fetch_entry_p1[0]);
          end
      end

    $display("[OK] %0s\n", name);

  endtask

  initial
    begin
      flush_pc = 1'b0;
      flush_bp = 1'b0;
      stall = 1'b0;
      except_valid = 1'b0;
      except_vec = '0;
      resolved_branch = '0;

      wait(rst == 1'b0);
      unittest("jump");
      unittest("jump_reg");
      $finish;
    end

endmodule
