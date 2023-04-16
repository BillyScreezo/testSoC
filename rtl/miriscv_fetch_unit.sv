/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_fetch_unit
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_opcodes_pkg::OPCODE_BRANCH;
(
  // clock, reset
  input                     clk_i,
  input                     arstn_i,

  input   logic [XLEN-1:0]  boot_addr_i,

  // instruction memory interface
  input                     instr_rvalid_i,
  input         [XLEN-1:0]  instr_rdata_i,
  output  logic             instr_req_o,
  output  logic [XLEN-1:0]  instr_addr_o,

  // core pipeline signals
  input         [XLEN-1:0]  cu_pc_bra_i,
  input                     cu_stall_f_i,
  input                     cu_kill_f_i,
  input                     cu_boot_addr_load_en_i,

  output logic [ILEN-1:0]   f_instr_o,
  output logic [XLEN-1:0]   f_current_pc_o,
  output logic [XLEN-1:0]   f_next_pc_o,
  output logic              f_valid_o
);

  localparam BYTE_ADDR_W = $clog2(XLEN/8);

  logic [XLEN-1:0] pc_plus_inc;
  logic            boot_reg;

  logic            predicted_flag; 
  logic [XLEN-1:0] imm_branch;
  logic [XLEN-1:0] pc_branch;

 /*
  miriscv_branch_pred_simple branch_prediction(
    .instr_rdata_i    ( instr_rdata_i ),
    .predicted_flag_o ( predicted_flag )
  );*/
  assign predicted_flag = ( instr_rdata_i[6:0] == OPCODE_BRANCH ) & ( instr_rdata_i[XLEN-1] ); // так бысрее

  assign pc_plus_inc    = f_next_pc_o + 'd4;
  assign f_valid_o      = instr_rvalid_i & ~boot_reg;
  assign instr_req_o    = ~cu_boot_addr_load_en_i & ~cu_stall_f_i & ~cu_kill_f_i;
  assign pc_branch      = f_next_pc_o + imm_branch;

  assign imm_branch [31:12] = {20{instr_rdata_i[31]}};
  assign imm_branch [11]    = instr_rdata_i[7];
  assign imm_branch [10:5]  = instr_rdata_i[30:25];
  assign imm_branch [4:1]   = instr_rdata_i[11:8];
  assign imm_branch [0]     = '0;

  always_comb begin
    if(~cu_boot_addr_load_en_i & boot_reg)
      instr_addr_o = boot_addr_i;
    else if(cu_stall_f_i)
      instr_addr_o = f_next_pc_o;
    else if(cu_kill_f_i)
      instr_addr_o = cu_pc_bra_i;
    else 
      instr_addr_o = predicted_flag ? pc_branch : pc_plus_inc;
  end

  always_ff @(posedge clk_i) boot_reg <= cu_boot_addr_load_en_i;

  // Pipeline register
  always_ff @(posedge clk_i) begin
    if(~arstn_i) begin
      f_instr_o                 <= { {(ILEN-8){1'b0}}, 8'h13 }; // ADDI x0, x0, 0 - NOP
      f_current_pc_o            <= '0;
      f_next_pc_o               <= '0;
    end
    else if (cu_kill_f_i) begin
      f_instr_o                 <= { {(ILEN-8){1'b0}}, 8'h13 }; // ADDI x0, x0, 0 - NOP
      f_current_pc_o            <= f_current_pc_o;
      f_next_pc_o               <= instr_addr_o;
    end
    else if (~cu_stall_f_i) begin // & ~cu_boot_addr_load_en_i
      f_instr_o                 <= instr_rdata_i;
      f_current_pc_o            <= f_next_pc_o;
      f_next_pc_o               <= instr_addr_o;
    end

  end

endmodule
