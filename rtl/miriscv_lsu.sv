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
  input                             rst_n,

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

  assign data_req_o  = lsu_req_i;
  assign data_addr_o = lsu_addr_i;
  assign data_we_o   = lsu_we_i;
  assign data_be_o   = data_be;

  typedef enum {
    S_IDLE,
    S_LOAD
  } state_t;

  state_t state;

  always_ff @(posedge clk_i) begin
    if(~rst_n) begin
      state <= S_IDLE;
    end else begin
       case (state)
        S_IDLE: 
          if(lsu_req_i && ~lsu_we_i)
            state <= S_LOAD;
        S_LOAD:
          if(data_rvalid_i)
            state <= S_IDLE;
       endcase
    end
  end

  assign lsu_stall_o = (lsu_req_i && ~lsu_we_i) && ((state == S_IDLE) || ((state == S_LOAD) && ~data_rvalid_i));

  ///////////
  // Store //
  ///////////

  always_comb
    (* full_case, parallel_case *) case ( lsu_size_i[1:0] )
      2'h2:  data_be = 'b1111;
      2'h1:  data_be = (lsu_addr_i[1:0] == 2'b00) ? 'b0011 : 'b1100;
      2'h0:  
              (* full_case, parallel_case *) case (lsu_addr_i[1:0])
                2'b00: data_be = 'b0001;
                2'b01: data_be = 'b0010;
                2'b10: data_be = 'b0100;
                2'b11: data_be = 'b1000;
              endcase
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
