/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_decoder
(
    input logic [31:0]  decode_instr_i,

    output              decode_rs1_re_o,
    output              decode_rs2_re_o,

    output logic        decode_ex_op1_sel_o,
    output logic        decode_ex_op2_sel_o,

    output logic [3:0]  decode_alu_operation_o,

    output logic [2:0]  decode_mdu_operation_o,
    output logic        decode_ex_mdu_req_o,

    output logic        decode_mem_we_o,
    output logic [2:0]  decode_mem_size_o,
    output logic        decode_mem_req_o,

    output logic [2:0]  decode_wb_src_sel_o,

    output              decode_wb_we_o,

    output logic        decode_fence_o,
    output logic        decode_branch_o,
    output logic        decode_jal_o,
    output logic        decode_jalr_o,
    output logic        decode_load_o,

    output              decode_illegal_instr_o
);

  import miriscv_pkg::XLEN;
  import miriscv_pkg::RV32M;
  import miriscv_opcodes_pkg::*;
  import miriscv_alu_pkg::*;
  import miriscv_mdu_pkg::*;
  import miriscv_decode_pkg::*;

  logic [6:0] funct7;
  logic [4:0] opcode;
  logic [2:0] funct3;
  logic ill_fence, ill_op, ill_opimm, ill_load, ill_store, ill_branch, ill_opcode, ill_op_mul, ill_op_s, ill_op_others, ill_last_bits;

  assign opcode = decode_instr_i[6:2];
  assign funct3 = decode_instr_i[14:12];
  assign funct7 = decode_instr_i[31:25];

  assign decode_rs1_re_o        = (decode_ex_op1_sel_o == 1'b0);
  assign decode_rs2_re_o        = (decode_ex_op2_sel_o == 1'b0);
  assign decode_ex_mdu_req_o    = (opcode == S_OPCODE_OP) && (funct7 == 1'b1);
  assign decode_wb_we_o         = !((opcode == S_OPCODE_FENCE) || (opcode[3:0] == 4'b1000)); // STORE or BRANCH
  assign decode_fence_o         = (opcode == S_OPCODE_FENCE);

  assign decode_mem_req_o       = (opcode == S_OPCODE_LOAD) || (opcode == S_OPCODE_STORE);
  assign decode_mem_we_o        = (opcode == S_OPCODE_STORE);
  assign decode_load_o          = (opcode == S_OPCODE_LOAD);

  assign decode_illegal_instr_o = ill_fence || ill_op || ill_opimm || ill_load || ill_store || ill_branch || ill_opcode || ill_last_bits;
  
  assign ill_fence      = (opcode == S_OPCODE_FENCE || opcode == S_OPCODE_JALR) && (funct3 != 3'b0);
  assign ill_op_others  = (funct7 != 7'd0 && funct7 != 7'b010_0000 && funct7 != 3'd1);
  assign ill_op_s       = (funct7 == 7'b010_0000 && funct3 != 3'b000 && funct3 != 3'b101);
  assign ill_op_mul     = (funct7 == 7'd1 && !RV32M);
  assign ill_op         = (opcode == S_OPCODE_OP) && (ill_op_others || ill_op_s || ill_op_mul);
  assign ill_opimm      = (opcode == S_OPCODE_OPIMM) && ((funct3[1:0] == 2'b01 && {funct7[6], funct7[4:0]} != 6'd0) || (funct3 == 3'b001 && funct7[5] == 1'b1));
  assign ill_load       = (opcode == S_OPCODE_LOAD) && (funct3 == 3 || funct3 > 5);
  assign ill_store      = (opcode == S_OPCODE_STORE) && (funct3 > 2);
  assign ill_branch     = (opcode == S_OPCODE_BRANCH) && (funct3 == 3'b010 || funct3 == 3'b011);
  assign ill_last_bits  = (decode_instr_i[1:0] != 2'b11);

  always_comb
    (* parallel_case *) case(opcode)
      S_OPCODE_SYSTEM: ill_opcode = 1'b0;
      S_OPCODE_FENCE : ill_opcode = 1'b0;
      S_OPCODE_OP    : ill_opcode = 1'b0;
      S_OPCODE_OPIMM : ill_opcode = 1'b0;
      S_OPCODE_LOAD  : ill_opcode = 1'b0;
      S_OPCODE_STORE : ill_opcode = 1'b0;
      S_OPCODE_BRANCH: ill_opcode = 1'b0;
      S_OPCODE_JAL   : ill_opcode = 1'b0;
      S_OPCODE_JALR  : ill_opcode = 1'b0;
      S_OPCODE_AUIPC : ill_opcode = 1'b0;
      S_OPCODE_LUI   : ill_opcode = 1'b0;
      default: ill_opcode = 1'b1;
    endcase

  assign decode_ex_op1_sel_o = (opcode == S_OPCODE_AUIPC);
  assign decode_ex_op2_sel_o = (opcode == S_OPCODE_OPIMM) || (opcode == S_OPCODE_AUIPC);

  always_comb
    (* parallel_case *) case(opcode)
      S_OPCODE_LOAD:                decode_wb_src_sel_o = LSU_DATA;
      S_OPCODE_JAL, S_OPCODE_JALR:  decode_wb_src_sel_o = PC_DATA;
      S_OPCODE_LUI:                 decode_wb_src_sel_o = IMM_DATA;
      default:                      decode_wb_src_sel_o = (decode_ex_mdu_req_o) ? MDU_DATA : ALU_DATA;
    endcase

  assign decode_jal_o     = (opcode == S_OPCODE_JAL);
  assign decode_jalr_o    = (opcode == S_OPCODE_JALR);
  assign decode_branch_o  = (opcode == S_OPCODE_BRANCH);

// Alu
  logic [3:0] alu_op;
  assign alu_op[2:0] = opcode[0] ? ALU_ADD_SUB : funct3;  // Арифметические отличаются по нулевому биту опкода

  always_comb
    (* parallel_case *) case (opcode)
      S_OPCODE_OP:      alu_op[3] = funct7[5];
      S_OPCODE_OPIMM:   alu_op[3] = (funct3 == 3'h5) ? funct7[5] : 1'b0;
      default:          alu_op[3] = '0;
    endcase

// Exit assigns
  assign decode_alu_operation_o = alu_op;
  assign decode_mem_size_o      = funct3;
  assign decode_mdu_operation_o = funct3;
endmodule
