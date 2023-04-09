/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of  miriscv core.
 *
 *
 *******************************************************/

package  miriscv_decode_pkg;

  parameter ALU_DATA   = 3'd0;
  parameter MDU_DATA   = 3'd1;
  parameter LSU_DATA   = 3'd2;
  parameter PC_DATA    = 3'd3;
  parameter IMM_DATA   = 3'd4;

  parameter MEM_ACCESS_WORD  = 3'd0;
  parameter MEM_ACCESS_HALF  = 3'd1;
  parameter MEM_ACCESS_BYTE  = 3'd2;
  parameter MEM_ACCESS_UHALF = 3'd3;
  parameter MEM_ACCESS_UBYTE = 3'd4;

  parameter CSRRW   = 2'd0;
  parameter CSRRS   = 2'd1;
  parameter CSRRC   = 2'd2;
  parameter CSR_ILL = 2'd3;

endpackage