`include "cpu_defs.svh"

module decoder(
	input  uint32_t        instr,
	output decoded_instr_t decoded_instr
);

// setup instruction fields
logic [5:0] opcode, funct;
reg_addr_t rs, rt, rd;

assign opcode    = instr[31:26];
assign rs        = instr[25:21];
assign rt        = instr[20:16];
assign rd        = instr[15:11];
assign funct     = instr[5:0];

logic is_branch, is_jump_i, is_jump_r, is_call, is_return;
decode_branch branch_decoder_inst(
	.*,
	.imm_branch(),
	.imm_jump()
);

always_comb begin
	unique casez( { is_branch, is_return, is_call, is_jump_i | is_jump_r } )
		4'b1???: decoded_instr.cf = ControlFlow_Branch;
		4'b01??: decoded_instr.cf = ControlFlow_Return;
		4'b001?: decoded_instr.cf = ControlFlow_Call;
		4'b0001: decoded_instr.cf = ControlFlow_Jump;
		default: decoded_instr.cf = ControlFlow_None;
	endcase
end

always_comb begin
	decoded_instr.rs1        = '0;
	decoded_instr.rs2        = '0;
	decoded_instr.rd         = '0;
	decoded_instr.op         = OP_INVALID;
	decoded_instr.fu         = FU_INVALID;
	decoded_instr.use_imm    = 1'b0;
	decoded_instr.imm_signed = 1'b1;
	decoded_instr.is_controlflow = is_branch | is_jump_i | is_jump_r;

	unique casez(opcode)
		6'b000000: begin  // SPECIAL (Reg-Reg)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = rt;
			decoded_instr.rd  = rd;

			unique casez(funct)
				6'b00100?: decoded_instr.fu = FU_BRANCH;
				6'b01?0??: decoded_instr.fu = FU_MUL;
				default:   decoded_instr.fu = FU_ALU;
			endcase

			unique case(funct)
				/* shift */
				6'b000000: decoded_instr.op = OP_SLL;
				6'b000010: decoded_instr.op = OP_SRL;
				6'b000011: decoded_instr.op = OP_SRA;
				6'b000100: decoded_instr.op = OP_SLLV;
				6'b000110: decoded_instr.op = OP_SRLV;
				6'b000111: decoded_instr.op = OP_SRAV;
				/* unconditional jump (reg) */
				6'b001000: decoded_instr.op = OP_JALR;
				6'b001001: decoded_instr.op = OP_JALR;
				/* conditional move */
				6'b001011: decoded_instr.op = OP_MOVN;
				6'b001010: decoded_instr.op = OP_MOVZ;
				/* breakpoint and syscall */
				6'b001100: decoded_instr.op = OP_SYSCALL;
				6'b001101: decoded_instr.op = OP_BREAK;
				/* sync */
				6'b001111: decoded_instr.op = OP_SLL;
				/* HI/LO move */
				6'b010000: decoded_instr.op = OP_MFHI;
				6'b010001: decoded_instr.op = OP_MTHI;
				6'b010010: decoded_instr.op = OP_MFLO;
				6'b010011: decoded_instr.op = OP_MTLO;
				/* multiplication and division */
				6'b011000: decoded_instr.op = OP_MULT;
				6'b011001: decoded_instr.op = OP_MULTU;
				6'b011010: decoded_instr.op = OP_DIV;
				6'b011011: decoded_instr.op = OP_DIVU;
				/* add and substract */
				6'b100000: decoded_instr.op = OP_ADD;
				6'b100001: decoded_instr.op = OP_ADDU;
				6'b100010: decoded_instr.op = OP_SUB;
				6'b100011: decoded_instr.op = OP_SUBU;
				/* logical */
				6'b100100: decoded_instr.op = OP_AND;
				6'b100101: decoded_instr.op = OP_OR;
				6'b100110: decoded_instr.op = OP_XOR;
				6'b100111: decoded_instr.op = OP_NOR;
				/* compare and set */
				6'b101010: decoded_instr.op = OP_SLT;
				6'b101011: decoded_instr.op = OP_SLTU;
				/* trap */
				6'b110000: decoded_instr.op = OP_TGE;
				6'b110001: decoded_instr.op = OP_TGEU;
				6'b110010: decoded_instr.op = OP_TLT;
				6'b110011: decoded_instr.op = OP_TLTU;
				6'b110100: decoded_instr.op = OP_TEQ;
				6'b110110: decoded_instr.op = OP_TNE;
				default:   decoded_instr.op = OP_INVALID;
			endcase
		end
		6'b011100: begin // SPECIAL2 (Reg-Reg)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = rt;
			decoded_instr.rd  = rd;
			decoded_instr.fu  = funct[5:3] == 3'b000 ? FU_MUL : FU_ALU;
			unique case(funct)
				6'b000000: decoded_instr.op = OP_MADD;
				6'b000001: decoded_instr.op = OP_MADDU;
				6'b000100: decoded_instr.op = OP_MSUB;
				6'b000101: decoded_instr.op = OP_MSUBU;
				6'b000010: decoded_instr.op = OP_MUL;
				6'b100000: decoded_instr.op = OP_CLZ;
				6'b100001: decoded_instr.op = OP_CLO;
				default:   decoded_instr.op = OP_INVALID;
			endcase
		end
		6'b000001: begin // REGIMM (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rd  = (instr[20:17] == 4'b1000) ? 5'd31 : 5'd0;
			decoded_instr.fu  = instr[19:17] == 3'b000 ? FU_BRANCH : FU_ALU;
			decoded_instr.use_imm = 1'b1;
			unique case(instr[20:16])
				/* trap */
				5'b01000: decoded_instr.op = OP_TGE;
				5'b01001: decoded_instr.op = OP_TGEU;
				5'b01010: decoded_instr.op = OP_TLT;
				5'b01011: decoded_instr.op = OP_TLTU;
				5'b01100: decoded_instr.op = OP_TEQ;
				5'b01110: decoded_instr.op = OP_TNE;
				/* branch */
				5'b00000: decoded_instr.op = OP_BLTZ;
				5'b00001: decoded_instr.op = OP_BGEZ;
				5'b10000: decoded_instr.op = OP_BLTZAL;
				5'b10001: decoded_instr.op = OP_BGEZAL;
				default:  decoded_instr.op = OP_INVALID;
			endcase
		end

		6'b0001??: begin // branch (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = rt;
			decoded_instr.fu  = FU_BRANCH;
			unique case(opcode[1:0])
				2'b00: decoded_instr.op = OP_BEQ;
				2'b01: decoded_instr.op = OP_BNE;
				2'b10: decoded_instr.op = OP_BLEZ;
				2'b11: decoded_instr.op = OP_BGTZ;
			endcase
		end

		6'b001???: begin // logic and arithmetic (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rd  = rt;
			decoded_instr.fu  = FU_ALU;
			decoded_instr.use_imm    = 1'b1;
			decoded_instr.imm_signed = ~opcode[2];
			unique case(opcode[2:0])
				3'b100: decoded_instr.op = OP_AND;
				3'b101: decoded_instr.op = OP_OR;
				3'b110: decoded_instr.op = OP_XOR;
				3'b111: decoded_instr.op = OP_LUI;
				3'b000: decoded_instr.op = OP_ADD;
				3'b001: decoded_instr.op = OP_ADDU;
				3'b010: decoded_instr.op = OP_SLT;
				3'b011: decoded_instr.op = OP_SLTU;
			endcase
		end

		6'b100???: begin // load (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = (opcode[1:0] == 2'b10) ? rt : '0;
			decoded_instr.rd  = rt;
			decoded_instr.fu  = FU_LOAD;
			unique case(opcode[2:0])
				3'b000: decoded_instr.op = OP_LB;
				3'b001: decoded_instr.op = OP_LH;
				3'b010: decoded_instr.op = OP_LWL;
				3'b011: decoded_instr.op = OP_LW;
				3'b100: decoded_instr.op = OP_LBU;
				3'b101: decoded_instr.op = OP_LHU;
				3'b110: decoded_instr.op = OP_LWR;
				3'b111: decoded_instr.op = OP_INVALID;
			endcase
		end

		6'b101???: begin // store (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = rt;
			decoded_instr.fu  = FU_STORE;
			unique case(opcode[2:0])
				3'b000:  decoded_instr.op = OP_SB;
				3'b001:  decoded_instr.op = OP_SH;
				3'b010:  decoded_instr.op = OP_SWL;
				3'b011:  decoded_instr.op = OP_SW;
				3'b110:  decoded_instr.op = OP_SWR;
				3'b111:  decoded_instr.op = OP_CACHE;
				default: decoded_instr.op = OP_INVALID;
			endcase
		end
		
		6'b110000: begin // load linked word (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rd  = rt;
			decoded_instr.fu  = FU_LOAD;
			decoded_instr.op  = OP_LL;
		end
		
		6'b111000: begin // store conditional word (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = rt;
			decoded_instr.rd  = rt;
			decoded_instr.fu  = FU_STORE;
			decoded_instr.op  = OP_SC;
		end
		
		6'b00001?: begin // jump and link
			decoded_instr.rd  = {$bits(reg_addr_t){opcode[0]}};
			decoded_instr.fu  = FU_BRANCH;
			decoded_instr.op  = OP_JAL;
		end

		6'b010000: begin // COP0
			decoded_instr.fu = FU_CP0;
			unique case(instr[25:21])
				5'b00000: begin
					decoded_instr.op = OP_MFC0;
					decoded_instr.rd = rt;
				end
				5'b00100: begin
					decoded_instr.op  = OP_MTC0;
					decoded_instr.rs1 = rt;
				end
				5'b10000: begin
					unique case(instr[5:0])
						6'b000001: decoded_instr.op = OP_TLBR;
						6'b000010: decoded_instr.op = OP_TLBWI;
						6'b000110: decoded_instr.op = OP_TLBWR;
						6'b001000: decoded_instr.op = OP_TLBP;
						6'b011000: decoded_instr.op = OP_ERET;
						default: decoded_instr.op = OP_INVALID;
					endcase
				end
				default: decoded_instr.op = OP_INVALID;
			endcase
		end

		default: decoded_instr.op = OP_INVALID;
	endcase
end

endmodule
