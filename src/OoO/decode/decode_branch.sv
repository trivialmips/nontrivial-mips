`include "cpu_defs.svh"

module decode_branch(
	input  uint32_t instr,
	output uint32_t imm_branch,
	output uint32_t imm_jump,
	output logic    is_branch,
	output logic    is_return,
	output logic    is_call,
	output logic    is_jump_r,
	output logic    is_jump_i
);

logic [5:0] opcode;

assign opcode = instr[31:26];

assign imm_jump   = { 4'b0, instr[25:0], 2'b0 };
assign imm_branch = { {14{instr[15]}}, instr[15:0], 2'b0 };

//assign is_jr     = (opcode == 6'b0 && instr[5:0] == 6'b001000);
//assign is_jalr   = (opcode == 6'b0 && instr[5:0] == 6'b001001);
assign is_jump_r = (opcode == 6'b0 && instr[5:1] == 5'b00100);
assign is_jump_i = (opcode[5:1] == 5'b00001);  // J, JAL
assign is_branch = (
	// BEQ (000100), BNE (000101), BLEZ (000110), BGTZ (000111)
	opcode[5:2] == 4'b0001 ||
	// BLTZ (00000), BGEZ (00001), BLTZAL (10000), BGEZAL (10001)
	opcode == 6'b000001 && instr[19:17] == 3'b0
);

assign is_call   =
      is_jump_r && (instr[15:11] == 5'd31)              // JALR reg, $31
   || opcode == 6'b000011                               // JAL
   || opcode == 6'b000001 && instr[20:17] == 4'b1000;   // BLTZAL, BGEZAL

assign is_return = 
      instr[31:21] == 11'b000000_11111 && instr[5:0] == 6'b001000  // JR $31
   || is_jump_r && instr[25:21] == 5'd31;                   // JALR $31, reg

endmodule
