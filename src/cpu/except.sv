`include "cpu_defs.svh"

module except(
	input  logic            rst,
	input  pipeline_exec_t  [1:0] pipe_mm,
	input  cp0_regs_t       cp0_regs,
	input  logic [7:0]      interrupt_req,
	output except_req_t     except_req
);

virt_t pc;

logic interrupt_occur;
assign interrupt_occur = (
	// TODO: check whether DM bit in debug is zero
	cp0_regs.status.ie
	&& ~cp0_regs.status.exl
	&& ~cp0_regs.status.erl
	&& interrupt_req != 8'b0
	&& (pipe_mm[0].valid || pipe_mm[1].valid)
	`ifdef ENABLE_FPU
		&& ~(pipe_mm[0].decoded.op == OP_LDC1B || pipe_mm[0].decoded.op == OP_SDC1B)
	`endif
);

logic tlb_refill;
`ifdef COMPILE_FULL_M
assign tlb_refill = pipe_mm[0].ex.valid ? pipe_mm[0].ex.tlb_refill : pipe_mm[1].ex.tlb_refill;
`else
assign tlb_refill = 1'b0;
`endif
assign except_req.eret = pipe_mm[0].eret;
always_comb begin
	if(interrupt_occur) begin
		except_req.valid = 1'b1;
		except_req.code  = `EXCCODE_INT;
		except_req.extra = '0;
		except_req.pc    = pipe_mm[0].pc;
		except_req.delayslot   = 1'b0;
		except_req.alpha_taken = 1'b1;
	end else if(pipe_mm[0].ex.valid | except_req.eret) begin
		except_req.valid = 1'b1;
		except_req.code  = pipe_mm[0].ex.exc_code;
		except_req.extra = pipe_mm[0].ex.extra;
		except_req.pc    = pipe_mm[0].pc;
		except_req.delayslot   = pipe_mm[0].delayslot;
		except_req.alpha_taken = 1'b1;
	end else begin
		except_req.valid = pipe_mm[1].ex.valid;
		except_req.code  = pipe_mm[1].ex.exc_code;
		except_req.extra = pipe_mm[1].ex.extra;
		except_req.pc    = pipe_mm[1].pc;
		except_req.delayslot   = pipe_mm[1].delayslot;
		except_req.alpha_taken = 1'b0;
	end

	except_req.valid &= ~rst;

	if(except_req.eret) begin
		if(cp0_regs.status.erl)
			except_req.except_vec = cp0_regs.error_epc;
		else except_req.except_vec = cp0_regs.epc;
	end else begin
		logic [11:0] offset;
		if(cp0_regs.status.exl == 1'b0) begin
			if(tlb_refill && (except_req.code == `EXCCODE_TLBL || except_req.code == `EXCCODE_TLBS))
				offset = 12'h000;
			else if(except_req.code == `EXCCODE_INT && cp0_regs.cause.iv)
				offset = 12'h200;
			else offset = 12'h180;
		end else begin
			offset = 12'h180;
		end

		if(cp0_regs.status.bev)
			except_req.except_vec = 32'hbfc00200 + offset;
		else except_req.except_vec = { cp0_regs.ebase[31:12], offset };
	end
end

endmodule
