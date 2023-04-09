/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of  miriscv core.
 *
 *
 *******************************************************/

package  miriscv_alu_pkg;

  parameter ALU_OP_WIDTH = 4;

  parameter ALU_EQ   = 3'h0;    //           rs1 == rs2 (branch)
  parameter ALU_NE   = 3'h1;    //           rs1 != rs2 (branch)
  parameter ALU_LT   = 3'h4;    // signed,   rs1 <  rs2 (branch)
  parameter ALU_GE   = 3'h5;    // signed,   rs1 >= rs2 (branch)
  parameter ALU_LTU  = 3'h6;    // unsigned, rs1 <  rs2 (branch)
  parameter ALU_GEU  = 3'h7;    // unsigned, rs1 >= rs2 (branch)


  parameter ALU_ADD_SUB = 3'h0;    // addition
  parameter ALU_SLL     = 3'h1;    // logical left shift
  parameter ALU_SLT     = 3'h2;    // signed,   rs1 <  rs2 (reg-reg)
  parameter ALU_SLTU    = 3'h3;    // unsigned, rs1 <  rs2 (reg-reg)
  parameter ALU_XOR     = 3'h4;    // bitwise XOR
  parameter ALU_SRL_SRA = 3'h5;    // logical right shift
  parameter ALU_OR      = 3'h6;    // bitwise OR
  parameter ALU_AND     = 3'h7;    // bitwise AND

endpackage :  miriscv_alu_pkg