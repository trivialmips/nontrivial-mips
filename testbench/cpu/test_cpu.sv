`include "cpu_defs.svh"

`define PATH_PREFIX "testbench/cpu/testcases/"

module test_cpu_tb();

cpu_interrupt_t intr;
assign intr = '0;

logic rst, clk;
cpu_clock clk_inst(.*);

cpu_ibus_if ibus();
fake_ibus ibus_inst(.*);

cpu_dbus_if dbus();
fake_dbus dbus_inst(.*);

cpu_core core_inst(.*);

logic mem_access_path1;
pipeline_memwb_t [1:0] pipe_wb;
pipeline_exec_t [1:0] pipe_exec_d;
assign pipe_wb = core_inst.pipeline_wb;
assign pipe_exec_d = core_inst.pipeline_exec_d;
assign mem_access_path1 = pipe_exec_d[0].memreq.read | pipe_exec_d[0].memreq.write;

task judge(input integer fans, input integer cycle, input string out);
	string ans;
	$fscanf(fans, "%s\n", ans);
	if(out != ans && ans != "skip")
	begin
		$display("[%0d] %s", cycle, out);
		$display("[Error] Expected: %0s, Got: %0s", ans, out);
		$stop;
	end else begin
		$display("[%0d] %s [%s]", cycle, out, ans == "skip" ? "skip" : "pass");
	end
endtask

logic dbus_we_delay;
logic [15:0] dbus_addr_delay;
logic [31:0] dbus_data_delay;
always @(negedge clk) begin
	dbus_we_delay   <= dbus_inst.pipe_write | dbus_inst.pipe_uncached_write;
	dbus_addr_delay <= { dbus_inst.pipe_addr[15:2], 2'b0 };
	dbus_data_delay <= dbus_inst.wrdata;
end

logic post_stall;
always @(negedge clk) begin
	post_stall <= dbus_inst.dbus.stall;
end

string path;

task unittest(
	input string name
);
	integer i, fans, fmem, cycle, path_counter, mem_counter;
	string ans, out, info;

	ibus_inst.mem = '{ default: '0 };
	dbus_inst.mem = '{ default: '0 };

	path_counter = 0;
	if(!$fopen({ path, name, ".ans"}, "r")) begin
		path = `PATH_PREFIX;
		while(!$fopen({ path, name, ".ans"}, "r") && path_counter < 20) begin
			path_counter++;
			path = { "../", path };
		end
	end

	begin 
		fans = $fopen({ path, name, ".ans"}, "r");
		fmem = $fopen({ path, name, ".mem"}, "r");
		ibus_inst.mem = '{default: 'x};
		mem_counter = 0;
		while(!$feof(fmem)) begin
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
	begin @(negedge clk);
		cycle = cycle + 1;
		intr[0] = (40 <= cycle && cycle <= 45);

		if(!post_stall) begin
			if(dbus_we_delay && mem_access_path1) begin
				$sformat(out, "[0x%x]=0x%x", dbus_addr_delay[15:0], dbus_data_delay);
				judge(fans, cycle, out);
			end 

			if(pipe_wb[0].rd != '0) begin
				$sformat(out, "$%0d=0x%x", pipe_wb[0].rd, pipe_wb[0].wdata);
				judge(fans, cycle, out);
			end 

			if(pipe_wb[0].hiloreq.we) begin
				$sformat(out, "$hilo=0x%x", pipe_wb[0].hiloreq.wdata);
				judge(fans, cycle, out);
			end 

			if(dbus_we_delay && ~mem_access_path1) begin
				$sformat(out, "[0x%x]=0x%x", dbus_addr_delay[15:0], dbus_data_delay);
				judge(fans, cycle, out);
			end 

			if(pipe_wb[1].rd != '0) begin
				$sformat(out, "$%0d=0x%x", pipe_wb[1].rd, pipe_wb[1].wdata);
				judge(fans, cycle, out);
			end 

			if(pipe_wb[1].hiloreq.we) begin
				$sformat(out, "$hilo=0x%x", pipe_wb[1].hiloreq.wdata);
				judge(fans, cycle, out);
			end 
		end
	end

	$display("[OK] %0s\n", name);

endtask

initial
begin
	wait(rst == 1'b0);
	unittest("instr/ori");
	unittest("instr/logical");
	unittest("instr/move");
	unittest("instr/shift");
	unittest("instr/trap");
	unittest("instr/arith");
	unittest("instr/jump");
	unittest("instr/mem_aligned");
	unittest("instr/mem_unaligned");
	unittest("instr/llsc");
	unittest("instr/multicyc");
	unittest("except/except");
	unittest("except/delayslot");
	unittest("except/interrupt");
	unittest("except/timer");
	unittest("sys/usermode");
	unittest("across_tlb/1");
	unittest("across_tlb/2");
	unittest("across_tlb/3");
	unittest("across_tlb/4");
	unittest("across_tlb/5");
	unittest("across_tlb/6");
	// unittest("branch_loop");
	$display("[Done]\n");
	$finish;
end

endmodule
