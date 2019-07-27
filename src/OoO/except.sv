`include "cpu_defs.svh"

module except(
	input  logic            rst,
	input  rob_packet_t     rob_packet,
	input  cp0_regs_t       cp0_regs,
	input  logic [7:0]      interrupt_flag,
	output except_req_t     except_req
);

logic interrupt_occur;
assign interrupt_occur = (
	cp0_regs.status.ie
	&& ~cp0_regs.status.exl
	&& ~cp0_regs.status.erl
	&& interrupt_flag != 8'b0
	&& (rob_packet[0].valid || rob_packet[1].valid)
);

assign except_req.eret =
	rob_packet[0].ex.valid & rob_packet[0].ex.eret;

always_comb begin
	if(interrupt_occur) begin
		except_req.valid = 1'b1;
		except_req.code  = `EXCCODE_INT;
		except_req.extra = interrupt_flag;
		except_req.pc    = rob_packet[0].pc;
		except_req.delayslot   = 1'b0;
		except_req.alpha_taken = 1'b1;
	end else if(rob_packet[0].ex.valid | except_req.eret) begin
		except_req.valid = 1'b1;
		except_req.code  = rob_packet[0].ex.exc_code;
		except_req.extra = rob_packet[0].ex.extra;
		except_req.pc    = rob_packet[0].pc;
		except_req.delayslot   = rob_packet[0].delayslot;
		except_req.alpha_taken = 1'b1;
	end else begin
		except_req.valid = rob_packet[1].ex.valid;
		except_req.code  = rob_packet[1].ex.exc_code;
		except_req.extra = rob_packet[1].ex.extra;
		except_req.pc    = rob_packet[1].pc;
		except_req.delayslot   = rob_packet[1].delayslot;
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
			if(except_req.code == `EXCCODE_TLBL || except_req.code == `EXCCODE_TLBS)
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
