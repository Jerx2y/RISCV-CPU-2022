`include "defines.v"

module Issue (
    input wire clk, rst, rdy,

    // IFetcher
    input wire              IF_ins_sgn,
    input wire   [31 : 0]   IF_ins,
    input wire              IF_jump_flag,
    input wire   [31 : 0]   IF_jump_pc,

    // ROB
    input wire   [`ROBID]   ROB_name,
    output reg              ROB_sgn,
    output reg              ROB_ready,
    output reg   [ 5 : 0]   ROB_opcode,
    output reg   [31 : 0]   ROB_value,
    output reg   [ 4 : 0]   ROB_dest,
    output reg              ROB_jumped,
    output reg   [31 : 0]   ROB_jumpto,

    // RS
    input wire              RS_full,
    output reg              RS_sgn,
    output reg   [ 5 : 0]   RS_opcode,
    output reg   [31 : 0]   RS_rs1_val,
    output reg   [31 : 0]   RS_rs2_val,
    output reg              RS_rs1_rdy,
    output reg              RS_rs2_rdy,

    // LSB
    input wire              LSB_full,
    input wire   [`LSBID]   LSB_name,
    output reg              LSB_sgn,
    output reg   [ 5 : 0]   LSB_opcode,
    output reg   [31 : 0]   LSB_adr_val,
    output reg   [31 : 0]   LSB_val_val,
    output reg              LSB_adr_rdy,
    output reg              LSB_val_rdy,

    // REG
    input  wire  [31 : 0]   REG_rs1_val,
    input  wire  [31 : 0]   REG_rs2_val,
    input  wire             REG_rs1_rdy,
    input  wire             REG_rs2_rdy,
    output wire  [ 4 : 0]   REG_rs1,
    output wire  [ 4 : 0]   REG_rs2,
    output reg              REG_sgn,
    output wire  [ 4 : 0]   REG_rd
);

    reg [31 : 0] imm;
    reg [31 : 0] ins, jump_pc;
    reg          jump_flag;

    wire [6 : 0] op;
    wire [4 : 0] rs1    =  ins[19 : 15];
    wire [4 : 0] rs2    =  ins[24 : 20];
    wire [4 : 0] rd     =  ins[11 :  7];
    wire [2 : 0] func3  =  ins[14 : 12];
    wire [6 : 0] func7  =  ins[31 : 25];
    wire [4 : 0] shamt  =  ins[24 : 20];

    assign REG_rs1 = rs1;
    assign REG_rs2 = rs2;
    assign REG_rd  = rd;

    always @(*) begin
        if (ROB_sgn) begin
            case (op)
                `LUIOP: begin
                    imm = {ins[31:12], 12'b0};                                 

                    RS_sgn = `False;

                    LSB_sgn = `False;

                    ROB_dest = rd;
                    ROB_opcode = `LUI;
                    ROB_ready = `True;
                    ROB_value = imm;

                    REG_sgn = `True;
                end
                `AUIPCOP: begin // jump_pc is "pc"
                    imm = {ins[31:12], 12'b0};                                 

                    RS_sgn = `False;

                    LSB_sgn = `False;

                    ROB_dest = rd;
                    ROB_opcode = `AUIPC;
                    ROB_ready = `True;
                    ROB_value = jump_pc + imm;

                    REG_sgn = `True;
                end
                `JALOP: begin // jump_pc is "pc + 4"
                    RS_sgn = `False;

                    LSB_sgn = `False;

                    ROB_dest = rd;
                    ROB_opcode = `JAL;
                    ROB_ready = `True;
                    ROB_value = jump_pc;

                    REG_sgn = `True;
                end
                `JALROP: begin // jump_pc is 't'
                    imm = {{20{ins[31]}}, ins[31:20]};

                    RS_sgn = `True;
                    RS_opcode = `JALR;
                    RS_rs1_val = REG_rs1_val;
                    RS_rs1_rdy = REG_rs1_rdy;
                    RS_rs2_val = imm;
                    RS_rs2_rdy = `True;

                    LSB_sgn = `False;

                    ROB_dest = rd;
                    ROB_opcode = `JALR;
                    ROB_ready = `True;
                    ROB_value = jump_pc;

                    REG_sgn = `True;
                end
                `BROP: begin
                    imm = {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8]} << 1;
                    case (func3)
                        3'b000: RS_opcode = `BEQ;   // BEQ
                        3'b001: RS_opcode = `BNE;   // BNE
                        3'b100: RS_opcode = `BLT;   // BLT
                        3'b101: RS_opcode = `BGE;   // BGE
                        3'b110: RS_opcode = `BLTU;  // BLTU
                        3'b111: RS_opcode = `BGEU;  // BGEU
                    endcase
                    RS_sgn     = `True;
                    RS_rs1_val = REG_rs1_val;
                    RS_rs1_rdy = REG_rs1_rdy;
                    RS_rs2_val = REG_rs2_val;
                    RS_rs2_rdy = REG_rs2_rdy;

                    LSB_sgn    = `False;

                    ROB_opcode = `BTYPE;
                    ROB_jumped = IF_jump_flag;
                    ROB_jumpto = IF_jump_pc;
                    ROB_ready  = `False;

                    REG_sgn = `False;
                end
                `LOP: begin
                    imm = {{20{ins[31]}}, ins[31:20]};
                    case (func3)
                        3'b000: LSB_opcode = `LB;
                        3'b001: LSB_opcode = `LH;
                        3'b010: LSB_opcode = `LW;
                        3'b100: LSB_opcode = `LBU;
                        3'b101: LSB_opcode = `LHU;
                    endcase
                    RS_sgn      = `True;
                    RS_rs1_val  = REG_rs1_val;
                    RS_rs1_rdy  = REG_rs1_rdy;
                    RS_rs2_val  = imm;
                    RS_rs2_rdy  = `True;
                    RS_opcode   = `ADD;

                    LSB_sgn     = `True;
                    LSB_adr_val = ROB_name;
                    LSB_adr_rdy = `False;
                    LSB_val_val = ROB_name; // Similar to ROB_name
                    LSB_val_rdy = `True;

                    ROB_opcode  = `LTYPE;
                    ROB_dest    = rd;
                    ROB_ready   = `False;

                    REG_sgn = `True;
                end
                `SOP: begin
                    imm = {{20{ins[31]}}, ins[31:25], ins[11:7]};
                    case (func3)
                        3'b000: LSB_opcode = `SB;
                        3'b001: LSB_opcode = `SH;
                        3'b010: LSB_opcode = `SW;
                    endcase
                    RS_sgn     = `True;
                    RS_rs1_val = REG_rs1_val;
                    RS_rs1_rdy = REG_rs1_rdy;
                    RS_rs2_val = imm;
                    RS_rs2_rdy = `True;
                    RS_opcode  = `ADD;

                    LSB_sgn     = `True;
                    LSB_adr_val = ROB_name;
                    LSB_adr_rdy = `False;
                    LSB_val_rdy = `False;

                    ROB_dest    = LSB_name;
                    ROB_opcode  = `STYPE;
                    ROB_value   = REG_rs2_val;
                    ROB_ready   = REG_rs2_rdy;

                    REG_sgn = `False;
                end
                `IOP: begin
                    imm = {{20{ins[31]}}, ins[31:20]};
                    case (func3)
                        3'b000: begin
                            RS_opcode = `ADDI;
                            RS_rs2_val = imm;
                        end
                        3'b010: begin
                            RS_opcode = `SLTI;
                            RS_rs2_val = imm;
                        end
                        3'b011: begin 
                            RS_opcode = `SLTIU;
                            RS_rs2_val = imm;
                        end
                        3'b100: begin 
                            RS_opcode = `XORI;
                            RS_rs2_val = imm;
                        end
                        3'b110: begin 
                            RS_opcode = `ORI;
                            RS_rs2_val = imm;
                        end
                        3'b111: begin 
                            RS_opcode = `ANDI;
                            RS_rs2_val = imm;
                        end
                        3'b001: begin
                            RS_opcode = `SLLI;
                            RS_rs2_val = shamt;
                        end
                        3'b101: begin
                            if (func7 == 7'b0000000) begin
                                RS_opcode = `SRLI;
                                RS_rs2_val = shamt;
                            end else begin
                                RS_opcode = `SRAI;
                                RS_rs2_val = shamt;
                            end
                        end
                    endcase
                    RS_sgn = `True;
                    RS_rs1_val = REG_rs1_val;
                    RS_rs1_rdy = REG_rs1_rdy;
                    RS_rs2_rdy = `True;

                    LSB_sgn = `False;

                    ROB_ready = `False;
                    ROB_opcode = `ITYPE;
                    ROB_dest = rd;

                    REG_sgn = `True;
                end
                `ROP: begin
                    case (func3)
                        3'b000: begin
                            if (func7 == 7'b0000000) begin // ADD
                                RS_opcode = `ADD;
                            end else begin // SUB
                                RS_opcode = `SUB;
                            end
                        end
                        3'b001: begin // SLL
                            RS_opcode = `SLL;
                        end
                        3'b010: begin // SLT
                            RS_opcode = `SLT;
                        end
                        3'b011: begin // SLTU
                            RS_opcode = `SLTU;
                        end
                        3'b100: begin // XOR
                            RS_opcode = `XOR;
                        end
                        3'b101: begin
                            if (func7 == 7'b0000000) begin // SRL
                                RS_opcode = `SRL;
                            end else begin // SRA
                                RS_opcode = `SRA;
                            end
                        end
                        3'b110: begin // OR
                            RS_opcode = `OR;
                        end
                        3'b111: begin // AND
                            RS_opcode = `AND;
                        end
                    endcase
                    RS_sgn = `True;
                    RS_rs1_val = REG_rs1_val;
                    RS_rs1_rdy = REG_rs1_rdy;
                    RS_rs2_val = REG_rs2_val;
                    RS_rs2_rdy = REG_rs2_rdy;

                    LSB_sgn = `False;

                    ROB_ready = `False;
                    ROB_opcode = `RTYPE;
                    ROB_dest = rd;

                    REG_sgn = `True;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            ROB_sgn <= `False;
        end else if (!rdy) begin
            
        end else begin
            if (IF_ins_sgn) begin
                ROB_sgn <= `True;
                ins <= IF_ins;
                jump_pc <= IF_jump_pc;
                jump_flag <= IF_jump_flag;
            end else begin
                ROB_sgn <= `False;
            end
        end
    end

endmodule