/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_fetch_stage
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
#(
  parameter bit RVFI = 1'b0
) (
  input  logic             clk_i,
  input  logic             arstn_i,

  input  logic [XLEN-1:0]  boot_addr_i,

  // Instruction memory interface
  input  logic             instr_rvalid_i,
  input  logic [XLEN-1:0]  instr_rdata_i,
  output logic             instr_req_o,
  output logic [XLEN-1:0]  instr_addr_o,

  // Control Unit
  input  logic [XLEN-1:0]  cu_pc_bra_i,
  input  logic             cu_kill_f_i,
  input  logic             cu_boot_addr_load_en_i,
  input  logic             cu_stall_f_i,


  // To Decode
  output logic [ILEN-1:0]  f_instr_o,
  output logic [XLEN-1:0]  f_current_pc_o,
  output logic [XLEN-1:0]  f_next_pc_o,
  output logic             f_valid_o
);


  miriscv_fetch_unit fetch_unit (
   .clk_i                   (clk_i          ),
   .arstn_i                 (arstn_i        ),

   .boot_addr_i             (boot_addr_i    ),

   // instruction memory interface
   .instr_rvalid_i          (instr_rvalid_i ),
   .instr_rdata_i           (instr_rdata_i  ),
   .instr_req_o             (instr_req_o    ),
   .instr_addr_o            (instr_addr_o   ),

    // core pipeline signals
    .cu_pc_bra_i            (cu_pc_bra_i    ),
    .cu_stall_f_i           (cu_stall_f_i   ),
    .cu_kill_f_i            (cu_kill_f_i    ),
    .cu_boot_addr_load_en_i (cu_boot_addr_load_en_i ),

    .f_current_pc_o         (f_current_pc_o ),
    .f_next_pc_o            (f_next_pc_o    ),
    .f_instr_o              (f_instr_o      ),
    .f_valid_o              (f_valid_o      )
  );


endmodule