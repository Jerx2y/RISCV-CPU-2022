`include "defines.v"

module IFetcher (
    input wire clk, rst, rdy,

    // ICache
    input  wire          IC_ins_sgn,
    input  wire [31 : 0] IC_ins,
    output wire          IC_pc_sgn,
    output wire [31 : 0] IC_pc,

    // Issue
    output reg           IS_ins_sgn,
    output wire [31 : 0] IS_ins,
    output reg           IS_jump_flag,
    output reg  [31 : 0] IS_jump_pc,

    // ALU
    input  wire          ALU_sgn,
    input  wire [31 : 0] ALU_pc,

    // ROB
    input  wire          ROB_jp_wrong,
    input  wire [31 : 0] ROB_jp_tar,
    input  wire          ROB_full,
    input  wire          ROB_jump_sgn,
    input  wire          ROB_need_jump,

    // LSB
    input  wire          LSB_full
);

    wire [31 : 0]   ins = IC_ins;

    reg  [31 : 0]   pc, next_pc;
    wire [ 6 : 0]   op = IC_ins[6 : 0];

    reg  [31 : 0]   imm;

    reg             IF_stall;

    // assign IS_ins_sgn = IC_ins_sgn;
    assign IS_ins = IC_ins;
    assign IC_pc_sgn = !IF_stall && !ROB_full && !LSB_full;
    assign IC_pc = next_pc;

    always @(*) begin
        case (op)
            `JALOP  : imm = {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21]} << 1;
            `JALROP : imm = {{20{ins[31]}}, ins[31:20]};
            default : imm = {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8]} << 1;          // branch
        endcase
    end

    reg last_full;
    reg IF_stall_tmp;
    reg IS_ins_sgn_tmp;
    reg IS_jump_flag_tmp;
    reg [31 : 0] IS_jump_pc_tmp ;
    reg [31 : 0] next_pc_tmp;

    always @(*) begin
        if (rst) begin
            next_pc = 0;
            IF_stall = `False;
            IS_ins_sgn = `False;
            IS_jump_flag = 0;
            IS_jump_pc = 0;
        end else if (ROB_full || LSB_full) begin
            next_pc = pc;
            IF_stall = IF_stall_tmp;
            IS_ins_sgn = IS_ins_sgn_tmp;
            IS_jump_flag = IS_jump_flag_tmp;
            IS_jump_pc = IS_jump_pc_tmp;
            if (!last_full)
                IS_ins_sgn = IC_ins_sgn;
        end else if (IC_ins_sgn) begin
            IS_ins_sgn = `True;
            IS_jump_flag = 0;
            IS_jump_pc = 0;
            if (op == `BROP) begin
                next_pc = pc;
                IS_jump_flag = `False;
                IS_jump_pc = pc + imm;
                IF_stall = `True;
            end else if (op == `JALOP) begin
                next_pc = pc + imm;
                IS_jump_pc = pc + 4;
                IF_stall = `False;
            end else if (op == `JALROP) begin
                next_pc = pc;
                IS_jump_pc = pc + 4;
                IF_stall = `True;
            end else if (op == `AUIPCOP) begin
                next_pc = pc + 4;
                IS_jump_pc = pc;
                IF_stall = `False;
            end else begin
                next_pc = pc + 4;
                IF_stall = `False;
                IS_jump_pc = 0;
            end
        end else begin
            IS_ins_sgn = IF_stall && (last_full) && IS_ins_sgn_tmp;
            IF_stall = IF_stall_tmp;
            IS_jump_flag = IS_jump_flag_tmp;
            IS_jump_pc = IS_jump_pc_tmp;
            next_pc = next_pc_tmp;
        end

        if (ALU_sgn)  begin
            next_pc = ALU_pc;
            IF_stall = `False;
        end

        if (ROB_jump_sgn) begin
            if (ROB_need_jump)
                next_pc = ROB_jp_tar;
            else next_pc = pc + 4;
            IF_stall = `False;
        end
    end

    always @(posedge clk) begin
        IF_stall_tmp <= IF_stall;
        IS_ins_sgn_tmp <= IS_ins_sgn;
        IS_jump_flag_tmp <= IS_jump_flag;
        IS_jump_pc_tmp <= IS_jump_pc;
        last_full <= ROB_full || LSB_full;
        next_pc_tmp <= next_pc;
        if (rst) begin
            pc <= 0;
        end else if (!rdy) begin
            
        end else if (IC_ins_sgn || ALU_sgn || ROB_jump_sgn) begin
            pc <= next_pc;
        end
    end

endmodule