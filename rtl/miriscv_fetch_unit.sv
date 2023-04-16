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

  output  logic [XLEN-1:0]  fetched_pc_addr_o,
  output  logic [XLEN-1:0]  fetched_pc_next_addr_o,
  output  logic [31:0]      instr_o,
  output  logic             fetch_rvalid_o
);

  localparam BYTE_ADDR_W = $clog2(XLEN/8);

  logic [XLEN-1:0] pc_reg;
  logic [XLEN-1:0] pc_next;
  logic [XLEN-1:0] pc_plus_inc;
  logic            fetch_en, f_valid;

  logic            predicted_flag; 
  logic [XLEN-1:0] pc_branch; 
  logic [XLEN-1:0] imm_branch;

  miriscv_branch_pred_simple branch_prediction(
    .instr_rdata_i    ( instr_rdata_i ),
    .predicted_flag_o ( predicted_flag )
  );
  
  assign fetch_en = f_valid | cu_kill_f_i;

  always_ff @(posedge clk_i) begin
    if ( ~arstn_i ) begin
      pc_reg <= '0; // Reset value here
    end
    else if ( cu_boot_addr_load_en_i ) begin
      pc_reg <= boot_addr_i;
    end
    else if ( fetch_en ) begin
      pc_reg <= pc_next;
    end
  end

  assign pc_plus_inc    = pc_reg + 'd4;
  assign pc_next        = cu_kill_f_i ? cu_pc_bra_i : pc_branch ;
  assign pc_branch      = predicted_flag ? pc_reg + imm_branch : pc_plus_inc; 
  
  assign imm_branch [31:12] = {20{instr_rdata_i[31]}};
  assign imm_branch [11]    = instr_rdata_i[7];
  assign imm_branch [10:5]  = instr_rdata_i[30:25];
  assign imm_branch [4:1]   = instr_rdata_i[11:8];
  assign imm_branch [0]     = '0;


  assign instr_req_o  = ~(cu_boot_addr_load_en_i | instr_rvalid_i | cu_stall_f_i | cu_kill_f_i);
  assign instr_addr_o = pc_reg;

  assign f_valid      = instr_rvalid_i & ~(cu_kill_f_i | cu_stall_f_i);

  // Pipeline register
  always_ff @(posedge clk_i) begin
    if(~arstn_i) begin
      instr_o                 <= { {(ILEN-8){1'b0}}, 8'h13 }; // ADDI x0, x0, 0 - NOP
      fetched_pc_addr_o       <= '0;
      fetched_pc_next_addr_o  <= '0;
      fetch_rvalid_o          <= '0;
    end
    else if (~cu_stall_f_i) begin
      instr_o                 <= f_valid ? instr_rdata_i : { {(ILEN-8){1'b0}}, 8'h13 }; // put NOP if not valid
      fetched_pc_addr_o       <= pc_reg;
      fetched_pc_next_addr_o  <= pc_plus_inc;
      fetch_rvalid_o          <= f_valid;
    end

  end
  

endmodule
