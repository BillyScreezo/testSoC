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

  logic [XLEN-1:0] pc_reg, c_pc, n_pc, c_pc_f, n_pc_f;
  logic [XLEN-1:0] pc_next;
  logic [XLEN-1:0] pc_plus_inc;

  logic stall_f;
  logic [XLEN-1:0] instr_f, instr;

  assign instr = (stall_f) ? instr_f : instr_rdata_i;

  always_ff @(posedge clk_i) begin
    if(~arstn_i) begin
      stall_f <= '0;
      instr_f <= '0;
    end else begin
      stall_f <= cu_stall_f_i;
      instr_f <= (cu_stall_f_i & !stall_f) ? instr_rdata_i : instr_f;
    end
  end

  always_ff @(posedge clk_i) begin
    if ( ~arstn_i ) begin
      pc_reg          <= '0;
      fetch_rvalid_o  <= '0;
    end else if ( cu_boot_addr_load_en_i ) begin
      pc_reg          <= boot_addr_i;
      fetch_rvalid_o  <= '0;
    end else begin
      if ( !cu_stall_f_i )
        pc_reg <= pc_next;

      if(!fetch_rvalid_o)
        fetch_rvalid_o <= '1;
      else if (cu_kill_f_i)
        fetch_rvalid_o <= '0;

      c_pc  <= pc_reg;
      n_pc  <= pc_plus_inc;

      c_pc_f <= (cu_stall_f_i & !stall_f) ? c_pc : c_pc_f;
      n_pc_f <= (cu_stall_f_i & !stall_f) ? n_pc : n_pc_f;

    end
  end

  assign pc_plus_inc  = pc_reg + 'd4;
  assign pc_next      = ( cu_kill_f_i ) ? cu_pc_bra_i : pc_plus_inc;

  assign instr_req_o  = ~(cu_stall_f_i);
  assign instr_addr_o = pc_reg;
  
  assign instr_o      = fetch_rvalid_o ? instr : { {(32-8){1'b0}}, 8'h13 };


  assign fetched_pc_addr_o      = (stall_f) ? c_pc_f : c_pc;
  assign fetched_pc_next_addr_o = (stall_f) ? n_pc_f : n_pc;

endmodule
