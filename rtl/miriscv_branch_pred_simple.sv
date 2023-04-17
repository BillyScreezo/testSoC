`timescale 1ns / 1ps

module miriscv_branch_pred_simple
  import miriscv_pkg::XLEN;
  import miriscv_opcodes_pkg::OPCODE_BRANCH;
(
  input  [XLEN-1:0]  instr_rdata_i,
  output             predicted_flag_o
);

  assign predicted_flag_o = ( instr_rdata_i[6:0] == OPCODE_BRANCH ) & ( instr_rdata_i[XLEN-1] ); 
endmodule
