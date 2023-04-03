/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_mdu
  import miriscv_pkg::XLEN;
  import miriscv_mdu_pkg::*;
(
  input                             clk_i,
  input                             arstn_i,
  input                             mdu_req_i,        // request for proceeding operation
  input         [XLEN-1:0]          mdu_port_a_i,     // operand A
  input         [XLEN-1:0]          mdu_port_b_i,     // operand B
  input         [MDU_OP_WIDTH-1:0]  mdu_op_i,         // opcode
  input                             mdu_kill_i,       // cancel a current multicycle operation
  input                             mdu_keep_i,       // save the result and prevent repetition of computation
  output  logic [XLEN-1:0]          mdu_result_o,     // computation result
  output  logic                     mdu_stall_req_o   // stall the pipeline during a multicycle operation
);


  ////////////////////////////////////
  // Sign extention for multipliers //
  ////////////////////////////////////

  // used for both MUL and DIV
  logic b_is_zero;
  assign b_is_zero = ~|mdu_port_b_i;

  logic mult_op;

  always_comb begin
    (* full_case, parallel_case *) case ( mdu_op_i ) inside
      MDU_MUL, MDU_MULH, MDU_MULHSU, MDU_MULHU: mult_op = 1'b1;
      MDU_DIV, MDU_DIVU, MDU_REM, MDU_REMU:     mult_op = 1'b0;
    endcase
  end

  ////////////////////
  // Multiplication //
  ////////////////////

  logic [2*XLEN-1:0] mult_result;
  logic sign_a, sign_b;
  logic msb_a, msb_b;

  logic mult_req, mult_stall;
  logic mult_rdy;

  assign mult_req   = mult_op & mdu_req_i;
  assign mult_stall = mult_req & (~mult_rdy);

  assign sign_a = mdu_port_a_i[31];
  assign sign_b = mdu_port_b_i[31];

  always_comb begin
    (* full_case, parallel_case *) case ( mdu_op_i )
      MDU_MUL,
      MDU_MULH: begin
          msb_a = sign_a;
          msb_b = sign_b;
      end
      MDU_MULHU: begin
          msb_a = 1'b0;
          msb_b = 1'b0;
      end
      MDU_MULHSU: begin
          msb_a = sign_a;
          msb_b = 1'b0;
      end
    endcase
  end

  smult_32_32 smult_32_32_inst (
      .clk      (clk_i),    // Clock
      .rst_n    (arstn_i),  // Asynchronous reset active low
      
      .ai       ({msb_a, mdu_port_a_i}), 
      .bi       ({msb_b, mdu_port_b_i}),
      .r        (mult_result),

      .req      (mult_req),
      .rdy      (mult_rdy)
  );

  //////////////
  // Division //
  //////////////

  logic        [XLEN-1:0] div_result;
  logic signed [XLEN-1:0] rem_result;
  logic                   div_start;
  logic                   div_stall;

  assign div_start = !mult_op && mdu_req_i;

  logic b_zero_flag;
  always_ff @( posedge clk_i or negedge arstn_i ) begin
    if ( ~arstn_i ) begin
      b_zero_flag <= 1'b0;
    end
    else begin
      b_zero_flag <= b_is_zero;
    end
  end

  miriscv_div #(
    .DIV_IMPLEMENTATION( "GENERIC" )
  ) div_unit (
    .clk_i           ( clk_i        ),
    .arstn_i         ( arstn_i      ),
    .div_start_i     ( div_start    ),
    .port_a_i        ( mdu_port_a_i ),
    .port_b_i        ( mdu_port_b_i ),
    .mdu_op_i        ( mdu_op_i     ),
    .zero_i          ( b_zero_flag  ),
    .kill_i          ( mdu_kill_i   ),
    .keep_i          ( mdu_keep_i   ),
    .div_result_o    ( div_result   ),
    .rem_result_o    ( rem_result   ),
    .div_stall_req_o ( div_stall    )
  );


  assign mdu_stall_req_o = div_stall || mult_stall;

  always_comb begin
    (* full_case, parallel_case *) case ( mdu_op_i ) inside
      MDU_MUL:    mdu_result_o = mult_result[XLEN-1:0];
      MDU_MULH,
      MDU_MULHSU,
      MDU_MULHU:  mdu_result_o = mult_result[2*XLEN-1:XLEN];
      MDU_DIV,
      MDU_DIVU:   mdu_result_o = div_result;
      MDU_REM,
      MDU_REMU:   mdu_result_o = rem_result;
    endcase

  end


  

endmodule
