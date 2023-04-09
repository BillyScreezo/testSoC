/*******************************************************
 * Copyright (C) 2022 National Research University of Electronic Technology (MIET),
 * Institute of Microdevices and Control Systems.
 * All Rights Reserved.
 *
 * This file is part of miriscv core.
 *
 *
 *******************************************************/

module miriscv_decode_stage
  import miriscv_pkg::XLEN;
  import miriscv_pkg::ILEN;
  import miriscv_gpr_pkg::GPR_ADDR_WIDTH;
  import miriscv_decode_pkg::*;
  import miriscv_opcodes_pkg::*;
  import miriscv_alu_pkg::*;
#(
  parameter bit RVFI     = 1'b0
) (
  input   logic                       clk_i,
  input   logic                       arstn_i,

  // From Fetch
  input   logic [ILEN-1:0]            f_instr_i,
  input   logic [XLEN-1:0]            f_current_pc_i,
  input   logic [XLEN-1:0]            f_next_pc_i,
  input   logic                       f_valid_i,

  // data memory interface
  input   logic                       data_rvalid_i,
  input   logic [XLEN-1:0]            data_rdata_i,
  output  logic                       data_req_o,
  output  logic                       data_we_o,
  output  logic [XLEN/8-1:0]          data_be_o,
  output  logic [XLEN-1:0]            data_addr_o,
  output  logic [XLEN-1:0]            data_wdata_o,

  
  // RVFI
  output  logic [XLEN-1:0]            d_rvfi_wb_data_o,
  output  logic                       d_rvfi_wb_we_o,
  output  logic [GPR_ADDR_WIDTH-1:0]  d_rvfi_wb_rd_addr_o,

  output  logic [ILEN-1:0]            d_rvfi_instr_o,
  output  logic [GPR_ADDR_WIDTH-1:0]  d_rvfi_rs1_addr_o,
  output  logic [GPR_ADDR_WIDTH-1:0]  d_rvfi_rs2_addr_o,
  output  logic                       d_rvfi_op1_gpr_o,
  output  logic                       d_rvfi_op2_gpr_o,
  output  logic [XLEN-1:0]            d_rvfi_rs1_rdata_o,
  output  logic [XLEN-1:0]            d_rvfi_rs2_rdata_o,
  output  logic [XLEN-1:0]            d_rvfi_current_pc_o,
  output  logic [XLEN-1:0]            d_rvfi_next_pc_o,
  output  logic                       d_rvfi_valid_o,
  output  logic                       d_rvfi_trap_o,
  output  logic                       d_rvfi_intr_o,

  output  logic                       d_rvfi_mem_req_o,
  output  logic                       d_rvfi_mem_we_o,
  output  logic [2:0]                 d_rvfi_mem_size_o,
  output  logic [XLEN-1:0]            d_rvfi_mem_addr_o,
  output  logic [XLEN-1:0]            d_rvfi_mem_wdata_o,
  output  logic [XLEN-1:0]            d_rvfi_mem_rdata_o,

  

  // Control Unit
  output  logic [XLEN-1:0]            cu_pc_bra_o,
  output  logic                       cu_boot_addr_load_en_o,
  output  logic                       cu_stall_f_o,
  output  logic                       cu_kill_f_o,
  output  logic                       cu_stall_d_o,
  output  logic                       cu_kill_d_o
);

  logic        decode_rs1_re;
  logic        decode_rs2_re;

  logic        decode_ex_op1_sel;
  logic        decode_ex_op2_sel;

  logic [3:0]  decode_alu_operation;
  logic [2:0]  decode_mdu_operation;

  logic        decode_ex_mdu_req;

  logic        decode_mem_we;
  logic [2:0]  decode_mem_size;
  logic        decode_mem_req;

  logic [2:0]  decode_wb_src_sel;
  logic        decode_wb_we;

  logic [XLEN-1:0] decode_mem_addr;
  logic [XLEN-1:0] decode_mem_data;
  logic            decode_load;

  logic        d_illegal_instr;

  logic        d_fence;
  logic        d_branch;
  logic        d_jal;
  logic        d_jalr;

  logic        mdu_stall_req;
  logic        lsu_stall_req;

  logic [XLEN-1:0] ex_result;
  logic            branch_des;

  // Decoder

  miriscv_decoder decoder (
    .decode_instr_i         (f_instr_i            ),

    .decode_rs1_re_o        (decode_rs1_re        ),
    .decode_rs2_re_o        (decode_rs2_re        ),

    .decode_ex_op1_sel_o    (decode_ex_op1_sel    ),
    .decode_ex_op2_sel_o    (decode_ex_op2_sel    ),

    .decode_alu_operation_o (decode_alu_operation ),

    .decode_mdu_operation_o (decode_mdu_operation ),
    .decode_ex_mdu_req_o    (decode_ex_mdu_req    ),

    .decode_mem_we_o        (decode_mem_we        ),
    .decode_mem_size_o      (decode_mem_size      ),
    .decode_mem_req_o       (decode_mem_req       ),

    .decode_wb_src_sel_o    (decode_wb_src_sel    ),
    .decode_wb_we_o         (decode_wb_we         ),

    .decode_fence_o         (d_fence              ),
    .decode_branch_o        (d_branch             ),
    .decode_jal_o           (d_jal                ),
    .decode_jalr_o          (d_jalr               ),
    .decode_load_o          (decode_load          ),

    .decode_illegal_instr_o (d_illegal_instr      )
  );

  // Register File
  logic [GPR_ADDR_WIDTH-1:0]  r1_addr, r2_addr, rd_addr;
  logic [XLEN-1:0]            r1_data, r2_data;

  logic                       gpr_wr_en;
  logic [GPR_ADDR_WIDTH-1:0]  gpr_wr_addr;
  logic [XLEN-1:0]            gpr_wr_data;

  assign gpr_wr_en   = decode_wb_we & ~cu_stall_d_o;
  assign gpr_wr_addr = rd_addr;
  assign gpr_wr_data = ex_result;
  
  assign r1_addr = f_instr_i[19:15];
  assign r2_addr = f_instr_i[24:20];
  assign rd_addr = f_instr_i[11:7];  

  miriscv_gpr  gpr (
    .clk_i      (clk_i        ),

    .wr_en_i    (gpr_wr_en    ),
    .wr_addr_i  (gpr_wr_addr  ),
    .wr_data_i  (gpr_wr_data  ),

    .r1_addr_i  (r1_addr      ),
    .r1_data_o  (r1_data      ),
    .r2_addr_i  (r2_addr      ),
    .r2_data_o  (r2_data      )

  );

  // Immediate and signextend
  logic [XLEN-1:0] imm;

  miriscv_imm imm_inst (
    .instr_i(f_instr_i),
    .imm_o(imm)
  );

  // Datapath
  logic [XLEN-1:0] op1;
  logic [XLEN-1:0] op2;

  assign op1 = decode_ex_op1_sel ? f_current_pc_i : r1_data;
  assign op2 = decode_ex_op2_sel ? imm            : r2_data;

  assign decode_mem_data = r2_data;
  assign decode_mem_addr = alu_add;

  logic [XLEN-1:0] alu_result, alu_add;
  logic [XLEN-1:0] mdu_result;
  logic [XLEN-1:0] lsu_result;

  always_comb
    (* full_case, parallel_case *) case (decode_wb_src_sel)
      ALU_DATA : ex_result = alu_result;
      MDU_DATA : ex_result = mdu_result;
      LSU_DATA : ex_result = lsu_result;
      PC_DATA  : ex_result = f_next_pc_i;
      IMM_DATA : ex_result = imm;
    endcase

  miriscv_alu alu (
    .alu_port_a_i      (op1                  ),
    .alu_port_b_i      (op2                  ),
    .cmp_a_i           (r1_data              ),
    .cmp_b_i           (r2_data              ),
    .alu_op_i          (decode_alu_operation ),
    .alu_result_o      (alu_result           ),
    .alu_branch_des_o  (branch_des           ),

    .alu_add           (alu_add)
  );

  miriscv_mdu mdu (
    .clk_i           (clk_i                            ),
    .arstn_i         (arstn_i                          ),
    .mdu_req_i       (decode_ex_mdu_req                ),
    .mdu_port_a_i    (r1_data                          ),
    .mdu_port_b_i    (r2_data                          ),
    .mdu_op_i        (decode_mdu_operation             ),
    .mdu_kill_i      (1'b0                             ),
    .mdu_keep_i      (1'b0                             ),
    .mdu_result_o    (mdu_result                       ),
    .mdu_stall_req_o (mdu_stall_req                    )
  );

  miriscv_lsu lsu (
    // clock, reset
    .clk_i                   (clk_i                      ),
    .rst_n                   (arstn_i                    ),

    // data memory interface
    .data_rvalid_i           (data_rvalid_i              ),
    .data_rdata_i            (data_rdata_i               ),
    .data_req_o              (data_req_o                 ),
    .data_we_o               (data_we_o                  ),
    .data_be_o               (data_be_o                  ),
    .data_addr_o             (data_addr_o                ),
    .data_wdata_o            (data_wdata_o               ),

    // core pipeline signals
    .lsu_req_i               (decode_mem_req             ),
    .lsu_kill_i              (1'b0                       ),
    .lsu_keep_i              (1'b0                       ),
    .lsu_we_i                (decode_mem_we              ),
    .lsu_size_i              (decode_mem_size            ),
    .lsu_addr_i              (decode_mem_addr            ),
    .lsu_data_i              (decode_mem_data            ),
    .lsu_data_o              (lsu_result                 ),

    // control and status signals
    .lsu_stall_o             (lsu_stall_req              )
  );

  // Control Unit
  logic [1:0] boot_addr_load;

  always_ff @(posedge clk_i) begin
    if(~arstn_i) begin
      boot_addr_load <= '0;
    end else begin
      boot_addr_load <= {boot_addr_load[0], 1'b1};
    end
  end

  assign cu_boot_addr_load_en_o = ~boot_addr_load[1];

  assign cu_stall_f_o = cu_boot_addr_load_en_o  | lsu_stall_req | mdu_stall_req;
  assign cu_kill_f_o  = (branch_des & d_branch) | d_jal | d_jalr;

  assign cu_kill_d_o  = 'b0;
  assign cu_stall_d_o = cu_stall_f_o;

  // precompute PC values in case of jump
  assign cu_pc_bra_o = alu_add;

  // RVFI INTERFACE
  if (RVFI) begin
    always_ff @(posedge clk_i) begin
      if(~arstn_i) begin
        d_rvfi_wb_data_o        <= 'd0;
        d_rvfi_wb_we_o          <= 'd0;
        d_rvfi_wb_rd_addr_o     <= 'd0;

        d_rvfi_instr_o          <= 'd0;
        d_rvfi_rs1_addr_o       <= 'd0;
        d_rvfi_rs2_addr_o       <= 'd0;
        d_rvfi_op1_gpr_o        <= 'd0;
        d_rvfi_op2_gpr_o        <= 'd0;
        d_rvfi_rs1_rdata_o      <= 'd0;
        d_rvfi_rs2_rdata_o      <= 'd0;
        d_rvfi_current_pc_o     <= 'd0;
        d_rvfi_next_pc_o        <= 'd0;
        d_rvfi_valid_o          <= 'd0;
        d_rvfi_trap_o           <= 'd0;
        d_rvfi_intr_o           <= 'd0;

        d_rvfi_mem_req_o        <= 'd0;
        d_rvfi_mem_we_o         <= 'd0;
        d_rvfi_mem_size_o       <= 'd0;
        d_rvfi_mem_addr_o       <= 'd0;
        d_rvfi_mem_wdata_o      <= 'd0;
        d_rvfi_mem_rdata_o      <= 'd0;
      end

      else if (cu_kill_d_o) begin
        d_rvfi_wb_data_o        <= 'd0;
        d_rvfi_wb_we_o          <= 'd0;
        d_rvfi_wb_rd_addr_o     <= 'd0;

        d_rvfi_instr_o          <= 'd0;
        d_rvfi_rs1_addr_o       <= 'd0;
        d_rvfi_rs2_addr_o       <= 'd0;
        d_rvfi_op1_gpr_o        <= 'd0;
        d_rvfi_op2_gpr_o        <= 'd0;
        d_rvfi_rs1_rdata_o      <= 'd0;
        d_rvfi_rs2_rdata_o      <= 'd0;
        d_rvfi_current_pc_o     <= 'd0;
        d_rvfi_next_pc_o        <= 'd0;
        d_rvfi_valid_o          <= 'd0;
        d_rvfi_trap_o           <= 'd0;
        d_rvfi_intr_o           <= 'd0;

        d_rvfi_mem_req_o        <= 'd0;
        d_rvfi_mem_we_o         <= 'd0;
        d_rvfi_mem_size_o       <= 'd0;
        d_rvfi_mem_addr_o       <= 'd0;
        d_rvfi_mem_wdata_o      <= 'd0;
        d_rvfi_mem_rdata_o      <= 'd0;
      end

      else if (~cu_stall_d_o) begin
        d_rvfi_wb_data_o        <= gpr_wr_data;
        d_rvfi_wb_we_o          <= gpr_wr_en;
        d_rvfi_wb_rd_addr_o     <= gpr_wr_addr;

        d_rvfi_instr_o          <= f_instr_i;
        d_rvfi_rs1_addr_o       <= r1_addr;
        d_rvfi_rs2_addr_o       <= r2_addr;
        d_rvfi_op1_gpr_o        <= decode_rs1_re;
        d_rvfi_op2_gpr_o        <= decode_rs2_re;
        d_rvfi_rs1_rdata_o      <= op1;
        d_rvfi_rs2_rdata_o      <= op2;
        d_rvfi_current_pc_o     <= f_current_pc_i;
        d_rvfi_next_pc_o        <= f_next_pc_i;
        d_rvfi_valid_o          <= f_valid_i;
        d_rvfi_trap_o           <= 'd0;
        d_rvfi_intr_o           <= 'd0;

        d_rvfi_mem_req_o        <= decode_mem_req;
        d_rvfi_mem_we_o         <= decode_mem_we;
        d_rvfi_mem_size_o       <= decode_mem_size;
        d_rvfi_mem_addr_o       <= decode_mem_addr;
        d_rvfi_mem_wdata_o      <= decode_mem_data;
        d_rvfi_mem_rdata_o      <= lsu_result;
      end

    end
  end
  else begin
    
    assign d_rvfi_wb_data_o        = 'd0;
    assign d_rvfi_wb_we_o          = 'd0;
    assign d_rvfi_wb_rd_addr_o     = 'd0;

    assign d_rvfi_instr_o          = 'd0;
    assign d_rvfi_rs1_addr_o       = 'd0;
    assign d_rvfi_rs2_addr_o       = 'd0;
    assign d_rvfi_op1_gpr_o        = 'd0;
    assign d_rvfi_op2_gpr_o        = 'd0;
    assign d_rvfi_rs1_rdata_o      = 'd0;
    assign d_rvfi_rs2_rdata_o      = 'd0;
    assign d_rvfi_current_pc_o     = 'd0;
    assign d_rvfi_next_pc_o        = 'd0;
    assign d_rvfi_valid_o          = 'd0;
    assign d_rvfi_trap_o           = 'd0;
    assign d_rvfi_intr_o           = 'd0;

    assign d_rvfi_mem_req_o        = 'd0;
    assign d_rvfi_mem_we_o         = 'd0;
    assign d_rvfi_mem_size_o       = 'd0;
    assign d_rvfi_mem_addr_o       = 'd0;
    assign d_rvfi_mem_wdata_o      = 'd0;
    assign d_rvfi_mem_rdata_o      = 'd0;
  end
endmodule
