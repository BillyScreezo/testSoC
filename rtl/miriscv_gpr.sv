/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/


 module miriscv_gpr
  import miriscv_pkg::XLEN;
  import miriscv_gpr_pkg::*;
  (

  // Clocking
  input                               clk_i,
  input                               arstn_i,

  // Write port
  input                               wr_en_i,
  input         [GPR_ADDR_WIDTH-1:0]  wr_addr_i,
  input         [XLEN-1:0]            wr_data_i,

  // Read port 1
  input         [GPR_ADDR_WIDTH-1:0]  r1_addr_i,
  output logic  [XLEN-1:0]            r1_data_o,

  // Read port 2
  input         [GPR_ADDR_WIDTH-1:0]  r2_addr_i,
  output logic  [XLEN-1:0]            r2_data_o
  );

  localparam    NUM_WORDS  = 2**GPR_ADDR_WIDTH;

  logic [XLEN-1:0] rf_reg [0 : NUM_WORDS-1];

  initial begin
    rf_reg[0] = '0;
  end

  assign r1_data_o = rf_reg[r1_addr_i];
  assign r2_data_o = rf_reg[r2_addr_i];

  always_ff @(posedge clk_i)
    if(wr_en_i && (wr_addr_i != 0))
      rf_reg[wr_addr_i] <= wr_data_i;

endmodule: miriscv_gpr