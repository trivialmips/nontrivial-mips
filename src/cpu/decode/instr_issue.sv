`include "cpu_defs.svh"

// only support ISSUE_NUM == 2
module instr_issue(
	input  fetch_entry_t     [`ISSUE_NUM-1:0] fetch_entry,
	input  decoded_instr_t   [`ISSUE_NUM-1:0] id_decoded,
	input  decoded_instr_t   [`ISSUE_NUM-1:0] ex_decoded,
	input  decoded_instr_t   [`DCACHE_PIPE_DEPTH-1:0][`ISSUE_NUM-1:0] dcache_decoded,
	input  logic             delayslot_not_exec,
	output decoded_instr_t   [`ISSUE_NUM-1:0] issue_instr,
	output logic   [$clog2(`ISSUE_NUM+1)-1:0] issue_num,
	output logic   stall_req
);

function logic is_hilo(
	input uint32_t instr
);
	// MFHI, MTHI, MFLO, MTLO, MULT, MULTU, DIV, DIVU
	return instr[31:26] == 6'b000000 && instr[5:4] == 2'b01 && instr[2] == 1'b0
	// MADD, MADDU, MSUB, MSUBU
	    || instr[31:26] == 6'b011100 && instr[5:3] == 3'b000 && instr[1] == 1'b0;
endfunction

function logic is_ssnop(
	input fetch_entry_t entry
);
	return entry.valid & entry.instr == 32'h40;
endfunction

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

logic instr2_not_taken;
logic priv_executing, nonrw_priv_executing;
logic [`ISSUE_NUM-1:0] instr_valid;
logic [`ISSUE_NUM-1:0] load_related, mem_access, hilo_access;

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_access
	assign mem_access[i]  = id_decoded[i].is_load | id_decoded[i].is_store;
	assign instr_valid[i] = fetch_entry[i].valid;
	assign hilo_access[i] = is_hilo(fetch_entry[i].instr);
end

always_comb begin
	load_related = '0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			load_related[i] |= is_load_related(
				id_decoded[i], ex_decoded[j]);
			for(int k = 0; k < `DCACHE_PIPE_DEPTH - 1; ++k) begin
				load_related[i] |= is_load_related(
					id_decoded[i], dcache_decoded[k][j]);
			end
		end
	end
	load_related &= instr_valid;
end

always_comb begin
	priv_executing = 1'b0;
	nonrw_priv_executing = 1'b0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		priv_executing |= ex_decoded[i].is_priv;
		nonrw_priv_executing |= ex_decoded[i].is_nonrw_priv;
		for(int k = 0; k < `DCACHE_PIPE_DEPTH; ++k) begin
			priv_executing |= dcache_decoded[k][i].is_priv;
			nonrw_priv_executing |= dcache_decoded[k][i].is_nonrw_priv;
		end
	end
end

// logic delayslot_load_related;
// always_comb begin
// 	delayslot_load_related = id_decoded[0].is_load;
// 	for(int i = 0; i < `ISSUE_NUM; ++i) begin
// 		delayslot_load_related |= ex_decoded[i].is_load;
// 		for(int k = 0; k < `DCACHE_PIPE_DEPTH - 2; ++k)
// 			delayslot_load_related |= dcache_decoded[k][i].is_load;
// 	end
// 	delayslot_load_related &= id_decoded[1].is_controlflow;
// end
assign delayslot_not_loaded;
assign delayslot_not_loaded = id_decoded[0].is_controlflow & ~instr_valid[1];

assign instr2_not_taken = 
      ~instr_valid[1]
   || is_data_related(id_decoded[0], id_decoded[1])
   || (mem_access[0] & mem_access[1])
   || (hilo_access[0] & hilo_access[1])
      // mispredict but delayslot does not executed
   || delayslot_not_exec
      // branch must be issued on pipeline 1
   || id_decoded[1].is_controlflow
   || (is_ssnop(fetch_entry[0]) | is_ssnop(fetch_entry[1]))
   || (id_decoded[0].op == OP_SC || id_decoded[1].op == OP_SC)
   || (id_decoded[0].is_priv | id_decoded[1].is_priv)
   || (id_decoded[1].op == OP_DIV || id_decoded[1].op == OP_DIVU);

assign stall_req = load_related[0]
	| (load_related[1] & ~instr2_not_taken)
	| (id_decoded[0].is_nonrw_priv && priv_executing)
	| nonrw_priv_executing
	| delayslot_not_loaded
	| (instr_valid == '0);

always_comb begin
	issue_instr = id_decoded;
	issue_num   = 2;
	if(instr2_not_taken) begin
		issue_num      = 1;
		issue_instr[1] = '0;
	end
end

endmodule
