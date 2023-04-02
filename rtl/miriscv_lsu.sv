/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_lsu
  import miriscv_pkg::XLEN;
  import miriscv_lsu_pkg::*;
(
  // clock, reset
  input                             clk_i,
  input                             arstn_i,

  // data memory interface
  input                             data_rvalid_i,
  input         [XLEN-1:0]          data_rdata_i,
  output  logic                     data_req_o,
  output  logic                     data_we_o,
  output  logic [XLEN/8-1:0]        data_be_o,
  output  logic [XLEN-1:0]          data_addr_o,
  output  logic [XLEN-1:0]          data_wdata_o,

  // core pipeline signals
  input                             lsu_req_i,
  input                             lsu_kill_i,
  input                             lsu_keep_i,
  input                             lsu_we_i,
  input         [MEM_ACCESS_W-1:0]  lsu_size_i,
  input         [XLEN-1:0]          lsu_addr_i,
  input         [XLEN-1:0]          lsu_data_i,
  output  logic [XLEN-1:0]          lsu_data_o,

  // control and status signals
  output  logic                     lsu_stall_o
);

  localparam BYTE_ADDR_W = $clog2(XLEN/8);
  
  logic [XLEN/4-1:0] data_be;

  assign data_req_o  = lsu_req_i & ~lsu_kill_i & ~data_rvalid_i;
  assign data_addr_o = lsu_addr_i;
  assign data_we_o   = lsu_we_i;
  assign data_be_o   = data_be;
  
  assign lsu_stall_o = data_req_o;
  
  ///////////
  // Store //
  ///////////

  always_comb
    (* full_case, parallel_case *) case ( lsu_size_i[1:0] )
      2'h2:  data_be = 'b1111;
      2'h1:  data_be = ( 'b0011 << lsu_addr_i[1:0] );
      2'h0:  data_be = ( 'b0001 << lsu_addr_i[1:0] );
    endcase

  always_comb
    (* full_case, parallel_case *) case ( lsu_size_i[1:0] )
      2'h0:   data_wdata_o = {4{lsu_data_i[7:0]}};
      2'h1:   data_wdata_o = {2{lsu_data_i[15:0]}};
      2'h2:   data_wdata_o = lsu_data_i;
    endcase
   

  //////////
  // Load //
  //////////

  always_comb
    (* full_case, parallel_case *) case ( lsu_size_i[1:0] )
      2'h2:
        lsu_data_o = data_rdata_i[31:0];

      2'h1:
        (* full_case, parallel_case *) case ( lsu_addr_i[1:0] )
          2'h0: lsu_data_o = { {(16){data_rdata_i[15] & ~lsu_size_i[2]}}, data_rdata_i[15:0] };
          2'h2: lsu_data_o = { {(16){data_rdata_i[31] & ~lsu_size_i[2]}}, data_rdata_i[31:16] };
        endcase

      2'h0:
        (* full_case, parallel_case *) case ( lsu_addr_i[1:0] )
          2'h0: lsu_data_o = { {(24){data_rdata_i[7]  & ~lsu_size_i[2]}}, data_rdata_i[7  : 0] };
          2'h1: lsu_data_o = { {(24){data_rdata_i[15] & ~lsu_size_i[2]}}, data_rdata_i[15 : 8] };
          2'h2: lsu_data_o = { {(24){data_rdata_i[23] & ~lsu_size_i[2]}}, data_rdata_i[23 : 16] };
          2'h3: lsu_data_o = { {(24){data_rdata_i[31] & ~lsu_size_i[2]}}, data_rdata_i[31 : 24] };
        endcase

    endcase
 

endmodule
