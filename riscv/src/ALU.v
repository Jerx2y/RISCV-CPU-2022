`include "defines.v"

module ALU (
    input wire clk, rst, rdy,

    // RS
    input wire            RS_sgn,
    input wire  [ 5 : 0]  RS_opcode,
    input wire  [`ROBID]  RS_ROB_name,
    input wire  [31 : 0]  RS_lhs,
    input wire  [31 : 0]  RS_rhs,

    // IF
    output reg            IF_sgn,
    output reg  [31 : 0]  IF_pc,

    // LSB
    output reg            LSB_sgn,
    output reg  [31 : 0]  LSB_result,
    output reg  [`ROBID]  LSB_ROB_name,

    // CDB
    output wire           CDB_sgn,
    output wire [31 : 0]  CDB_result,
    output wire [`ROBID]  CDB_ROB_name
);

    reg          sgn;
    reg [31 : 0] result;
    reg [ 5 : 0] opcode;
    reg [`ROBID] ROB_name;

    wire [31 : 0] lhs = RS_lhs;
    wire [31 : 0] rhs = RS_rhs;

    assign CDB_result   = result;
    assign CDB_sgn      = sgn;
    assign CDB_ROB_name = ROB_name;

    always @(*) begin
        if (RS_sgn) begin
            case (RS_opcode)
                `ADD   : result = lhs + rhs;
                `ADDI  : result = lhs + rhs;
                `SUB   : result = lhs - rhs;
                `XOR   : result = lhs ^ rhs;
                `XORI  : result = lhs ^ rhs;
                `OR    : result = lhs | rhs;
                `ORI   : result = lhs | rhs;
                `AND   : result = lhs & rhs;
                `ANDI  : result = lhs & rhs;
                `SLL   : result = lhs << rhs[4:0];
                `SLLI  : result = lhs << rhs[4:0];
                `SRL   : result = lhs >> rhs[4:0];
                `SRLI  : result = lhs >> rhs[4:0];
                `SRA   : result = $signed(lhs) >> rhs[4:0];
                `SRAI  : result = $signed(lhs) >> rhs[4:0];
                `SLT   : result = $signed(lhs) < $signed(rhs);
                `SLTI  : result = $signed(lhs) < $signed(rhs);
                `SLTU  : result = lhs < rhs;
                `SLTIU : result = lhs < rhs;
                `BEQ   : result = lhs == rhs;
                `BNE   : result = lhs != rhs;
                `BLT   : result = $signed(lhs) < $signed(rhs);
                `BGE   : result = $signed(lhs) >= $signed(rhs);
                `BLTU  : result = lhs < rhs;
                `BGEU  : result = lhs >= rhs;
                `JALR  : result = (lhs + rhs) & ~(32'b1);
                `LTYPE : result = lhs + rhs;
                `STYPE : result = lhs + rhs;
                default: result = 0;
            endcase
            opcode = RS_opcode;
            ROB_name = RS_ROB_name;
            if (opcode == `STYPE || opcode == `LTYPE) begin
                IF_sgn = `False;
                sgn = `False;
                LSB_sgn = `True;
                LSB_ROB_name = ROB_name;
                LSB_result = result;
            end else begin
                sgn = `True;
                LSB_sgn = `False;
                if (opcode == `JALR) begin
                    IF_sgn = `True;
                    IF_pc = result;
                end else begin
                    IF_sgn = `False;
                end
            end
        end else begin
            sgn = `False;
            LSB_sgn = `False;
            IF_sgn = `False;
        end
    end

endmodule