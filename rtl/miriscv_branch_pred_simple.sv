`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.04.2023 22:38:37
// Design Name: 
// Module Name: miriscv_branch_pred_simple
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module miriscv_branch_pred_simple
  import miriscv_pkg::XLEN;
  import miriscv_opcodes_pkg::OPCODE_BRANCH;
(
  input  [XLEN-1:0]  instr_rdata_i,
  output             predicted_flag_o
);

  assign predicted_flag_o = ( instr_rdata_i[6:0] == OPCODE_BRANCH ) & ( instr_rdata_i[XLEN-1] ); 
endmodule
