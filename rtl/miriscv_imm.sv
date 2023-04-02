module miriscv_imm #(
	int XLEN = 32
)(
	input 	logic [XLEN-1:0] 	instr_i,
	output 	logic [XLEN-1:0] 	imm_o
);

	import miriscv_opcodes_pkg::*;
    
<<<<<<< HEAD
    logic [4:0] opcode;
	assign opcode = instr_i[6:2];

	always_comb begin
		case (opcode) inside
=======
	always_comb begin
		case (instr_i[6:2]) inside
>>>>>>> main
			S_OPCODE_OPIMM, S_OPCODE_LOAD, S_OPCODE_JALR:
				imm_o = { {21{instr_i[31]}}, instr_i[30:25], instr_i[24:21], instr_i[20] };
			S_OPCODE_STORE:
				imm_o = { {21{instr_i[31]}}, instr_i[30:25], instr_i[11:8],  instr_i[7]  };
			S_OPCODE_BRANCH:
				imm_o = { {20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8],  1'b0 };
			S_OPCODE_LUI, S_OPCODE_AUIPC:
				imm_o = { instr_i[31], instr_i[30:20], instr_i[19:12], 12'b0 };
<<<<<<< HEAD
			S_OPCODE_JALR:
				imm_o = { {12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:25], instr_i[24:21], 1'b0 };
			default:
				imm_o = 32'h0;
=======
			S_OPCODE_JAL:
				imm_o = { {12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:25], instr_i[24:21], 1'b0 };
>>>>>>> main
		endcase
	end

endmodule
