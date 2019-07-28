`include "cpu_defs.svh"

`define PATH_PREFIX "testbench/cpu/testcases/"
`define CHECK_RESULT 0

module test_OoO_tb();

cpu_interrupt_t intr;
assign intr = '0;

logic sync_rst;
logic rst, clk, fake_stall_en;
assign fake_stall_en = 1'b1;
cpu_clock clk_inst(.*);

always_ff @(posedge clk) begin
	sync_rst <= rst;
end

cpu_ibus_if ibus();
fake_ibus ibus_inst(.rst(sync_rst), .*);

cpu_dbus_if dbus();
cpu_dbus_if dbus_uncached();
fake_dbus dbus_inst(.rst(sync_rst), .*);

cpu_core core_inst(.rst(sync_rst), .*);

data_memreq_t memreq;
logic [1:0] reg_we;
uint32_t [1:0] reg_wdata;
reg_addr_t [1:0] reg_waddr;
assign memreq = core_inst.lsu_store_memreq;
assign reg_we = core_inst.reg_we;
assign reg_wdata = core_inst.reg_wdata;
assign reg_waddr = core_inst.reg_waddr;

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

string path;
string summary;

task unittest_(
	input string name,
	input integer check_total_cycles
);
	integer i, fans, fmem, cycle, path_counter, mem_counter, last_write;
	integer instr_count;
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

	instr_count = 0;
	cycle = 0;
	while(!$feof(fans))
	begin @(negedge clk);
		cycle = cycle + 1;
		intr[0] = (4000 <= cycle && cycle <= 4005);

		if(reg_we[0] && reg_waddr[0] != '0) begin
			$sformat(out, "$%0d=0x%x", reg_waddr[0], reg_wdata[0]);
			judge(fans, cycle, out);
		end 

		if(cpu_core.lsu_store_push && cpu_core.instr_commit_inst.is_store[0]) begin
			$sformat(out, "[0x%x]=0x%x", memreq.paddr[15:0], memreq.wrdata);
			judge(fans, cycle, out);
		end

		if(reg_we[1] && reg_waddr[1] != '0) begin
			$sformat(out, "$%0d=0x%x", reg_waddr[1], reg_wdata[1]);
			judge(fans, cycle, out);
		end 

		if(cpu_core.lsu_store_push && cpu_core.instr_commit_inst.is_store[1]) begin
			$sformat(out, "[0x%x]=0x%x", memreq.paddr[15:0], memreq.wrdata);
			judge(fans, cycle, out);
		end
	end

	$display("[OK] %0s\n", name);

endtask

task unittest(input string name);
	unittest_(name, 0);
endtask

task unittest_cycle(input string name);
	unittest_(name, 1);
endtask

initial
begin
	wait(rst == 1'b0);
	summary = "";
	unittest("instr/mem_aligned");
	unittest("instr/mem_unaligned");
	unittest("instr/ori");
	unittest("instr/logical");
	unittest("instr/shift");
	unittest("instr/jump");
	unittest("instr/trap");

	unittest("except/delayslot");
	$display(summary);
	$display("[Done]\n");
	$finish;
end

endmodule
