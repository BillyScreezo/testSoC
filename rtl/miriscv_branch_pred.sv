module miriscv_branch_pred
    import miriscv_pkg::XLEN;
    import miriscv_opcodes_pkg::OPCODE_BRANCH;
(
    input   logic               arstn_i,
    input   logic               clk_i,

    input   logic   [XLEN-1:0]  pc_i,       // Текущий PC для которого предсказывается переход
    input   logic   [XLEN-1:0]  instr_i,    // Инструкция для соответствующего PC

    output  logic               flag_o      // Флаг, что переход должен произойти, выставляется комбинационно
);
  
    assign flag_o = ( instr_i[6:0] == OPCODE_BRANCH ) & ( instr_i[XLEN-1] ); 

endmodule
