`include "defines.v"

module IFetcher (
    input wire clk, rst, rdy,

    // ICache
    input  wire          IC_ins_sgn,
    input  wire [31 : 0] IC_ins,
    output wire          IC_pc_sgn,
    output wire [31 : 0] IC_pc,

    // Issue
    input  wire          IS_stall,
    output wire          IS_ins_sgn,
    output wire [31 : 0] IS_ins,
    output reg           IS_jump_flag,
    output reg  [31 : 0] IS_jump_pc
);

    wire [31 : 0]   ins = IC_ins;

    reg  [31 : 0]   pc, next_pc;
    wire [ 6 : 0]   op = IC_ins[6 : 0];

    reg  [31 : 0]   imm;
    reg  [ 1 : 0]   BHB[`BHBSZ];

    reg             IF_stall;

    assign IS_ins_sgn = IC_ins_sgn;
    assign IS_ins = IC_ins;
    assign IC_pc_sgn = !IF_stall && !IS_stall;
    assign IC_pc = next_pc;

    always @(*) begin
        case (op)
            `JALOP  : imm = {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21]} << 1;
            `JALROP : imm = {{20{ins[31]}}, ins[31:20]};
            default : imm = {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8]} << 1;          // branch
        endcase
    end

    always @(*) begin
        if (!IS_stall && IC_ins_sgn) begin
            if (op == `BROP) begin
                if (BHB[pc[`BHBID]][1]) begin
                    next_pc = pc + imm;
                    IS_jump_flag = `True;
                    IS_jump_pc = pc + 4;
                end else begin
                    next_pc = pc + 4;
                    IS_jump_flag = `False;
                    IS_jump_pc = pc + imm;
                end
                IF_stall = `False;
            end else if (op == `JALOP) begin
                next_pc = pc + imm;
                IS_jump_pc = pc + 4;
                IF_stall = `False;
            end else if (op == `JALROP) begin
                IS_jump_pc = pc + 4;
                IF_stall = `True;
            end else if (op == `AUIPCOP) begin
                IS_jump_pc = pc;
                IF_stall = `False;
            end else begin
                next_pc = pc + 4;
                IF_stall = `False;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'b0;
        end else if (!rdy) begin
            
        end else if (IS_stall) begin
            
        end else if (IC_ins_sgn) begin // pc <= next_pc ?
            case (op)
                `BROP: begin
                    if (BHB[pc[`BHBID]][1])
                        pc <= pc + imm;
                    else 
                        pc <= pc + 4;
                end
                `JALOP: pc <= pc + imm;
                `JALROP: pc <= pc;
                default: pc <= pc + 4;
            endcase
        end
    end

endmodule