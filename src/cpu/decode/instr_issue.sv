`include "cpu_defs.svh"

// only support ISSUE_NUM == 2
module instr_issue(
	input                  [`ISSUE_NUM-1:0] instr_valid,
	input  decoded_instr_t [`ISSUE_NUM-1:0] id_decoded,
	input  decoded_instr_t [`ISSUE_NUM-1:0] ex_decoded,
	output decoded_instr_t [`ISSUE_NUM-1:0] issue_instr,
	output logic [$clog2(`ISSUE_NUM+1)-1:0] issue_num,
	output logic stall_req
);

logic instr2_not_taken;
logic [`ISSUE_NUM-1:0] load_related, mem_access;

function logic is_load_related(
	input decoded_instr_t id,
	input decoded_instr_t ex
);
	return ex.is_load & (
	    ex.rd != '0 && (id.rs1 == ex.rd || id.rs2 == ex.rd)
	);
endfunction

function logic is_data_related(
	input decoded_instr_t id1,
	input decoded_instr_t id2
);
	return id1.rd != '0 && (
		id2.rs1 == id1.rd || id2.rs2 == id1.rd
	);
endfunction

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_mem_access
	assign mem_access[i] = id_decoded[i].is_load | id_decoded[i].is_store;
end

always_comb begin
	load_related = '0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			load_related[i] |= is_load_related(
				id_decoded[i], ex_decoded[j]);
		end
	end
	load_related &= instr_valid;
end

assign instr2_not_taken = 
      ~instr_valid[1]
   || is_data_related(id_decoded[0], id_decoded[1])
   || (mem_access[0] & mem_access[1]);

assign stall_req = (|load_related) | (instr_valid == '0);

always_comb begin
	issue_instr = id_decoded;
	issue_num   = 2;
	if(instr2_not_taken) begin
		issue_num      = 1;
		issue_instr[1] = '0;
	end
end

endmodule
