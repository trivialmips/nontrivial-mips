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

`ifdef ENABLE_FPU
function logic is_fpu_load_related(
	input decoded_instr_t id,
	input decoded_instr_t ex
);
	return ex.is_load & (id.fs1 == ex.fd || id.fs2 == ex.fd
		|| id.op == OP_SDC1A && (id.fs1 + 1 == ex.fd || id.fs2 + 1 == ex.fd));
endfunction
`endif

function logic is_load_related_store(
	input decoded_instr_t id,
	input decoded_instr_t ex
);
	return ex.is_load & (
	    ex.rd != '0 && (id.rs1 == ex.rd
			|| id.rs2 == ex.rd && ~id.is_store)
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

function logic is_data_delayed(
	input decoded_instr_t id,
	input decoded_instr_t ex
);
	return ex.delayed_exec & (
	    ex.rd != '0 && (id.rs1 == ex.rd || id.rs2 == ex.rd)
	);
endfunction

logic instr2_not_taken;
logic priv_executing, nonrw_priv_executing;
logic [`ISSUE_NUM-1:0] instr_valid;
logic [`ISSUE_NUM-1:0] ex_load_related, load_related, mem_access, data_delayed;
logic [`ISSUE_NUM-1:0] allow_delayed;

for(genvar i = 0; i < `ISSUE_NUM; ++i) begin : gen_access
	assign mem_access[i]    = id_decoded[i].is_load | id_decoded[i].is_store;
	assign instr_valid[i]   = fetch_entry[i].valid;
	assign allow_delayed[i] = id_decoded[i].delayed_exec;
end

always_comb begin
	data_delayed = '0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			data_delayed[i] |= is_data_delayed(
				id_decoded[i], ex_decoded[j]);
			data_delayed[i] |= is_data_delayed(
				id_decoded[i], dcache_decoded[0][j]);
		end
	end
	data_delayed &= instr_valid;
end

`ifdef ENABLE_FPU
logic [`ISSUE_NUM-1:0] fpu_load_related;
always_comb begin
	fpu_load_related = '0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			fpu_load_related[i] |= is_fpu_load_related(
				id_decoded[i], ex_decoded[j]);
			for(int k = 0; k < `DCACHE_PIPE_DEPTH - 1; ++k) begin
				fpu_load_related[i] |= is_fpu_load_related(
					id_decoded[i], dcache_decoded[k][j]);
			end
		end
	end
	fpu_load_related &= instr_valid;
end
`endif

always_comb begin
	load_related = '0;
	ex_load_related = '0;
	for(int i = 0; i < `ISSUE_NUM; ++i) begin
		for(int j = 0; j < `ISSUE_NUM; ++j) begin
			ex_load_related[i] |= is_load_related(
				id_decoded[i], ex_decoded[j]);
			load_related[i] |= is_load_related(
				id_decoded[i], dcache_decoded[0][j]);
			for(int k = 1; k < `DCACHE_PIPE_DEPTH - 1; ++k) begin
				load_related[i] |= is_load_related_store(
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

logic [1:0] hilo_read;
assign hilo_read[0] = id_decoded[0].op == OP_MFHI || id_decoded[0].op == OP_MFLO;
assign hilo_read[1] = id_decoded[1].op == OP_MFHI || id_decoded[1].op == OP_MFLO;

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
logic delayslot_not_loaded, speculative_branch;
logic speculative_branch_conflict;
logic [`ISSUE_NUM-1:0] possible_except;
assign delayslot_not_loaded = id_decoded[0].is_controlflow & ~instr_valid[1];
assign speculative_branch = ex_decoded[0].is_controlflow & ex_decoded[0].delayed_exec;
for(genvar i = 0; i < `ISSUE_NUM; ++i) begin: gen_possible_ex
	assign possible_except[i] = ~id_decoded[i].delayed_exec | (|fetch_entry[i].iaddr_ex);
end

assign speculative_branch_conflict = 
	  (id_decoded[0].is_store | id_decoded[1].is_store)
	| (id_decoded[0].is_priv | id_decoded[1].is_priv);
//assign speculative_branch_conflict = 
//	  ~(id_decoded[0].delayed_exec & id_decoded[1].delayed_exec);

assign instr2_not_taken = ~id_decoded[0].is_controlflow && (
	  ~instr_valid[1]
   || is_data_related(id_decoded[0], id_decoded[1])
   || (mem_access[0] & mem_access[1])
      // mispredict but delayslot does not executed
   || delayslot_not_exec
      // branch must be issued on pipeline 1
   || id_decoded[1].is_controlflow
//   || (is_ssnop(fetch_entry[0]) | is_ssnop(fetch_entry[1]))
//   || (id_decoded[0].op == OP_SC || id_decoded[1].op == OP_SC)
   || (id_decoded[0].is_priv && id_decoded[1].is_priv)
   || (id_decoded[0].is_multicyc && id_decoded[1].is_multicyc)
   || (id_decoded[0].is_multicyc && hilo_read[1])
   `ifdef ENABLE_FPU
	   || (id_decoded[0].is_fpu && id_decoded[1].is_fpu)
	   || (id_decoded[0].op == OP_LDC1A || id_decoded[0].op == OP_SDC1A)
   `endif
   `ifdef ENABLE_ASIC
	   || (id_decoded[0].op == OP_MFC2 || id_decoded[1].op == OP_MFC2)
	   || (id_decoded[0].op == OP_MTC2 || id_decoded[1].op == OP_MTC2)
   `endif
   || (id_decoded[1].op == OP_ERET)
);

assign stall_req =
	  ex_load_related[0]
	| (ex_load_related[1] & ~instr2_not_taken)
	| (load_related[0] & ~allow_delayed[0])
	| (load_related[1] & ~instr2_not_taken & ~(&allow_delayed))
	| (data_delayed[0] & ~allow_delayed[0])
	| (data_delayed[1] & ~instr2_not_taken & ~(&allow_delayed))
	| (id_decoded[0].is_nonrw_priv && priv_executing) & `CPU_MUTEX_PRIV
	| nonrw_priv_executing & `CPU_MUTEX_PRIV
	| (ex_decoded[0].is_priv | ex_decoded[1].is_priv)
   `ifdef ENABLE_FPU
	   | fpu_load_related[0]
	   | (fpu_load_related[1] & ~instr2_not_taken)
   `endif
   `ifdef ENABLE_ASIC
	   | (ex_decoded[0].op == OP_MTC2 && id_decoded[0].op == OP_MFC2)
   `endif
	| delayslot_not_loaded
	| (speculative_branch & speculative_branch_conflict)
	| (instr_valid == '0);

logic [1:0] id_delayed_exec;
assign id_delayed_exec[0] =
	  (load_related[0] & allow_delayed[0])
	| (data_delayed[0] & allow_delayed[0]);
assign id_delayed_exec[1] = 
	  (load_related[1] & ~instr2_not_taken & &allow_delayed)
	| (data_delayed[1] & ~instr2_not_taken & &allow_delayed);

always_comb begin
	issue_instr = id_decoded;
	issue_num   = 2;
	issue_instr[0].delayed_exec = id_delayed_exec[0];
	issue_instr[1].delayed_exec = id_delayed_exec[1];
	if(instr2_not_taken) begin
		issue_num      = 1;
		issue_instr[1] = '0;
	end
end

endmodule
