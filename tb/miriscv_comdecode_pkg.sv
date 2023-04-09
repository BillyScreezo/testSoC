package miriscv_comdecode_pkg;
	
	typedef enum {
	OPCODE_SYSTEM = 7'b1110011,
    OPCODE_FENCE  = 7'b0001111,
    OPCODE_OP     = 7'b0110011,
    OPCODE_OPIMM  = 7'b0010011,
    OPCODE_LOAD   = 7'b0000011,
    OPCODE_STORE  = 7'b0100011,
    OPCODE_BRANCH = 7'b1100011,
    OPCODE_JAL    = 7'b1101111,
    OPCODE_JALR   = 7'b1100111,
    OPCODE_AUIPC  = 7'b0010111,
    OPCODE_LUI    = 7'b0110111} opcode_t;

    typedef enum logic [9:0] {
    	ALU_ADD 	= 10'b000_0000000,
    	ALU_SUB 	= 10'b000_0100000,
    	ALU_XOR 	= 10'b100_0000000,
        ALU_OR 		= 10'b110_0000000,
        ALU_AND 	= 10'b111_0000000,
		ALU_SLL 	= 10'b001_0000000,
        ALU_SRL 	= 10'b101_0000000,
        ALU_SRA 	= 10'b101_0100000,
        ALU_SLTS 	= 10'b010_0000000,
        ALU_SLTU 	= 10'b011_0000000
    } alu_op_t;

    typedef enum {
        NOP,
        ADD,
        SUB,
        XOR,
        OR,
        AND,
        SLL,
        SRL,
        SRA,
        SLTS,
        SLTU,
        ADDI,
        XORI,
        ORI,
        ANDI,
        SLLI,
        SRLI,
        SRAI,
        SLTSI,
        SLTUI,
        LOAD_BYTE,
        LOAD_HALF,
        LOAD_WORD,
        LOAD_BYTE_UNSIGN,
        LOAD_HALF_UNSIGN,
        STORE_BYTE,
        STORE_HALF,
        STORE_WORD,
        BEQ,
        BNE,
        BLT,
        BGE,
        BLTU,
        BGEU,
        JAL,
        JALR,
        LUI,
        AUIPC,
        SYSTEM,
        MISCMEM
    } command_t;

endpackage : miriscv_comdecode_pkg