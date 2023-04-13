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
        output  logic [XLEN-1:0]  instr_o,
        output  logic             fetch_rvalid_o
    );

    logic [XLEN-1:0] pc_reg, c_pc, n_pc, c_pc_f, n_pc_f, c_pc_o, n_pc_o;
    logic [XLEN-1:0] pc_next;
    logic [XLEN-1:0] pc_plus_inc;

    logic stall_f;
    logic [XLEN-1:0] instr_f, instr;

// ==============================================
// ===================== Stall logic
// ==============================================

    always_ff @(posedge clk_i)
        if(~arstn_i)
            stall_f <= '0;
        else
            stall_f <= cu_stall_f_i;

    always_ff @(posedge clk_i) begin   // Если был stall - сохраняем инструкцию из регистра памяти для выдачи её на следующий такт
        instr_f <= (cu_stall_f_i & !stall_f) ? instr_rdata_i : instr_f;
        c_pc_f  <= (cu_stall_f_i & !stall_f) ? c_pc : c_pc_f;
        n_pc_f  <= (cu_stall_f_i & !stall_f) ? n_pc : n_pc_f;
    end

    assign instr  = (stall_f) ? instr_f : instr_rdata_i; // Если был stall - на следующий такт выдаём сохранённую инструкцию и PC
    assign c_pc_o = (stall_f) ? c_pc_f : c_pc;
    assign n_pc_o = (stall_f) ? n_pc_f : n_pc;

// ==============================================
// ===================== PC logic
// ==============================================

    always_ff @(posedge clk_i)
        if ( ~arstn_i )
            pc_reg          <= '0;
        else if ( cu_boot_addr_load_en_i )
            pc_reg          <= boot_addr_i;
        else if ( !cu_stall_f_i )
            pc_reg <= pc_next;

    always_ff @(posedge clk_i) begin
        c_pc  <= pc_reg;
        n_pc  <= pc_plus_inc;
    end

    always_comb begin
        pc_next = pc_plus_inc;

            if(cu_kill_f_i)
                pc_next = cu_pc_bra_i;
    end

    assign pc_plus_inc  = pc_reg + 'd4;

// ==============================================
// ===================== Pipeline reg
// ==============================================

    always_ff @(posedge clk_i) begin
        if(~arstn_i) begin
            instr_o                 <= { {(XLEN-8){1'b0}}, 8'h13 };
            fetch_rvalid_o          <= '0;
            fetched_pc_addr_o       <= '0;
            fetched_pc_next_addr_o  <= '0;
        end else if (~cu_stall_f_i )begin
            instr_o                 <= (cu_kill_f_i | ~instr_rvalid_i) ? { {(XLEN-8){1'b0}}, 8'h13 } : instr;
            fetch_rvalid_o          <= (cu_kill_f_i | ~instr_rvalid_i) ? '0 : '1;
            fetched_pc_addr_o       <= c_pc_o;
            fetched_pc_next_addr_o  <= n_pc_o;
        end
    end

// ==============================================
// ===================== Instr ram 
// ==============================================

    assign instr_req_o  = ~(cu_kill_f_i);
    assign instr_addr_o = pc_reg;

endmodule
