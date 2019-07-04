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

logic rst_n, clk;
cpu_clock clk_inst(.rst_n, .clk);

cpu_ibus_if ibus();
fake_ibus ibus_inst(.clk, .rst_n, .ibus);

logic flush_pc, flush_bp, stall;
logic except_valid;
virt_t except_vec;
branch_resolved_t    resolved_branch;
instr_fetch_memres_t icache_res;
instr_fetch_memreq_t icache_req;
fetch_ack_t   fetch_ack;
fetch_entry_t [`FETCH_NUM-1:0] fetch_entry;

instr_fetch if_inst(.*);
resolv_instr_fetch_req resolv_ibus_req_inst(.*);

always_comb begin
	if(~rst_n) begin
		fetch_ack = 0;
	end else if(fetch_entry[0].valid) begin
		fetch_ack = 1;
	end else begin
		fetch_ack = 0;
	end
end

task judge(input integer fans, input integer cycle, input fetch_entry_t entry);
	string cf_type;
	integer pc;
	$fscanf(fans, "%d,%s\n", pc, cf_type);
	if((entry.vaddr[15:0] >> 2) == pc - 1)
	begin
		$display("[%0d] %d, %s [pass]", cycle, pc - 1, cf_type);
	end else begin
		$display("[%0d] %d, %s", cycle, pc - 1, cf_type);
		$display("[Error] Expected: %d, Got: %d", pc - 1, entry.vaddr[15:0] >> 2);
		$stop;
	end
endtask

string path;

task unittest(
	input string name
);

integer fans, fmem, cycle, path_counter, mem_counter;

path_counter = 0;
path = `PATH_PREFIX;
while(!$fopen({ path, name, ".ans"}, "r") && path_counter < 20) begin
	path_counter++;
	path = { "../", path };
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
while(!$feof(fans)) begin
	@(negedge clk);
		cycle = cycle + 1;

		if(fetch_entry[0].valid) begin
			judge(fans, cycle, fetch_entry[0]);
		end
end

$display("[OK] %0s\n", name);

endtask

initial begin
	flush_pc = 1'b0;
	flush_bp = 1'b0;
	stall = 1'b0;
	except_valid = 1'b0;
	except_vec = '0;
	resolved_branch = '0;

	wait(rst_n == 1'b1);
	unittest("jump");
end

endmodule
