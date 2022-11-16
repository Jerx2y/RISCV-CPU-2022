//    LUI,    U    Load Upper Immediate
//    AUIPC,  U    Add Upper Immediate to PC
//    JAL,    J    Jump & Link
//    JALR,   I    Jump & Link Register

//    BEQ,    B    Branch Equal
//    BNE,    B    Branch Not Equal
//    BLT,    B    Branch Less Than
//    BGE,    B    Branch Greater than or Equal
//    BLTU,   B    Branch Less than Unsigned
//    BGEU,   B    Branch Greater than or Equal Unsigned
//    LB,     I    Load Byte
//    LH,     I    Load Halfword
//    LW,     I    Load Word
//    LBU,    I    Load Byte Unsigned
//    LHU,    I    Load Halfword Unsigned
//    SB,     S    Store Byte
//    SH,     S    Store Halfword
//    SW,     S    Store Word
//    ADDI,   I    ADD Immediate
//    SLTI,   I    Set Less than Immediate
//    SLTIU,  I    Set Less than Immediate Unsigned
//    XORI,   I    XOR Immediate
//    ORI,    I    OR Immediate
//    ANDI,   I    AND Immediate
//    SLLI,   I    Shift Left Immediate
//    SRLI,   I    Shift Right Immediate
//    SRAI,   I    Shift Right Arith Immediate
//    ADD,    R    ADD
//    SUB,    R    SUBtract
//    SLL,    R    Shift Left
//    SLT,    R    Set Less than
//    SLTU,   R    Set Less than Unsigned
//    XOR,    R    XOR
//    SRL,    R    Shift Right
//    SRA,    R    Shift Right Arithmetic
//    OR,     R    OR
//    AND     R    AND

`include "defines.v"

module IFetcher (
    input wire clk, rst, rdy,

    // ICache
    input  wire          IC_ins_sgn,
    input  wire [31 : 0] IC_ins,
    output wire [31 : 0] IC_pc,

    // Issue
    input  wire          IS_stall,
    output wire          IS_ins_sgn,
    output wire [31 : 0] IS_ins
);

    reg [31 : 0] pc, next_pc;
    wire [6 : 0] op = IC_ins[6 : 0];

    assign IS_ins_sgn = IC_ins_sgn;
    assign IS_ins = IC_ins;
    assign IC_pc = next_pc;

    always @(*) begin
        
    end

    always @(posedge clk) begin
        if (rdy) begin
        end
    end

endmodule