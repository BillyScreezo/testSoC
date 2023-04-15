    
    import miriscv_comdecode_pkg::*;

    logic [31:0] f_instr;
    logic [31:0] d_instr;
    // logic [31:0] f_rs1;
    // logic [31:0] f_rs2;
    // logic [31:0] f_rd;
    // logic [31:0] f_imm;
    logic [31:0] d_imm;
    logic        d_alu_flag;
    logic [31:0] d_ram_cell_ls_op;
    logic [31:0] d_branch_addr;
    logic        d_gpr_we;

    logic [4:0]  d_addr_rs1;
    logic [4:0]  d_addr_rs2;
    logic [4:0]  d_addr_rd;
    logic [31:0] d_rs1;
    logic [31:0] d_rs2;
    logic [31:0] d_rd;

    logic [31:0] f_current_PC;
    logic [31:0] d_current_PC;
    logic [31:0] f_next_PC;
    logic [31:0] d_next_PC;


    assign d_current_PC     = DUT.core.fetch.fetch_unit.f_current_pc_o;
    assign d_next_PC        = DUT.core.fetch.fetch_unit.f_next_pc_o;
    assign f_current_PC     = DUT.core.fetch.fetch_unit.f_next_pc_o;
    assign f_next_PC        = DUT.core.fetch.fetch_unit.instr_addr_o;
    assign f_instr          = DUT.core.fetch.fetch_unit.instr_rdata_i;
    assign d_instr          = DUT.core.fetch.fetch_unit.f_instr_o;

    assign d_rs1            = DUT.core.decode.gpr.r1_data_o;
    assign d_rs2            = DUT.core.decode.gpr.r2_data_o;
    assign d_rd             = DUT.core.decode.gpr.wr_data_i;
    assign d_imm            = DUT.core.decode.imm_inst.imm_o;
    assign d_alu_flag       = DUT.core.decode.alu.alu_branch_des_o;
    assign d_ram_cell_ls_op = DUT.ram.dmem[DUT.core.decode.lsu.data_addr_o];
    assign d_branch_addr    = DUT.core.decode.cu_pc_bra_o;
    assign d_gpr_we         = DUT.core.decode.gpr.wr_en_i;
    assign d_addr_rs1       = DUT.core.decode.gpr.r1_addr_i;
    assign d_addr_rs2       = DUT.core.decode.gpr.r2_addr_i;
    assign d_addr_rd        = DUT.core.decode.gpr.wr_addr_i;

    logic [6:0] f_func7;
    logic [6:0] d_func7;
    logic [6:0] f_opcode;
    logic [6:0] d_opcode;
    logic [2:0] f_func3;
    logic [2:0] d_func3;

    assign f_func7  = f_instr[31:25];
    assign d_func7  = d_instr[31:25];
    assign f_opcode = f_instr[6:0];
    assign d_opcode = d_instr[6:0];
    assign f_func3  = f_instr[14:12];
    assign d_func3  = d_instr[14:12];

    command_t f_command;
    command_t d_command;

    int nop_cnt;
    int all_cnt;

    always_ff @(posedge DUT.core.clk_i or negedge DUT.core.arstn_i) begin
        if(~DUT.core.arstn_i) begin
            nop_cnt <= 0;
            all_cnt <= 0;
        end else begin
            all_cnt <= all_cnt + 1;
            if(d_instr == { {(32-8){1'b0}}, 8'h13 })
                nop_cnt = nop_cnt + 1;
        end
    end

    always_comb begin : f_decode
        if(f_instr == { {(32-8){1'b0}}, 8'h13 })
            f_command = NOP;
        else
        case (f_opcode)
            OPCODE_OP: begin
                case({f_func3, f_func7})
                    ALU_ADD:  f_command = ADD;
                    ALU_SUB:  f_command = SUB;
                    ALU_XOR:  f_command = XOR;
                    ALU_OR:   f_command = OR;
                    ALU_AND:  f_command = AND;
                    ALU_SLL:  f_command = SLL;
                    ALU_SRL:  f_command = SRL;
                    ALU_SRA:  f_command = SRA;
                    ALU_SLTS: f_command = SLTS;
                    ALU_SLTU: f_command = SLTU;
                endcase
            end
            OPCODE_OPIMM: begin
                case({d_func3, d_func7})
                    ALU_SLL:  f_command = SLLI;
                    ALU_SRL:  f_command = SRLI;
                    ALU_SRA:  f_command = SRAI;
                    default: begin 
                        case(d_func3)
                            ALU_ADDI: f_command = ADDI;
                            ALU_XORI: f_command = XORI;
                            ALU_ORI:  f_command = ORI;
                            ALU_ANDI: f_command = ANDI;
                            ALU_SLTSI:f_command = SLTSI;
                            ALU_SLTUI:f_command = SLTUI;
                        endcase
                    end
                endcase
            end
            OPCODE_LOAD: begin
                case(f_func3)
                    'h0: f_command = LOAD_BYTE;
                    'h1: f_command = LOAD_HALF;
                    'h2: f_command = LOAD_WORD;
                    'h4: f_command = LOAD_BYTE_UNSIGN;
                    'h5: f_command = LOAD_HALF_UNSIGN;
                endcase
            end
            OPCODE_STORE: begin
                case(f_func3)
                    'h0: f_command = STORE_BYTE;
                    'h1: f_command = STORE_HALF;
                    'h2: f_command = STORE_WORD;
                endcase
            end
            OPCODE_BRANCH: begin
                case(f_func3)
                    'h0: f_command = BEQ;
                    'h1: f_command = BNE;
                    'h4: f_command = BLT;
                    'h5: f_command = BGE;
                    'h6: f_command = BLTU;
                    'h7: f_command = BGEU;
                endcase
            end
            OPCODE_JAL: begin
                f_command = JAL;
            end
            OPCODE_JALR: begin
                f_command = JALR;
            end
            OPCODE_LUI: begin
                f_command = LUI;
            end
            OPCODE_AUIPC: begin
                f_command = AUIPC;
            end
            OPCODE_SYSTEM: begin
                f_command = SYSTEM;
            end
            OPCODE_FENCE: begin
                f_command = MISCMEM;
            end
        endcase
    end

    always_comb begin : d_decode
        if(d_instr == { {(32-8){1'b0}}, 8'h13 })
            d_command = NOP;
        else
        case (d_opcode)
            OPCODE_OP: begin
                case({d_func3, d_func7})
                    ALU_ADD:  d_command = ADD;
                    ALU_SUB:  d_command = SUB;
                    ALU_XOR:  d_command = XOR;
                    ALU_OR:   d_command = OR;
                    ALU_AND:  d_command = AND;
                    ALU_SLL:  d_command = SLL;
                    ALU_SRL:  d_command = SRL;
                    ALU_SRA:  d_command = SRA;
                    ALU_SLTS: d_command = SLTS;
                    ALU_SLTU: d_command = SLTU;
                endcase
            end
            OPCODE_OPIMM: begin
                case({d_func3, d_func7})
                    ALU_SLL:  d_command = SLLI;
                    ALU_SRL:  d_command = SRLI;
                    ALU_SRA:  d_command = SRAI;
                    default: begin 
                        case(d_func3)
                            ALU_ADDI: d_command = ADDI;
                            ALU_XORI: d_command = XORI;
                            ALU_ORI:  d_command = ORI;
                            ALU_ANDI: d_command = ANDI;
                            ALU_SLTSI:d_command = SLTSI;
                            ALU_SLTUI:d_command = SLTUI;
                        endcase
                    end
                endcase
            end
            OPCODE_LOAD: begin
                case(d_func3)
                    'h0: d_command = LOAD_BYTE;
                    'h1: d_command = LOAD_HALF;
                    'h2: d_command = LOAD_WORD;
                    'h4: d_command = LOAD_BYTE_UNSIGN;
                    'h5: d_command = LOAD_HALF_UNSIGN;
                endcase
            end
            OPCODE_STORE: begin
                case(d_func3)
                    'h0: d_command = STORE_BYTE;
                    'h1: d_command = STORE_HALF;
                    'h2: d_command = STORE_WORD;
                endcase
            end
            OPCODE_BRANCH: begin
                case(d_func3)
                    'h0: d_command = BEQ;
                    'h1: d_command = BNE;
                    'h4: d_command = BLT;
                    'h5: d_command = BGE;
                    'h6: d_command = BLTU;
                    'h7: d_command = BGEU;
                endcase
            end
            OPCODE_JAL: begin
                d_command = JAL;
            end
            OPCODE_JALR: begin
                d_command = JALR;
            end
            OPCODE_LUI: begin
                d_command = LUI;
            end
            OPCODE_AUIPC: begin
                d_command = AUIPC;
            end
            OPCODE_SYSTEM: begin
                d_command = SYSTEM;
            end
            OPCODE_FENCE: begin
                d_command = MISCMEM;
            end
        endcase
    end
