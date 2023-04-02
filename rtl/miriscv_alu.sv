/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of  miriscv core.
 *
 *
 *******************************************************/

module  miriscv_alu
  import  miriscv_pkg::XLEN;
  import  miriscv_alu_pkg::*;
(
  input         [XLEN-1:0]          alu_port_a_i, alu_port_b_i,   // ALU operation operand
  input   logic [XLEN-1:0]          cmp_a_i, cmp_b_i,

  input         [3:0]  alu_op_i,        // ALU opcode

  output  logic [XLEN-1:0]          alu_result_o,    // ALU result
  output  logic                     alu_branch_des_o // Comparison result for branch decision

);

  logic [XLEN-1:0] alu_add;

  always_comb begin
        alu_add = $signed(alu_port_a_i) + $signed(alu_op_i[3] ? ~alu_port_b_i : alu_port_b_i) + alu_op_i[3];

        case (alu_op_i[2:0])
            ALU_ADD_SUB:    alu_result_o = alu_add;
            ALU_SLL:        alu_result_o = alu_port_a_i << alu_port_b_i[$clog2(XLEN)-1:0];
            ALU_SLT:        alu_result_o = ($signed(alu_port_a_i) < $signed(alu_port_b_i));
            ALU_SLTU:       alu_result_o = (alu_port_a_i < alu_port_b_i);
            ALU_XOR:        alu_result_o = alu_port_a_i ^ alu_port_b_i;
            ALU_SRL_SRA:    alu_result_o = alu_op_i[3] ? (alu_port_a_i >>> alu_port_b_i[$clog2(XLEN)-1:0]) : alu_port_a_i >> alu_port_b_i[$clog2(XLEN)-1:0];
            ALU_OR:         alu_result_o = alu_port_a_i | alu_port_b_i;
            default:        alu_result_o = alu_port_a_i & alu_port_b_i;
        endcase

        case (alu_op_i[2:0])
            ALU_EQ:     alu_branch_des_o = (cmp_a_i == cmp_b_i);
            ALU_NE:     alu_branch_des_o = (cmp_a_i != cmp_b_i);
            ALU_LT:     alu_branch_des_o = ($signed(cmp_a_i)  < $signed(cmp_b_i));
            ALU_GE:     alu_branch_des_o = ($signed(cmp_a_i) >= $signed(cmp_b_i));
            ALU_LTU:    alu_branch_des_o = (cmp_a_i  < cmp_b_i);
            default:    alu_branch_des_o = (cmp_a_i >= cmp_b_i);
        endcase
    end

endmodule