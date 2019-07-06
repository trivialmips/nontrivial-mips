`include "cpu_defs.svh"

`define PATH_PREFIX "testbench/cpu/testcases/"

module test_cpu_tb();

cpu_interrupt_t intr;
assign intr = '0;

logic rst_n, clk;
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
always @(negedge clk)
begin
	dbus_we_delay   <= dbus_inst.dbus.write;
	dbus_addr_delay <= { dbus_inst.dbus.address[15:2], 2'b0 };
	dbus_data_delay <= dbus_inst.dbus.wrdata;
end

logic post_stall;
always @(negedge clk)
begin
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
		rst_n = 1'b0;
		#50 rst_n = 1'b1;
	end

	$display("======= unittest: %0s =======", name);

	cycle = 0;
	while(!$feof(fans))
	begin @(negedge clk);
		cycle = cycle + 1;

		if(!post_stall) begin
			if(dbus_we_delay && mem_access_path1) begin
				$sformat(out, "[0x%x]=0x%x", dbus_addr_delay[15:0], dbus_data_delay);
				judge(fans, cycle, out);
			end 

			if(pipe_wb[0].rd != '0)
			begin
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

			if(pipe_wb[1].rd != '0)
			begin
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
	wait(rst_n == 1'b1);
	unittest("inst_ori");
	unittest("inst_logical");
	unittest("inst_move");
	unittest("inst_shift");
	unittest("inst_jump");
	unittest("branch_loop");
	// unittest("inst_multicyc");
	$display("[Done]\n");
	$finish;
end

endmodule
