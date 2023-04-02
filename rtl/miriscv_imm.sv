module miriscv_imm #(
	int XLEN = 32
)(
	input 	logic [XLEN-1:0] 	instr_i,
	output 	logic [XLEN-1:0] 	imm_o
);

	import miriscv_opcodes_pkg::*;

    always_comb
		(* parallel_case *) case (instr_i[6:2]) inside
			S_OPCODE_OPIMM, S_OPCODE_LOAD, S_OPCODE_JALR:
				imm_o[0] = instr_i[20];
			S_OPCODE_STORE:
				imm_o[0] = instr_i[7];
			default: imm_o[0] = 1'b0;
		endcase

	always_comb
		(* parallel_case *) case (instr_i[6:2]) inside
			S_OPCODE_STORE, S_OPCODE_BRANCH:
				imm_o[4:1] = instr_i[11:8];
			S_OPCODE_LUI, S_OPCODE_AUIPC:
				imm_o[4:1] = 4'b0;
			default: imm_o[4:1] = instr_i[24:21];
		endcase

	always_comb
		(* parallel_case *) case (instr_i[6:2]) inside
			S_OPCODE_BRANCH:
				imm_o[11] = instr_i[7];
			S_OPCODE_LUI, S_OPCODE_AUIPC:
				imm_o[11] = 1'b0;
			S_OPCODE_JAL:
				imm_o[11] = instr_i[20];
			default: imm_o[11] = instr_i[31];
		endcase

	assign imm_o[10:5]  = (instr_i[6:2]==S_OPCODE_LUI || instr_i[6:2]==S_OPCODE_AUIPC) ? 6'b0 : instr_i[30:25];

	assign imm_o[19:12] = (instr_i[6:2]==S_OPCODE_LUI || instr_i[6:2]==S_OPCODE_AUIPC || instr_i[6:2]==S_OPCODE_JAL) ? instr_i[19:12] : {8{instr_i[31]}};

	assign imm_o[30:20] = (instr_i[6:2]==S_OPCODE_LUI || instr_i[6:2]==S_OPCODE_AUIPC) ? instr_i[30:20] : {11{instr_i[31]}};

	assign imm_o[31] = instr_i[31];

endmodule
